import argparse
import subprocess
import re
import json

#
# Class to hold information on git merge
# members
#   commit hash
#   merge hash
#   git_author_name
#   date of merge
#   title of pr
#   pr number
#   pr log
#
#
class GitMerge:
    commit_pattern = re.compile(r'^commit (\w+)')
    merge_pattern = re.compile(r'^Merge: (\w+\s+\w+)')
    author_pattern = re.compile(r'^Author: (\w+\s+\w+)')
    date_pattern = re.compile(r'^Date:\s+(.*?)$')
    embed_pattern = re.compile(r'^\s+(.*?)$')
    prnum_pattern = re.compile(r'#(\d+)')

    # Block has all the fields
    def __init__(self, block):
        prlog_filled = False
        self.set_defaults()
        lines = block.splitlines()

        for item in lines:
            commit_match = self.commit_pattern.search(item)
            if commit_match:
                self.commit = commit_match.group(1)

            merge_match = self.merge_pattern.search(item)
            if merge_match:
                self.merge = merge_match.group(1)

            author_match = self.author_pattern.search(item)
            if author_match:
                self.git_author_name = author_match.group(1)

            date_match = self.date_pattern.search(item)
            if date_match:
                self.date = date_match.group(1)

            # multiple lines with leading tabs they appear nested aka embed
            # first time an embed line is detected it is treated as a PR Log Entry
            # all subsequent lines are treated as PR Titles
            # last title is set overriding previous titles
            embed_match = self.embed_pattern.search(item)
            if embed_match:
                if prlog_filled:
                    self.title = embed_match.group(1)
                else:
                    self.prlog = embed_match.group(1)
                    prnum_match = self.prnum_pattern.search(self.prlog)
                    if prnum_match:
                        self.prnumber = prnum_match.group(1)
                    prlog_filled = True

    def __str__(self):
        return self.prepare_print()

    def prepare_print(self):
        commit = f"Commit: {self.commit}\n"
        merge = f"Merge: {self.merge}\n"
        git_author_name = f"Author: {self.git_author_name}\n"
        date = f"Date: {self.date}\n"
        title = f"Title: {self.title}\n"
        prnum = f"PR Num: {self.prnumber}\n"
        prlog = f"PR: {self.prlog}\n"
        return commit + merge + git_author_name + date + title + prnum + prlog

    def set_defaults(self):
        self.commit = "NA"
        self.merge = "NA"
        self.git_author_name = "NA"
        self.date = "NA"
        self.title = "NA"
        self.prnumber = 0
        self.prlog = "NA"

#
# Class to hold information about PR
# PR Number
# PR Title
# PR author
# milestone
# isDraft
# body
# comments
# approvers
class GH_PullRequest:
    def __init__(self, pr_number):
        pull_request_details = json.loads(self.get_gh_pr(pr_number))
        self.author = pull_request_details["author"]["login"]
        self.body = pull_request_details["body"]
        self.is_draft = pull_request_details["isDraft"]
        # default to None
        self.milestone = None
        # only expand if defined
        if pull_request_details["milestone"]:
            self.milestone = pull_request_details["milestone"]["title"]
        self.prnum = pull_request_details["number"]
        self.title = pull_request_details["title"]
        self.comments = pull_request_details["comments"]
        self.approvers = []
        # loop over all the comments, approvals, and rejections
        # pull out approving authors and append to list
        for review in pull_request_details["reviews"]:
            if review["state"] == "APPROVED":
                login = review["author"]["login"]
                if login not in self.approvers:
                    self.approvers.append(login)
        # parse issues
        self.issues = self.search_issues(self.body)

    def get_gh_pr(self, prnum):
        # gh pr view --json number,title,author,reviews,isDraft,comments
        command = ['gh', 'pr', 'view', '--json', 'number,title,author,milestone,isDraft,body,comments,reviews', prnum]
        result = subprocess.run(command, capture_output=True, text=True)

        if result.returncode != 0:
            raise Exception('Error executing command: {}\n{}'.format(command, result.stderr))

        return result.stdout

    def search_issues(self, body):
        issues = []
        # search for keywords
        search_keywords = '[close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved]'
        git_issue_pattern = re.compile(r''+search_keywords+'\s+#(\d+)', re.IGNORECASE)
        for i in re.findall(git_issue_pattern, body):
            issues.append(i)
        return issues

    def as_oneline(self):
        author = f" Author: {self.author}"
        milestone = f" Milestone: {self.milestone}"
        pr_num = f"PR Num: {self.prnum}"
        title  = f" Title: {self.title[0:40]}"
        approvers = f" Approvers: {', '.join(self.approvers)}"
        issues = f" Issues: {', '.join(self.issues)}"
        return pr_num + author + milestone + approvers + issues + title

    def __str__(self):
        author = f"Author: {self.author}\n"
        body = f"Body: {self.body}\n"
        is_draft = f"isDraft: {self.is_draft}\n"
        milestone = f"Milestone: {self.milestone}\n"
        pr_num = f"PR Num: {self.prnum}\n"
        title  = f"Title: {self.title}\n"
        approvers = f"Approvers: {', '.join(self.approvers)}\n"
        issues = f"Issues: {', '.join(self.issues)}\n"
        return title + author + pr_num + approvers + issues + milestone + is_draft + body

def get_git_log_messages(repo_path, start):
    range=start+'..HEAD'
    command = ['git', '-C', repo_path, 'log', range, '--abbrev-commit', '--merges', '--first-parent']
    result = subprocess.run(command, capture_output=True, text=True)

    if result.returncode != 0:
        raise Exception('Error executing command: {}\n{}'.format(command, result.stderr))

    return result.stdout

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Get git log messages from a repository.')
    parser.add_argument('repo_path', type=str, help='Path to the git repository')
    parser.add_argument('start', type=str, help='commit or tag that marks the beginning of the release')
    parser.add_argument('--debug', action='store_true', help='print out debug statments')
    parser.add_argument('-n', '--debug_pr_num', type=str, help='dump contents for this PR Id')
    parser.add_argument('--oneline',action='store_true', help='format as a single line of text')

    args = parser.parse_args()
    if args.debug:
        DEBUG=True
    else:
        DEBUG=False

    messages = get_git_log_messages(args.repo_path,args.start)
    pattern = re.compile(r"^commit\s+\w+", re.MULTILINE)
    result = pattern.finditer(messages)

    start_positions = []
    merges = []

    # iterate through matches calculating the start and end of blocks
    for match in result:
        start, end = match.span()
        start_positions.append(start)

    # second loop because its easier to calcuate boundries after appending the ending location
    start_positions.append(len(messages)+1)
    if DEBUG:
        print(f"Processing Git Logs")
    for end in start_positions:
        # skip first
        if end > 0:
            if DEBUG:
                print(f"Text Block {start} to {end-1}")
            merges.append(GitMerge(messages[start:end]))
        # last block's end is new block's start
        start = end

    if DEBUG:
        print(f"Gathering Issues Details using gh pr view")
    for item in merges:
        if DEBUG:
            print(".")
        pr_details = GH_PullRequest(item.prnumber)
        # DEBUG print out full details
        if DEBUG == True and item.prnumber == args.debug_pr_num:
            print(f'\n***** MERGE FROM GIT LOG ******')
            print(item)
            print(f'***** PR DETAILS FROM GH ******')
            print(pr_details)
        #if len(pr_details.issues) > 0:
        if args.oneline:
            print(pr_details.as_oneline())
        else:
            print(pr_details)
