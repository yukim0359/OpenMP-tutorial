#!/usr/bin/env python3
"""
SUBSAMPLES と実行時間の関係を計測し，CSV とグラフを出力する。

使い方（03_correct_parallel/data_race/ で）:
  make plot-subsamples          # .venv を自動作成して matplotlib を入れる
  make plot-venv                # venv だけ用意
  .venv/bin/python plot_subsamples.py --plot-only   # 計測済み CSV から作図のみ
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
CSV_DIR = ROOT / "csv"
IMG_DIR = ROOT / "img"
SLIDE_IMG = ROOT.parent.parent / "slide" / "img"
PROGS = ("seq", "lock", "critical", "atomic", "reduction")
TIME_RE = re.compile(r"Elapsed time: ([0-9.]+) seconds")
DEFAULT_SUBSAMPLES = (1, 2, 4, 8, 16, 32, 64, 128)


def run_cmd(cmd: list[str], cwd: Path) -> None:
    subprocess.run(cmd, cwd=cwd, check=True)


def exe_path(prog: str) -> Path:
    return ROOT / "bin" / prog


def build(progs: tuple[str, ...], n: int, seed: int, subsamples: int) -> None:
    make_args = [f"N={n}", f"SEED={seed}", f"SUBSAMPLES={subsamples}", "-j1"]
    for prog in progs:
        exe_path(prog).unlink(missing_ok=True)
        run_cmd(["make", prog, *make_args], ROOT)
        if not exe_path(prog).is_file():
            raise RuntimeError(
                f"Build failed: {exe_path(prog)} not found "
                f"(SUBSAMPLES={subsamples})"
            )


def measure_once(prog: str) -> float:
    binary = exe_path(prog)
    if not binary.is_file():
        raise FileNotFoundError(f"Executable not found: {binary}")
    out = subprocess.run(
        [str(binary)],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    for line in out.stdout.splitlines():
        m = TIME_RE.search(line)
        if m:
            return float(m.group(1))
    raise RuntimeError(f"Elapsed time not found in {prog} output:\n{out.stdout}")


def measure_mean(prog: str, runs: int) -> tuple[float, float]:
    times = [measure_once(prog) for _ in range(runs)]
    return statistics.mean(times), statistics.stdev(times) if runs > 1 else 0.0


def benchmark(
    subsamples_list: list[int],
    n: int,
    seed: int,
    skip_build: bool,
    runs: int,
    csv_path: Path | None = None,
) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for subsamples in subsamples_list:
        if not skip_build:
            build(PROGS, n, seed, subsamples)
        else:
            missing = [p for p in PROGS if not exe_path(p).is_file()]
            if missing:
                raise RuntimeError(
                    f"Missing executables (run without --skip-build): {missing}"
                )
        for prog in PROGS:
            mean_t, std_t = measure_mean(prog, runs)
            row = {
                "subsamples": subsamples,
                "program": prog,
                "seconds": mean_t,
                "stddev": std_t,
                "runs": runs,
            }
            rows.append(row)
            print(
                f"SUBSAMPLES={subsamples:4d}  {prog:10s}  "
                f"{mean_t:.6f} ± {std_t:.6f} s  ({runs} runs)"
            )
            if csv_path is not None:
                write_csv(rows, csv_path)
    return rows


def write_csv(rows: list[dict[str, object]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w = csv.DictWriter(
            f, fieldnames=["subsamples", "program", "seconds", "stddev", "runs"]
        )
        w.writeheader()
        w.writerows(rows)
    print(f"Saved {path}")


def read_csv(path: Path) -> list[dict[str, object]]:
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def plot(rows: list[dict[str, object]], path: Path, n: int, threads: str, runs: int) -> None:
    import matplotlib.pyplot as plt

    by_prog: dict[str, list[tuple[int, float, float]]] = {p: [] for p in PROGS}
    for row in rows:
        prog = str(row["program"])
        if prog in by_prog:
            std = float(row["stddev"]) if row.get("stddev") not in (None, "") else 0.0
            by_prog[prog].append((int(row["subsamples"]), float(row["seconds"]), std))

    colors = {
        "seq": "#4d4d4d",
        "lock": "#e41a1c",
        "critical": "#ff7f00",
        "atomic": "#377eb8",
        "reduction": "#4daf4a",
    }

    plt.figure(figsize=(9, 5.5))
    for prog in PROGS:
        pts = sorted(by_prog[prog], key=lambda x: x[0])
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
            label=prog,
            color=colors[prog],
            linewidth=2,
            markersize=6,
            capsize=3,
            elinewidth=1,
        )

    plt.xscale("log", base=2)
    plt.yscale("log")
    plt.xlabel("SUBSAMPLES (darts per trial)", fontsize=14)
    plt.ylabel("Elapsed time [s]", fontsize=14)
    plt.title(
        f"Monte Carlo π: SUBSAMPLES vs elapsed time (log-log)",
        fontsize=15,
    )
    plt.grid(True, linestyle="--", linewidth=0.5, alpha=0.6)
    plt.legend(fontsize=11)
    plt.tight_layout()
    path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(path, dpi=150)
    print(f"Saved {path}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark SUBSAMPLES vs elapsed time")
    parser.add_argument(
        "--subsamples",
        type=int,
        nargs="+",
        default=list(DEFAULT_SUBSAMPLES),
        help="SUBSAMPLES values to try",
    )
    parser.add_argument("--n", type=int, default=5_000_000, help="N (trials)")
    parser.add_argument("--seed", type=int, default=42, help="SEED")
    parser.add_argument(
        "--runs",
        type=int,
        default=10,
        help="各設定の実行回数（この平均を CSV / グラフに使う）",
    )
    parser.add_argument(
        "--csv", type=Path, default=CSV_DIR / "subsamples_timing.csv", help="CSV output"
    )
    parser.add_argument(
        "--png",
        type=Path,
        default=IMG_DIR / "subsamples_timing.png",
        help="Plot output",
    )
    parser.add_argument(
        "--png-slide",
        type=Path,
        default=SLIDE_IMG / "subsamples_timing.png",
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

    subsamples_list = sorted(set(args.subsamples))
    threads = os.environ.get("OMP_NUM_THREADS", "default")

    runs = max(1, args.runs)

    if args.plot_only:
        if not args.csv.is_file():
            print(f"CSV not found: {args.csv}", file=sys.stderr)
            return 1
        rows = read_csv(args.csv)
        n = args.n
        if rows and rows[0].get("runs"):
            runs = int(rows[0]["runs"])
    else:
        print(
            f"N={args.n}, SEED={args.seed}, runs={runs}, "
            f"OMP_NUM_THREADS={threads}"
        )
        print(f"SUBSAMPLES: {subsamples_list}\n")
        rows = benchmark(
            subsamples_list,
            args.n,
            args.seed,
            args.skip_build,
            runs,
            csv_path=args.csv,
        )
        write_csv(rows, args.csv)
        n = args.n

    if args.csv_only:
        return 0

    try:
        plot(rows, args.png, n, threads, runs)
        if args.png_slide:
            plot(rows, args.png_slide, n, threads, runs)
    except ImportError:
        print(
            "matplotlib が必要です。\n"
            "  make plot-venv && .venv/bin/python plot_subsamples.py --plot-only\n"
            "  または conda install matplotlib\n"
            "CSV は作成済みなら --plot-only で作図のみ実行できます。",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
