
URL="https://github.com/AntelopeIO/reference-contracts/issues/"
def read_records(filename):
    with open(filename, 'r') as f:
        content = f.read()
        records = content.split('\ntitle:')

    for i, record in enumerate(records):
        # split by title: and now we need to repair
        # if the first record we don't repair
        if i > 0:
          record = 'title:'+ record
        print (f"Record: {i}\n")
        lines = record.split('\n')
        acc_body = False
        for line in lines:
            line = line.replace("`", "\\`")
            line = line.replace("!", "\\!")
            if line.startswith('title:'):
                title=line[6:].strip()

            elif line.startswith('author:'):
                author=line[7:].strip()

            elif line.startswith('labels:'):
                labels=line[7:].strip()

            elif line.startswith('assignees:'):
                assignees=line[10:].strip()

            elif line.startswith('milestone:'):
                milestones=line[10:].strip()
            elif line.startswith('number:'):
                body=f'Transferred from {URL}{line[7:].strip()} original author {author}\n'
                acc_body = True
            elif acc_body:
                body = body + line + "\n";
        print(f'gh issue create --title "{title}" --body "{body}" --label "{labels}" --assignee "{assignees}" --milestone "{milestones}"')

# Usage
read_records('/home/eric/issues-to-migrate.txt')
