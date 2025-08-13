from __future__ import annotations

from typing import Tuple

import numpy as np


def make_moons_local(n_samples: int = 2000, noise: float = 0.2, random_state: int = 42) -> tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(random_state)
    n_samples_out = n_samples // 2
    n_samples_in = n_samples - n_samples_out

    # Outer moon
    outer_theta = rng.random(n_samples_out) * np.pi
    outer_x = np.stack([np.cos(outer_theta), np.sin(outer_theta)], axis=1)

    # Inner moon
    inner_theta = rng.random(n_samples_in) * np.pi
    inner_x = np.stack([1 - np.cos(inner_theta), 1 - np.sin(inner_theta) - 0.5], axis=1)

    X = np.concatenate([outer_x, inner_x], axis=0).astype(np.float32)
    y = np.concatenate([np.zeros(n_samples_out, dtype=np.int64), np.ones(n_samples_in, dtype=np.int64)], axis=0)

    if noise > 0:
        X += rng.normal(scale=noise, size=X.shape).astype(np.float32)

    # Shuffle
    idx = rng.permutation(len(X))
    return X[idx], y[idx]


def train_val_split(
    X: np.ndarray,
    y: np.ndarray,
    test_size: float = 0.2,
    random_state: int = 42,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(random_state)
    n = len(X)
    idx = rng.permutation(n)
    n_test = int(n * test_size)
    test_idx = idx[:n_test]
    train_idx = idx[n_test:]
    return X[train_idx], y[train_idx], X[test_idx], y[test_idx]


def make_synthetic_classification(
    num_samples: int = 2000,
    noise: float = 0.2,
    random_state: int = 42,
    test_size: float = 0.2,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    X, y = make_moons_local(num_samples, noise=noise, random_state=random_state)
    return train_val_split(X, y, test_size=test_size, random_state=random_state)