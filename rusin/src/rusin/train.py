from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from datetime import datetime
from typing import List, Tuple

import numpy as np

from .data import make_synthetic_classification
from .model import RusinNet


@dataclass
class TrainConfig:
    output_dir: str
    epochs: int = 200
    learning_rate: float = 0.1
    batch_size: int = 64
    hidden_sizes: List[int] | None = None
    dropout: float = 0.0
    seed: int = 42


def set_seed(seed: int) -> None:
    np.random.seed(seed)


def one_hot(y: np.ndarray, num_classes: int) -> np.ndarray:
    out = np.zeros((y.shape[0], num_classes), dtype=np.float32)
    out[np.arange(y.shape[0]), y] = 1.0
    return out


def cross_entropy_with_logits(logits: np.ndarray, targets_one_hot: np.ndarray) -> tuple[float, np.ndarray]:
    # logits: (N, C), targets: (N, C)
    logits_stable = logits - logits.max(axis=1, keepdims=True)
    exp = np.exp(logits_stable)
    probs = exp / exp.sum(axis=1, keepdims=True)
    # Add epsilon to avoid log(0)
    eps = 1e-12
    loss = -np.sum(targets_one_hot * np.log(probs + eps)) / logits.shape[0]
    grad = (probs - targets_one_hot) / logits.shape[0]
    return loss, grad


def forward_backward(model: RusinNet, x_batch: np.ndarray, y_batch: np.ndarray) -> tuple[float, list[np.ndarray]]:
    logits, activations = model.forward(x_batch, train=True)
    targets = one_hot(y_batch, num_classes=model.num_classes)
    loss, grad_logits = cross_entropy_with_logits(logits, targets)

    # Backpropagate through layers
    grads_W: list[np.ndarray] = []
    grads_b: list[np.ndarray] = []

    grad = grad_logits  # dL/dz_last
    for layer_index in reversed(range(len(model.layers))):
        a_prev = activations[layer_index]  # input to this layer
        z = activations[layer_index + 1]   # pre-activation (or post-activation for last)
        layer = model.layers[layer_index]

        # Gradients for weights and biases
        dW = a_prev.T @ grad
        db = grad.sum(axis=0)
        grads_W.insert(0, dW)
        grads_b.insert(0, db)

        if layer_index > 0:  # backprop to previous layer if exists
            # Compute gradient w.r.t. previous activation through ReLU
            grad = grad @ layer.weight.T
            grad = grad * (a_prev > 0).astype(np.float32)

    return loss, list(zip(grads_W, grads_b))


def sgd_step(model: RusinNet, grads: list[tuple[np.ndarray, np.ndarray]], lr: float) -> None:
    for layer, (dW, db) in zip(model.layers, grads):
        layer.weight -= lr * dW
        layer.bias -= lr * db


def evaluate(model: RusinNet, X: np.ndarray, y: np.ndarray, batch_size: int = 1024) -> tuple[float, float]:
    num_examples = X.shape[0]
    total_loss = 0.0
    total_correct = 0
    for start in range(0, num_examples, batch_size):
        end = min(start + batch_size, num_examples)
        xb = X[start:end]
        yb = y[start:end]
        logits, _ = model.forward(xb, train=False)
        targets = one_hot(yb, num_classes=model.num_classes)
        loss, _ = cross_entropy_with_logits(logits, targets)
        preds = logits.argmax(axis=1)
        total_loss += loss * (end - start)
        total_correct += (preds == yb).sum()
    avg_loss = total_loss / num_examples
    acc = total_correct / num_examples
    return float(avg_loss), float(acc)


def train(config: TrainConfig) -> dict:
    os.makedirs(config.output_dir, exist_ok=True)
    set_seed(config.seed)

    X_train, y_train, X_val, y_val = make_synthetic_classification()

    model = RusinNet(
        input_dim=X_train.shape[1],
        hidden_sizes=config.hidden_sizes or [32, 32],
        num_classes=int(y_train.max()) + 1,
        dropout=config.dropout,
        seed=config.seed,
    )

    history = {"train_loss": [], "val_loss": [], "val_acc": []}
    num_train = X_train.shape[0]

    for epoch in range(1, config.epochs + 1):
        # Shuffle each epoch
        idx = np.random.permutation(num_train)
        X_train = X_train[idx]
        y_train = y_train[idx]

        running_loss = 0.0
        for start in range(0, num_train, config.batch_size):
            end = min(start + config.batch_size, num_train)
            xb = X_train[start:end]
            yb = y_train[start:end]

            loss, grads = forward_backward(model, xb, yb)
            sgd_step(model, grads, lr=config.learning_rate)
            running_loss += loss * (end - start)

        train_loss = running_loss / num_train
        val_loss, val_acc = evaluate(model, X_val, y_val)
        history["train_loss"].append(train_loss)
        history["val_loss"].append(val_loss)
        history["val_acc"].append(val_acc)
        print(f"Epoch {epoch:03d}/{config.epochs} - train_loss={train_loss:.4f} val_loss={val_loss:.4f} val_acc={val_acc:.4f}")

    # Save checkpoint as npz
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    checkpoint_path = os.path.join(config.output_dir, f"rusin_checkpoint_{timestamp}.npz")
    save_data: dict[str, np.ndarray] = {
        "input_dim": np.array([X_train.shape[1]], dtype=np.int64),
        "hidden_sizes": np.array(model.hidden_sizes, dtype=np.int64),
        "num_classes": np.array([model.num_classes], dtype=np.int64),
        "dropout": np.array([config.dropout], dtype=np.float32),
        "num_layers": np.array([len(model.layers)], dtype=np.int64),
    }
    for i, layer in enumerate(model.layers):
        save_data[f"W_{i}"] = layer.weight.astype(np.float32)
        save_data[f"b_{i}"] = layer.bias.astype(np.float32)
    np.savez(checkpoint_path, **save_data)

    metrics = {
        "final_train_loss": float(history["train_loss"][-1]) if history["train_loss"] else None,
        "final_val_loss": float(history["val_loss"][-1]) if history["val_loss"] else None,
        "final_val_acc": float(history["val_acc"][-1]) if history["val_acc"] else None,
        "epochs": int(config.epochs),
        "batch_size": int(config.batch_size),
        "learning_rate": float(config.learning_rate),
        "hidden_sizes": [int(x) for x in model.hidden_sizes],
        "checkpoint_path": checkpoint_path,
    }

    metrics_path = os.path.join(config.output_dir, f"rusin_metrics_{timestamp}.json")
    with open(metrics_path, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2)

    print(f"Saved checkpoint to: {checkpoint_path}")
    print(f"Saved metrics to: {metrics_path}")

    return metrics


def parse_args() -> TrainConfig:
    parser = argparse.ArgumentParser(description="Train RUSIN (NumPy) on synthetic moons")
    parser.add_argument("--output_dir", type=str, default="/workspace/rusin/artifacts")
    parser.add_argument("--epochs", type=int, default=200)
    parser.add_argument("--learning_rate", type=float, default=0.1)
    parser.add_argument("--batch_size", type=int, default=64)
    parser.add_argument("--hidden_sizes", type=str, default="32,32")
    parser.add_argument("--dropout", type=float, default=0.0)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    hidden_sizes = [int(x) for x in args.hidden_sizes.split(",") if x.strip()]

    return TrainConfig(
        output_dir=args.output_dir,
        epochs=args.epochs,
        learning_rate=args.learning_rate,
        batch_size=args.batch_size,
        hidden_sizes=hidden_sizes,
        dropout=args.dropout,
        seed=args.seed,
    )


if __name__ == "__main__":
    config = parse_args()
    train(config)