#!/usr/bin/env python3
import hashlib
import math
import random
import struct

rng = random.Random(0x272104)
digest = hashlib.sha256()
for case in range(6000):
    samples = rng.randrange(1, 33)
    classes = rng.randrange(2, 9)
    logits = [[rng.uniform(-20.0, 20.0) for _ in range(classes)] for _ in range(samples)]
    targets = [rng.randrange(classes) for _ in range(samples)]
    losses = []
    predictions = []
    matrix = [0] * (classes * classes)
    for row, target in zip(logits, targets):
        maximum = max(row)
        losses.append(maximum + math.log(sum(math.exp(x - maximum) for x in row)) - row[target])
        predicted = max(range(classes), key=row.__getitem__)
        predictions.append(predicted)
        matrix[target * classes + predicted] += 1
    accuracy = sum(a == b for a, b in zip(predictions, targets)) / samples
    positive = case % classes
    tp = sum(p == positive and t == positive for p, t in zip(predictions, targets))
    fp = sum(p == positive and t != positive for p, t in zip(predictions, targets))
    fn = sum(p != positive and t == positive for p, t in zip(predictions, targets))
    precision = tp / (tp + fp) if tp + fp else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    digest.update(struct.pack('<III5d', case, samples, classes, sum(losses) / samples, accuracy, precision, recall, float(tp)))
    digest.update(b''.join(struct.pack('<Q', x) for x in matrix))
print(f'RF27_G21_F04_ORACLE=PASS seed=0x272104 cases=6000 digest={digest.hexdigest()}')
