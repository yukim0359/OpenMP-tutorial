"""04_fast_parallel/threads ベンチマーク用: 複数回実行の平均・標準偏差。"""

from __future__ import annotations

import csv
import math
import statistics
import subprocess
from pathlib import Path

RUNS = 10
CSV_DIR = Path(__file__).resolve().parent / "csv"
IMG_DIR = Path(__file__).resolve().parent / "img"

SWEEP_FIELDS = ["threads", "time_mean", "time_std", "speedup", "speedup_std"]


def measure_once(cmd: list[str], cwd: Path) -> float:
    out = subprocess.run(
        cmd, cwd=cwd, check=True, capture_output=True, text=True
    )
    return float(out.stdout.split()[1])


def measure_mean(cmd: list[str], cwd: Path, runs: int = RUNS) -> tuple[float, float]:
    times = [measure_once(cmd, cwd) for _ in range(runs)]
    std = statistics.stdev(times) if runs > 1 else 0.0
    return statistics.mean(times), std


def speedup_stats(
    baseline_mean: float,
    baseline_std: float,
    mean: float,
    std: float,
) -> tuple[float, float]:
    """1 スレッド実行時間を基準とした speedup = T(1) / T(n) とその誤差。"""
    if mean <= 0.0 or baseline_mean <= 0.0:
        return 0.0, 0.0
    speedup = baseline_mean / mean
    rel = math.hypot(baseline_std / baseline_mean, std / mean)
    return speedup, speedup * rel


def speedup_series(
    baseline_mean: float,
    baseline_std: float,
    means: list[float],
    stds: list[float],
) -> tuple[list[float], list[float]]:
    out_s: list[float] = []
    out_e: list[float] = []
    for mean, std in zip(means, stds):
        s, e = speedup_stats(baseline_mean, baseline_std, mean, std)
        out_s.append(s)
        out_e.append(e)
    return out_s, out_e


def write_sweep_csv(
    path: Path,
    threads: list[int],
    means: list[float],
    stds: list[float],
    speedups: list[float],
    speedup_stds: list[float],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=SWEEP_FIELDS)
        writer.writeheader()
        for t, mean, std, speedup, speedup_std in zip(
            threads, means, stds, speedups, speedup_stds
        ):
            writer.writerow(
                {
                    "threads": t,
                    "time_mean": f"{mean:.9f}",
                    "time_std": f"{std:.9f}",
                    "speedup": f"{speedup:.6f}",
                    "speedup_std": f"{speedup_std:.6f}",
                }
            )
    print(f"wrote {path}")


def read_sweep_csv(
    path: Path,
) -> tuple[list[int], list[float], list[float], list[float], list[float]]:
    with path.open(newline="") as f:
        rows = list(csv.DictReader(f))
    threads = [int(row["threads"]) for row in rows]
    means = [float(row["time_mean"]) for row in rows]
    stds = [float(row["time_std"]) for row in rows]
    speedups = [float(row["speedup"]) for row in rows]
    speedup_stds = [float(row["speedup_std"]) for row in rows]
    return threads, means, stds, speedups, speedup_stds
