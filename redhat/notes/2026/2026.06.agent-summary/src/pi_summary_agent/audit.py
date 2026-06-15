from __future__ import annotations

import json
import threading
import time
from pathlib import Path

from .model_client import ChatModel


class AuditedModel:
    def __init__(self, model: ChatModel, audit_path: Path, run_id: str):
        self.model = model
        self.audit_path = audit_path
        self.run_id = run_id
        self._lock = threading.Lock()
        self._call_index = 0
        self.audit_path.parent.mkdir(parents=True, exist_ok=True)

    def complete(
        self,
        messages: list[dict[str, str]],
        max_tokens: int,
        temperature: float,
    ) -> str:
        with self._lock:
            self._call_index += 1
            call_index = self._call_index
            record = {
                "run_id": self.run_id,
                "call_index": call_index,
                "timestamp_unix": time.time(),
                "max_tokens": max_tokens,
                "temperature": temperature,
                "request_char_count": sum(len(message["content"]) for message in messages),
                "messages": messages,
            }
            with self.audit_path.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record, ensure_ascii=False) + "\n")
        return self.model.complete(messages=messages, max_tokens=max_tokens, temperature=temperature)
