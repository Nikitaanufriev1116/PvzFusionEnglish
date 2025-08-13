from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple

import numpy as np


@dataclass
class DenseLayer:
    weight: np.ndarray
    bias: np.ndarray


class RusinNet:
    def __init__(
        self,
        input_dim: int = 2,
        hidden_sizes: List[int] | None = None,
        num_classes: int = 2,
        dropout: float = 0.0,
        seed: int | None = 42,
    ) -> None:
        if hidden_sizes is None:
            hidden_sizes = [32, 32]
        if seed is not None:
            rng = np.random.default_rng(seed)
        else:
            rng = np.random.default_rng()

        self.hidden_sizes = hidden_sizes
        self.num_classes = num_classes
        self.dropout_rate = dropout
        self.rng = rng

        layer_dims = [input_dim] + hidden_sizes + [num_classes]
        self.layers: List[DenseLayer] = []
        for in_dim, out_dim in zip(layer_dims[:-1], layer_dims[1:]):
            limit = np.sqrt(6.0 / (in_dim + out_dim))
            W = rng.uniform(-limit, limit, size=(in_dim, out_dim)).astype(np.float32)
            b = np.zeros((out_dim,), dtype=np.float32)
            self.layers.append(DenseLayer(weight=W, bias=b))

    @staticmethod
    def relu(x: np.ndarray) -> np.ndarray:
        return np.maximum(0, x)

    @staticmethod
    def softmax(x: np.ndarray) -> np.ndarray:
        x_stable = x - x.max(axis=1, keepdims=True)
        exp_x = np.exp(x_stable)
        return exp_x / exp_x.sum(axis=1, keepdims=True)

    def forward(self, x: np.ndarray, train: bool = False) -> Tuple[np.ndarray, list[np.ndarray]]:
        activations: list[np.ndarray] = [x]
        h = x
        for idx, layer in enumerate(self.layers):
            h = h @ layer.weight + layer.bias
            is_last = idx == len(self.layers) - 1
            if not is_last:
                h = self.relu(h)
                if train and self.dropout_rate > 0:
                    mask = (self.rng.random(h.shape) > self.dropout_rate).astype(np.float32)
                    h = h * mask / (1.0 - self.dropout_rate)
            activations.append(h)
        return h, activations

    def predict(self, x: np.ndarray) -> np.ndarray:
        logits, _ = self.forward(x, train=False)
        probs = self.softmax(logits)
        return probs.argmax(axis=1)