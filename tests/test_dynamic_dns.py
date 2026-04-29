"""Unit tests for the Cloudflare dynamic DNS updater."""

import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import requests


MODULE_PATH = Path(__file__).resolve().parents[1] / "network-routing" / "dynamic_dns.py"
MODULE_SPEC = importlib.util.spec_from_file_location("dynamic_dns", MODULE_PATH)
dynamic_dns = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(dynamic_dns)


class FakeResponse:
    """Simple fake HTTP response for requests mocking."""

    def __init__(self, payload=None, status_error=None, json_error=None):
        self._payload = payload
        self._status_error = status_error
        self._json_error = json_error

    def raise_for_status(self):
        if self._status_error is not None:
            raise self._status_error

    def json(self):
        if self._json_error is not None:
            raise self._json_error
        return self._payload


class DynamicDNSTests(unittest.TestCase):
    """Behavioral tests for the dynamic DNS script helpers."""

    def test_load_env_variables_requires_cfacc(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            env_path = Path(temp_dir) / "dynamic-dns.env"
            env_path.write_text(
                "CFBEARER=token\nCFZONE=zone\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "CFACC"):
                dynamic_dns.load_env_variables(str(env_path))

    def test_get_request_uses_bearer_auth_and_record_type_filter(self):
        fake_response = FakeResponse(payload={"success": True, "result": []})

        with patch.object(dynamic_dns.requests, "get", return_value=fake_response) as mock_get:
            result = dynamic_dns.get_request("token-123", "zone-456", "A")

        self.assertEqual(result, [])
        mock_get.assert_called_once()
        _, kwargs = mock_get.call_args
        self.assertEqual(kwargs["params"], {"type": "A"})
        self.assertEqual(kwargs["headers"]["Authorization"], "Bearer token-123")

    def test_get_records_to_update_skips_matching_and_wrong_type_records(self):
        records = [
            {"id": "1", "name": "example.com", "type": "A", "content": "203.0.113.9"},
            {"id": "2", "name": "www.example.com", "type": "A", "content": "198.51.100.10"},
            {"id": "3", "name": "v6.example.com", "type": "AAAA", "content": "2001:db8::1"},
        ]

        records_to_update = dynamic_dns.get_records_to_update(records, "203.0.113.9", "A")

        self.assertEqual([record["id"] for record in records_to_update], ["2"])

    def test_sync_dns_records_updates_only_records_that_need_the_target_ip(self):
        env_vars = {"CFBEARER": "token", "CFACC": "account", "CFZONE": "zone"}
        list_response = FakeResponse(
            payload={
                "success": True,
                "result": [
                    {
                        "id": "1",
                        "name": "example.com",
                        "type": "A",
                        "content": "198.51.100.10",
                        "ttl": 1,
                        "proxied": False,
                    },
                    {
                        "id": "2",
                        "name": "www.example.com",
                        "type": "A",
                        "content": "203.0.113.9",
                        "ttl": 120,
                        "proxied": True,
                    },
                    {
                        "id": "3",
                        "name": "v6.example.com",
                        "type": "AAAA",
                        "content": "2001:db8::1",
                        "ttl": 1,
                    },
                ],
            }
        )
        patch_response = FakeResponse(payload={"success": True, "result": {"id": "1"}})

        with (
            patch.object(dynamic_dns.requests, "get", return_value=list_response) as mock_get,
            patch.object(dynamic_dns.requests, "patch", return_value=patch_response) as mock_patch,
        ):
            updated_count = dynamic_dns.sync_dns_records("203.0.113.9", env_vars)

        self.assertEqual(updated_count, 1)
        mock_get.assert_called_once()
        mock_patch.assert_called_once()
        _, kwargs = mock_patch.call_args
        self.assertEqual(kwargs["json"]["content"], "203.0.113.9")
        self.assertEqual(kwargs["json"]["type"], "A")
        self.assertEqual(kwargs["json"]["name"], "example.com")
        self.assertEqual(kwargs["json"]["ttl"], 1)
        self.assertIs(kwargs["json"]["proxied"], False)

    def test_patch_request_raises_on_cloudflare_error_envelope(self):
        patch_response = FakeResponse(
            payload={
                "success": False,
                "errors": [{"code": 1000, "message": "invalid request"}],
            }
        )

        with patch.object(dynamic_dns.requests, "patch", return_value=patch_response):
            with self.assertRaisesRegex(RuntimeError, r"\[1000\] invalid request"):
                dynamic_dns.patch_request(
                    "token",
                    "zone",
                    "record-1",
                    {"name": "example.com", "type": "A", "content": "203.0.113.9"},
                )

    def test_get_request_raises_on_http_failure(self):
        request_error = requests.exceptions.HTTPError("403 Client Error")
        fake_response = FakeResponse(status_error=request_error)

        with patch.object(dynamic_dns.requests, "get", return_value=fake_response):
            with self.assertRaisesRegex(RuntimeError, "403 Client Error"):
                dynamic_dns.get_request("token", "zone", "A")


if __name__ == "__main__":
    unittest.main()
