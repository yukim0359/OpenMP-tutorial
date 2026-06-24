#!/usr/bin/env python3
"""simd / simd_scalar を各スレッド数で複数回実行し，平均・標準偏差を表示する。"""

from __future__ import annotations

import os
import re
import statistics
import subprocess
from pathlib import Path

RUNS = 10
THREADS = (1, 4)
DIR = Path(__file__).parent
BIN_DIR = DIR / "bin"


def measure_once(exe: str, threads: int) -> float:
    env = os.environ.copy()
    env["OMP_NUM_THREADS"] = str(threads)
    out = subprocess.run(
        [str(BIN_DIR / exe)],
        cwd=DIR,
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    m = re.search(r"([\d.]+)\s*sec", out.stdout)
    if not m:
        raise RuntimeError(f"unexpected output from {exe}: {out.stdout!r}")
    return float(m.group(1))


def measure_mean(exe: str, threads: int, runs: int = RUNS) -> tuple[float, float]:
    measure_once(exe, threads)  # warmup
    times = [measure_once(exe, threads) for _ in range(runs)]
    std = statistics.stdev(times) if runs > 1 else 0.0
    return statistics.mean(times), std


def main() -> None:
    print(f"# {RUNS} runs each (mean ± stdev, seconds)\n")
    for exe, label in (("simd", "SIMD"), ("simd_scalar", "scalar")):
        print(f"## {label} ({exe})")
        for t in THREADS:
            mean, std = measure_mean(exe, t)
            print(f"  OMP_NUM_THREADS={t}: {mean:.6f} ± {std:.6f}")
        print()


if __name__ == "__main__":
    main()
