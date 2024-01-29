import argparse
import subprocess
import re
import json
import sys

def useage():
    message = "NOTE: Running this requires you have a local clone of the repository and you are in that directory\n"
    message += "Example: git clone https://github.com/org/repo && cd repo && python3 $HELPER_PATH/draft-release-notes.py tag\n\n"
    message += "Additional requirements: must have git installed and gh cli installed.\n"
    message += "    See https://github.com/cli/cli and https://git-scm.com/book/en/v2/Getting-Started-Installing-Git\n\n"
    message += "Platforms: This script has been tested on ubunut linux with python3\n"
    message += "  - for a summary use the --oneline option\n"
    message += "  - for a html summary user the --html option\n"
    message += "  - to print this useage try the --useage option\n"

    return message

def git_repo_name():
    command = ['git', 'remote', 'get-url', 'origin']
    result = subprocess.run(command, capture_output=True, text=True)

    if result.returncode != 0:
        raise Exception('Error executing command: {}\n{}'.format(command, result.stderr))
    paths = result.stdout.split('/')
    # strip off end of line
    return (paths[3] + "/" + paths[4]).strip()


def styling():
    css = "<style>\n"
    css += "/* Style the collapsible content. Note: hidden by default */\n"
    css += ".textblock { padding: 0 18px; background-color: #f1f1f1; width: 80%; transition: all .3s ease;}\n"
    css += "p { margin: 0; }\n"
    css += ".btcode { color: blue; font-family: 'Monaco', monospace; font-size: .75em }\n"
    css += "</style>\n"
    return css

def javascript():
    return ""

def start_doc(html=False):
    # only applies to html, skip in all other cases
    if not html:
        return ""

    js = javascript()
    css = styling()
    return "<!DOCTYPE html>\n<html><head>"+js+css+"</head><body>\n"

def end_doc(html=False):
    # only applies to html, skip in all other cases
    if not html:
        return ""

    return "\n</body></html>\n"

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
    def __init__(self, pr_number, git_repo_path):
        self.git_repo_path = git_repo_path
        # get pr and parse json response
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
        # parse special meta data
        self.enf_meta_data = self.pull_enf_notes(self.comments)

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
        # The (?:   ) is a non-matching group
        # This return a tuple for each keyword found matching both short and long formats
        #  - first tuple matches #XXXX
        #  - second tuple matches https://github.com/org/repo/XXXX
        search_keywords = '(?:close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved|resovles)'
        git_issue_pattern = re.compile(r''+search_keywords+'\s+(?:#(\d+)|(https?://\S+/\d+))', re.IGNORECASE)
        for tuple_i in re.findall(git_issue_pattern, body):
            for pos in range(0, 2):
                if len(tuple_i[pos]) > 0:
                    if not tuple_i[pos].startswith('http'):
                        # can't reasign tuple so we need temp variable
                        url = 'https://github.com/' + self.git_repo_path + '/issues/' + tuple_i[pos]
                        issues.append(url)
                    else:
                        issues.append(tuple_i[pos])
        return issues

    def pull_enf_notes(self, comments):
        meta_data = {
            'group': None,
            'category': None,
            'summary': None,
            }
        for single_comment in comments:
            match = re.search(r'Note:start(.*?)Note:end', single_comment['body'], re.DOTALL)
            if match:
                for line in match.group(1).split('\n'):
                    parts = line.split(":")
                    if parts[0] == "group":
                        meta_data['group'] = parts[1].strip()
                    if parts[0] == "category":
                        meta_data['category'] = parts[1].strip()
                    if parts[0] == "summary":
                        meta_data['summary'] = parts[1].strip()
        return meta_data

    def as_oneline(self):
        author = f" Author: {self.author}"
        pr_num = f"PR Num: {self.prnum}"
        category = f" Category: {self.enf_meta_data['category']}"
        group = f" Group: {self.enf_meta_data['group']}"
        title  = f" Title: {self.title[0:55]}"
        approvers = f" Approvers: {', '.join(self.approvers)}"
        if len(self.issues) > 0:
            # strip down to ids
            issue_ids = list(map(lambda n: n.split('/')[-1], self.issues))
            issues = f" Issues: {', '.join(issue_ids)}"
        else:
            issues = "Issues: None Linked"
        summary = f" Summary: {self.enf_meta_data['summary']}"

        return pr_num + author + approvers + issues + title + summary

    def replace_with_link(self, match):
        url = match.group(0)
        shortened_url = url[-7:]  # Get the last 7 characters of the URL
        return f'<a href="{url}">{shortened_url}</a>'

    def replace_md_with_html(self):
        backtik_pattern = r'`([^`]*)`'
        body_as_html = re.sub(backtik_pattern, r'<span class="btcode">\1</span>', self.body)
        url_pattern = r'https?://\S+'
        body_as_html = re.sub(url_pattern, self.replace_with_link, body_as_html)
        self.body = body_as_html

    def as_html(self, newafter):
        newtag = ""
        if newafter > 0 and self.prnum > newafter:
            newtag = "<font color='red'> NEW </font>"

        base_url = f"https://github.com/{self.git_repo_path}"
        author = f"<p>Author: {self.author}</p>\n"

        category = f"<p>Category: {self.enf_meta_data['category']}</p>\n"
        group = f"<p>Group: {self.enf_meta_data['group']}</p>\n"

        linked_title  = f"<h2>{newtag}<a href=\"{base_url}/pull/{self.prnum}\">{self.title[0:55]}</a></h2>\n"
        approvers = f"<p>Approvers: {', '.join(self.approvers)}</p>\n"
        self.replace_md_with_html()
        body = f"<div class=\"textblock\">PR Text: {self.body}</div>\n"
        issues = f"<p>Issues:</p>\n"
        if len(self.issues) > 0:
            issues += "<ul>\n"
            for i in self.issues:
                issues += f"<li><a href=\"{i}\">{i}</a></li>\n"
            issues += "</ul>\n"
        else:
            issues = "<p>Issues: None Linked</p>\n"
        summary = f"<p>Summary: {self.enf_meta_data['summary']}</p>\n"
        sep = f"<hr width=\"50%\" size=\"3px\" align=\"center\"/>"

        return linked_title + summary + category + group + author + approvers + issues + body + sep

    def __str__(self):
        author = f"Author: {self.author}\n"
        body = f"Body: {self.body}\n"
        category = f"Category: {self.enf_meta_data['category']}\n"
        group = f"Group: {self.enf_meta_data['group']}\n"
        is_draft = f"isDraft: {self.is_draft}\n"
        milestone = f"Milestone: {self.milestone}\n"
        pr_num = f"PR Num: {self.prnum}\n"
        title  = f"Title: {self.title}\n"
        approvers = f"Approvers: {', '.join(self.approvers)}\n"
        issues = f"Issues: {', '.join(self.issues)}\n"
        summary = f"Summary: {self.enf_meta_data['summary']}\n"
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
    parser.add_argument('start', type=str, help='commit or tag that marks the beginning of the release')
    parser.add_argument('--debug', action='store_true', help='print out debug statments')
    parser.add_argument('--debug_pr_num', '-n', type=str, help='dump contents for this PR Id')
    parser.add_argument('--newafter', '-a', type=str, help='Only for HTML Reports: Tag later PRs with New')
    parser.add_argument('--oneline', action='store_true', help='format as a single line of text')
    parser.add_argument('--html', action='store_true', help='format as html for the web')
    parser.add_argument('--useage', '-u', action='store_true', help='print useage')

    args = parser.parse_args()

    # print useage, documentation on useage
    if args.useage:
        print(useage())
        exit()

    # prefer the look of DEBUG to args.debug
    if args.debug:
        DEBUG=True
    else:
        DEBUG=False

    # owner/repo parsed from .gitconfig origin url
    git_repo_name = git_repo_name()
    # get all the first parent merge requests to branch
    messages = get_git_log_messages(".",args.start)
    # split the string into an array of commits
    pattern = re.compile(r"^commit\s+\w+", re.MULTILINE)
    commit_boundry = pattern.finditer(messages)

    # init some arrays
    start_positions = []
    merges = []

    # iterate through matches calculating the start and end of blocks
    for match in commit_boundry:
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
            # Create an array of GitMerge objects
            # GitMerge object has properites with the commit log data
            merges.append(GitMerge(messages[start:end]))
        # last block's end is new block's start
        start = end

    if DEBUG:
        print(f"Gathering Issues Details using gh pr view")
    # print document header
    print(start_doc(args.html))
    for item in merges:
        # shows work getting done, otherwise you question the silence
        if DEBUG:
            print(".")
        # Create an object from the Git PR data
        pr_details = GH_PullRequest(item.prnumber, git_repo_name)

        # DEBUG print out full details
        if DEBUG == True and item.prnumber == args.debug_pr_num:
            print(f'\n***** MERGE FROM GIT LOG ******')
            print(item)
            print(f'***** PR DETAILS FROM GH ******')
            print(pr_details)

        # different formate options delegated to object
        if args.oneline:
            print(pr_details.as_oneline())
        elif args.html:
            newafter = 0
            if args.newafter:
                newafter = int(args.newafter)
            print(pr_details.as_html(newafter))
        else:
            print(pr_details)

    # print document footer
    print(end_doc(args.html))
