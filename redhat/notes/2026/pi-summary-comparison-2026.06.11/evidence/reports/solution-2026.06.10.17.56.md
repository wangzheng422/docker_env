# Nebius L40S 1M Summary-Agent Benchmark Report

| Field | Value |
|---|---|
| Test time | 2026-06-10 17:56-18:17 CST |
| Remote host | `wzh@89.169.120.64` |
| Hostname | `computeinstance-e00xe3xtmfv7ezbh05` |
| OS | Ubuntu 24.04.4 LTS, kernel `6.11.0-1016-nvidia` |
| GPU | 4 x NVIDIA L40S, 46,068 MiB each |
| Runtime | Docker 29.5.3 |
| vLLM image | `registry.redhat.io/rhaii/vllm-cuda-rhel9:3.4.0` |
| vLLM version | `0.18.0+rhaiv.7` as reported by container logs |
| Model | `RedHatAI/Qwen3.5-122B-A10B-FP8-dynamic` |
| Serving profile | `max_model_len=1010000`, `tensor_parallel_size=4`, `max_num_seqs=1`, `max_num_batched_tokens=32768` |
| Long-context method | YaRN/RoPE override with `factor=4.0`, `rope_theta=10000000`, `original_max_position_embeddings=262144` |

## Conclusion

On this rebooted/replaced Nebius 4xL40S host, direct 1M input is faster than the current Pi-style summary agent.

The direct full-context request succeeded in `34.10s` with a single audited `1,000,067` character request. The summary agent also covered the full `1,000,000` character input, but took `194.22s`, about `5.70x` slower than direct 1M. The reason is visible in the request audit: the agent split the document into `42` map calls plus `4` reduce calls, while the vLLM service was started conservatively with `max_num_seqs=1`, so those calls were effectively serialized at the server.

This result is different from the original small-context motivation: once Qwen3.5 is actually served with a verified 1M context window, direct ingestion can be much faster for this synthetic repetitive document. The agent still provides bounded per-call prompts and deterministic coverage, but it is not a latency win on this exact 4xL40S profile.

## GPU Topology

`nvidia-smi topo -m` output:

```text
        GPU0    GPU1    GPU2    GPU3    CPU Affinity    NUMA Affinity   GPU NUMA ID
GPU0     X      PHB     SYS     SYS     0-63            0               N/A
GPU1    PHB      X      SYS     SYS     0-63            0               N/A
GPU2    SYS     SYS      X      PHB     64-127          1               N/A
GPU3    SYS     SYS     PHB      X      64-127          1               N/A
```

There is no NVLink. GPU0/GPU1 share NUMA node 0, GPU2/GPU3 share NUMA node 1, and cross-pair traffic traverses `SYS`. vLLM logged:

```text
SymmMemCommunicator: Device capability 8.9 not supported, communicator is not available.
Custom allreduce is disabled because it's not supported on more than two PCIe-only GPUs.
```

That matches the PCIe-only topology and is relevant to multi-GPU serving efficiency.

## Deployment Evidence

The live endpoint returned:

```json
{"id":"RedHatAI/Qwen3.5-122B-A10B-FP8-dynamic","max_model_len":1010000}
```

The full `/v1/models` response and vLLM startup log are archived under:

- `solution/files/solution-2026-06-10-17-56/prepare-nebius-qwen35-l40s-1m-r6.log`

Important startup observations:

| Observation | Evidence |
|---|---|
| vLLM accepted 1M profile | `Using max model len 1010000` |
| Model architecture | `Qwen3_5MoeForConditionalGeneration` |
| Weight download time | `306.070099 seconds` |
| Model loading time | `327.901683 seconds` |
| Weight memory per worker log | `30.28 GiB memory` |
| torch compile time | `37.45 s` |

## Benchmark Results

| Path | Status | Input chars | Covered chars | Model calls | Max audited request chars | Elapsed seconds | Relative to direct 1M |
|---|---:|---:|---:|---:|---:|---:|---:|
| Summary agent | succeeded | 1,000,000 | 1,000,000 | 46 | 24,181 | 194.22 | 5.70x slower |
| Direct full 1M | succeeded | 1,000,000 | 1,000,000 | 1 | 1,000,067 | 34.10 | baseline |
| Direct clipped | succeeded | 1,000,000 | 28,000 | 1 | 28,067 | 5.77 | 5.91x faster than direct 1M, but only covers 2.8% |

Raw benchmark files:

- `solution/files/solution-2026-06-10-17-56/nebius-l40s-r6-qwen35-1m-benchmark.json`
- `solution/files/solution-2026-06-10-17-56/nebius-l40s-r6-qwen35-1m-benchmark.stdout`
- `solution/files/solution-2026-06-10-17-56/nebius-l40s-r6-qwen35-1m-requests.jsonl`

## LLM Input Audit

The request audit contains `48` JSONL records and preserves full request `messages`.

| Call range | Role in test | Count | Request char count |
|---|---:|---:|---|
| 1-42 | Agent map calls | 42 | min `23,367`, max `24,181` |
| 43-46 | Agent reduce calls | 4 | `23,750`, `21,377`, `4,581`, `2,319` |
| 47 | Direct full 1M | 1 | `1,000,067` |
| 48 | Direct clipped | 1 | `28,067` |

So the exact LLM-facing contrast is:

- Agent path: never sends the whole source in one prompt; it sends bounded map/reduce prompts.
- Direct full path: sends the whole synthetic 1M document in one request, and succeeds because the endpoint is configured for `max_model_len=1010000`.

## Notes And Risks

- This is a latency and coverage benchmark, not a summary-quality benchmark. The test input is synthetic and highly repetitive.
- `max_num_seqs=1` was chosen to keep the 1M profile stable on 46 GB L40S cards. It strongly disadvantages the agent because the agent needs many small LLM calls.
- A follow-up experiment could start vLLM with a second profile optimized for many short concurrent requests, but that would be a different serving configuration from the proven 1M direct profile.
- The model returned reasoning-style content in the benchmark output. The current client reads the OpenAI-compatible response content path used by this Red Hat vLLM/Qwen configuration.

## Modified Artifact

The deployment helper was updated so the replacement host can run tensor parallelism across all four L40S GPUs:

```text
scripts/nebius_prepare_qwen35.zsh
```

Key final settings:

```zsh
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-1}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-1010000}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-1}"
MAX_NUM_BATCHED_TOKENS="${MAX_NUM_BATCHED_TOKENS:-32768}"
...
--tensor-parallel-size "$TENSOR_PARALLEL_SIZE"
--max-model-len "$MAX_MODEL_LEN"
--hf-overrides "$HF_OVERRIDES"
```

For this run it was invoked with `TENSOR_PARALLEL_SIZE=4` and `GPU_MEMORY_UTILIZATION=0.90`.
