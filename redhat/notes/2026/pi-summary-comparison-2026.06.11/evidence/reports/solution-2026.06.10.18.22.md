# Tuned vLLM Concurrency Benchmark

| Field | Value |
|---|---|
| Test time | 2026-06-10 18:22-18:36 CST |
| Remote host | `wzh@89.169.120.64` |
| GPU | 4 x NVIDIA L40S, 46,068 MiB each |
| Model | `RedHatAI/Qwen3.5-122B-A10B-FP8-dynamic` |
| Baseline report | `solution/solution-2026.06.10.17.56.md` |
| Tuned report artifacts | `solution/files/solution-2026-06-10-18-22/` |

## Why 1M Became 42 Chunks

The benchmark ran with `--chunk-chars 24000` and default `--overlap-chars 0`.

Raw chunking:

| Metric | Value |
|---|---:|
| Input characters | 1,000,000 |
| Target chunk size | 24,000 characters |
| Chunk count | 42 |
| Raw chunk length min | 23,162 |
| Raw chunk length max | 23,980 |
| Coverage | 1,000,000 characters |

The math is simply `ceil(1,000,000 / 24,000) = 42`. The chunks are a little below 24,000 because `chunk_text()` tries to end at a paragraph/newline/sentence/space boundary before the hard limit.

Audited LLM request sizes are slightly different from raw chunk sizes because the agent wraps each chunk in a system prompt plus a user prompt containing chunk index and source character range. In the tuned benchmark, the 42 map requests ranged from `23,367` to `24,181` characters.

## Concurrency Tuning

I tried two profiles while keeping the 1M context configuration:

| Profile | Result | Notes |
|---|---|---|
| `max_num_seqs=8`, `max_num_batched_tokens=65536` | Failed | vLLM failed during KV cache initialization with `No available memory for the cache blocks`. |
| `max_num_seqs=4`, `max_num_batched_tokens=32768` | Succeeded | Endpoint reported `max_model_len=1010000`; benchmark completed. |

The successful `seqs=4` profile logged:

```text
GPU KV cache size: 89,760 tokens
Maximum concurrency for 1,010,000 tokens per request: 0.36x
```

This means the server still cannot run multiple theoretical 1,010,000-token requests concurrently, but it can schedule several much smaller map prompts. That is exactly why agent latency improved.

## Benchmark Result

| Run | vLLM profile | Agent elapsed | Direct full 1M elapsed | Agent vs direct | Agent improvement vs `seqs=1` |
|---|---|---:|---:|---:|---:|
| Round 6 baseline | `max_num_seqs=1`, `max_num_batched_tokens=32768` | 194.22s | 34.10s | 5.70x slower | baseline |
| Round 7 tuned | `max_num_seqs=4`, `max_num_batched_tokens=32768` | 93.26s | 34.19s | 2.73x slower | 2.08x faster |

The tuned agent improved a lot, but it still did not beat direct 1M on this host.

Full tuned benchmark details:

| Path | Status | Covered chars | Model calls | Max audited request chars | Elapsed seconds |
|---|---|---:|---:|---:|---:|
| Summary agent | succeeded | 1,000,000 | 46 | 24,181 | 93.26 |
| Direct full 1M | succeeded | 1,000,000 | 1 | 1,000,067 | 34.19 |
| Direct clipped | succeeded | 28,000 | 1 | 28,067 | 5.76 |

## Interpretation

`max_num_seqs` absolutely mattered. Moving from `1` to `4` cut agent latency by about half. The reason it still did not beat direct is that the direct path is a single prefill/decode request over a highly repetitive synthetic document, while the agent path still requires 46 model calls, reduce synchronization, and request overhead.

On this 4xL40S topology, the best validated 1M-context profile so far is `max_num_seqs=4`. The attempted `seqs=8` profile is too aggressive for the available KV cache memory at 1M context.

## Evidence Files

- `solution/files/solution-2026-06-10-18-22/prepare-nebius-qwen35-l40s-1m-r7-seqs8.log`
- `solution/files/solution-2026-06-10-18-22/prepare-nebius-qwen35-l40s-1m-r7-seqs4.log`
- `solution/files/solution-2026-06-10-18-22/nebius-l40s-r7-seqs4-qwen35-1m-benchmark.json`
- `solution/files/solution-2026-06-10-18-22/nebius-l40s-r7-seqs4-qwen35-1m-requests.jsonl`
- `solution/files/solution-2026-06-10-18-22/nebius-l40s-r7-seqs4-qwen35-1m-benchmark.stdout`

The final live service check confirmed the tuned endpoint was still running and reporting `max_model_len=1010000`.
