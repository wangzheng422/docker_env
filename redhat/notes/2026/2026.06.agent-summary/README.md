# Summary Agent

Summary Agent is a lightweight long-document summarization tool for OpenAI-compatible chat-completions endpoints, such as vLLM or an OpenAI-compatible gateway.

It uses a simple map/reduce flow:

1. Split a long input into context-window-aware chunks.
2. Summarize chunks in parallel.
3. Reduce partial summaries into a final summary.
4. If the final summary is still over a configured size limit, run another bounded map/reduce refinement pass.

This project intentionally does not depend on a larger agent framework. It is meant for a focused long-text summary workflow.

## Features

- Context-window-aware chunk sizing from `/v1/models` or `--context-window-tokens`.
- Parallel map-stage summarization.
- Reduce-stage summary merge.
- Bounded final refinement with `--final-max-chars`.
- Default-on progress logs to stderr for long-running diagnostics.
- JSON metrics output.
- Containerized runtime.
- Optional benchmark command for agent-vs-direct comparisons.

## Repository Layout

| Path | Description |
|---|---|
| `src/pi_summary_agent/cli.py` | `summary-agent` command |
| `src/pi_summary_agent/benchmark.py` | `summary-benchmark` command |
| `src/pi_summary_agent/summarizer.py` | Map/reduce summary implementation |
| `src/pi_summary_agent/context_window.py` | Context-window-aware chunk sizing |
| `src/pi_summary_agent/model_client.py` | OpenAI-compatible HTTP client |
| `tests/` | Unit tests |
| `Containerfile` | UBI9 Python 3.12 container image |
| `container-entrypoint.sh` | Container entrypoint |

## Requirements

- Python 3.11+
- An OpenAI-compatible endpoint with:

```text
POST /v1/chat/completions
GET  /v1/models
```

If `/v1/models` does not expose `max_model_len` or equivalent context-window metadata, pass `--context-window-tokens` explicitly.

## Install

```sh
python -m pip install -e .
```

Installed commands:

```sh
summary-agent --help
summary-benchmark --help
```

## Run A Summary

```sh
summary-agent \
  --base-url http://127.0.0.1:8000/v1 \
  --model Qwen/Qwen3.6-27B-FP8 \
  --input ./input.txt \
  --output ./summary.md \
  --metrics ./summary-metrics.json
```

Outputs:

- `summary.md`: final summary.
- `summary-metrics.json`: input size, coverage, chunk count, model-call count, timing, and chunk-sizing details.
- stdout: metrics JSON.
- stderr: progress logs, enabled by default.

## Long-Input Example

For a model with a 262,144-token context window:

```sh
summary-agent \
  --base-url http://127.0.0.1:8000/v1 \
  --model Qwen/Qwen3.6-27B-FP8 \
  --input ./long-input.txt \
  --output ./summary.md \
  --metrics ./summary-metrics.json \
  --chunk-chars 0 \
  --context-window-tokens 262144 \
  --chunk-context-utilization 0.96 \
  --chars-per-token 1.0 \
  --prompt-reserve-tokens 1024 \
  --map-max-tokens 1024 \
  --reduce-max-tokens 2048 \
  --max-reduce-rounds 8 \
  --final-max-chars 8000 \
  --max-refine-rounds 3 \
  --reduce-input-budget-chars 0 \
  --workers 4 \
  --timeout 1800
```

Notes:

- `--chunk-chars 0` derives chunk size from the model context window.
- `--reduce-input-budget-chars 0` uses the resolved chunk size for reduce grouping. This is the recommended default.
- Progress logs are enabled by default. Use `--no-progress` only when stderr must stay quiet.
- Client-side concurrency is controlled by `--workers`; real throughput also depends on server-side batching, KV cache, and GPU capacity.

## Container Usage

Build:

```sh
podman build -t pi-summary-agent:local -f Containerfile .
```

Run against a host-network endpoint:

```sh
mkdir -p data

podman run --rm --network host \
  -v "$PWD/data:/data:Z" \
  pi-summary-agent:local \
  summary-agent \
    --base-url http://127.0.0.1:8000/v1 \
    --model Qwen/Qwen3.6-27B-FP8 \
    --input /data/input.txt \
    --output /data/summary.md \
    --metrics /data/summary-metrics.json \
    --chunk-chars 0 \
    --context-window-tokens 262144 \
    --map-max-tokens 1024 \
    --reduce-max-tokens 2048 \
    --final-max-chars 8000 \
    --workers 4 \
    --timeout 1800
```

For authenticated endpoints:

```sh
summary-agent \
  --base-url https://example.com/v1 \
  --api-key "$API_KEY" \
  --model your-model \
  --input ./input.txt
```

Do not commit API keys, request logs, or customer input files.

## Benchmark

Synthetic input:

```sh
summary-benchmark \
  --base-url http://127.0.0.1:8000/v1 \
  --model Qwen/Qwen3.6-27B-FP8 \
  --chars 1000000 \
  --output benchmark-result.json \
  --chunk-chars 0 \
  --context-window-tokens 262144 \
  --map-max-tokens 1024 \
  --reduce-max-tokens 2048 \
  --final-max-chars 8000 \
  --workers 4 \
  --timeout 1800
```

Real input:

```sh
summary-benchmark \
  --base-url http://127.0.0.1:8000/v1 \
  --model Qwen/Qwen3.6-27B-FP8 \
  --input-file ./input.txt \
  --output benchmark-result.json
```

Benchmark output includes:

| Field | Description |
|---|---|
| `metadata` | model, endpoint, input size, chunk sizing |
| `agent` | map/reduce agent timing, coverage, chunks, model calls |
| `direct_full` | direct full-input model call result |
| `direct_max_context` | direct truncated-input model call result |

`--audit-jsonl` records full model requests. Use it only with non-sensitive inputs.

## Public Validation Result

The latest successful validation used a 2,000,000-character synthetic input against an OpenAI-compatible vLLM endpoint serving `Qwen/Qwen3.6-27B-FP8` with a 262,144-token context window.

| Metric | Value |
|---|---:|
| Input size | 2,000,000 characters |
| Covered input | 2,000,000 characters |
| Coverage | 100% |
| Chunk count | 9 |
| Resolved chunk size | 248,709 characters |
| Max model prompt size | 248,893 characters |
| Model calls | 14 |
| Reduce rounds | 1 |
| Refinement rounds | 1 |
| Final summary size | 3,181 characters |
| Agent elapsed time | 722.17 seconds |
| Wall time | 722.70 seconds |

Final validation metrics:

```json
{
  "status": "succeeded",
  "input_chars": 2000000,
  "coverage_chars": 2000000,
  "chunk_count": 9,
  "reduce_rounds": 1,
  "refinement_rounds": 1,
  "elapsed_seconds": 722.1680650520011,
  "max_model_prompt_chars": 248893,
  "model_call_count": 14,
  "final_summary_chars": 3181,
  "chunk_sizing": {
    "chunk_chars": 248709,
    "chunk_chars_requested": 0,
    "source": "argument",
    "context_window_tokens": 262144,
    "chunk_context_utilization": 0.96,
    "chars_per_token": 1.0,
    "reserved_tokens": 3072,
    "reduce_input_budget_chars": 248709
  }
}
```

Progress logs from that run showed the agent path clearly:

```text
[summary-agent] summary_start input_chars=2000000
[summary-agent] chunking_done chunk_count=9 max_chunk_chars=248709 overlap_chars=0
[summary-agent] reduce_round_start round=1 input_items=9 group_count=1 budget_chars=248709
[summary-agent] reduce_done reduce_rounds=1 summary_chars=7611
[summary-agent] refinement_round_done round=1 output_chars=3181 target_chars=4000
[summary-agent] summary_done elapsed_seconds=722.08 summary_chars=3181 refinement_rounds=1
```

The validation used character counts, not tokenizer-exact token counts.

## Important Options

| Option | Default | Description |
|---|---:|---|
| `--base-url` | `http://127.0.0.1:8000/v1` | OpenAI-compatible endpoint |
| `--model` | `Qwen/Qwen3.6-27B-FP8` | model name |
| `--input` | required | input file for `summary-agent` |
| `--input-file` | optional | input file for `summary-benchmark` |
| `--chars` | `1000000` | synthetic benchmark length |
| `--chunk-chars` | `0` | `0` auto-computes chunk size |
| `--context-window-tokens` | unset | manual context-window override |
| `--chunk-context-utilization` | `0.96` | context-window utilization for input chunks |
| `--chars-per-token` | `1.0` | conservative character-per-token estimate |
| `--prompt-reserve-tokens` | `1024` | prompt wrapper reserve |
| `--map-max-tokens` | `512` | max map output tokens |
| `--reduce-max-tokens` | `1024` | max reduce output tokens |
| `--max-reduce-rounds` | `8` | reduce loop guard |
| `--final-max-chars` | `0` | final summary character limit; `0` disables refinement |
| `--max-refine-rounds` | `3` | max final refinement rounds |
| `--progress` / `--no-progress` | `true` | enable or disable stderr progress logs |
| `--reduce-input-budget-chars` | `0` | `0` uses resolved chunk size |
| `--workers` | `4` | map-stage client concurrency |
| `--timeout` | `900` | per-request timeout in seconds |

## Development

Run tests:

```sh
python -m unittest discover -s tests
```

Run a small smoke test:

```sh
python - <<'PY'
from pathlib import Path
Path("sample.txt").write_text(("This is a customer document with risks and action items.\\n" * 1000), encoding="utf-8")
PY

summary-agent \
  --base-url http://127.0.0.1:8000/v1 \
  --model Qwen/Qwen3.6-27B-FP8 \
  --input sample.txt \
  --output sample-summary.md \
  --metrics sample-summary-metrics.json \
  --chunk-chars 4000 \
  --workers 2
```
