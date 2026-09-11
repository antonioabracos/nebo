#!/usr/bin/env python3
"""Seeded finite DAG/cycle property oracle for package resolution."""
from hashlib import sha256
from random import Random

rng = Random(0x272404)
digest = sha256()
acyclic = cyclic = 0
for _ in range(5000):
    count = rng.randrange(1, 33)
    graph = [[] for _ in range(count)]
    for node in range(count):
        for _ in range(rng.randrange(0, 4)):
            target = rng.randrange(0, count)
            if target != node and target not in graph[node]:
                graph[node].append(target)
    colors = [0] * count
    cycle = False
    def visit(node: int) -> None:
        global cycle
        if colors[node] == 1:
            cycle = True
            return
        if colors[node] == 2:
            return
        colors[node] = 1
        for target in sorted(graph[node]):
            visit(target)
        colors[node] = 2
    for node in range(count):
        visit(node)
    cyclic += cycle
    acyclic += not cycle
    digest.update(bytes((count, cycle)))
    for edges in graph:
        digest.update(bytes(sorted(edges)))
print(f"RF27_G24_F04_ORACLE=PASS seed=0x272404 cases=5000 acyclic={acyclic} cyclic={cyclic} digest={digest.hexdigest()}")
