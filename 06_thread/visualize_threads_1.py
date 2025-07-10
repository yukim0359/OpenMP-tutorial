import subprocess
import matplotlib.pyplot as plt

threads = list(range(1, 41))
times = []
for t in threads:
    result = subprocess.run(['./measure_threads_1', str(t)],
                            capture_output=True, text=True, check=True)
    num, tm = result.stdout.split()
    times.append(float(tm))

plt.figure(figsize=(8, 4))
plt.plot(threads, times, marker='o')
plt.xticks(threads)
plt.ylim(bottom=0)
plt.xlabel('Number of Threads')
plt.ylabel('Elapsed Time (s)')
plt.title('Execution Time vs Thread Count')
plt.grid(True, linestyle='--', alpha=0.5)
plt.tight_layout()
plt.savefig('threads_1.png', dpi=150)
plt.show()
