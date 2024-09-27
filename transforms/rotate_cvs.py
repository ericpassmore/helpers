"""Rotates CSV file from columns to rows"""
import argparse
import os

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="""Converts CSV file from columns to rows""")
    parser.add_argument('--file', type=str, help='file to transform')
    args = parser.parse_args()

    headers = []
    data = []
    # Open the file in read mode
    with open(args.file, 'r') as file:
        # get first line
        first_line = next(file)
        # Split the content by commas
        items = first_line.split(',')
        # Pop off the first item
        header_title = items.pop(0)
        headers.append(header_title.strip())
        # get the max entries
        max_entries = len(items)
        row = 0
        # initalize first col across all rows with first line
        for i in items:
            if len(data) <= row:
                data.append([])
            data[row].append(i.strip())
            row = row +1

        # Read the contents of the file line by line
        for line in file:
            # Split the content by commas
            items = line.split(',')

            # Pop off the first item
            header_title = items.pop(0)

            # add col to header row
            headers.append(header_title.strip())
            # add col to all other rows
            for row_number in range(max_entries):
                entry = ""
                if len(items) > row_number:
                    entry = items[row_number].strip()
                data[row_number].append(entry)
    # print out
    print (",".join(headers))
    for row in data:
        print(",".join(row))
