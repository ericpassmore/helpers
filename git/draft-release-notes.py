import argparse
import subprocess
import re

#
#
#commit 58deb5b51
#Merge: ef910f795 1d0aef60c
#Author: Kevin Heifner <heifnerk@objectcomputing.com>
#Date:   Thu Jun 29 07:03:40 2023 -0400
#
#    Merge pull request #1350 from AntelopeIO/GH-1302-docs-4.0
#
#    [4.0] Docs: Additional nodeos --help info
#
#
class GitMerge:
    commit_pattern = re.compile(r'^commit (\w+)')
    merge_pattern = re.compile(r'^Merge: (\w+\s+\w+)')
    author_pattern = re.compile(r'^Author: (\w+\s+\w+)')
    date_pattern = re.compile(r'^Date:\s+(.*?)$')
    embed_pattern = re.compile(r'^\s+(.*?)$')
    prnum_pattern = re.compile(r'#(\d+)')

    def __init__(self, block):
        prlog_filled = False
        self.prnumber = 0
        lines = block.splitlines();
        for item in lines:
            commit_match = self.commit_pattern.search(item)
            if commit_match:
                self.commit = commit_match.group(1)

            merge_match = self.merge_pattern.search(item)
            if merge_match:
                self.merge = merge_match.group(1)

            author_match = self.author_pattern.search(item)
            if author_match:
                self.author = author_match.group(1)

            date_match = self.date_pattern.search(item)
            if date_match:
                self.date = date_match.group(1)

            # multiple lines with leading tabs they appear nested aka embed
            # first time an embed line is detected it is treated as a PR Log Entry
            # all subsequent lines are treated as PR Titles
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
        return f"Commit: {self.commit}\nMerge: {self.merge}\nAuthor: {self.author}\nDate: {self.date}\nTitle: {self.title}\nPR: {self.prlog}\nPR Num: {self.prnumber}"

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

    args = parser.parse_args()
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
    for end in start_positions:
        # skip first
        if end > 0:
            print(f"Text Block {start} to {end-1}")
            merges.append(GitMerge(messages[start:end]))
        # last block's end is new block's start
        start = end

    for item in merges:
        print(item)
