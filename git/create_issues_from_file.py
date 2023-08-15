
URL="https://github.com/AntelopeIO/leap/issues/"
def read_records(filename):
    with open(filename, 'r') as f:
        content = f.read()
        records = content.split('--\n\n')

    for i, record in enumerate(records):
        lines = record.split('\n')
        for line in lines:
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
                body=f'Transferred from {URL}{line[7:].strip()} original author {author}'
        print(f'gh issue create --title "{title}" --body "{body}" --label "{labels}" --assignee "{assignees}" --milestone "{milestones}"')

# Usage
read_records('/home/eric/issues-to-migrate.txt')
