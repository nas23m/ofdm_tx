# FPGA-Based OFDM Transmitter

A VHDL implementation of a **64-point OFDM transmitter** featuring QPSK symbol mapping, a radix-2 Decimation-in-Frequency (DIF) IFFT, fixed-point complex arithmetic, and cyclic-prefix insertion.

The design implements a streaming transmit chain and is verified through **AMD Vivado simulation**, with a Python script used to compare the IFFT output against a NumPy reference and check cyclic-prefix correctness.

> **Project status:** Simulation-validated. No physical FPGA deployment or hardware measurements are claimed.

## 1. Architecture

The transmitter processes a 128-bit input frame and converts it into an OFDM time-domain symbol.

```text
       Serial Input (128 bits)
                 |
                 v
          Input Buffer
        QPSK Symbol Mapping
                 |
                 v
           64 Complex
          QPSK Symbols
                 |
                 v
          64-Point IFFT
        Radix-2 DIF Engine
                 |
                 v
          64 Time-Domain
             Samples
                 |
                 v
          Cyclic Prefix
             Insertion
                 |
                 v
         80 Output Samples
          (64 + 16 CP)
```

### Main parameters

| Parameter | Value |
|---|---:|
| FFT/IFFT size | 64 points |
| Modulation | QPSK |
| Input frame | 128 bits |
| Complex input symbols | 64 |
| IFFT architecture | Radix-2 DIF |
| IFFT stages | 6 |
| Data width | 16 bits |
| Twiddle-factor format | Q1.15 |
| Cyclic prefix length | 16 samples |
| Output symbol length | 80 samples |

## 2. Main Design Components

### QPSK Mapping and Input Buffer

The input buffer collects 128 serial bits and groups them into 64 two-bit symbols.

Each bit pair is mapped to a complex QPSK value using signed 16-bit fixed-point components:

- A bit value of `0` maps to `+16384`.
- A bit value of `1` maps to `-16384`.

The resulting complex symbols are stored in separate I and Q arrays before being transferred to the IFFT engine.

### 64-Point Radix-2 DIF IFFT

The `fft64_engine` performs an iterative, six-stage radix-2 Decimation-in-Frequency transform.

The butterfly operations calculate the sum and difference of complex input samples. The difference branch is multiplied by the corresponding twiddle factor.

The implementation uses:

- An iterative butterfly processing architecture.
- Internal storage for real and imaginary components.
- A twiddle-factor ROM.
- Fixed-point complex multiplication.
- One-half scaling at each butterfly stage.
- Bit-reversed-to-natural-order output reordering.

The six scaling stages implement the overall \(1/64\) normalization used by the inverse transform.

### Twiddle-Factor ROM

The twiddle coefficients are generated using Python and stored in separate real and imaginary memory initialization files.

The coefficients use a Q1.15 representation and are loaded by the VHDL ROM during simulation.

Run the generator before launching the Vivado simulation:

```bash
python python/gen_twiddles.py
```

### Cyclic Prefix Insertion

The `cp_buffer` stores the 64 IFFT output samples and constructs the OFDM symbol by copying the last 16 samples to the beginning.

The output sequence is therefore:

```text
[Last 16 IFFT samples] + [All 64 IFFT samples]
```

This produces an 80-sample complex output stream.

The module provides an output-valid signal and a completion signal to indicate the end of the transmitted symbol.

## 3. Fixed-Point Processing

The datapath uses signed 16-bit values for the real and imaginary components.

The twiddle factors are represented in Q1.15 format. Complex multiplication is performed using the real and imaginary products:

\[
(a+jb)(c+jd)
=
(ac-bd)+j(ad+bc)
\]

The implementation applies the inverse-transform twiddle convention and shifts the multiplication results to return them to the 16-bit datapath.

Each butterfly stage also applies a right shift by one bit to implement the IFFT scaling.

## 4. Simulation and Verification

The design includes a VHDL testbench and a Python verification script.

The testbench applies a fixed 128-bit input pattern:

```text
1B4E1B4E1B4E1B4E1B4E1B4E1B4E1B4E
```

It records two output files:

| File | Contents |
|---|---|
| `ofdm_ifft.txt` | 64 complex IFFT output samples |
| `ofdm_out.txt` | 80 complex samples after cyclic-prefix insertion |

The Python verification script uses NumPy to calculate a reference IFFT and compares it with the simulated hardware output.

### Verification checks

1. **IFFT comparison:** compares the simulated IFFT output against `numpy.fft.ifft`.
2. **Error Vector Magnitude (EVM):** calculates the normalized RMS error between the reference and simulated outputs.
3. **Cyclic-prefix verification:** checks that the first 16 output samples match the last 16 IFFT samples.
4. **Payload verification:** checks that the remaining 64 output samples match the original IFFT output.

### Simulation results

The archived simulation outputs were evaluated using the supplied Python verification method.

| Verification | Result |
|---|---:|
| IFFT output samples | 64 |
| Output samples with CP | 80 |
| RMS EVM | 0.444% |
| EVM threshold | 5% |
| Cyclic-prefix check | PASS |
| IFFT payload check | PASS |

The measured EVM is calculated from the archived simulation output and the NumPy reference. It is a simulation comparison, not a physical RF measurement.

The verification script also generates `ofdm_check.png`, containing the input constellation, IFFT comparison, error plot, and output waveform.

## 5. Repository Structure

```text
FPGA-OFDM-Transmitter/
│
├── rtl/
│   ├── ofdm_pkg.vhd
│   ├── qpsk_mapper.vhd
│   ├── input_buffer.vhd
│   ├── twiddle_rom.vhd
│   ├── fft64_engine.vhd
│   ├── cp_buffer.vhd
│   └── ofdm_tx_top.vhd
│
├── sim/
│   └── tb_ofdm_tx.vhd
│
├── python/
│   ├── gen_twiddles.py
│   └── check_output.py
│
├── mem/
│   ├── twiddle_re.mem
│   └── twiddle_im.mem
│
├── build.tcl
└── README.md
```

## 6. Running the Project

### Requirements

- AMD Vivado with VHDL-2008 support
- Python 3
- NumPy
- Matplotlib

Install the Python dependencies:

```bash
pip install numpy matplotlib
```

### Generate twiddle coefficients

From the repository root:

```bash
python python/gen_twiddles.py
```

### Create the Vivado project

Update the project and repository paths in `build.tcl` to match your local environment, then execute:

```bash
vivado -mode batch -source build.tcl
```

Open the generated Vivado project and launch the behavioral simulation using `tb_ofdm_tx` as the simulation top.

### Run Python verification

After simulation generates `ofdm_ifft.txt` and `ofdm_out.txt` in the working directory:

```bash
python python/check_output.py
```

The script prints the EVM and verification results and generates the visualization `ofdm_check.png`.

## 7. Scope and Limitations

This project focuses on the digital OFDM transmit chain and its functional verification.

- The archived results come from behavioral simulation.
- No physical FPGA deployment or RF transmission is included.
- No resource-utilization or post-implementation timing results are reported.
- The verification uses a fixed input pattern rather than an exhaustive set of QPSK input frames.
- The current build script requires path adjustments for other environments.

## 8. Technologies

- VHDL-2008
- AMD Vivado
- FPGA Digital Signal Processing
- OFDM
- QPSK Modulation
- Radix-2 DIF IFFT
- Fixed-Point Arithmetic
- Python
- NumPy
- Matplotlib

---

**Project focus:** FPGA-based digital signal processing, fixed-point datapath design, and hardware implementation of an OFDM transmission chain.
