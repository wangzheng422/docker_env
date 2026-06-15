import unittest


from pi_summary_agent.chunking import chunk_text


class ChunkingTests(unittest.TestCase):
    def test_chunk_text_keeps_chunks_within_budget_and_preserves_order(self):
        text = ("alpha beta gamma\n\n" * 30).strip()

        chunks = chunk_text(text, max_chars=80, overlap_chars=0)

        self.assertGreater(len(chunks), 1)
        self.assertTrue(all(len(chunk.text) <= 80 for chunk in chunks))
        reconstructed = "".join(chunk.text for chunk in chunks)
        self.assertEqual(reconstructed, text)
        self.assertEqual([chunk.index for chunk in chunks], list(range(len(chunks))))
        self.assertEqual(chunks[0].start, 0)
        self.assertEqual(chunks[-1].end, len(text))

    def test_chunk_text_adds_overlap_without_losing_source_offsets(self):
        text = "0123456789" * 12

        chunks = chunk_text(text, max_chars=25, overlap_chars=5)

        self.assertGreater(len(chunks), 1)
        self.assertEqual(chunks[1].start, chunks[0].end - 5)
        self.assertTrue(chunks[1].text.startswith(text[chunks[1].start : chunks[0].end]))
        self.assertTrue(all(len(chunk.text) <= 25 for chunk in chunks))

    def test_chunk_text_rejects_invalid_overlap(self):
        with self.assertRaisesRegex(ValueError, "overlap_chars"):
            chunk_text("abcdef", max_chars=10, overlap_chars=10)


if __name__ == "__main__":
    unittest.main()
