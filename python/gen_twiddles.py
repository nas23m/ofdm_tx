import numpy as np
from pathlib import Path

N = 64
SCALE = 32767          # Q1.15
lines_re, lines_im = [], []

for k in range(N // 2):          # DIF radix-2 needs twiddles W_N^j, j=0..N/2-1
    w = np.exp(-2j * np.pi * k / N)   # FFT twiddle; IFFT uses conj
    re = int(round(np.real(w) * SCALE))
    im = int(round(np.imag(w) * SCALE))
    lines_re.append(f"{re & 0xFFFF:04x}")
    lines_im.append(f"{im & 0xFFFF:04x}")

output_dir = Path(__file__).resolve().parent.parent / "mem"
for filename, lines in (
    ("twiddle_re.mem", lines_re),
    ("twiddle_im.mem", lines_im),
):
    output_path = output_dir / filename
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="ascii")
print("Wrote twiddle_re.mem, twiddle_im.mem (32 entries each, Q1.15)")