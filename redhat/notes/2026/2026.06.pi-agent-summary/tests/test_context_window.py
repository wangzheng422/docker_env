import unittest

from pi_summary_agent.benchmark import synthetic_document
from pi_summary_agent.chunking import chunk_text
from pi_summary_agent.context_window import build_chunk_sizing, compute_context_aware_chunk_chars


class ContextWindowChunkSizingTests(unittest.TestCase):
    def test_native_256k_context_yields_four_chunks_for_1m_chars(self):
        chunk_chars = compute_context_aware_chunk_chars(
            context_window_tokens=262_144,
            chars_per_token=1.0,
            chunk_context_utilization=0.96,
            reserved_tokens=1_536,
        )
        chunks = chunk_text(synthetic_document(1_000_000), chunk_chars)

        self.assertGreaterEqual(chunk_chars, 250_000)
        self.assertEqual(len(chunks), 4)
        self.assertEqual(sum(len(chunk.text) for chunk in chunks), 1_000_000)

    def test_manual_chunk_size_bypasses_context_lookup(self):
        sizing = build_chunk_sizing(
            base_url="http://unused.example/v1",
            model="unused",
            api_key=None,
            chunk_chars=24_000,
            context_window_tokens=None,
            chunk_context_utilization=0.96,
            chars_per_token=1.0,
            prompt_reserve_tokens=1_024,
            output_reserve_tokens=512,
            min_chunk_chars=1,
            max_auto_chunk_chars=None,
        )

        self.assertEqual(sizing.chunk_chars, 24_000)
        self.assertEqual(sizing.source, "manual")

    def test_invalid_auto_sizing_rejects_exhausted_context(self):
        with self.assertRaises(ValueError):
            compute_context_aware_chunk_chars(
                context_window_tokens=1_000,
                chars_per_token=1.0,
                chunk_context_utilization=0.96,
                reserved_tokens=2_000,
            )


if __name__ == "__main__":
    unittest.main()
