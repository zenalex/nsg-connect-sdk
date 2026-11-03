# -*- coding: utf-8 -*-
"""
TASK-ringback: генератор синтетических ringback-ассетов для исходящего
звонка (см. `call_ringback_player.dart`). Чистые синусоидальные тоны,
8 кГц / mono / 16-bit PCM WAV — телефонный стандарт, крошечные файлы,
проигрываются just_audio на всех целевых платформах.

Две РАЗЛИЧИМЫЕ стадии (постановщик просил «немного разные тоны»):
  * connecting — стадия 1 «дозвон до сервера»: выше и быстрее,
    двойной блип, цикл 1.0с (busy «идёт соединение»).
  * ringing    — стадия 2 «звонит на устройстве»: классический
    низкий гудок 425 Гц, 1с тон / 3с тишина, цикл 4.0с (узнаваемый КПВ).

Тишина «вшита» в конец каждого цикла → бесшовный LoopMode.one (стык
петли попадает в тишину, щелчка нет). Запуск:
    python generate_ringback.py
"""
import math
import struct
import wave

SAMPLE_RATE = 8000  # Гц — с запасом для тонов 400–520 Гц (Найквист 4 кГц)


def _tone(freq, seconds, amp, fade_ms=12.0):
    """Синус `freq` длительностью `seconds` с raised-cosine fade in/out
    (fade убирает щелчки на границах тон↔тишина)."""
    n = int(SAMPLE_RATE * seconds)
    fade = max(1, int(SAMPLE_RATE * fade_ms / 1000.0))
    out = []
    for i in range(n):
        s = math.sin(2.0 * math.pi * freq * (i / SAMPLE_RATE))
        # огибающая: линейный рост/спад на краях
        if i < fade:
            s *= i / fade
        elif i > n - fade:
            s *= (n - i) / fade
        out.append(amp * s)
    return out


def _silence(seconds):
    return [0.0] * int(SAMPLE_RATE * seconds)


def _write(path, samples):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)  # 16-bit
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(bytes(frames))
    print("wrote", path, len(samples), "samples")


# ── стадия 1: connecting (двойной блип 520 Гц, цикл 1.0с) ──────────────
connecting = []
connecting += _tone(520.0, 0.10, 0.22)
connecting += _silence(0.08)
connecting += _tone(520.0, 0.10, 0.22)
connecting += _silence(0.72)  # хвост тишины → цикл ровно 1.0с
_write("ringback_connecting.wav", connecting)

# ── стадия 2: ringing (гудок 425 Гц, 1с/3с, цикл 4.0с) ─────────────────
ringing = []
ringing += _tone(425.0, 1.0, 0.28, fade_ms=15.0)
ringing += _silence(3.0)
_write("ringback_ringing.wav", ringing)
