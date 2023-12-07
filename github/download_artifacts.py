"""Downloads latest leap artifact from a branch and returns the associated git commit"""
import argparse
import json
import logging
from datetime import datetime
import requests

@staticmethod
def api_headers(token):
    """Headers always the same"""
    return {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Authorization': "Bearer "+token
    }

def get_latest_build_action(action, branch, token):
    """Search through workflow
    by looking at PRs on a given branch
    and pull out the id for the most recent action"""
    # this will store the record for the most recent action
    latest_action = {}
    # set url
    url='https://api.github.com/repos/AntelopeIO/leap/actions/runs'
    # set params
    params = {'branch': branch, 'event': 'pull_request'}

    # API Request
    query_pull_requests = requests.get(url,
            params=params,
            headers=api_headers(token),
            timeout=10)

    if query_pull_requests.status_code == 200:
        root_json = query_pull_requests.content.decode('utf-8')
        root = json.loads(root_json)

        for record in root['workflow_runs']:
            workflow_id = record['id']
            workflow_name = record['name']
            update_time = datetime.strptime(record['updated_at'], '%Y-%m-%dT%H:%M:%SZ')

            # match our action
            if workflow_name == action:
                logging.debug('matching record %s with id %i update time %s',
                    workflow_name, workflow_id, update_time)

                # update with latest where name equals action param
                if not latest_action or \
                    latest_action['update_time'] < update_time:
                    latest_action = {
                        'update_time': update_time,
                        'name': workflow_name,
                        'id': workflow_id,
                        'sha': record['head_sha'],
                        'status': record['status']
                    }
    return latest_action

def get_deb_download_url(artifact_id, artifact_name, token):
    """Now get the URL for our artifact"""
    # set url
    url=f"https://api.github.com/repos/AntelopeIO/leap/actions/runs/{artifact_id}/artifacts"

    # API Request
    query_artifacts = requests.get(url,
            headers=api_headers(token),
            timeout=10)

    if query_artifacts.status_code == 200:
        root_json = query_artifacts.content.decode('utf-8')
        root = json.loads(root_json)

        for item in root['artifacts']:
            if item['name'] == artifact_name:
                logging.debug('matching artifact %s with id %i',
                    item['name'], item['id'])

            return {
                'name': item['name'],
                'id': item['id'],
                'url': item['url'],
                'archive_download_url': item['archive_download_url'],
                'is_expired': item['expired'],
                'expires_at': datetime.strptime(item['expires_at'], '%Y-%m-%dT%H:%M:%SZ')
            }
    return None

def download_artifact(url, destination_dir, file_name, token):
    """Download artifact"""

    file_path = f"{destination_dir}/{file_name}"
    # API Request
    download_request = requests.get(url,
            headers=api_headers(token),
            allow_redirects=True,
            timeout=10)

    if download_request.status_code == 200:
        with open(file_path, 'wb') as file:
            file.write(download_request.content)
        # success
        return True
    # failed
    return False

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="""Downloads latest leap artifact from a branch
and returns the associated git commit""")
    parser.add_argument('--branch', type=str, default='release/5.0', help='branch to get latest artifact')
    parser.add_argument('--download-dir', type=str, default='.', help='director to download into')
    parser.add_argument('--bearer-token', type=str, help="""github bearer token to access github api
    see https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens""")
    parser.add_argument('--debug', action=argparse.BooleanOptionalAction, \
        default=False, help='print debug stmts to stderr')

    args = parser.parse_args()
    BUILD_TEST_ACTION='Build & Test'
    ARTIFACT='leap-deb-amd64'

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.ERROR)

    # Step 1. Query the workflows for the branch and event you want
    # Iterate over "workflow_runs" look for name = "Build & Test".
    # return matching action with the latest updated date
    logging.info("Step 1: query workflows for %s branch and action %s", {args.branch}, {BUILD_TEST_ACTION})
    most_recent_action = get_latest_build_action(BUILD_TEST_ACTION, args.branch, args.bearer_token)
    if not most_recent_action:
        logging.error("Step 1: failed could not find any matches for action on branch")
        exit()
    logging.debug(most_recent_action)


    # Step 2. Get all the artifact from workflow
    # iterate over list "artifacts" look for name = "leap-deb-amd64" and return "id" and "archive_download_url"
    logging.info("Step 2: query for artifact %s", ARTIFACT)
    artifact = get_deb_download_url(most_recent_action['id'],
        ARTIFACT,
        args.bearer_token)
    if not artifact:
        logging.error("Step 2: failed could not find any matching artifacts")
        exit()
    if artifact['is_expired']:
        logging.error("Step 2: failed found artifact but it is expired")
        exit()
    logging.debug(artifact)


    # Step 3. download
    logging.info("Step 3: download artifact to %s", args.download_dir)
    download_success = download_artifact(artifact['archive_download_url'],
        args.download_dir,
        ARTIFACT,
        args.bearer_token)
    if not download_success:
        logging.error("Step 3. failed to download artifact")
        exit()
    print(f"Download Complete corresponding commit: {most_recent_action['sha']}")
