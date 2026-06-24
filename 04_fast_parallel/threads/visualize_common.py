"""04_fast_parallel/threads ベンチマーク用: speedup グラフ。"""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt

AXIS_LABEL_FONTSIZE = 16
TICK_FONTSIZE = 14
TITLE_FONTSIZE = 14
LEGEND_FONTSIZE = 12


def add_plot_only_arg(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--plot-only",
        action="store_true",
        help="csv/ の計測結果を読み込み、図だけ再生成する",
    )


def nice_thread_ticks(threads: list[int], *, step: int = 5) -> list[int]:
    """横軸目盛りを step 刻み（5, 10, 15, ..., 100）で返す。"""
    lo, hi = threads[0], threads[-1]
    hi = ((hi + step - 1) // step) * step
    start = step if lo < step else ((lo + step - 1) // step) * step
    return list(range(start, hi + 1, step))


def axis_limits(x_min: int, x_max: int, *, step: int = 5) -> tuple[float, float]:
    """データ端に余白を持たせ、右端が目盛りとぴったり重ならないようにする。"""
    tick_hi = ((x_max + step - 1) // step) * step
    return max(0, x_min - 1), tick_hi + step


def speedup_yerr(
    speedups: list[float], speedup_stds: list[float]
) -> tuple[list[float], list[float]]:
    """speedup は 0 未満になり得ないので、下側エラーバーを非対称にする。"""
    lower = [min(std, speedup) for speedup, std in zip(speedups, speedup_stds)]
    return lower, speedup_stds


def plot_speedup_sweep(
    series: list[tuple[list[int], list[float], list[float], str, str]],
    title: str,
    out_paths: list[Path],
    *,
    show_ideal: bool = True,
    ideal_max: int | None = None,
) -> None:
    x_min = min(threads[0] for threads, *_ in series)
    x_max = max(threads[-1] for threads, *_ in series)
    axis_threads = list(range(x_min, x_max + 1))
    ticks = nice_thread_ticks(axis_threads)
    figsize = (9.5, 4.5) if x_max - x_min > 32 else (8, 4.5)

    fig, ax = plt.subplots(figsize=figsize)
    for threads, speedups, speedup_stds, label, fmt in series:
        markevery = [threads.index(t) for t in ticks if t in threads]
        yerr_lo, yerr_hi = speedup_yerr(speedups, speedup_stds)
        ax.errorbar(
            threads,
            speedups,
            yerr=(yerr_lo, yerr_hi),
            fmt=fmt,
            linewidth=2,
            markersize=5,
            markevery=markevery,
            capsize=3,
            elinewidth=1,
            label=label,
        )
    if show_ideal:
        ideal_hi = ideal_max if ideal_max is not None else x_max
        ideal_threads = list(range(x_min, ideal_hi + 1))
        ax.plot(
            ideal_threads,
            ideal_threads,
            "--",
            color="#888888",
            linewidth=1.5,
            alpha=0.7,
            label="ideal",
        )
    ax.set_xlabel("Number of threads", fontsize=AXIS_LABEL_FONTSIZE)
    ax.set_ylabel("Speedup (vs 1 thread)", fontsize=AXIS_LABEL_FONTSIZE)
    ax.set_title(title, fontsize=TITLE_FONTSIZE)
    ax.set_xticks(ticks)
    ax.tick_params(axis="both", labelsize=TICK_FONTSIZE)
    ax.set_xlim(*axis_limits(x_min, x_max))
    ax.set_ylim(bottom=0)
    ax.grid(True, linestyle="--", alpha=0.5)
    if len(series) > 1 or show_ideal:
        ax.legend(fontsize=LEGEND_FONTSIZE)
    fig.tight_layout()
    for path in out_paths:
        path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(path, dpi=150)
        print(f"wrote {path}")
    plt.close(fig)
