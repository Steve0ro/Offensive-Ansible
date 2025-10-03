#!/usr/bin/env python3
"""
Convert ISO-8601 timestamps in tmux logs like:
  2025-10-02T21:44:09-0400:  some text...

to a readable format while preserving the rest of the lines.

Usage:
  python3 pretty_tmux_log.py input.log                 # prints to stdout
  python3 pretty_tmux_log.py -o out.log input.log     # write to out.log
  python3 pretty_tmux_log.py --utc -i input.log       # convert to UTC, edit file in-place (creates input.log.bak)
"""
from __future__ import annotations
import argparse
import re
from datetime import datetime, timezone, timedelta
from typing import Match

TS_RE = re.compile(r'\b(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:[+-]\d{4}|Z))\b')

def insert_colon_offset(offset_str: str) -> str:
    if len(offset_str) == 5 and (offset_str.startswith('+') or offset_str.startswith('-')):
        return offset_str[:3] + ':' + offset_str[3:]
    return offset_str

def normalize_to_fromiso(ts: str) -> str:
    if ts.endswith('Z'):
        return ts.replace('Z', '+00:00')
    if re.match(r'.*[+-]\d{4}$', ts):
        return ts[:-5] + ts[-5:-2] + ':' + ts[-2:]
    return ts

def format_dt_for_readability(dt: datetime, to_utc: bool) -> str:
    if to_utc:
        dt_utc = dt.astimezone(timezone.utc)
        return dt_utc.strftime('%Y-%m-%d %H:%M:%S UTC')
    else:
        base = dt.strftime('%Y-%m-%d %H:%M:%S %z')  # %z gives ±HHMM
        if base.endswith('+0000') or base.endswith('-0000'):
            return base[:-5] + '+00:00'
        return base[:-5] + base[-5:-2] + ':' + base[-2:]

def repl(match: Match, to_utc: bool) -> str:
    ts_raw = match.group(1)
    try:
        iso_like = normalize_to_fromiso(ts_raw)
        dt = datetime.fromisoformat(iso_like)
    except Exception:
        return ts_raw
    return format_dt_for_readability(dt, to_utc)

def process_stream(in_f, out_f, to_utc: bool):
    for line in in_f:
        newline = TS_RE.sub(lambda m: repl(m, to_utc), line)
        out_f.write(newline)

def main():
    p = argparse.ArgumentParser(description="Pretty-print timestamps in tmux logs")
    p.add_argument('infile', help="input log file (use '-' for stdin)")
    p.add_argument('-o', '--outfile', help="output file (default stdout)")
    p.add_argument('--utc', action='store_true', help='convert timestamps to UTC')
    p.add_argument('-i', '--inplace', action='store_true', help='edit input file in-place (creates .bak)')
    args = p.parse_args()

    if args.inplace and args.outfile:
        p.error("Cannot use --inplace and --outfile simultaneously")

    if args.infile == '-':
        import sys
        process_stream(sys.stdin, sys.stdout, args.utc)
        return

    if args.inplace:
        import shutil
        backup = args.infile + '.bak'
        shutil.copy2(args.infile, backup)
        with open(backup, 'r', encoding='utf-8', errors='replace') as inf, \
             open(args.infile, 'w', encoding='utf-8', errors='replace') as outf:
            process_stream(inf, outf, args.utc)
        print(f"[inplace] original backed up to {backup}")
        return

    if args.outfile:
        with open(args.infile, 'r', encoding='utf-8', errors='replace') as inf, \
             open(args.outfile, 'w', encoding='utf-8', errors='replace') as outf:
            process_stream(inf, outf, args.utc)
        print(f"Wrote converted log to {args.outfile}")
    else:
        with open(args.infile, 'r', encoding='utf-8', errors='replace') as inf:
            import sys
            process_stream(inf, sys.stdout, args.utc)

if __name__ == '__main__':
    main()
