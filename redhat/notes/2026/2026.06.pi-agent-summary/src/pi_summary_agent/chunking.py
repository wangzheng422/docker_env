from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TextChunk:
    index: int
    start: int
    end: int
    text: str


def chunk_text(text: str, max_chars: int, overlap_chars: int = 0) -> list[TextChunk]:
    if max_chars <= 0:
        raise ValueError("max_chars must be greater than zero")
    if overlap_chars < 0:
        raise ValueError("overlap_chars must be non-negative")
    if overlap_chars >= max_chars:
        raise ValueError("overlap_chars must be smaller than max_chars")
    if not text:
        return []

    chunks: list[TextChunk] = []
    start = 0
    text_len = len(text)
    while start < text_len:
        hard_end = min(start + max_chars, text_len)
        end = _choose_boundary(text, start, hard_end)
        if end <= start:
            end = hard_end
        chunks.append(TextChunk(index=len(chunks), start=start, end=end, text=text[start:end]))
        if end >= text_len:
            break
        start = max(0, end - overlap_chars)
    return chunks


def _choose_boundary(text: str, start: int, hard_end: int) -> int:
    if hard_end == len(text):
        return hard_end
    window = text[start:hard_end]
    minimum = max(1, int(len(window) * 0.55))
    for separator in ("\n\n", "\n", ". ", " "):
        idx = window.rfind(separator)
        if idx >= minimum:
            return start + idx + len(separator)
    return hard_end
