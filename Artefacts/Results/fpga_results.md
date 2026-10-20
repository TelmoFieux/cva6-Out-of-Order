# Synthesis and FPGA results

Area, timing and on-board performance of the in-order and out-of-order CVA6 variants.
Simulation counters are in [`simulation_results.md`](simulation_results.md).

## Setup

* **Board**: Digilent Zybo Z7-20 (Xilinx Zynq-7020, `xc7z020clg400-1`), Vivado 2024.1.
* **Memory**: programs run from an on-chip BRAM (192 KiB at `0x80000000`); data cache: hpdcache.
* **Area and timing**: core synthesised and routed out of context (OoC). *Core LUTs* = Slice
  LUTs of the core (logic + LUT memory). *T*<sub>min</sub> = constrained period − WNS;
  *F*<sub>max</sub> = 1 / *T*<sub>min</sub>.
* **Performance**: cycles read from `mcycle` on the board, two consecutive runs per benchmark.
  IPC = instructions / mean cycles, with the instruction counts below (read from `minstret`).
* **Benchmarks** (GCC 15.2.0, `-march=rv32im_zicsr -O3`):

| Benchmark | Description | Instructions |
|---|---|---:|
| FFT | kiss_fft, result checked | 110 651 |
| MNIST | one-image inference (8-bit weights), result checked | 1 119 565 |
| CoreMark | 3 iterations, timed region, CRCs validated | 824 071 |

Naming: in-order versions are labelled by their scoreboard size (SB), out-of-order versions
by their reorder-buffer size (ROB, `scoreboard` in the sources).

## Summary

| Version | Core LUTs | Constraint (ns) | WNS (ns) | *T*<sub>min</sub> (ns) | *F*<sub>max</sub> (MHz) | FFT IPC | MNIST IPC | CoreMark IPC | CoreMark/MHz |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| In-order single-issue SB16 (original CVA6) | 14 381 | 20 | -0.111 | 20.11 | 49.7 | 0.770 | 0.654 | 0.699 | 2.55 |
| In-order single-issue SB8 | 10 933 | 15 | -4.625 | 19.62 | 51.0 | 0.770 | 0.654 | 0.699 | 2.55 |
| In-order dual-issue SB16 | 23 269 | 22 | -1.529 | 23.53 | 42.5 | 0.948 | 0.874 | 0.866 | 3.15 |
| In-order dual-issue SB8 | 18 410 | 18 | -0.812 | 18.81 | 53.2 | 0.949 | 0.873 | 0.865 | 3.15 |
| OoO single-issue ROB16 | 21 838 | 21 | -1.404 | 22.40 | 44.6 | 0.837 | 0.891 | 0.779 | 2.84 |
| OoO single-issue ROB8 | 16 344 | 18 | -1.596 | 19.60 | 51.0 | 0.730 | 0.735 | 0.733 | 2.67 |
| OoO dual-issue ROB16 (reference OoO design) | 33 794 | 22 | -1.710 | 23.71 | 42.2 | 1.101 | 1.415 | 1.064 | 3.87 |
| OoO dual-issue ROB8 | 25 261 | 20 | -3.884 | 23.88 | 41.9 | 0.850 | 0.859 | 0.897 | 3.26 |
| OoO dual-issue ROB8, 44 physical registers | 25 083 | 22 | -1.184 | 23.18 | 43.1 | 0.881 | 0.918 | 0.910 | 3.31 |

CoreMark/MHz is derived from the cycle count (3 iterations / cycles); the run is shorter than
the 10 s required by the EEMBC reporting rules, so it is given for comparison only.
The single-issue in-order SB8 and SB16 versions produced identical cycle counts (both
configurations were checked).

## Detailed results per version

### In-order single-issue SB16 (original CVA6)

* **Parameters**: scoreboard 16
* **Core LUTs**: 14 381
* **Timing**: constraint 20 ns, WNS -0.111 ns → *T*<sub>min</sub> 20.11 ns, *F*<sub>max</sub> 49.7 MHz
* **Critical path**: `csr_regfile_i/pmpaddr_q_reg[3][4]` → `ex_stage_i/lsu_i/lsu_bypass_i/mem_q_reg[0][operation][2]`, data path 19.946 ns (25 % logic, 75 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 145 873 | 141 714 | 143 794 | 0.770 |
| MNIST | 1 710 682 | 1 712 009 | 1 711 346 | 0.654 |
| CoreMark | 1 179 058 | 1 178 094 | 1 178 576 | 0.699 |

### In-order single-issue SB8

* **Parameters**: scoreboard 8
* **Core LUTs**: 10 933
* **Timing**: constraint 15 ns, WNS -4.625 ns → *T*<sub>min</sub> 19.62 ns, *F*<sub>max</sub> 51.0 MHz
* **Critical path**: `issue_stage_i/i_scoreboard/commit_pointer_q_reg[0][1]_rep` → `issue_stage_i/i_scoreboard/mem_q_reg[5][sbe][result][18] (CE)`, data path 19.336 ns (17 % logic, 83 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 145 873 | 141 714 | 143 794 | 0.770 |
| MNIST | 1 710 682 | 1 712 009 | 1 711 346 | 0.654 |
| CoreMark | 1 179 058 | 1 178 094 | 1 178 576 | 0.699 |

### In-order dual-issue SB16

* **Parameters**: scoreboard 16
* **Core LUTs**: 23 269
* **Timing**: constraint 22 ns, WNS -1.529 ns → *T*<sub>min</sub> 23.53 ns, *F*<sub>max</sub> 42.5 MHz
* **Critical path**: `csr_regfile_i/pmpaddr_q_reg[2][4]` → `issue_stage_i/i_scoreboard/mem_q_reg[8][sbe][rd][2]`, data path 23.476 ns (23 % logic, 77 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 118 889 | 114 650 | 116 770 | 0.948 |
| MNIST | 1 280 114 | 1 281 671 | 1 280 892 | 0.874 |
| CoreMark | 952 299 | 951 078 | 951 688 | 0.866 |

### In-order dual-issue SB8

* **Parameters**: scoreboard 8
* **Core LUTs**: 18 410
* **Timing**: constraint 18 ns, WNS -0.812 ns → *T*<sub>min</sub> 18.81 ns, *F*<sub>max</sub> 53.2 MHz
* **Critical path**: `csr_regfile_i/pmpaddr_q_reg[6][0]` → `i_dcache/.../gen_dir_sram[1].dir_sram (RAMB18 address)`, data path 18.162 ns (24 % logic, 76 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 118 674 | 114 431 | 116 552 | 0.949 |
| MNIST | 1 282 048 | 1 283 608 | 1 282 828 | 0.873 |
| CoreMark | 952 865 | 952 003 | 952 434 | 0.865 |

### OoO single-issue ROB16

* **Parameters**: 48 phys. reg., RS 8, LSQ 4, lsq_bypass 4, rollback 2
* **Core LUTs**: 21 838
* **Timing**: constraint 21 ns, WNS -1.404 ns → *T*<sub>min</sub> 22.40 ns, *F*<sub>max</sub> 44.6 MHz
* **Critical path**: `ex_stage_i/lsu_i/load_store_queue_i/previous_translation_pointer_q_reg[1]` → `i_dcache/.../data_sram (RAMB36 address)`, data path 21.754 ns (25 % logic, 75 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 134 454 | 130 081 | 132 268 | 0.837 |
| MNIST | 1 255 334 | 1 257 587 | 1 256 460 | 0.891 |
| CoreMark | 1 058 544 | 1 057 841 | 1 058 192 | 0.779 |

### OoO single-issue ROB8

* **Parameters**: 40 phys. reg., RS 4, LSQ 2, lsq_bypass 2, rollback 2
* **Core LUTs**: 16 344
* **Timing**: constraint 18 ns, WNS -1.596 ns → *T*<sub>min</sub> 19.60 ns, *F*<sub>max</sub> 51.0 MHz
* **Critical path**: `csr_regfile_i/pmpaddr_q_reg[3][1]` → `i_dcache/.../data_sram (RAMB36 address)`, data path 18.946 ns (28 % logic, 72 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 153 743 | 149 545 | 151 644 | 0.730 |
| MNIST | 1 523 091 | 1 525 026 | 1 524 058 | 0.735 |
| CoreMark | 1 124 909 | 1 124 136 | 1 124 522 | 0.733 |

### OoO dual-issue ROB16 (reference OoO design)

* **Parameters**: 48 phys. reg., RS 4, LSQ 4, lsq_bypass 4, rollback 2
* **Core LUTs**: 33 794
* **Timing**: constraint 22 ns, WNS -1.710 ns → *T*<sub>min</sub> 23.71 ns, *F*<sub>max</sub> 42.2 MHz
* **Critical path**: `issue_stage_i/gen_rs_blocks[0]...i_reservation_station/rs_q_reg[rs_table][0][global_rs_id][5]` → `issue_stage_i/i_issue_read_operands/fu_data_q_reg[1][operand_a][15]`, data path 23.655 ns (24 % logic, 76 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 102 260 | 98 665 | 100 462 | 1.101 |
| MNIST | 789 820 | 792 622 | 791 221 | 1.415 |
| CoreMark | 774 474 | 774 115 | 774 294 | 1.064 |

### OoO dual-issue ROB8

* **Parameters**: 40 phys. reg., RS 3, LSQ 2, lsq_bypass 2, rollback 2
* **Core LUTs**: 25 261
* **Timing**: constraint 20 ns, WNS -3.884 ns → *T*<sub>min</sub> 23.88 ns, *F*<sub>max</sub> 41.9 MHz
* **Critical path**: `id_stage_i/issue_q_reg[0][sbe][rs1][1]` → `issue_stage_i/i_issue_read_operands/fu_data_q_reg[1][operand_a][12]`, data path 23.829 ns (27 % logic, 73 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 132 625 | 127 714 | 130 170 | 0.850 |
| MNIST | 1 302 189 | 1 303 950 | 1 303 070 | 0.859 |
| CoreMark | 919 179 | 918 677 | 918 928 | 0.897 |

### OoO dual-issue ROB8, 44 physical registers

* **Parameters**: 44 phys. reg., RS 3, LSQ 2, lsq_bypass 2, rollback 2
* **Core LUTs**: 25 083
* **Timing**: constraint 22 ns, WNS -1.184 ns → *T*<sub>min</sub> 23.18 ns, *F*<sub>max</sub> 43.1 MHz
* **Critical path**: `id_stage_i/issue_q_reg[1][sbe][rs1][2]` → `issue_stage_i/i_issue_read_operands/fu_data_q_reg[1][operand_a][3]`, data path 23.132 ns (21 % logic, 79 % routing)

| Benchmark | Run 1 (cycles) | Run 2 (cycles) | Mean | IPC |
|---|---:|---:|---:|---:|
| FFT | 128 134 | 123 174 | 125 654 | 0.881 |
| MNIST | 1 218 795 | 1 220 993 | 1 219 894 | 0.918 |
| CoreMark | 905 202 | 904 991 | 905 096 | 0.910 |

## Design-space experiments (OoO dual-issue ROB16)

### Same-cycle paths (timing ablation)

Each line removes one more same-cycle path: fall-through of the reservation stations (RS FT),
fall-through of `lsq_bypass` (bypass FT), and sending a load to the cache in the cycle of its
address translation (translation bypass).

| Variant | Constraint (ns) | WNS (ns) | *T*<sub>min</sub> (ns) | *F*<sub>max</sub> (MHz) | Critical path |
|---|---:|---:|---:|---:|---|
| Reference (all paths) | 22 | −1.710 | 23.71 | 42.2 | RS entry → tournament → read operands |
| No RS fall-through | 22 | −1.262 | 23.26 | 43.0 | RS entry → tournament → read operands |
| No fall-through | 22 | −1.018 | 23.02 | 43.4 | LSQ: translation → cache → LQ |
| No fall-through, no translation bypass | 21 | −2.000 | 23.00 | 43.5 | RS entry → tournament → read operands |

On-board cycles of the last variant (single run): FFT 114 701, MNIST 971 865, CoreMark 860 285
(+14.2 %, +22.8 %, +11.1 % cycles versus the reference; +3.1 % *F*<sub>max</sub>, so the
execution time is 12.5 % longer).

### Rollback width

Instructions cancelled per cycle after a misprediction (reference: 2). All synthesised with a
22 ns constraint.

| Rollback width | Core LUTs | WNS (ns) | *T*<sub>min</sub> (ns) | *F*<sub>max</sub> (MHz) | Critical path |
|---:|---:|---:|---:|---:|---|
| 1 | 32 487 | −1.830 | 23.83 | 42.0 | `id_stage_i/issue_q_reg[0][sbe][rs2][1]` → `fu_data_q_reg[1][operand_a][20]` (data path 23.775 ns, 72 % routing) |
| 2 (reference) | 33 794 | −1.710 | 23.71 | 42.2 | RS entry → tournament → read operands |
| 4 | 34 909 | −2.352 | 24.35 | 41.1 | `id_stage_i/issue_q_reg[0][sbe][rs2][0]` → `fu_data_q_reg[1][operand_b][15]` (data path 24.299 ns, 75 % routing) |

### Early load wakeup (synthesis and simulation only)

Consumers of a load are woken by the cache response, one cycle before write-back. Synthesised
with a 23 ns constraint; not run on the board (simulation IPC in `simulation_results.md`).

| Variant | Core LUTs | WNS (ns) | *T*<sub>min</sub> (ns) | *F*<sub>max</sub> (MHz) | Critical path |
|---|---:|---:|---:|---:|---|
| Early wakeup | 33 573 | −0.968 | 23.97 | 41.7 | `id_stage_i/issue_q_reg[1][sbe][rs2][1]` → `fu_data_q_reg[1][operand_b][10]` (data path 23.963 ns, 77 % routing) |
| Early wakeup, no LSQ store-credit register | 33 573 | −2.261 | 25.26 | 39.6 | `load_store_queue_i/previous_translation_pointer_type_q_reg` → `issue_stage_i/st_return_token_q_reg[2]` (data path 25.208 ns, 75 % routing) |

### Scaling study (synthesis not completed)

All OoO structures doubled: ROB 32, 70 physical registers, RS 8, LSQ 8, `lsq_bypass` 8,
rollback 8. The out-of-context synthesis did not complete; the synthesis estimate gave more
than 60 000 LUTs and a *T*<sub>min</sub> well above 30 ns.

## Area breakdown

Hierarchical utilisation (Total LUTs per instance) of the full SoC implementation (not out of
context, so totals differ slightly from the summary). Vivado optimises across module
boundaries, so logic can be counted in a neighbouring block (in the SB8 run the decoder is
absorbed by the issue stage); stage subtotals are the most reliable comparison.

| Block | In-order dual-issue SB8 | In-order dual-issue SB16 | OoO dual-issue ROB16 |
|---|---:|---:|---:|
| Front-end | 3 427 | 3 345 | 3 245 |
| Decode (`id_stage`) | 8 | 1 212 | 1 274 |
| **Issue stage** | **9 011** | **9 668** | **15 048** |
| · Scoreboard / ROB | 2 671 | 4 885 | 6 967 |
| · RAT (speculative + commit) | — | — | 1 657 |
| · Reservation stations (incl. tournament trees) | — | — | 1 329 |
| · `lsq_bypass` | — | — | 534 |
| · Read operands + register file | 6 341 | 4 783 | 4 568 |
| **Execute stage** | **1 446** | **3 769** | **8 763** |
| · LSQ / `lsu_bypass` | 212 | 297 | 7 330 |
| · Load, store units, PMP | 554 | 2 618 | 702 |
| · MUL / DIV | 281 | 456 | 376 |
| · CSR buffer | 401 | 398 | 394 |
| CSR register file | 1 094 | 1 140 | 873 |
| Caches (I$ + D$) | 3 505 | 3 522 | 3 129 |
| **Core total** | **18 252** | **22 420** | **32 039** |
| Flip-flops | 8 192 | 9 479 | 9 905 |

## Memory micro-benchmark (`membench`)

Run on the FPGA board. One load per iteration over an 80 KiB array (larger than the data
cache), 4096 accesses per kernel. The kernels differ only in the dependence between cache misses: `stream` (sequential,
one access per cache line), `gather` (random, independent addresses), `chase` (pointer
chasing, each address is the previous load's result).

| Kernel | In-order dual-issue SB8: cycles (cycles/access) | OoO dual-issue ROB16: cycles (cycles/access) | Speed-up in cycles |
|---|---:|---:|---:|
| stream | 79 816 (19.5) | 49 277 (12.0) | 1.62× |
| gather | 64 417 (15.7) | 39 851 (9.7) | 1.62× |
| chase | 57 396 (14.0) | 60 947 (14.9) | 0.94× |

In this run, `stream` indexed the array with a modulo (the array size is not a power of two),
which adds a multiply-and-shift sequence per access; the published `membench.c` uses an
explicit wrap-around instead.
