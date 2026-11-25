\# OFDM Transmitter — Real Streaming VHDL (N=64, CP=16, QPSK)

Pure simulation-validated. No board, no PS, no Kria.

\## Pipeline

128 bits -\> input\_buffer (RAM) -\> fft64\_engine (radix-2 DIF,

iterative, twiddle ROM) -\> cp\_buffer (RAM, CP prepend) -\>

80 complex samples streamed out.

\## Build and simulate

\`\`\`bash

python python/gen\_twiddles.py        # one-time

vivado -mode batch -source build.tcl
