#!/usr/bin/env python3
"""
fib.c の OMP_NUM_THREADS スケーリングを gcc / Apple clang で計測し，CSV とグラフを出力する。

使い方（05_other_syntax/task/ で）:
  make plot-fib-threads
  .venv/bin/python plot_fib_threads.py --plot-only
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import statistics
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BIN_DIR = ROOT / "bin"
CSV_DIR = ROOT / "csv"
IMG_DIR = ROOT / "img"
SLIDE_IMG = ROOT.parent.parent / "slide" / "img"
COMPILERS = ("gcc", "clang")
TIME_RE = re.compile(r"Elapsed time: ([0-9.]+) seconds")
DEFAULT_THREADS = tuple(range(1, 11))


def run_cmd(cmd: list[str], cwd: Path) -> None:
    subprocess.run(cmd, cwd=cwd, check=True)


def exe_path(compiler: str) -> Path:
    return BIN_DIR / f"fib-{compiler}"


def build(n: int, cutoff: int) -> None:
    run_cmd(
        ["make", "fib-gcc", "fib-clang", f"N={n}", f"CUTOFF={cutoff}", "-j2"],
        ROOT,
    )
    for compiler in COMPILERS:
        if not exe_path(compiler).is_file():
            raise RuntimeError(f"Build failed: {exe_path(compiler)} not found")


def measure_once(compiler: str, threads: int) -> float:
    binary = exe_path(compiler)
    env = os.environ.copy()
    env["OMP_NUM_THREADS"] = str(threads)
    out = subprocess.run(
        [str(binary)],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    for line in out.stdout.splitlines():
        m = TIME_RE.search(line)
        if m:
            return float(m.group(1))
    raise RuntimeError(
        f"Elapsed time not found in {compiler} output (threads={threads}):\n{out.stdout}"
    )


def measure_mean(compiler: str, threads: int, runs: int) -> tuple[float, float]:
    times = [measure_once(compiler, threads) for _ in range(runs)]
    return statistics.mean(times), statistics.stdev(times) if runs > 1 else 0.0


def benchmark(
    threads_list: list[int],
    n: int,
    cutoff: int,
    skip_build: bool,
    runs: int,
    csv_path: Path | None = None,
) -> list[dict[str, object]]:
    if not skip_build:
        build(n, cutoff)

    rows: list[dict[str, object]] = []
    for compiler in COMPILERS:
        if skip_build and not exe_path(compiler).is_file():
            raise RuntimeError(
                f"Missing {exe_path(compiler)} (run without --skip-build)"
            )
        for threads in threads_list:
            mean_t, std_t = measure_mean(compiler, threads, runs)
            row = {
                "n": n,
                "cutoff": cutoff,
                "compiler": compiler,
                "threads": threads,
                "seconds": mean_t,
                "stddev": std_t,
                "runs": runs,
            }
            rows.append(row)
            print(
                f"{compiler:5s}  threads={threads:2d}  "
                f"{mean_t:.6f} ± {std_t:.6f} s  ({runs} runs)"
            )
            if csv_path is not None:
                write_csv(rows, csv_path)
    return rows


def write_csv(rows: list[dict[str, object]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["n", "cutoff", "compiler", "threads", "seconds", "stddev", "runs"],
        )
        w.writeheader()
        w.writerows(rows)
    print(f"Saved {path}")


def read_csv(path: Path) -> list[dict[str, object]]:
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def plot(
    rows: list[dict[str, object]],
    path: Path,
    n: int,
    cutoff: int,
    runs: int,
) -> None:
    import matplotlib.pyplot as plt

    by_compiler: dict[str, list[tuple[int, float, float]]] = {
        c: [] for c in COMPILERS
    }
    for row in rows:
        compiler = str(row["compiler"])
        if compiler in by_compiler:
            std = float(row["stddev"]) if row.get("stddev") not in (None, "") else 0.0
            by_compiler[compiler].append(
                (int(row["threads"]), float(row["seconds"]), std)
            )

    colors = {
        "gcc": "#377eb8",
        "clang": "#e41a1c",
    }
    labels = {
        "gcc": "gcc-15 (libgomp)",
        "clang": "Apple clang (libomp)",
    }

    plt.figure(figsize=(9, 5.5))
    for compiler in COMPILERS:
        pts = sorted(by_compiler[compiler], key=lambda x: x[0])
        if not pts:
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        yerr = [p[2] for p in pts]
        plt.errorbar(
            xs,
            ys,
            yerr=yerr,
            fmt="o-",
            label=labels[compiler],
            color=colors[compiler],
            linewidth=2,
            markersize=6,
            capsize=3,
            elinewidth=1,
        )

    plt.xlabel("OMP_NUM_THREADS", fontsize=14)
    plt.ylabel("Elapsed time [s]", fontsize=14)
    cutoff_note = f", CUTOFF={cutoff}" if cutoff >= 0 else ""
    plt.title(
        f"fib({n}) task parallel: threads vs elapsed time (mean of {runs} runs{cutoff_note})",
        fontsize=14,
    )
    plt.xticks(list(range(1, 11)))
    plt.grid(True, linestyle="--", linewidth=0.5, alpha=0.6)
    plt.legend(fontsize=11)
    plt.tight_layout()
    path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(path, dpi=150)
    print(f"Saved {path}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Benchmark fib.c OMP_NUM_THREADS scaling (gcc vs clang)"
    )
    parser.add_argument(
        "--threads",
        type=int,
        nargs="+",
        default=list(DEFAULT_THREADS),
        help="OMP_NUM_THREADS values (default: 1..10)",
    )
    parser.add_argument("--n", type=int, default=32, help="N passed to make -DN=...")
    parser.add_argument(
        "--cutoff",
        type=int,
        default=-1,
        help="CUTOFF passed to make -DCUTOFF=...",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=5,
        help="各設定の実行回数（平均を CSV / グラフに使う）",
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=CSV_DIR / "fib_threads_timing.csv",
        help="CSV output",
    )
    parser.add_argument(
        "--png",
        type=Path,
        default=IMG_DIR / "fib_threads_timing.png",
        help="Plot output",
    )
    parser.add_argument(
        "--png-slide",
        type=Path,
        default=SLIDE_IMG / "fib_threads_timing.png",
        help="Also save under slide/img/",
    )
    parser.add_argument("--skip-build", action="store_true", help="Skip make")
    parser.add_argument(
        "--csv-only",
        action="store_true",
        help="Only benchmark and write CSV (no plot)",
    )
    parser.add_argument(
        "--plot-only",
        action="store_true",
        help="Plot from existing CSV (no benchmark)",
    )
    args = parser.parse_args()

    threads_list = sorted(set(args.threads))
    runs = max(1, args.runs)

    if args.plot_only:
        if not args.csv.is_file():
            print(f"CSV not found: {args.csv}", file=sys.stderr)
            return 1
        rows = read_csv(args.csv)
        n = int(rows[0]["n"]) if rows else args.n
        cutoff = int(rows[0]["cutoff"]) if rows and "cutoff" in rows[0] else args.cutoff
        if rows and rows[0].get("runs"):
            runs = int(rows[0]["runs"])
    else:
        print(
            f"N={args.n}, CUTOFF={args.cutoff}, runs={runs}, "
            f"threads={threads_list}\n"
        )
        rows = benchmark(
            threads_list,
            args.n,
            args.cutoff,
            args.skip_build,
            runs,
            csv_path=args.csv,
        )
        write_csv(rows, args.csv)
        n = args.n
        cutoff = args.cutoff

    if args.csv_only:
        return 0

    try:
        plot(rows, args.png, n, cutoff, runs)
        if args.png_slide:
            args.png_slide.parent.mkdir(parents=True, exist_ok=True)
            plot(rows, args.png_slide, n, cutoff, runs)
    except ImportError:
        print(
            "matplotlib が必要です。\n"
            "  make plot-venv && .venv/bin/python plot_fib_threads.py --plot-only\n"
            "  または conda install matplotlib\n"
            "CSV は作成済みなら --plot-only で作図のみ実行できます。",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
