import pandas as pd
import matplotlib.pyplot as plt
import os

csv_files = [
    ("static_data.csv", "static"),
    ("dynamic_data.csv", "dynamic"),
    ("guided_data.csv", "guided"),
]

for filename, sched in csv_files:
    if not os.path.exists(filename):
        print(f"Warning: {filename} not found. Skipping.")
        continue
    df = pd.read_csv(filename)
    plt.figure(figsize=(12, 3))
    plt.scatter(df['iteration'], df['thread'], s=2, alpha=0.5)
    plt.grid(True, linestyle='--', linewidth=0.5, alpha=0.5)
    plt.title(f"Schedule: {sched}", fontsize=14)
    plt.xlabel('Iteration', fontsize=12)
    plt.ylabel('Thread ID', fontsize=12)
    plt.yticks(sorted(df['thread'].unique()))
    plt.tight_layout()
    plt.savefig(f"{sched}_schedule.png", dpi=150)
    print(f"Saved {sched}_schedule.png")
plt.show()
