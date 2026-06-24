#!/usr/bin/env python3
"""static / dynamic / guided を複数回実行し，平均・標準偏差を表示する。"""

from __future__ import annotations

import argparse
import csv
import os
import re
import statistics
import subprocess
from pathlib import Path

RUNS = 10
DIR = Path(__file__).parent
CSV_DIR = DIR / "csv"
BIN_DIR = DIR / "bin"
PROGRAMS = ("static", "dynamic", "guided")
TIME_RE = re.compile(r"^\s*(\w+)\s*:\s*([\d.]+)\s*s\s*$", re.MULTILINE)


def measure_once(exe: str, threads: int | None) -> float:
    env = os.environ.copy()
    if threads is not None:
        env["OMP_NUM_THREADS"] = str(threads)
    out = subprocess.run(
        [str(BIN_DIR / exe)],
        cwd=DIR,
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    m = TIME_RE.search(out.stdout)
    if not m:
        raise RuntimeError(f"unexpected output from {exe}: {out.stdout!r}")
    return float(m.group(2))


def measure_mean(
    exe: str, threads: int | None, runs: int = RUNS
) -> tuple[float, float]:
    measure_once(exe, threads)  # warmup
    times = [measure_once(exe, threads) for _ in range(runs)]
    std = statistics.stdev(times) if runs > 1 else 0.0
    return statistics.mean(times), std


def build() -> None:
    subprocess.run(["make", "static", "dynamic", "guided"], cwd=DIR, check=True)


def run_bench(
    runs: int,
    threads: int | None,
    csv_path: Path | None,
) -> list[dict[str, object]]:
    build()
    rows: list[dict[str, object]] = []
    threads_label = str(threads) if threads is not None else os.environ.get(
        "OMP_NUM_THREADS", "default"
    )
    print(f"# OMP_NUM_THREADS={threads_label}, {runs} runs each (mean ± stdev, seconds)\n")
    for exe in PROGRAMS:
        mean, std = measure_mean(exe, threads, runs)
        rows.append(
            {
                "schedule": exe,
                "seconds": mean,
                "stddev": std,
                "runs": runs,
                "threads": threads_label,
            }
        )
        print(f"  {exe:7s}: {mean:.6f} ± {std:.6f} s")
    print()

    if csv_path is not None:
        csv_path.parent.mkdir(parents=True, exist_ok=True)
        with csv_path.open("w", newline="") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=["schedule", "seconds", "stddev", "runs", "threads"],
            )
            writer.writeheader()
            writer.writerows(rows)
        print(f"Wrote {csv_path}")

    return rows


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run static/dynamic/guided multiple times and report mean time."
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=RUNS,
        help="各スケジュールの実行回数（デフォルト: 10）",
    )
    parser.add_argument(
        "--threads",
        type=int,
        default=None,
        help="OMP_NUM_THREADS（省略時は環境変数または OpenMP デフォルト）",
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=CSV_DIR / "schedule_timing.csv",
        help="結果 CSV の出力先（--csv '' で無効）",
    )
    args = parser.parse_args()
    runs = max(1, args.runs)
    csv_path = None if args.csv == Path("") else args.csv
    run_bench(runs, args.threads, csv_path)


if __name__ == "__main__":
    main()
