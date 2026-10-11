# Dentro de la foto

Convierte una foto en una escena 3D (Gaussian splat, con [Apple ML Sharp](https://github.com/apple/ml-sharp)) y camina dentro de ella con el Quest 3 en passthrough.

- **Visor (ábrelo en el navegador del Quest):** https://valibii.github.io/dentro-de-la-foto/
- **Convertir una foto desde el cel (Colab, GPU gratis):** [![Abrir en Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/Valibii/dentro-de-la-foto/blob/main/foto_a_3d.ipynb)
- **Convertir en una PC con NVIDIA:** carpeta `pc/` — arrastra fotos encima de `foto-a-3d.bat`.

## Flujo sin PC
1. Cel: sube tus fotos a Google Drive, carpeta **Dentro de la foto/fotos** (el Colab la crea la primera vez).
   Abre el Colab → *Entorno de ejecución → Cambiar tipo → T4 GPU* → *Ejecutar todo*. Los `-quest.ply` quedan en **Dentro de la foto**.
2. Quest: drive.google.com → descarga `tu-foto-quest.ply`.
3. Quest: abre el visor → **Cargar mi .ply** → **Entrar con passthrough**.

## Controles en el Quest
| Acción | Qué hace |
|---|---|
| Pellizco / gatillo | Coloca la escena frente a ti (con animación) |
| Stick der. ↑↓ / ←→ | Acercar-alejar / girar |
| Stick izq. ↑↓ / ←→ | Altura / escala |
| Botón A o X | Repetir la animación de aparición |

`?src=archivo.ply` abre directo otra escena subida a este repo.
