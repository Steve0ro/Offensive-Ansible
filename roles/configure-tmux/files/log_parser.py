#!/usr/bin/env python3
"""
Advanced tmux log cleaner + transcript formatter
"""

from __future__ import annotations
import argparse
import re
import shutil
import sys
from datetime import datetime, timezone
from typing import Match

# ISO timestamp match
TS_RE = re.compile(
    r'\b(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:[+-]\d{4}|Z))\b'
)

# ANSI escape sequences
ANSI_RE = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')

# Stray percent-only lines
PERCENT_RE = re.compile(r'^\s*%\s*$')

# Prompt detection (customize if needed)
PROMPT_RE = re.compile(r'<-\[.*?\].*?->')

def normalize_iso(ts: str) -> str:
    if ts.endswith('Z'):
        return ts.replace('Z', '+00:00')
    if re.match(r'.*[+-]\d{4}$', ts):
        return ts[:-5] + ts[-5:-2] + ':' + ts[-2:]
    return ts

def format_dt(dt: datetime, to_utc: bool) -> str:
    if to_utc:
        dt = dt.astimezone(timezone.utc)
        return dt.strftime('%Y-%m-%d %H:%M:%S UTC')
    return dt.strftime('%Y-%m-%d %H:%M:%S %z')[:-2] + ':' + dt.strftime('%z')[-2:]

def clean_line(line: str, remove_prompt: bool) -> str | None:
    # Remove ANSI codes
    line = ANSI_RE.sub('', line)

    # Remove stray %
    if PERCENT_RE.match(line):
        return None

    # Optionally remove prompt lines
    if remove_prompt and PROMPT_RE.search(line):
        return None

    return line.rstrip()

def process_stream(in_f, out_f, args):
    previous = None

    for raw in in_f:
        line = raw

        # Convert timestamp
        def repl(match: Match):
            try:
                dt = datetime.fromisoformat(normalize_iso(match.group(1)))
                return format_dt(dt, args.utc)
            except Exception:
                return match.group(1)

        line = TS_RE.sub(repl, line)

        # Clean junk
        line = clean_line(line, args.no_prompt)
        if line is None or not line.strip():
            continue

        # Remove duplicate redraw lines
        if line == previous:
            continue
        previous = line

        # Transcript mode formatting
        if args.transcript:
            if line.strip().startswith("$"):
                out_f.write(f"\n{line}\n")
            else:
                out_f.write(f"  {line}\n")
        else:
            out_f.write(line + "\n")

def main():
    p = argparse.ArgumentParser(description="Clean and pretty-print tmux logs")
    p.add_argument('infile', help="input log file")
    p.add_argument('-o', '--outfile', help="output file")
    p.add_argument('--utc', action='store_true', help='convert timestamps to UTC')
    p.add_argument('-i', '--inplace', action='store_true', help='edit file in-place (.bak created)')
    p.add_argument('--transcript', action='store_true', help='format like terminal transcript')
    p.add_argument('--no-prompt', action='store_true', help='remove prompt lines')

    args = p.parse_args()

    if args.inplace and args.outfile:
        p.error("Cannot use --inplace and --outfile together")

    if args.inplace:
        backup = args.infile + ".bak"
        shutil.copy2(args.infile, backup)
        with open(backup, 'r', encoding='utf-8', errors='replace') as inf, \
             open(args.infile, 'w', encoding='utf-8', errors='replace') as outf:
            process_stream(inf, outf, args)
        print(f"[inplace] backup created: {backup}")
        return

    if args.outfile:
        with open(args.infile, 'r', encoding='utf-8', errors='replace') as inf, \
             open(args.outfile, 'w', encoding='utf-8', errors='replace') as outf:
            process_stream(inf, outf, args)
    else:
        with open(args.infile, 'r', encoding='utf-8', errors='replace') as inf:
            process_stream(inf, sys.stdout, args)

if __name__ == "__main__":
    main()