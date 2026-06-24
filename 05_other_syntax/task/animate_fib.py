#!/usr/bin/env python3
"""fib_tree.dot からタスク実行の GIF アニメーションを生成する。
"""

from __future__ import annotations

import io
from pathlib import Path

import pydot
from PIL import Image

ROOT = Path(__file__).resolve().parent
IMG_DIR = ROOT / "img"
DOT_PATH = ROOT / "fib_tree.dot"
GIF_PATH = IMG_DIR / "fibonacci_tasks_animation.gif"
SLIDE_GIF = ROOT.parent.parent / "slide" / "img" / "fibonacci_tasks_animation.gif"

FRAME_DURATION_MS = 500
GRAPH_ATTRS = {
    "dpi": "144",
    "bgcolor": "white",
    "fontname": "Helvetica",
    "fontsize": "16",
    "pad": "0.4",
    "nodesep": "0.45",
    "ranksep": "0.55",
}
NODE_FONT = {
    "fontname": "Helvetica",
    "fontsize": "14",
}


def load_graph(path: Path) -> pydot.Dot:
    graphs = pydot.graph_from_dot_file(str(path))
    if not graphs:
        raise RuntimeError(f"could not parse {path}")
    return graphs[0]


def iter_task_nodes(graph: pydot.Dot):
    for node in graph.get_nodes():
        name = node.get_name().strip('"')
        if name.isdigit():
            yield name, node


def load_task_seqs(graph: pydot.Dot) -> dict[str, tuple[int, int, dict[str, str]]]:
    tasks: dict[str, tuple[int, int, dict[str, str]]] = {}
    for name, node in iter_task_nodes(graph):
        attrs = node.get_attributes()
        if "start_seq" not in attrs or "end_seq" not in attrs:
            raise RuntimeError(f"node {name} missing start_seq/end_seq")
        start_seq = int(attrs["start_seq"])
        end_seq = int(attrs["end_seq"])
        if start_seq >= end_seq:
            raise RuntimeError(
                f"node {name}: start_seq={start_seq} >= end_seq={end_seq}"
            )
        tasks[name] = (start_seq, end_seq, dict(attrs))
    if not tasks:
        raise RuntimeError("no task nodes in fib_tree.dot")
    return tasks


def phase_at_frame(start_seq: int, end_seq: int, frame: int) -> str:
    if frame < start_seq:
        return "pending"
    if frame < end_seq:
        return "running"
    return "done"


def render_frame(
    graph: pydot.Dot,
    tasks: dict[str, tuple[int, int, dict[str, str]]],
    frame: int,
) -> Image.Image:
    dot = pydot.Dot(graph_type="digraph")
    for key, val in GRAPH_ATTRS.items():
        dot.set(key, val)

    for name, (start_seq, end_seq, attrs) in tasks.items():
        phase = phase_at_frame(start_seq, end_seq, frame)
        node_attrs = {**attrs, **NODE_FONT}
        if phase == "pending":
            node_attrs = {**node_attrs, "fillcolor": "white"}
        elif phase == "running":
            pass
        else:
            node_attrs = {**node_attrs, "fillcolor": "gray"}
        dot.add_node(pydot.Node(name, **node_attrs))

    for edge in graph.get_edges():
        dot.add_edge(
            pydot.Edge(
                edge.get_source(),
                edge.get_destination(),
                **edge.get_attributes(),
            )
        )

    png = dot.create_png()
    return Image.open(io.BytesIO(png)).convert("RGB")


def build_frames(graph: pydot.Dot) -> list[Image.Image]:
    tasks = load_task_seqs(graph)
    max_seq = max(end_seq for _start, end_seq, _ in tasks.values())
    return [render_frame(graph, tasks, frame) for frame in range(max_seq + 1)]


def save_gif(frames: list[Image.Image], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    durations = [FRAME_DURATION_MS] * len(frames)
    paletted = [
        frame.convert(
            "P",
            palette=Image.Palette.ADAPTIVE,
            colors=256,
            dither=Image.Dither.NONE,
        )
        for frame in frames
    ]
    paletted[0].save(
        path,
        save_all=True,
        append_images=paletted[1:],
        duration=durations,
        loop=0,
        optimize=False,
    )


def main() -> None:
    if not DOT_PATH.is_file():
        raise SystemExit(f"{DOT_PATH} not found. Run: make fib-tree-run")

    graph = load_graph(DOT_PATH)
    frames = build_frames(graph)
    save_gif(frames, GIF_PATH)
    print(
        f"wrote {GIF_PATH} ({len(frames)} frames, "
        f"{FRAME_DURATION_MS}ms each)"
    )

    SLIDE_GIF.parent.mkdir(parents=True, exist_ok=True)
    SLIDE_GIF.write_bytes(GIF_PATH.read_bytes())
    print(f"wrote {SLIDE_GIF}")


if __name__ == "__main__":
    main()
