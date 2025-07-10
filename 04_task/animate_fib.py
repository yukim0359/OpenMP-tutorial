import pydot
import imageio
import re
import os

DOT_PATH = 'fib_tree.dot'

colors = [
    "lightblue", "lightgreen", "lightpink", "lightgoldenrod",
    "lightcyan", "lightcoral", "lightseagreen", "lightyellow"
]

def main():
    graphs = pydot.graph_from_dot_file(DOT_PATH)
    graph  = graphs[0]

    start_orders = {}
    end_orders = {}
    tid_map      = {}
    for node in graph.get_nodes():
        label = node.get_attributes().get('label', '')
        m1 = re.search(r'\[seq=(\d+)→(\d+)\]', label)
        m2 = re.search(r'tid=(\d+)', label)
        if m1 and m2:
            start_orders[node.get_name()] = int(m1.group(1))
            end_orders[node.get_name()] = int(m1.group(2))
            tid_map[node.get_name()] = int(m2.group(1))

    max_step = max(end_orders.values())

    tid_color = {}
    for tid in sorted(set(tid_map.values())):
        idx = len(tid_color) % len(colors)
        tid_color[tid] = colors[idx]

    os.makedirs('animation', exist_ok=True)
    frames = []

    for step in range(1, max_step+1):
        g = pydot.Dot(graph_type='digraph')
        for node in graph.get_nodes():
            name = node.get_name()
            new_node = pydot.Node(name, **node.get_attributes())
            if name in start_orders:
                if start_orders[name] <= step:  # 開始時以降
                    if step < end_orders[name]:
                        fill = tid_color[tid_map[name]]  # 実行中は色付き
                    else:
                        fill = "gray"  # 終了後は灰色
                else:
                    fill = "white"  # 開始前は白色
            else:
                fill = "white"
            new_node.set_style("filled,rounded")
            new_node.set_fillcolor(fill)
            g.add_node(new_node)
        for edge in graph.get_edges():
            g.add_edge(edge)

        frame_path = f'animation/frame_{step:03d}.png'
        g.write_png(frame_path)
        frames.append(imageio.imread(frame_path))

    gif_path = 'fibonacci_tasks_animation.gif'
    imageio.mimsave(gif_path, frames, duration=2.0)
    print(f'made gif animation: {gif_path}')

if __name__ == "__main__":
    main()
