from __future__ import annotations

import argparse
import glob
import os
from typing import Optional

import numpy as np

from .model import RusinNet


def find_latest_checkpoint(artifacts_dir: str) -> Optional[str]:
    paths = sorted(glob.glob(os.path.join(artifacts_dir, "rusin_checkpoint_*.npz")))
    return paths[-1] if paths else None


def load_model(checkpoint_path: str, seed: int | None = None) -> RusinNet:
    data = np.load(checkpoint_path, allow_pickle=True)
    input_dim = int(data["input_dim"][0])
    hidden_sizes = data["hidden_sizes"].astype(int).tolist()
    num_classes = int(data["num_classes"][0])
    dropout = float(data["dropout"][0])
    num_layers = int(data["num_layers"][0])

    model = RusinNet(input_dim=input_dim, hidden_sizes=hidden_sizes, num_classes=num_classes, dropout=dropout, seed=seed)
    for i in range(num_layers):
        W = data[f"W_{i}"]
        b = data[f"b_{i}"]
        model.layers[i].weight = W.astype(np.float32)
        model.layers[i].bias = b.astype(np.float32)
    return model


def parse_point(s: str) -> np.ndarray:
    values = [float(x.strip()) for x in s.split(",")]
    return np.array(values, dtype=np.float32)


def main() -> None:
    parser = argparse.ArgumentParser(description="RUSIN inference (NumPy)")
    parser.add_argument("--checkpoint", type=str, default=None, help="Path to checkpoint; defaults to latest in artifacts")
    parser.add_argument("--artifacts_dir", type=str, default="/workspace/rusin/artifacts")
    parser.add_argument("--point", type=str, default=None, help="Comma-separated features for a single point, e.g. '1.0,2.0'")
    parser.add_argument("--csv", type=str, default=None, help="Path to CSV (no header) or .npy with rows as feature vectors")
    args = parser.parse_args()

    checkpoint_path = args.checkpoint or find_latest_checkpoint(args.artifacts_dir)
    if not checkpoint_path or not os.path.exists(checkpoint_path):
        raise SystemExit("Checkpoint not found. Run training first or provide --checkpoint.")

    model = load_model(checkpoint_path)

    if args.csv:
        if args.csv.endswith(".npy"):
            points = np.load(args.csv).astype(np.float32)
        else:
            points = np.loadtxt(args.csv, delimiter=",", dtype=np.float32)
    elif args.point:
        points = parse_point(args.point)[None, :]
    else:
        raise SystemExit("Provide either --point or --csv for inference.")

    logits, _ = model.forward(points, train=False)
    probs = np.exp(logits - logits.max(axis=1, keepdims=True))
    probs = probs / probs.sum(axis=1, keepdims=True)
    preds = probs.argmax(axis=1)
    conf = probs.max(axis=1)

    for i, (p, c) in enumerate(zip(preds, conf)):
        print(f"row={i} pred_class={int(p)} confidence={float(c):.4f}")


if __name__ == "__main__":
    main()