import unittest

from pi_summary_agent.summarizer import SummaryAgent, SummaryConfig


class RecordingModel:
    def __init__(self):
        self.calls = []

    def complete(self, messages, max_tokens, temperature):
        prompt = "\n".join(message["content"] for message in messages)
        self.calls.append(
            {
                "prompt": prompt,
                "max_tokens": max_tokens,
                "temperature": temperature,
            }
        )
        return "summary:" + prompt[-32:]


class RefiningModel:
    def __init__(self):
        self.calls = []

    def complete(self, messages, max_tokens, temperature):
        prompt = "\n".join(message["content"] for message in messages)
        self.calls.append({"prompt": prompt, "max_tokens": max_tokens})
        if "merge these compressed summary chunks" in prompt:
            return "short summary"
        if "compress refinement chunk" in prompt:
            return "compressed chunk"
        return "x" * 80


class NonConvergingReduceModel:
    def __init__(self):
        self.calls = []

    def complete(self, messages, max_tokens, temperature):
        prompt = "\n".join(message["content"] for message in messages)
        self.calls.append(prompt)
        return "y" * 80


class SummaryAgentTests(unittest.TestCase):
    def test_summary_agent_never_sends_full_large_text_to_model(self):
        text = "customer evidence sentence. " * 80
        model = RecordingModel()
        agent = SummaryAgent(
            model=model,
            config=SummaryConfig(max_chunk_chars=120, overlap_chars=0, max_workers=2),
        )

        result = agent.summarize(text)

        self.assertEqual(result.input_chars, len(text))
        self.assertGreater(result.chunk_count, 1)
        self.assertEqual(result.coverage_chars, len(text))
        self.assertTrue(result.final_summary)
        self.assertTrue(all(len(call["prompt"]) < len(text) for call in model.calls))
        self.assertLessEqual(max(result.model_prompt_chars), 900)

    def test_summary_agent_single_small_text_uses_one_map_and_no_reduce(self):
        text = "short customer update"
        model = RecordingModel()
        agent = SummaryAgent(model=model, config=SummaryConfig(max_chunk_chars=200))

        result = agent.summarize(text)

        self.assertEqual(result.chunk_count, 1)
        self.assertEqual(result.reduce_rounds, 0)
        self.assertEqual(result.refinement_rounds, 0)
        self.assertEqual(len(model.calls), 1)

    def test_summary_agent_refines_final_summary_when_over_limit(self):
        text = "short customer update"
        model = RefiningModel()
        agent = SummaryAgent(
            model=model,
            config=SummaryConfig(
                max_chunk_chars=200,
                final_max_chars=40,
                max_refine_rounds=2,
            ),
        )

        result = agent.summarize(text)

        self.assertEqual(result.final_summary, "short summary")
        self.assertEqual(result.refinement_rounds, 1)
        self.assertEqual(len(model.calls), 4)
        self.assertIn("compress refinement chunk 1 of 2", model.calls[1]["prompt"])
        self.assertIn("at most 20 characters", model.calls[1]["prompt"])
        self.assertLess(model.calls[1]["max_tokens"], 512)
        self.assertIn("merge these compressed summary chunks", model.calls[-1]["prompt"])
        self.assertLess(model.calls[-1]["max_tokens"], 512)

    def test_summary_agent_limits_non_converging_reduce_rounds(self):
        text = "customer evidence sentence. " * 20
        model = NonConvergingReduceModel()
        agent = SummaryAgent(
            model=model,
            config=SummaryConfig(
                max_chunk_chars=80,
                reduce_input_budget_chars=20,
                max_reduce_rounds=2,
            ),
        )

        result = agent.summarize(text)

        self.assertEqual(result.reduce_rounds, 2)
        self.assertTrue(result.final_summary)
        self.assertLess(len(model.calls), result.chunk_count * 4)


if __name__ == "__main__":
    unittest.main()
