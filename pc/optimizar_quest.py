"""Reduce un .ply de ML Sharp para que corra fluido en el Quest 3.

Uso:  python optimizar_quest.py entrada.ply salida.ply [max_splats]

- Quita splats casi transparentes (no aportan nada visual).
- Si quedan mas de max_splats (700,000 por defecto), conserva los mas visibles
  (opacidad x tamano).
- Escribe un .ply estandar de 3DGS (sin los metadatos extra de Sharp).
"""
import sys
import numpy as np
from plyfile import PlyData, PlyElement

src, dst = sys.argv[1], sys.argv[2]
max_splats = int(sys.argv[3]) if len(sys.argv) > 3 else 700_000

v = PlyData.read(src)["vertex"].data
n0 = len(v)
alpha = 1 / (1 + np.exp(-v["opacity"]))
keep = alpha > 0.04
v = v[keep]
alpha = alpha[keep]

if len(v) > max_splats:
    size = np.exp((v["scale_0"] + v["scale_1"] + v["scale_2"]) / 3)
    score = alpha * np.sqrt(size)
    idx = np.argpartition(-score, max_splats)[:max_splats]
    v = v[np.sort(idx)]

PlyData([PlyElement.describe(v, "vertex")]).write(dst)
print(f"{n0:,} -> {len(v):,} splats  ({dst})")
