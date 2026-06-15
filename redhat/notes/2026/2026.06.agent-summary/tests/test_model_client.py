import unittest

from pi_summary_agent.model_client import extract_message_text


class ModelClientTests(unittest.TestCase):
    def test_extracts_normal_content(self):
        response = {"choices": [{"message": {"content": "hello"}}]}

        self.assertEqual(extract_message_text(response), "hello")

    def test_uses_reasoning_content_when_content_is_null(self):
        response = {
            "choices": [
                {"message": {"content": None, "reasoning_content": "hidden summary"}}
            ]
        }

        self.assertEqual(extract_message_text(response), "hidden summary")

    def test_uses_vllm_reasoning_when_content_is_null(self):
        response = {"choices": [{"message": {"content": None, "reasoning": "thinking text"}}]}

        self.assertEqual(extract_message_text(response), "thinking text")

    def test_null_content_without_reasoning_becomes_empty_string(self):
        response = {"choices": [{"message": {"content": None}}]}

        self.assertEqual(extract_message_text(response), "")


if __name__ == "__main__":
    unittest.main()
