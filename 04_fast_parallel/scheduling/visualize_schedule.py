import os
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, BoundaryNorm

ROOT = Path(__file__).resolve().parent
CSV_DIR = ROOT / "csv"
IMG_DIR = ROOT / "img"

csv_files = [
    ("static_data.csv", "static"),
    ("dynamic_data.csv", "dynamic"),
    ("guided_data.csv", "guided"),
]

colors = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3']
cmap = ListedColormap(colors)
norm = BoundaryNorm(boundaries=[-0.5, 0.5, 1.5, 2.5, 3.5], ncolors=4)

IMG_DIR.mkdir(parents=True, exist_ok=True)

for filename, sched in csv_files:
    path = CSV_DIR / filename
    if not path.is_file():
        print(f"Warning: {path} not found. Skipping.")
        continue
    df = pd.read_csv(path)
    plt.figure(figsize=(12, 1.8))
    plt.scatter(
        df['iteration'],
        [0] * len(df),
        c=df['thread'],
        s=5,
        cmap=cmap,
        norm=norm,
        alpha=0.7,
    )
    plt.title(f"Schedule: {sched}", fontsize=18)
    plt.xlabel('Iteration', fontsize=16)
    plt.xticks(fontsize=14)
    plt.yticks([])
    plt.ylim(-1, 1)
    plt.tight_layout()
    out = IMG_DIR / f"{sched}_schedule.png"
    plt.savefig(out, dpi=150)
    print(f"Saved {out}")
