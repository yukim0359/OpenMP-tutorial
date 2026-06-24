#!/usr/bin/env python3
"""ヒストグラム例: atomic（一様/偏り）のスレッド数スイープ作図。"""

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
THREADS_SKEWED = list(range(1, 51))
SLIDE_IMG = ROOT.parent.parent / "slide" / "img"
CSV_UNIFORM = CSV_DIR / "threads_hist_uniform.csv"
CSV_SKEWED = CSV_DIR / "threads_hist_skewed.csv"


def build() -> None:
    subprocess.run(["make", "measure_threads_hist"], cwd=ROOT, check=True)


def sweep_mode(
    mode: str,
    csv_path: Path,
    threads: list[int],
) -> tuple[list[int], list[float], list[float], list[float], list[float]]:
    means: list[float] = []
    stds: list[float] = []
    for t in threads:
        mean, std = measure_mean(["./measure_threads_hist", str(t), mode], ROOT)
        means.append(mean)
        stds.append(std)
        print(f"atomic {mode:7s} t={t:2d}  {mean:.6f} ± {std:.6f} s  ({RUNS} runs)")
    speedups, speedup_stds = speedup_series(means[0], stds[0], means, stds)
    for t, sp, sp_std in zip(threads, speedups, speedup_stds):
        print(f"atomic {mode:7s} t={t:2d}  speedup={sp:.3f} ± {sp_std:.3f}")
    write_sweep_csv(csv_path, threads, means, stds, speedups, speedup_stds)
    return threads, means, stds, speedups, speedup_stds


def measure_all() -> None:
    build()
    sweep_mode("uniform", CSV_UNIFORM, THREADS)
    sweep_mode("skewed", CSV_SKEWED, THREADS_SKEWED)


def trim_sweep(
    threads: list[int],
    speedups: list[float],
    speedup_stds: list[float],
    max_threads: int,
) -> tuple[list[int], list[float], list[float]]:
    trimmed = [(t, sp, sp_std) for t, sp, sp_std in zip(threads, speedups, speedup_stds) if t <= max_threads]
    return (
        [row[0] for row in trimmed],
        [row[1] for row in trimmed],
        [row[2] for row in trimmed],
    )


def plot_hist_threads() -> None:
    u_threads, _, _, u_speedups, u_speedup_stds = read_sweep_csv(CSV_UNIFORM)
    s_threads, _, _, s_speedups, s_speedup_stds = read_sweep_csv(CSV_SKEWED)
    s_threads, s_speedups, s_speedup_stds = trim_sweep(
        s_threads, s_speedups, s_speedup_stds, THREADS_SKEWED[-1]
    )

    plot_speedup_sweep(
        [
            (u_threads, u_speedups, u_speedup_stds, "uniform (atomic)", "o-"),
            (s_threads, s_speedups, s_speedup_stds, "skewed (atomic)", "s-"),
        ],
        f"Histogram atomic speedup (mean of {RUNS} runs)",
        [IMG_DIR / "threads_hist.png", SLIDE_IMG / "threads_hist.png"],
        ideal_max=10,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    add_plot_only_arg(parser)
    args = parser.parse_args()

    if not args.plot_only:
        measure_all()
    plot_hist_threads()


if __name__ == "__main__":
    main()
