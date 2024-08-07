"""Downloads latest leap artifact from a branch and returns the associated git commit"""
import argparse
import json
import logging
from datetime import datetime
import subprocess
import os
import re
import requests

@staticmethod
def api_headers(token):
    """Headers always the same"""
    return {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Authorization': "Bearer "+token
    }

def get_pr_list(branch, token):
    """Search PRs on a given branch
    and pull out the id for the most recent"""
    # this will store the record for the most recent pr
    pr_list = {}
    # set url
    url='https://api.github.com/repos/AntelopeIO/spring/pulls'
    # set params
    params = {'base': branch, 'state': 'closed'}

    # API Request
    query_pull_requests = requests.get(url,
            params=params,
            headers=api_headers(token),
            timeout=10)

    if query_pull_requests.status_code == 200:
        root_json = query_pull_requests.content.decode('utf-8')
        root = json.loads(root_json)

        for record in root:
            # if not merged skip to next
            if not record['merged_at']:
                continue

            merge_record = {
                "internal_id": record['id'],
                "title": record['title'],
                "number": record['number'],
                "head_branch": record['head']['ref'],
                "merge_sha": record['merge_commit_sha'],
                "head_sha": record['head']['sha'],
                "merged_at": record['merged_at']
            }
            merge_time = datetime.strptime(record['merged_at'], '%Y-%m-%dT%H:%M:%SZ')

            # no drafts and succesfully merged
            if record['draft'] != "false":
                logging.debug('id: %i matching record %s with pr# %i merge time %s',
                    merge_record['internal_id'], merge_record['title'], merge_record['number'], merge_time)

                # build list of actions
                pr_list[merge_time] = merge_record

    # return sorted list
    return dict(sorted(pr_list.items(), reverse=True))

def get_latest_build_action(action, head_sha, token):
    """Search through workflow
    by looking head sha for all pull requests
    look for the most recent action"""
    # this will store the record for the most recent action
    latest_action = {}
    # set url
    url='https://api.github.com/repos/AntelopeIO/spring/actions/runs'
    # set params
    params = {'head_sha': head_sha, 'event': 'push'}

    # API Request
    query_runs = requests.get(url,
            params=params,
            headers=api_headers(token),
            timeout=10)

    if query_runs.status_code == 200:
        root_json = query_runs.content.decode('utf-8')
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
    url=f"https://api.github.com/repos/AntelopeIO/spring/actions/runs/{artifact_id}/artifacts"

    # API Request
    query_artifacts = requests.get(url,
            headers=api_headers(token),
            timeout=10)

    if query_artifacts.status_code == 200:
        root_json = query_artifacts.content.decode('utf-8')
        root = json.loads(root_json)

        for item in root['artifacts']:
            # print (f"ARTIFACT ----> {item['name']} COMPARING --> {artifact_name}")
            if item['name'] == artifact_name:
                # print (f"matching artifact {item['name']} with id {item['id']}")
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

    # replace file if it already exists, remove first
    logging.info("checking for existing file %s, will rm if found", file_path)
    try:
        os.remove(file_path)
    except FileNotFoundError:
        pass

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

def unzip_artifact(destination_dir, file_name, merge_sha):
    """unzip artifact and print out information on deb"""

    zip_file = destination_dir+"/"+file_name
    deb_file_pattern = re.compile('.*antelope-spring_[0-9].+_amd64.deb$')

    # replace file if it already exists, remove first
    logging.info("cleaning out previous debs in dir %s", destination_dir)
    clean_dir_list = os.listdir(destination_dir)
    clean_file_list = [ s for s in clean_dir_list if deb_file_pattern.match(s) ]
    logging.info("found matching files %s", clean_file_list)
    if len(clean_file_list) > 0:
        try:
            os.remove(destination_dir+"/"+clean_file_list[0])
        except FileNotFoundError:
            pass

    # commands
    unzip_cmd = ["unzip", zip_file, "-d", destination_dir]
    logging.info("running cmd %s", unzip_cmd)
    unzip_result = subprocess.run(unzip_cmd, \
        check=False, timeout=30, capture_output=True, text=True)
    if unzip_result.returncode != 0:
        logging.error("failed to unzip %s error %s", zip_file, unzip_result.stderr)
        exit()

    # rm zip after unzipping
    logging.info("removing file %s", zip_file)
    os.remove(zip_file)

    # list to get exact file name
    logging.info("running os list for  %s", destination_dir)
    dir_list = os.listdir(destination_dir)
    logging.info("found matching files %s", dir_list)
    file_list = [ s for s in dir_list if deb_file_pattern.match(s) ]
    if len(file_list) <= 0:
        logging.error("expected to find deb package after unzip and found nothing!")
        exit()
    full_file_listing = file_list[0]

    # checksum
    checksum_cmd = ["sha256sum", destination_dir+"/"+full_file_listing]
    logging.info("running cmd %s", checksum_cmd)
    checksum_result = subprocess.run(checksum_cmd, \
        check=False, timeout=3, capture_output=True, text=True)
    if checksum_result.returncode != 0:
        logging.error("failed to checksum %s error %s", full_file_listing, checksum_result.stderr)
    checksum = checksum_result.stdout.split()[0]

    results = {
        "deb": full_file_listing,
        "gitcommitsha": merge_sha,
        "sha256sum": checksum
    }

    return results

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="""Downloads latest leap artifact from a branch
and returns the associated git commit""")
    parser.add_argument('--branch', type=str, default='release/5.0', help='branch to get latest artifact')
    parser.add_argument('--download-dir', type=str, default='.', help='director to download into')
    parser.add_argument('--select-pr', action=argparse.BooleanOptionalAction, \
        default=False, help='select pr and filter by that pr\'s commit')
    parser.add_argument('--stop-after-prs', action=argparse.BooleanOptionalAction, \
        default=False, help='optional: prints PRs and then stops')
    parser.add_argument('--pr-search-length', type=int, \
        default=10, help='number of prs to search back default 10')
    parser.add_argument('--bearer-token', type=str, help="""github bearer token to access github api
    see https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens""")
    parser.add_argument('--debug', action=argparse.BooleanOptionalAction, \
        default=False, help='print debug stmts to stderr')

    args = parser.parse_args()
    BUILD_TEST_ACTION='Build & Test'
    ARTIFACT='antelope-spring-deb-amd64'

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.ERROR)

    # Step 1. Query the prs for the branch we are interested in
    # return matching PR with the latest updated date
    logging.info("Step 1: query for latest PR on %s branch", {args.branch})
    recent_prs = get_pr_list(args.branch, args.bearer_token)
    if not recent_prs:
        logging.error("Step 1: failed could not find any matches for action on branch")
        exit()

    # if desired print PRs
    # if stop_after_prs then exit otherwise break loop and continue with Step 2.
    if args.stop_after_prs or args.select_pr:
        stop_limit = args.pr_search_length
        for time_of_merge, pr_rec in recent_prs.items():
            logging.debug("stop limit for printing prs at %i", stop_limit)
            if stop_limit <= 0:
                if args.stop_after_prs:
                    exit()
                else:
                    break
            format_time = time_of_merge.strftime("%b %d %Y %I%p")
            print(f"[{args.pr_search_length-stop_limit+1}] PR {pr_rec['number']} {pr_rec['title']}")
            print(f"\t\tMerge time {format_time}")
            print(f"\t\tSHA {pr_rec['merge_sha']}")
            stop_limit=stop_limit-1

    pr_index = 0
    if args.select_pr:
        # if selecting a PR get the number
        print("Please Select a PR >>", end="")
        pr_index = int(input())

    # Step 2. Query workflow runs to find the latest Build & Test Action
    selected_pr = {}
    for run in recent_prs.values():
        pr_index = pr_index - 1
        selected_pr = run
        # select by index trigger select if pr_index undefined or pr_index zero
        if args.select_pr:
            if pr_index <= 0:
                break
        # select most recent
        else:
            break
    logging.info("Step 2: Select PR %i query workflows for %s sha and action %s",
        selected_pr['number'],
        {selected_pr['merge_sha']},
        {BUILD_TEST_ACTION}
    )
    most_recent_action = get_latest_build_action(BUILD_TEST_ACTION,
        selected_pr['merge_sha'],
        args.bearer_token
    )
    if not most_recent_action:
        logging.error("Step 2: failed could not find any matches for action on branch")
        exit()
    logging.debug(most_recent_action)

    # Step 3. Get all the artifacts from workflow
    # iterate over list "artifacts" look for name = "antelope-spring-deb-amd64" and return "id" and "archive_download_url"
    logging.info("Step 3: query for artifact %s using github action id %i", ARTIFACT, most_recent_action['id'])
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


    # Step 4. download
    logging.info("Step 4: download artifact to %s", args.download_dir)
    download_success = download_artifact(artifact['archive_download_url'],
        args.download_dir,
        ARTIFACT,
        args.bearer_token)
    if not download_success:
        logging.error("Step 3. failed to download artifact")
        exit()
    logging.info("Download Complete corresponding commit: %s", {most_recent_action['sha']})

    # Step 5. Unzip, print summary results with checksum and commit sha
    logging.info("Step 5: unzip downloaded archive to dir %s", args.download_dir)
    # returns checksum of deb, sha of git commit, and deb file name
    package_info = unzip_artifact(args.download_dir, ARTIFACT, most_recent_action['sha'])
    package_info['pr_num']   = selected_pr['number']
    package_info['pr_title'] = selected_pr['title']
    package_info['branch']   = args.branch
    package_info['merge_time'] = selected_pr['merged_at']

    print(json.dumps(package_info))
