#!/usr/bin/env python3
"""Inclusive and self sample counts for one thread of a macOS `sample` file.

    python3 sample_tree.py <sample.txt> [thread-substring] [top] [filter-substring]
"""
import re
import sys

path = sys.argv[1]
want = sys.argv[2] if len(sys.argv) > 2 else "Main Thread"
top = int(sys.argv[3]) if len(sys.argv) > 3 else 60
only = sys.argv[4] if len(sys.argv) > 4 else None

lines = open(path, errors="replace").read().splitlines()
start = None
end = None
for i, line in enumerate(lines):
    if re.match(r"^\s+\d+ Thread_\d+", line):
        if start is None and want in line:
            start = i
        elif start is not None and end is None:
            end = i
            break
if start is None:
    sys.exit("thread not found")
body = lines[start:end]
node = re.compile(r"^([\s+!:|]*)(\d+) (.+?)(?:\s+\(in ([^)]+)\))?(?:\s+\+ \d+)?(?:\s+\[[^\]]+\])?(?:\s+\S+:\d+)?\s*$")
stack = []  # (depth, name, count, childsum)
inclusive = {}
selfc = {}
total = int(re.match(r"^\s+(\d+)", body[0]).group(1))


def pop_to(depth):
    while stack and stack[-1][0] >= depth:
        d, name, count, childsum = stack.pop()
        selfc[name] = selfc.get(name, 0) + max(0, count - childsum)


for line in body[1:]:
    m = node.match(line)
    if not m:
        continue
    depth = len(m.group(1))
    count = int(m.group(2))
    name = m.group(3).strip()
    module = m.group(4) or ""
    name = (name[:150] + " [" + module + "]")
    pop_to(depth)
    if stack:
        stack[-1][3] += count
    if name not in [s[1] for s in stack]:
        inclusive[name] = inclusive.get(name, 0) + count
    stack.append([depth, name, count, 0])
pop_to(-1)

print(f"thread total {total}")
print("== inclusive")
items = sorted(inclusive.items(), key=lambda kv: -kv[1])
shown = 0
for name, count in items:
    if only and only not in name:
        continue
    print(f"{count:7d} {100*count/total:5.1f}%  {name}")
    shown += 1
    if shown >= top:
        break
print("== self")
for name, count in sorted(selfc.items(), key=lambda kv: -kv[1])[:top // 2]:
    print(f"{count:7d} {100*count/total:5.1f}%  {name}")
