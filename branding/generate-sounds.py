#!/usr/bin/env python3
"""Genera los sonidos de inicio/fin de grabación propios de Impulso Talker.

Salida: src-tauri/resources/<tema>_start.wav y <tema>_stop.wav (estéreo, 48 kHz, 16 bits).
Temas: capsula (el de siempre), micro y burbuja. Solo usa numpy y la biblioteca estándar.
Son síntesis original: sin muestras ni licencias de terceros. Es determinista: correrlo dos
veces da los mismos bytes.

    python3 branding/generate-sounds.py
"""
import wave
from pathlib import Path

import numpy as np

SR = 48000
OUT = Path(__file__).resolve().parent.parent / "src-tauri" / "resources"
# RMS objetivo del tramo audible. El Pop original medía 0,145; estos quedan más bajos a propósito.
LOUD_SOFT = 0.075
LOUD_CAPSULA = 0.095


def glide(f0, f1, dur, speed=30.0):
    """Tono que resbala de f0 a f1 rápido al principio."""
    x = np.arange(int(SR * dur)) / SR
    f = f1 + (f0 - f1) * np.exp(-x * speed)
    return x, 2 * np.pi * np.cumsum(f) / SR


def shape(x, attack=0.006, decay=20.0):
    """Ataque suavizado (sin clic) y caída exponencial."""
    a = np.clip(x / attack, 0, 1)
    return (0.5 - 0.5 * np.cos(np.pi * a)) * np.exp(-decay * x)


def lowpass(s, fc):
    """Filtro de un polo, ida y vuelta: quita lo chillón sin correr la fase."""
    k = np.exp(-2 * np.pi * fc / SR)

    def run(v):
        out = np.zeros_like(v)
        y = 0.0
        for i, val in enumerate(v):
            y = (1 - k) * val + k * y
            out[i] = y
        return out

    return run(run(s)[::-1])[::-1]


def room(s, tail=0.22, wet=0.14, seed=3):
    """Sala mínima: una cola de ruido muy baja que da sensación de espacio."""
    rng = np.random.default_rng(seed)
    n = int(SR * tail)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / SR * 22)
    ir = lowpass(ir, 3200)
    ir /= np.sqrt((ir**2).sum())
    return np.concatenate([s, np.zeros(n - 1)]) + wet * np.convolve(s, ir)


def seq(parts):
    end = max(int(SR * t) + len(s) for t, s in parts)
    buf = np.zeros(end)
    for t, s in parts:
        i = int(SR * t)
        buf[i : i + len(s)] += s
    return buf


def save(name, s, loud):
    """Normaliza por volumen percibido (RMS del tramo audible), no por pico."""
    s = s - s.mean()
    active = np.abs(s) > np.abs(s).max() * 0.03
    s = s * (loud / np.sqrt((s[active] ** 2).mean()))
    k = int(SR * 0.012)
    s[-k:] *= np.linspace(1, 0, k)
    s = np.tanh(s * 1.1) / 1.1  # limitador suave, por si algún pico se pasa
    data = (s * 32767).astype("<i2")
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(np.repeat(data[:, None], 2, axis=1).tobytes())


# --- Cápsula: tono que sube al empezar y baja al terminar, con brillo de vidrio y un
# golpe corto debajo. El golpe cae de 240 a 130 Hz (no más grave) para que se note
# también en parlantes de notebook, que casi no reproducen los graves bajos.
def capsula(up, dose=0.6):
    a, b = (440, 660) if up else (660, 430)
    x, ph = glide(a, b, 0.22, 38)
    body = np.sin(ph) * shape(x, 0.002, 22)
    shimmer = (np.sin(ph * 3) + np.sin(ph * 3.012)) * 0.055 * shape(x, 0.014, 26)
    xt, pt = glide(*((240, 130) if up else (210, 115)), 0.09, 55)
    thump = np.sin(pt) * shape(xt, 0.001, 48) * dose
    rng = np.random.default_rng(9)
    n = int(SR * 0.006)
    tick = lowpass(rng.standard_normal(n), 3500) * np.hanning(n) * 0.5 * dose
    return room(seq([(0, body + shimmer), (0, thump), (0, tick)]), 0.2, 0.1)


# --- Micro: dos toques limpios y muy cortos, en el carácter de un micrófono de teléfono.
def micro(up):
    lo, hi = 880.0, 1174.66
    a, b = (lo, hi) if up else (hi, lo)

    def note(f, d):
        x = np.arange(int(SR * d)) / SR
        return np.sin(2 * np.pi * f * x) * shape(x, 0.005, 26)

    return room(seq([(0, note(a, 0.1)), (0.075, note(b, 0.16))]), 0.14, 0.07)


# --- Burbuja: una burbuja suave; sube al empezar, baja al terminar.
def burbuja(up):
    x, ph = glide(*((430, 690) if up else (690, 410)), 0.16, 34)
    return room(np.sin(ph) * shape(x, 0.008, 24), 0.12, 0.08)


THEMES = {
    "capsula": (capsula, LOUD_CAPSULA),
    "micro": (micro, LOUD_SOFT),
    "burbuja": (burbuja, LOUD_SOFT),
}

if __name__ == "__main__":
    for name, (fn, loud) in THEMES.items():
        save(f"{name}_start", fn(True), loud)
        save(f"{name}_stop", fn(False), loud)
        print("ok", name)
