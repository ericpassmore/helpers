import re
import json

def search_issues(body):
    issues = []
    # search for keywords
    search_keywords = '(?:close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)'
    git_issue_pattern = re.compile(r''+search_keywords+'\s+(?:#(\d+)|https?://\S+/(\d+))', re.IGNORECASE)
    for tuple_i in re.findall(git_issue_pattern, body):
        for pos in range(0, 2):
            if len(tuple_i[pos]) > 0:
                issues.append(tuple_i[pos])
    return issues

with open('gh-pr-877.txt', 'r') as file:
    pull_request_details = json.load(file)
issues = search_issues(pull_request_details["body"])
if len(issues) > 0:
    print(issues)
    #print(' : '.join(issues))
else:
    print("No Issues Found")
