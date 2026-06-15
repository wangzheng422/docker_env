from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from typing import Any

from .audit import AuditedModel
from .context_window import build_chunk_sizing
from .model_client import ChatModel, OpenAICompatibleClient
from .summarizer import SummaryAgent, SummaryConfig


def synthetic_document(target_chars: int) -> str:
    if target_chars <= 0:
        raise ValueError("target_chars must be greater than zero")
    sections: list[str] = []
    section_id = 1
    while len("".join(sections)) < target_chars:
        sections.append(
            f"Customer Document Section {section_id}\n"
            "The customer runs a regulated platform and needs accurate summary coverage. "
            "Evidence includes deployment notes, operational risks, performance observations, "
            "security constraints, owners, dates, and follow-up actions. "
            f"Section marker {section_id} must survive chunking and summary reduction.\n\n"
        )
        section_id += 1
    return "".join(sections)[:target_chars]


def run_agent_once(
    model: ChatModel,
    text: str,
    config: SummaryConfig,
) -> dict[str, Any]:
    result = SummaryAgent(model=model, config=config).summarize(text)
    return {
        "status": "succeeded",
        "input_chars": result.input_chars,
        "coverage_chars": result.coverage_chars,
        "chunk_count": result.chunk_count,
        "reduce_rounds": result.reduce_rounds,
        "refinement_rounds": result.refinement_rounds,
        "elapsed_seconds": result.elapsed_seconds,
        "max_model_prompt_chars": max(result.model_prompt_chars) if result.model_prompt_chars else 0,
        "model_call_count": len(result.model_prompt_chars),
        "final_summary_chars": len(result.final_summary),
        "summary": result.final_summary,
    }


def run_direct_once(
    model: ChatModel,
    text: str,
    max_input_chars: int | None,
    max_output_tokens: int,
) -> dict[str, Any]:
    started = time.monotonic()
    direct_text = text[:max_input_chars] if max_input_chars is not None else text
    messages = [
        {
            "role": "system",
            "content": "Summarize the provided customer document. Preserve facts and risks.",
        },
        {"role": "user", "content": direct_text},
    ]
    try:
        summary = model.complete(messages=messages, max_tokens=max_output_tokens, temperature=0.1)
    except Exception as exc:  # noqa: BLE001 - benchmark must record model/server failures.
        return {
            "status": "failed",
            "input_chars": len(text),
            "coverage_chars": len(direct_text),
            "elapsed_seconds": time.monotonic() - started,
            "error": str(exc),
        }
    return {
        "status": "succeeded",
        "input_chars": len(text),
        "coverage_chars": len(direct_text),
        "elapsed_seconds": time.monotonic() - started,
        "summary": summary,
    }


def run_benchmark(args: argparse.Namespace) -> dict[str, Any]:
    text = Path(args.input_file).read_text(encoding="utf-8") if args.input_file else synthetic_document(args.chars)
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
    model: ChatModel = client
    if args.audit_jsonl:
        model = AuditedModel(model, audit_path=Path(args.audit_jsonl), run_id=args.audit_run_id)
    config = SummaryConfig(
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
    )
    return {
        "metadata": {
            "model": args.model,
            "base_url": args.base_url,
            "input_chars": len(text),
            "chunk_chars": chunk_sizing.chunk_chars,
            "chunk_chars_requested": args.chunk_chars,
            "chunk_sizing_source": chunk_sizing.source,
            "context_window_tokens": chunk_sizing.context_window_tokens,
            "chunk_context_utilization": chunk_sizing.chunk_context_utilization,
            "chars_per_token": chunk_sizing.chars_per_token,
            "chunk_reserved_tokens": chunk_sizing.reserved_tokens,
            "reduce_input_budget_chars": reduce_input_budget_chars,
            "max_reduce_rounds": args.max_reduce_rounds,
            "final_max_chars": args.final_max_chars,
            "max_refine_rounds": args.max_refine_rounds,
            "direct_max_input_chars": args.direct_max_input_chars,
        },
        "agent": run_agent_once(model, text, config),
        "direct_full": run_direct_once(model, text, None, args.direct_max_tokens),
        "direct_max_context": run_direct_once(
            model,
            text,
            args.direct_max_input_chars,
            args.direct_max_tokens,
        ),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Benchmark Pi-style summary agent vs direct model calls.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000/v1")
    parser.add_argument("--model", default="Qwen/Qwen3.6-27B-FP8")
    parser.add_argument("--api-key", default=None)
    parser.add_argument("--input-file", default=None)
    parser.add_argument("--chars", type=int, default=1_000_000)
    parser.add_argument(
        "--chunk-chars",
        type=int,
        default=0,
        help="Chunk size in characters. Use 0 to derive it from the model context window.",
    )
    parser.add_argument(
        "--context-window-tokens",
        type=int,
        default=None,
        help="Override the context window used for auto chunk sizing. If omitted, read max_model_len from /v1/models.",
    )
    parser.add_argument(
        "--chunk-context-utilization",
        type=float,
        default=0.96,
        help="Fraction of the context window to use for input chunk text in auto mode.",
    )
    parser.add_argument(
        "--chars-per-token",
        type=float,
        default=1.0,
        help="Conservative character-per-token multiplier for auto chunk sizing.",
    )
    parser.add_argument(
        "--prompt-reserve-tokens",
        type=int,
        default=1024,
        help="Token reserve for system/user prompt overhead when computing auto chunk size.",
    )
    parser.add_argument("--min-chunk-chars", type=int, default=1)
    parser.add_argument("--max-auto-chunk-chars", type=int, default=None)
    parser.add_argument("--overlap-chars", type=int, default=0)
    parser.add_argument("--workers", type=int, default=4)
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
    parser.add_argument("--progress", dest="progress", action="store_true", help="Print agent stage progress logs to stderr.")
    parser.add_argument("--no-progress", dest="progress", action="store_false", help="Disable agent stage progress logs.")
    parser.add_argument(
        "--reduce-input-budget-chars",
        type=int,
        default=0,
        help="Reduce grouping budget in characters. Use 0 to match the resolved chunk size.",
    )
    parser.add_argument("--direct-max-input-chars", type=int, default=28_000)
    parser.add_argument("--direct-max-tokens", type=int, default=1024)
    parser.add_argument("--timeout", type=float, default=900.0)
    parser.add_argument("--output", default="benchmark-result.json")
    parser.add_argument("--audit-jsonl", default=None)
    parser.add_argument("--audit-run-id", default="summary-benchmark")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    result = run_benchmark(args)
    Path(args.output).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k != "agent"}, ensure_ascii=False, indent=2))
    print(f"wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
