import json
import tempfile
import unittest
from pathlib import Path

from pi_summary_agent.audit import AuditedModel


class EchoModel:
    def complete(self, messages, max_tokens, temperature):
        return "ok"


class AuditTests(unittest.TestCase):
    def test_audited_model_writes_full_request_before_call(self):
        with tempfile.TemporaryDirectory() as tmp:
            audit_path = Path(tmp) / "requests.jsonl"
            model = AuditedModel(EchoModel(), audit_path=audit_path, run_id="test-run")

            result = model.complete(
                messages=[
                    {"role": "system", "content": "sys"},
                    {"role": "user", "content": "hello"},
                ],
                max_tokens=12,
                temperature=0.2,
            )

            self.assertEqual(result, "ok")
            rows = [json.loads(line) for line in audit_path.read_text().splitlines()]
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]["run_id"], "test-run")
            self.assertEqual(rows[0]["call_index"], 1)
            self.assertEqual(rows[0]["max_tokens"], 12)
            self.assertEqual(rows[0]["temperature"], 0.2)
            self.assertEqual(rows[0]["messages"][1]["content"], "hello")
            self.assertEqual(rows[0]["request_char_count"], len("sys") + len("hello"))


if __name__ == "__main__":
    unittest.main()
