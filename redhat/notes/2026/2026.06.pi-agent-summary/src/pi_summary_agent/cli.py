from __future__ import annotations

import argparse
import json
from pathlib import Path

from .benchmark import run_agent_once
from .context_window import build_chunk_sizing
from .model_client import OpenAICompatibleClient
from .summarizer import SummaryConfig


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the Pi-style summary agent.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000/v1")
    parser.add_argument("--model", default="Qwen/Qwen3.6-27B-FP8")
    parser.add_argument("--api-key", default=None)
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", default="summary.md")
    parser.add_argument("--metrics", default="summary-metrics.json")
    parser.add_argument(
        "--chunk-chars",
        type=int,
        default=0,
        help="Chunk size in characters. Use 0 to derive it from the model context window.",
    )
    parser.add_argument("--context-window-tokens", type=int, default=None)
    parser.add_argument("--chunk-context-utilization", type=float, default=0.96)
    parser.add_argument("--chars-per-token", type=float, default=1.0)
    parser.add_argument("--prompt-reserve-tokens", type=int, default=1024)
    parser.add_argument("--map-max-tokens", type=int, default=512)
    parser.add_argument("--reduce-max-tokens", type=int, default=1024)
    parser.add_argument("--max-reduce-rounds", type=int, default=8)
    parser.add_argument(
        "--final-max-chars",
        type=int,
        default=0,
        help="If greater than 0, repeatedly compress the final summary until it fits this character limit or refine rounds are exhausted.",
    )
    parser.add_argument("--max-refine-rounds", type=int, default=3)
    parser.set_defaults(progress=True)
    parser.add_argument("--progress", dest="progress", action="store_true", help="Print stage progress logs to stderr.")
    parser.add_argument("--no-progress", dest="progress", action="store_false", help="Disable stage progress logs.")
    parser.add_argument("--reduce-input-budget-chars", type=int, default=0)
    parser.add_argument("--min-chunk-chars", type=int, default=1)
    parser.add_argument("--max-auto-chunk-chars", type=int, default=None)
    parser.add_argument("--overlap-chars", type=int, default=0)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--timeout", type=float, default=900.0)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    text = Path(args.input).read_text(encoding="utf-8")
    chunk_sizing = build_chunk_sizing(
        base_url=args.base_url,
        model=args.model,
        api_key=args.api_key,
        chunk_chars=args.chunk_chars,
        context_window_tokens=args.context_window_tokens,
        chunk_context_utilization=args.chunk_context_utilization,
        chars_per_token=args.chars_per_token,
        prompt_reserve_tokens=args.prompt_reserve_tokens,
        output_reserve_tokens=max(args.map_max_tokens, args.reduce_max_tokens),
        min_chunk_chars=args.min_chunk_chars,
        max_auto_chunk_chars=args.max_auto_chunk_chars,
    )
    reduce_input_budget_chars = args.reduce_input_budget_chars
    if reduce_input_budget_chars <= 0:
        reduce_input_budget_chars = chunk_sizing.chunk_chars
    client = OpenAICompatibleClient(
        base_url=args.base_url,
        model=args.model,
        api_key=args.api_key,
        timeout_seconds=args.timeout,
    )
    result = run_agent_once(
        client,
        text,
        SummaryConfig(
            max_chunk_chars=chunk_sizing.chunk_chars,
            overlap_chars=args.overlap_chars,
            max_workers=args.workers,
            map_max_tokens=args.map_max_tokens,
            reduce_max_tokens=args.reduce_max_tokens,
            max_reduce_rounds=args.max_reduce_rounds,
            final_max_chars=args.final_max_chars,
            max_refine_rounds=args.max_refine_rounds,
            progress=args.progress,
            reduce_input_budget_chars=reduce_input_budget_chars,
        ),
    )
    Path(args.output).write_text(result["summary"], encoding="utf-8")
    metrics = {key: value for key, value in result.items() if key != "summary"}
    metrics["chunk_sizing"] = {
        "chunk_chars": chunk_sizing.chunk_chars,
        "chunk_chars_requested": args.chunk_chars,
        "source": chunk_sizing.source,
        "context_window_tokens": chunk_sizing.context_window_tokens,
        "chunk_context_utilization": chunk_sizing.chunk_context_utilization,
        "chars_per_token": chunk_sizing.chars_per_token,
        "reserved_tokens": chunk_sizing.reserved_tokens,
        "reduce_input_budget_chars": reduce_input_budget_chars,
    }
    Path(args.metrics).write_text(json.dumps(metrics, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(metrics, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
