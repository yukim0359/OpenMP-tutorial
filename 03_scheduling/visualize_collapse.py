import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, BoundaryNorm

df = pd.read_csv('collapse_data.csv')

colors = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3']
cmap = ListedColormap(colors)
norm = BoundaryNorm(boundaries=[-0.5, 0.5, 1.5, 2.5, 3.5], ncolors=4)

plt.figure(figsize=(8, 6))
scatter = plt.scatter(
    df['outer_it'],
    df['inner_it'],
    c=df['thread'],
    s=5,
    cmap=cmap,
    norm=norm,
    alpha=0.7
)

# cbar = plt.colorbar(scatter, ticks=range(4))
# cbar.set_label('Thread ID')

plt.xlabel('Outer iteration (i)')
plt.ylabel('Inner iteration (j)')
plt.title('Collapse(2) Thread Assignment (4 Threads)')

plt.grid(True, linestyle='--', linewidth=0.5, alpha=0.5)

plt.tight_layout()
plt.savefig('collapse_2_threads.png', dpi=150)
plt.show()
