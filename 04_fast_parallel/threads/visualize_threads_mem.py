#!/usr/bin/env python3
"""メモリ帯域律速 (measure_threads_mem) のスレッド数スイープ作図。"""

import argparse
import subprocess
from pathlib import Path

from bench_common import (
    CSV_DIR,
    IMG_DIR,
    RUNS,
    measure_mean,
    read_sweep_csv,
    speedup_series,
    write_sweep_csv,
)
from visualize_common import add_plot_only_arg, plot_speedup_sweep

ROOT = Path(__file__).resolve().parent
THREADS = list(range(1, 100))
SLIDE_IMG = ROOT.parent.parent / "slide" / "img"
CSV_PATH = CSV_DIR / "threads_mem.csv"


def build() -> None:
    subprocess.run(["make", "measure_threads_mem"], cwd=ROOT, check=True)


def measure() -> tuple[list[int], list[float], list[float], list[float], list[float]]:
    build()
    means: list[float] = []
    stds: list[float] = []
    for t in THREADS:
        mean, std = measure_mean(["./measure_threads_mem", str(t)], ROOT)
        means.append(mean)
        stds.append(std)
        print(f"threads={t:2d}  {mean:.6f} ± {std:.6f} s  ({RUNS} runs)")

    speedups, speedup_stds = speedup_series(means[0], stds[0], means, stds)
    for t, sp, sp_std in zip(THREADS, speedups, speedup_stds):
        print(f"threads={t:2d}  speedup={sp:.3f} ± {sp_std:.3f}")

    write_sweep_csv(CSV_PATH, THREADS, means, stds, speedups, speedup_stds)
    return THREADS, means, stds, speedups, speedup_stds


def plot(
    threads: list[int],
    speedups: list[float],
    speedup_stds: list[float],
) -> None:
    plot_speedup_sweep(
        [(threads, speedups, speedup_stds, "mem-bound update", "o-")],
        f"Memory-bandwidth-bound update speedup (mean of {RUNS} runs)",
        [IMG_DIR / "threads_mem.png", SLIDE_IMG / "threads_mem.png"],
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    add_plot_only_arg(parser)
    args = parser.parse_args()

    if args.plot_only:
        threads, _, _, speedups, speedup_stds = read_sweep_csv(CSV_PATH)
    else:
        threads, _, _, speedups, speedup_stds = measure()
    plot(threads, speedups, speedup_stds)


if __name__ == "__main__":
    main()
