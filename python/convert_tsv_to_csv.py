import csv
import sys
from pathlib import Path

if len(sys.argv) != 2:
    sys.exit(f"Usage: {sys.argv[0]} <path/to/file.tsv>")

input_file = Path(sys.argv[1])
output_file = input_file.with_suffix('.csv')

with open(input_file, 'r', encoding='utf-8') as tsv_in, \
     open(output_file, 'w', encoding='utf-8', newline='') as csv_out:
    reader = csv.reader(tsv_in, delimiter='\t')
    writer = csv.writer(csv_out, delimiter=',')
    writer.writerows(reader)

