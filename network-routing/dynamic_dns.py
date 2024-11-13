"""Scripts for Dynamic DNS Updates"""
import sys
import os
import json
import requests
from dotenv import dotenv_values

def load_env_variables(env_file):
    """
    Load environment variables from a file.
    """
    env_config = dotenv_values(env_file)
    if 'CFBEARER' not in env_config and not env_config['CFBEARER']:
        raise ValueError(f"CFBEARER not found in the env file {env_file}")
    if 'CFZONE' not in env_config and not env_config['CFZONE']:
        raise ValueError(f"CFZONE not found in the env file {env_file}")
    return env_config

def get_request(token, zone):
    """
    Make an HTTP GET request with the Authorization header.
    """
    url = f"https://api.cloudflare.com/client/v4/zones/{zone}/dns_records"
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    }

    try:
        response = requests.get(url, headers=headers, timeout=9)
        response.raise_for_status()
        return response.content.decode('utf-8')
    except requests.exceptions.RequestException as myreqexception:
        print(f"HTTP Request failed: {myreqexception}")
        sys.exit(1)
    except json.JSONDecodeError:
        print("Failed to parse JSON response")
        sys.exit(1)

def patch_request(token, zone, record_id, patch_json):
    """
    Make an HTTP patch request to update DNS dns_entries
    """
    url = f"https://api.cloudflare.com/client/v4/zones/{zone}/dns_records/{record_id}"
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    }

    try:
        response = requests.patch(url, headers=headers, json=patch_json, timeout=9)
        response.raise_for_status()
        dds_update = json.loads(response.content.decode('utf-8'))
        if not dds_update['success']:
            print(f"Dynamic DNS Failed with {dds_update.errors}")
        return dds_update['success']
    except requests.exceptions.RequestException as myreqexception:
        print(f"HTTP Patch Request failed: {myreqexception}")
        sys.exit(1)
    except json.JSONDecodeError:
        print("Failed to parse JSON response")
        sys.exit(1)

def main():
    """Main method for building dynamic dns updates"""
    debug=True
    # documentation see
    # https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-patch-dns-record
    if len(sys.argv) != 3:
        print("Usage: python fetch_data.py <IP> <ENV_FILE>")
        sys.exit(1)

    ip_address = sys.argv[1]
    env_file = sys.argv[2]

    try:
        env_vars = load_env_variables(env_file)
        json_response = get_request(env_vars['CFBEARER'], env_vars['CFZONE'])
        dns_entries = json.loads(json_response)
        for rec in dns_entries['result']:
            if debug:
                print(f"Working on record {rec['id']} with ip address {rec['content']}")
            if rec['content'] != ip_address:
                if debug:
                    print("No Match Updating Record")
                # acceptable fields
                # comment, name, proxied, settings, tags, ttl, content, type
                new_rec = {'content': ip_address}
                success = patch_request(env_vars['CFBEARER'], env_vars['CFZONE'], rec['id'], new_rec)
                if debug:
                    print(f"Completed update request with status {success}")

    except ValueError as myvalerr:
        print(f"Error: {myvalerr}")
        sys.exit(1)

if __name__ == "__main__":
    main()
