import unittest

from pi_summary_agent.benchmark import run_agent_once, run_direct_once, synthetic_document
from pi_summary_agent.summarizer import SummaryConfig


class FailingOnLargeModel:
    def __init__(self, max_prompt_chars):
        self.max_prompt_chars = max_prompt_chars
        self.calls = []

    def complete(self, messages, max_tokens, temperature):
        prompt = "\n".join(message["content"] for message in messages)
        self.calls.append(prompt)
        if len(prompt) > self.max_prompt_chars:
            raise RuntimeError("context length exceeded")
        return "direct summary"


class BenchmarkTests(unittest.TestCase):
    def test_synthetic_document_reaches_requested_size(self):
        text = synthetic_document(10_000)

        self.assertEqual(len(text), 10_000)
        self.assertIn("Customer Document Section", text)

    def test_direct_full_records_context_failure_without_truncation(self):
        model = FailingOnLargeModel(max_prompt_chars=500)
        text = synthetic_document(2_000)

        result = run_direct_once(
            model=model,
            text=text,
            max_input_chars=None,
            max_output_tokens=64,
        )

        self.assertEqual(result["status"], "failed")
        self.assertEqual(result["coverage_chars"], len(text))
        self.assertIn("context length exceeded", result["error"])

    def test_direct_max_context_records_partial_coverage(self):
        model = FailingOnLargeModel(max_prompt_chars=900)
        text = synthetic_document(2_000)

        result = run_direct_once(
            model=model,
            text=text,
            max_input_chars=400,
            max_output_tokens=64,
        )

        self.assertEqual(result["status"], "succeeded")
        self.assertEqual(result["coverage_chars"], 400)
        self.assertEqual(result["input_chars"], len(text))
        self.assertEqual(len(model.calls), 1)

    def test_agent_metrics_include_refinement_rounds_and_final_chars(self):
        model = FailingOnLargeModel(max_prompt_chars=5_000)
        text = synthetic_document(200)

        result = run_agent_once(
            model=model,
            text=text,
            config=SummaryConfig(max_chunk_chars=500),
        )

        self.assertIn("refinement_rounds", result)
        self.assertIn("final_summary_chars", result)
        self.assertEqual(result["refinement_rounds"], 0)
        self.assertEqual(result["final_summary_chars"], len(result["summary"]))


if __name__ == "__main__":
    unittest.main()
