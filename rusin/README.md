# RUSIN

Минимальный проект нейросети (NumPy) с обучением на синтетических данных (moons) и простым инференсом.

## Установка

```bash
python3 -m pip install --user -r /workspace/rusin/requirements.txt
```

Если система запрещает установку системно, можно обойтись без неё (в проекте используется только NumPy, который уже часто установлен). Если нужно, добавьте флаг `--break-system-packages`.

## Обучение

```bash
chmod +x /workspace/rusin/scripts/train_rusin.sh
/workspace/rusin/scripts/train_rusin.sh --epochs 200 --learning_rate 0.1 --hidden_sizes 64,64 --batch_size 64
```
Артефакты (чекпойнт `.npz` и метрики) сохраняются в `/workspace/rusin/artifacts`.

## Инференс

- Для одиночной точки:
```bash
chmod +x /workspace/rusin/scripts/predict_rusin.sh
/workspace/rusin/scripts/predict_rusin.sh --point "1.0,2.0"
```
- Для набора точек из CSV (без заголовка) или `.npy`:
```bash
/workspace/rusin/scripts/predict_rusin.sh --csv /path/to/data.csv
```

Можно передать `--checkpoint` для явного пути к сохранённой модели.