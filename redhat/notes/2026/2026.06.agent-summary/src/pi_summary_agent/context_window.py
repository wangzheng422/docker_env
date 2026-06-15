from __future__ import annotations

import json
import urllib.error
import urllib.request
from dataclasses import dataclass


@dataclass(frozen=True)
class ChunkSizing:
    chunk_chars: int
    context_window_tokens: int
    chunk_context_utilization: float
    chars_per_token: float
    reserved_tokens: int
    source: str


def fetch_context_window_tokens(base_url: str, model: str, api_key: str | None = None) -> int:
    url = f"{base_url.rstrip('/')}/models"
    headers = {"Accept": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (OSError, urllib.error.URLError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"failed to read model context window from {url}: {exc}") from exc

    for item in payload.get("data", []):
        if item.get("id") == model or item.get("root") == model:
            value = item.get("max_model_len")
            if isinstance(value, int) and value > 0:
                return value

    for item in payload.get("data", []):
        value = item.get("max_model_len")
        if isinstance(value, int) and value > 0:
            return value

    raise RuntimeError(f"/models response did not include max_model_len for {model}")


def resolve_context_window_tokens(
    *,
    base_url: str,
    model: str,
    api_key: str | None,
    context_window_tokens: int | None,
) -> tuple[int, str]:
    if context_window_tokens is not None:
        if context_window_tokens <= 0:
            raise ValueError("context_window_tokens must be greater than zero")
        return context_window_tokens, "argument"
    return fetch_context_window_tokens(base_url=base_url, model=model, api_key=api_key), "models_endpoint"


def compute_context_aware_chunk_chars(
    *,
    context_window_tokens: int,
    chars_per_token: float,
    chunk_context_utilization: float,
    reserved_tokens: int,
    min_chunk_chars: int = 1,
    max_chunk_chars: int | None = None,
) -> int:
    if context_window_tokens <= 0:
        raise ValueError("context_window_tokens must be greater than zero")
    if chars_per_token <= 0:
        raise ValueError("chars_per_token must be greater than zero")
    if not 0 < chunk_context_utilization <= 1:
        raise ValueError("chunk_context_utilization must be in the range (0, 1]")
    if reserved_tokens < 0:
        raise ValueError("reserved_tokens must be non-negative")
    if min_chunk_chars <= 0:
        raise ValueError("min_chunk_chars must be greater than zero")
    if max_chunk_chars is not None and max_chunk_chars < min_chunk_chars:
        raise ValueError("max_chunk_chars must be greater than or equal to min_chunk_chars")

    usable_tokens = int((context_window_tokens - reserved_tokens) * chunk_context_utilization)
    if usable_tokens <= 0:
        raise ValueError("reserved_tokens leaves no room for input chunks")

    chunk_chars = max(min_chunk_chars, int(usable_tokens * chars_per_token))
    if max_chunk_chars is not None:
        chunk_chars = min(chunk_chars, max_chunk_chars)
    return chunk_chars


def build_chunk_sizing(
    *,
    base_url: str,
    model: str,
    api_key: str | None,
    chunk_chars: int,
    context_window_tokens: int | None,
    chunk_context_utilization: float,
    chars_per_token: float,
    prompt_reserve_tokens: int,
    output_reserve_tokens: int,
    min_chunk_chars: int,
    max_auto_chunk_chars: int | None,
) -> ChunkSizing:
    if chunk_chars > 0:
        context_value = context_window_tokens or 0
        return ChunkSizing(
            chunk_chars=chunk_chars,
            context_window_tokens=context_value,
            chunk_context_utilization=chunk_context_utilization,
            chars_per_token=chars_per_token,
            reserved_tokens=prompt_reserve_tokens + output_reserve_tokens,
            source="manual",
        )
    if chunk_chars < 0:
        raise ValueError("chunk_chars must be zero for auto mode or greater than zero for manual mode")

    resolved_context, source = resolve_context_window_tokens(
        base_url=base_url,
        model=model,
        api_key=api_key,
        context_window_tokens=context_window_tokens,
    )
    reserved_tokens = prompt_reserve_tokens + output_reserve_tokens
    auto_chunk_chars = compute_context_aware_chunk_chars(
        context_window_tokens=resolved_context,
        chars_per_token=chars_per_token,
        chunk_context_utilization=chunk_context_utilization,
        reserved_tokens=reserved_tokens,
        min_chunk_chars=min_chunk_chars,
        max_chunk_chars=max_auto_chunk_chars,
    )
    return ChunkSizing(
        chunk_chars=auto_chunk_chars,
        context_window_tokens=resolved_context,
        chunk_context_utilization=chunk_context_utilization,
        chars_per_token=chars_per_token,
        reserved_tokens=reserved_tokens,
        source=source,
    )
