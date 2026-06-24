from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, BoundaryNorm

ROOT = Path(__file__).resolve().parent
CSV_DIR = ROOT / "csv"
IMG_DIR = ROOT / "img"

df = pd.read_csv(CSV_DIR / "collapse_data.csv")

colors = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3']
cmap = ListedColormap(colors)
norm = BoundaryNorm(boundaries=[-0.5, 0.5, 1.5, 2.5, 3.5], ncolors=4)

plt.figure(figsize=(9, 6.5))
plt.scatter(
    df['outer_it'],
    df['inner_it'],
    c=df['thread'],
    s=5,
    cmap=cmap,
    norm=norm,
    alpha=0.7
)

plt.xlabel('Outer iteration (i)', fontsize=16)
plt.ylabel('Inner iteration (j)', fontsize=16)
plt.title('Collapse(2) Thread Assignment (4 Threads)', fontsize=18)
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)

plt.grid(True, linestyle='--', linewidth=0.5, alpha=0.5)

plt.tight_layout()
IMG_DIR.mkdir(parents=True, exist_ok=True)
out = IMG_DIR / "collapse_2_threads.png"
plt.savefig(out, dpi=150)
print(f"Saved {out}")
