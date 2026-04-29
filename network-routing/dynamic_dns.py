"""Dynamic DNS updater for Cloudflare DNS records."""

import ipaddress
import sys

import requests


API_BASE_URL = "https://api.cloudflare.com/client/v4"
REQUIRED_ENV_KEYS = ("CFBEARER", "CFACC", "CFZONE")
PATCHABLE_RECORD_FIELDS = ("comment", "name", "proxied", "settings", "tags", "ttl", "type")


def load_env_variables(env_file):
    """
    Load environment variables from a simple KEY=VALUE file.
    Supports:
      - NAME=VALUE
      - NAME="VALUE"
      - NAME='VALUE'
      - ignores comments and blank lines
    """
    env_config = {}

    try:
        with open(env_file, "r", encoding="utf-8") as env_handle:
            for line_num, raw_line in enumerate(env_handle, 1):
                line = raw_line.strip()

                if not line or line.startswith("#"):
                    continue

                if "=" not in line:
                    raise ValueError(f"Invalid line {line_num} in {env_file}: {raw_line.strip()}")

                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()

                if (value.startswith('"') and value.endswith('"')) or (
                    value.startswith("'") and value.endswith("'")
                ):
                    value = value[1:-1]

                env_config[key] = value

    except FileNotFoundError as exc:
        raise ValueError(f"Env file not found: {env_file}") from exc
    except OSError as exc:
        raise ValueError(f"Error reading env file {env_file}: {exc}") from exc

    missing_keys = [key for key in REQUIRED_ENV_KEYS if not env_config.get(key)]
    if missing_keys:
        raise ValueError(f"Missing required env values in {env_file}: {', '.join(missing_keys)}")

    return env_config


def cloudflare_headers(token):
    """Build the Cloudflare bearer-token headers."""
    return {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}",
    }


def format_cloudflare_errors(errors):
    """Format Cloudflare API error objects for human-readable output."""
    if not isinstance(errors, list) or not errors:
        return "no error details returned"

    formatted_errors = []
    for error in errors:
        if isinstance(error, dict):
            code = error.get("code")
            message = error.get("message", "unknown error")
            if code is None:
                formatted_errors.append(str(message))
            else:
                formatted_errors.append(f"[{code}] {message}")
        else:
            formatted_errors.append(str(error))

    return "; ".join(formatted_errors)


def parse_cloudflare_response(response, operation):
    """Parse and validate a Cloudflare API response envelope."""
    try:
        payload = response.json()
    except ValueError as exc:
        raise RuntimeError(f"{operation} returned invalid JSON") from exc

    if not isinstance(payload, dict):
        raise RuntimeError(f"{operation} returned an unexpected response type")

    if payload.get("success") is not True:
        raise RuntimeError(f"{operation} failed: {format_cloudflare_errors(payload.get('errors'))}")

    return payload


def get_record_type_for_ip(ip_address):
    """Map the input IP address to the Cloudflare DNS record type."""
    parsed_ip = ipaddress.ip_address(ip_address)
    return "A" if parsed_ip.version == 4 else "AAAA"


def get_request(token, zone, record_type):
    """List Cloudflare DNS records matching the requested IP version."""
    url = f"{API_BASE_URL}/zones/{zone}/dns_records"

    try:
        response = requests.get(
            url,
            headers=cloudflare_headers(token),
            params={"type": record_type},
            timeout=9,
        )
        response.raise_for_status()
    except requests.exceptions.RequestException as exc:
        raise RuntimeError(f"Cloudflare DNS record lookup failed: {exc}") from exc

    payload = parse_cloudflare_response(
        response,
        f"Cloudflare DNS record lookup for zone {zone} and type {record_type}",
    )

    records = payload.get("result")
    if not isinstance(records, list):
        raise RuntimeError("Cloudflare DNS record lookup returned an invalid result set")

    return records


def build_patch_payload(record, ip_address):
    """Build a PATCH payload that preserves supported record metadata."""
    payload = {"content": ip_address}

    for field in PATCHABLE_RECORD_FIELDS:
        if field in record:
            payload[field] = record[field]

    required_fields = ("name", "type")
    missing_fields = [field for field in required_fields if not payload.get(field)]
    if missing_fields:
        raise RuntimeError(
            f"Cloudflare DNS record is missing required patch fields: {', '.join(missing_fields)}"
        )

    return payload


def patch_request(token, zone, record_id, patch_json):
    """Patch a Cloudflare DNS record."""
    url = f"{API_BASE_URL}/zones/{zone}/dns_records/{record_id}"

    try:
        response = requests.patch(
            url,
            headers=cloudflare_headers(token),
            json=patch_json,
            timeout=9,
        )
        response.raise_for_status()
    except requests.exceptions.RequestException as exc:
        raise RuntimeError(f"Cloudflare DNS record update failed for {record_id}: {exc}") from exc

    parse_cloudflare_response(response, f"Cloudflare DNS record update for {record_id}")
    return True


def get_records_to_update(records, ip_address, record_type):
    """Return only records that match the IP version and need updating."""
    records_to_update = []

    for record in records:
        if not isinstance(record, dict):
            raise RuntimeError("Cloudflare DNS record lookup returned a non-object record")

        if record.get("type") != record_type:
            continue

        missing_fields = [
            field for field in ("id", "name", "type", "content") if not record.get(field)
        ]
        if missing_fields:
            raise RuntimeError(
                f"Cloudflare DNS record is missing required fields: {', '.join(missing_fields)}"
            )

        if record["content"] == ip_address:
            continue

        records_to_update.append(record)

    return records_to_update


def sync_dns_records(ip_address, env_vars):
    """Synchronize zone records for the provided IP address."""
    record_type = get_record_type_for_ip(ip_address)
    dns_records = get_request(env_vars["CFBEARER"], env_vars["CFZONE"], record_type)
    records_to_update = get_records_to_update(dns_records, ip_address, record_type)

    for record in records_to_update:
        patch_payload = build_patch_payload(record, ip_address)
        patch_request(env_vars["CFBEARER"], env_vars["CFZONE"], record["id"], patch_payload)

    return len(records_to_update)


def main():
    """Build and execute the dynamic DNS update flow."""
    if len(sys.argv) != 3:
        print("Usage: python dynamic_dns.py <IP> <ENV_FILE>", file=sys.stderr)
        sys.exit(1)

    ip_address = sys.argv[1]
    env_file = sys.argv[2]

    try:
        env_vars = load_env_variables(env_file)
        sync_dns_records(ip_address, env_vars)
    except (RuntimeError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
