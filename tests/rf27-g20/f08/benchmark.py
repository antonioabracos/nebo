#!/usr/bin/env python3
import subprocess
import time

start = time.perf_counter_ns()
for _ in range(32):
    subprocess.run(["build/examples/rf27-g20/tiny-inference"], check=True)
elapsed = time.perf_counter_ns() - start
assert elapsed > 0
print(f"RF27_G20_F08_BENCHMARK=MEASURED iterations=32 elapsed_ns={elapsed} artifact=tiny-inference scope=local_methodology_only")
