import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

N, CP = 64, 16

word = 0x1B4E
bits = []
for _ in range(64):
    bits.append((word >> 15) & 1)
    bits.append((word >> 14) & 1)
    word = ((word << 2) & 0xFFFF) | ((word >> 14) & 0x3)

sym = np.array([(16384 if bits[2*k] == 0 else -16384) +
                1j*(16384 if bits[2*k+1] == 0 else -16384) for k in range(N)])
ref = np.fft.ifft(sym)                      # HW scales 1/2 per stage = 1/N

rx = np.loadtxt("ofdm_ifft.txt");  rx_c = rx[:, 0] + 1j*rx[:, 1]
cp = np.loadtxt("ofdm_out.txt");   cp_c = cp[:, 0] + 1j*cp[:, 1]

evm = np.sqrt(np.mean(np.abs(rx_c-ref)**2) / np.mean(np.abs(ref)**2))
print(f"EVM (RMS) : {evm*100:.3f} %")
print("PASS" if evm < 0.05 else "FAIL (EVM > 5%)")
assert cp.shape[0] == N + CP
assert np.allclose(cp_c[:CP], cp_c[N:N+CP]), "CP mismatch"
assert np.allclose(cp_c[CP:], rx_c), "CP output != IFFT output"
print("CP check  : PASS")

fig, ax = plt.subplots(2, 3, figsize=(15, 8))
ax[0,0].scatter(sym.real, sym.imag); ax[0,0].set_title("Input QPSK constellation")
ax[0,1].stem(ref.real, linefmt="C0-", markerfmt="C0o", label="ref")
ax[0,1].plot(rx_c.real, "rx", label="HW"); ax[0,1].set_title("IFFT output (I)"); ax[0,1].legend()
ax[0,2].stem(ref.imag, linefmt="C0-", markerfmt="C0o", label="ref")
ax[0,2].plot(rx_c.imag, "rx", label="HW"); ax[0,2].set_title("IFFT output (Q)"); ax[0,2].legend()
ax[1,0].plot(np.abs(rx_c-ref), "k.-"); ax[1,0].set_title(f"Error |HW-ref|  (EVM {evm*100:.3f}%)")
ax[1,1].plot(cp_c.real, label="I"); ax[1,1].plot(cp_c.imag, label="Q")
ax[1,1].axvspan(0, CP-1, color="orange", alpha=.3, label="CP")
ax[1,1].axvspan(N, N+CP-1, color="green", alpha=.3, label="CP source")
ax[1,1].set_title("Output with cyclic prefix (80 samples)"); ax[1,1].legend()
ax[1,2].plot(np.abs(np.fft.fft(cp_c[CP:]))/N, "m"); ax[1,2].set_title("Spectrum of symbol (|FFT|)")
for a in ax.flat: a.grid(alpha=.3)
plt.tight_layout()
plt.savefig("ofdm_check.png", dpi=120)
print("Saved ofdm_check.png")