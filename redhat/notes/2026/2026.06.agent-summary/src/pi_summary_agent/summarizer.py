from __future__ import annotations

import time
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from datetime import datetime, timezone
from threading import Lock

from .chunking import TextChunk, chunk_text
from .model_client import ChatModel


@dataclass(frozen=True)
class SummaryConfig:
    max_chunk_chars: int = 24_000
    overlap_chars: int = 0
    max_workers: int = 4
    map_max_tokens: int = 512
    reduce_max_tokens: int = 1024
    max_reduce_rounds: int = 8
    final_max_chars: int = 0
    max_refine_rounds: int = 3
    progress: bool = True
    temperature: float = 0.1
    reduce_input_budget_chars: int = 24_000
    system_prompt: str = (
        "You are a careful enterprise document summary agent. "
        "Preserve customer facts, risks, decisions, dates, and action items. "
        "Do not invent evidence."
    )


@dataclass(frozen=True)
class SummaryResult:
    final_summary: str
    input_chars: int
    coverage_chars: int
    chunk_count: int
    reduce_rounds: int
    refinement_rounds: int
    elapsed_seconds: float
    model_prompt_chars: list[int] = field(default_factory=list)
    chunk_summaries: list[str] = field(default_factory=list)


class SummaryAgent:
    def __init__(self, model: ChatModel, config: SummaryConfig | None = None):
        self.model = model
        self.config = config or SummaryConfig()
        self._progress_lock = Lock()

    def summarize(self, text: str) -> SummaryResult:
        started = time.monotonic()
        self._log_progress(f"summary_start input_chars={len(text)}")
        chunks = chunk_text(text, self.config.max_chunk_chars, self.config.overlap_chars)
        self._log_progress(
            f"chunking_done chunk_count={len(chunks)} max_chunk_chars={self.config.max_chunk_chars} "
            f"overlap_chars={self.config.overlap_chars}"
        )
        if not chunks:
            return SummaryResult(
                final_summary="",
                input_chars=0,
                coverage_chars=0,
                chunk_count=0,
                reduce_rounds=0,
                refinement_rounds=0,
                elapsed_seconds=0.0,
            )

        prompt_lengths: list[int] = []
        chunk_summaries = self._map_summaries(chunks, prompt_lengths)
        self._log_progress(f"map_done chunk_count={len(chunk_summaries)}")
        reduce_rounds = 0
        final_summary = chunk_summaries[0]
        if len(chunk_summaries) > 1:
            final_summary, reduce_rounds = self._reduce_summaries(chunk_summaries, prompt_lengths)
        self._log_progress(f"reduce_done reduce_rounds={reduce_rounds} summary_chars={len(final_summary)}")
        final_summary, refinement_rounds = self._refine_to_limit(final_summary, prompt_lengths)
        self._log_progress(
            f"summary_done elapsed_seconds={time.monotonic() - started:.2f} "
            f"summary_chars={len(final_summary)} refinement_rounds={refinement_rounds}"
        )

        coverage_chars = _coverage_chars(chunks)
        return SummaryResult(
            final_summary=final_summary,
            input_chars=len(text),
            coverage_chars=coverage_chars,
            chunk_count=len(chunks),
            reduce_rounds=reduce_rounds,
            refinement_rounds=refinement_rounds,
            elapsed_seconds=time.monotonic() - started,
            model_prompt_chars=prompt_lengths,
            chunk_summaries=chunk_summaries,
        )

    def _map_summaries(self, chunks: list[TextChunk], prompt_lengths: list[int]) -> list[str]:
        worker_count = max(1, min(self.config.max_workers, len(chunks)))
        if worker_count == 1:
            return [self._summarize_chunk(chunk, prompt_lengths) for chunk in chunks]
        with ThreadPoolExecutor(max_workers=worker_count) as executor:
            return list(executor.map(lambda chunk: self._summarize_chunk(chunk, prompt_lengths), chunks))

    def _summarize_chunk(self, chunk: TextChunk, prompt_lengths: list[int]) -> str:
        started = time.monotonic()
        self._log_progress(
            f"map_chunk_start index={chunk.index + 1} start={chunk.start} end={chunk.end} chars={len(chunk.text)}"
        )
        user_prompt = (
            f"Summarize chunk {chunk.index + 1}. "
            f"Source character range: {chunk.start}-{chunk.end}.\n\n"
            f"{chunk.text}"
        )
        messages = [
            {"role": "system", "content": self.config.system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        prompt_lengths.append(sum(len(message["content"]) for message in messages))
        output = self.model.complete(
            messages=messages,
            max_tokens=self.config.map_max_tokens,
            temperature=self.config.temperature,
        )
        self._log_progress(
            f"map_chunk_done index={chunk.index + 1} elapsed_seconds={time.monotonic() - started:.2f} "
            f"output_chars={len(output)}"
        )
        return output

    def _reduce_summaries(self, summaries: list[str], prompt_lengths: list[int]) -> tuple[str, int]:
        current = summaries
        rounds = 0
        budget = min(self.config.reduce_input_budget_chars, self.config.max_chunk_chars * 4)
        while (len(current) > 1 or len("\n\n".join(current)) > budget) and rounds < self.config.max_reduce_rounds:
            rounds += 1
            groups = _group_texts(current, budget)
            self._log_progress(
                f"reduce_round_start round={rounds} input_items={len(current)} group_count={len(groups)} budget_chars={budget}"
            )
            current = [self._reduce_group(group, rounds, prompt_lengths) for group in groups]
            self._log_progress(
                f"reduce_round_done round={rounds} output_items={len(current)} "
                f"joined_chars={len(chr(10).join(current))}"
            )
        if len(current) == 1:
            return current[0], rounds
        if rounds == 0:
            rounds = 1
        return self._reduce_group(current, rounds, prompt_lengths), rounds

    def _reduce_group(self, summaries: list[str], round_number: int, prompt_lengths: list[int]) -> str:
        started = time.monotonic()
        self._log_progress(
            f"reduce_group_start round={round_number} item_count={len(summaries)} "
            f"input_chars={len(chr(10).join(summaries))}"
        )
        joined = "\n\n".join(f"- {summary}" for summary in summaries)
        user_prompt = (
            f"Merge these partial summaries into a concise customer-facing summary. "
            f"Reduce round: {round_number}.\n\n{joined}"
        )
        messages = [
            {"role": "system", "content": self.config.system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        prompt_lengths.append(sum(len(message["content"]) for message in messages))
        output = self.model.complete(
            messages=messages,
            max_tokens=self.config.reduce_max_tokens,
            temperature=self.config.temperature,
        )
        self._log_progress(
            f"reduce_group_done round={round_number} elapsed_seconds={time.monotonic() - started:.2f} "
            f"output_chars={len(output)}"
        )
        return output

    def _refine_to_limit(self, summary: str, prompt_lengths: list[int]) -> tuple[str, int]:
        if self.config.final_max_chars <= 0 or len(summary) <= self.config.final_max_chars:
            return summary, 0
        if self.config.max_refine_rounds <= 0:
            return summary, 0

        current = summary
        rounds = 0
        while len(current) > self.config.final_max_chars and rounds < self.config.max_refine_rounds:
            rounds += 1
            self._log_progress(
                f"refinement_round_start round={rounds} input_chars={len(current)} "
                f"target_chars={self.config.final_max_chars}"
            )
            current = self._refine_map_reduce(current, rounds, prompt_lengths)
            self._log_progress(
                f"refinement_round_done round={rounds} output_chars={len(current)} "
                f"target_chars={self.config.final_max_chars}"
            )
        return current, rounds

    def _refine_map_reduce(self, summary: str, round_number: int, prompt_lengths: list[int]) -> str:
        chunk_chars = max(1, min(self.config.max_chunk_chars, self.config.final_max_chars))
        chunks = chunk_text(summary, chunk_chars, 0)
        self._log_progress(
            f"refinement_map_start round={round_number} chunk_count={len(chunks)} chunk_chars={chunk_chars}"
        )
        if not chunks:
            return ""

        compressed_chunks = [
            self._refine_chunk(chunk, round_number, len(chunks), prompt_lengths)
            for chunk in chunks
        ]
        self._log_progress(f"refinement_map_done round={round_number} chunk_count={len(compressed_chunks)}")
        self._log_progress(
            f"refinement_reduce_once_start round={round_number} item_count={len(compressed_chunks)} "
            f"input_chars={len(chr(10).join(compressed_chunks))}"
        )
        output = self._reduce_refinement_group(compressed_chunks, round_number, prompt_lengths)
        self._log_progress(
            f"refinement_reduce_once_done round={round_number} output_chars={len(output)}"
        )
        return output

    def _refine_chunk(
        self,
        chunk: TextChunk,
        round_number: int,
        chunk_count: int,
        prompt_lengths: list[int],
    ) -> str:
        started = time.monotonic()
        self._log_progress(
            f"refinement_chunk_start round={round_number} index={chunk.index + 1} "
            f"chunk_count={chunk_count} chars={len(chunk.text)}"
        )
        user_prompt = (
            f"Final refinement round {round_number}: compress refinement chunk "
            f"{chunk.index + 1} of {chunk_count} to at most "
            f"{_per_chunk_refinement_target(self.config.final_max_chars, chunk_count)} characters. "
            f"The final merged summary must fit within {self.config.final_max_chars} characters. "
            "Be terse and do not expand the text. Preserve the most important customer "
            "facts, risks, decisions, dates, and action items. Do not add new facts.\n\n"
            f"{chunk.text}"
        )
        messages = [
            {"role": "system", "content": self.config.system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        prompt_lengths.append(sum(len(message["content"]) for message in messages))
        output = self.model.complete(
            messages=messages,
            max_tokens=_chars_to_tokens(
                _per_chunk_refinement_target(self.config.final_max_chars, chunk_count),
                self.config.reduce_max_tokens,
            ),
            temperature=self.config.temperature,
        )
        self._log_progress(
            f"refinement_chunk_done round={round_number} index={chunk.index + 1} "
            f"elapsed_seconds={time.monotonic() - started:.2f} output_chars={len(output)}"
        )
        return output

    def _reduce_refinement_group(
        self,
        summaries: list[str],
        round_number: int,
        prompt_lengths: list[int],
    ) -> str:
        started = time.monotonic()
        self._log_progress(
            f"refinement_reduce_group_start round={round_number} item_count={len(summaries)} "
            f"input_chars={len(chr(10).join(summaries))}"
        )
        joined = "\n\n".join(f"- {summary}" for summary in summaries)
        user_prompt = (
            f"Final refinement round {round_number}: merge these compressed summary chunks "
            f"into a single summary within {self.config.final_max_chars} characters. Preserve "
            "the most important customer facts, risks, decisions, dates, and action items. "
            "Be terse and do not expand the text. "
            f"Do not add new facts.\n\n{joined}"
        )
        messages = [
            {"role": "system", "content": self.config.system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        prompt_lengths.append(sum(len(message["content"]) for message in messages))
        output = self.model.complete(
            messages=messages,
            max_tokens=_chars_to_tokens(self.config.final_max_chars, self.config.reduce_max_tokens),
            temperature=self.config.temperature,
        )
        self._log_progress(
            f"refinement_reduce_group_done round={round_number} elapsed_seconds={time.monotonic() - started:.2f} "
            f"output_chars={len(output)}"
        )
        return output

    def _log_progress(self, message: str) -> None:
        if not self.config.progress:
            return
        timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
        with self._progress_lock:
            print(f"[summary-agent] {timestamp} {message}", file=sys.stderr, flush=True)


def _group_texts(texts: list[str], max_chars: int) -> list[list[str]]:
    groups: list[list[str]] = []
    current: list[str] = []
    current_chars = 0
    for text in texts:
        next_size = len(text) + (2 if current else 0)
        if current and current_chars + next_size > max_chars:
            groups.append(current)
            current = []
            current_chars = 0
        current.append(text)
        current_chars += next_size
    if current:
        groups.append(current)
    return groups


def _coverage_chars(chunks: list[TextChunk]) -> int:
    if not chunks:
        return 0
    covered: set[int] = set()
    for chunk in chunks:
        covered.update(range(chunk.start, chunk.end))
    return len(covered)


def _per_chunk_refinement_target(final_max_chars: int, chunk_count: int) -> int:
    if chunk_count <= 0:
        return max(1, final_max_chars)
    return max(1, final_max_chars // chunk_count)


def _chars_to_tokens(target_chars: int, upper_bound: int) -> int:
    token_budget = max(64, target_chars // 6)
    return max(1, min(upper_bound, token_budget))
