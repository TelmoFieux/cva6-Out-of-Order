# Simulation results

Cycle-accurate simulation (Questa) of the out-of-order CVA6 variants, with the
instrumentation of the issue stage, the load/store queue and the commit stage.
FPGA cycle counts, area and timing are in [`fpga_results.md`](fpga_results.md).

## Method

* **Benchmarks**: FFT (kiss_fft), MNIST (one image inference) and CoreMark (3 iterations),
  compiled with GCC 15.2.0, `-march=rv32im_zicsr -O3`.
* **Measurement windows**: counters accumulate over windows of 4096 cycles. A window is kept
  only if at least 205 instructions committed in it, which automatically discards the end of
  the program and UART waits. Percentages are relative to the measured cycles.
* **Decode stalls** are exclusive and attributed by priority on issue port 0. Counters marked
  *non-exclusive* count (cycle, port) pairs and can overlap with other causes.
* **Front-end empty** and the decode-stall causes are mutually exclusive. **Nothing ready** is
  measured at issue and can overlap with them (typically with front-end empty after a
  misprediction).
* **Upper bounds**: "consumers issued at WB+1" counts instructions issued the cycle after
  their producer's write-back; it bounds the gain of an early wakeup, not the gain itself.
* Not reported: the RS fall-through potential (all designs were measured with fall-through
  enabled) and the ALU re-balancing counter (it is structurally zero in dual issue).
* "ROB" is the reorder buffer (`scoreboard` in the CVA6 sources).

## Summary

Commit IPC in simulation (measurement windows).

| Design | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| OoO dual-issue ROB16 (reference OoO design) | 1.278 | 1.453 | 1.162 |
| OoO single-issue ROB16 | 0.883 | 0.907 | 0.815 |
| OoO dual-issue ROB8 | 0.930 | 0.873 | 0.965 |
| OoO single-issue ROB8 | 0.771 | 0.745 | 0.768 |
| OoO dual-issue ROB8, 44 physical registers | 0.969 | 0.934 | 0.981 |
| OoO dual-issue ROB32 (scaling study) | 1.460 | 1.595 | 1.175 |
| OoO dual-issue ROB16, LSQ 8 | 1.331 | — | — |
| OoO dual-issue ROB16 + early load wakeup | 1.286 | 1.466 | 1.182 |
| OoO dual-issue ROB16 + early load wakeup, no LSQ store-credit register | 1.284 | 1.466 | 1.183 |

## Detailed counters

* [OoO dual-issue ROB16 (reference OoO design)](#ooo-dual-issue-rob16-reference-ooo-design)
* [OoO single-issue ROB16](#ooo-single-issue-rob16)
* [OoO dual-issue ROB8](#ooo-dual-issue-rob8)
* [OoO single-issue ROB8](#ooo-single-issue-rob8)
* [OoO dual-issue ROB8, 44 physical registers](#ooo-dual-issue-rob8-44-physical-registers)
* [OoO dual-issue ROB32 (scaling study)](#ooo-dual-issue-rob32-scaling-study)
* [OoO dual-issue ROB16, LSQ 8](#ooo-dual-issue-rob16-lsq-8)
* [OoO dual-issue ROB16 + early load wakeup](#ooo-dual-issue-rob16--early-load-wakeup)
* [OoO dual-issue ROB16 + early load wakeup, no LSQ store-credit register](#ooo-dual-issue-rob16--early-load-wakeup-no-lsq-store-credit-register)

### OoO dual-issue ROB16 (reference OoO design)

*Parameters:* 48 phys. reg., RS 4, LSQ 4, lsq_bypass 4, rollback 2.

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 21 / 0 | 188 / 0 | 173 / 0 |
| Measured cycles | 86016 | 770048 | 708608 |
| Committed instructions | 109907 | 1118992 | 823655 |
| IPC issue / commit | 1.279 / 1.278 | 1.467 / 1.453 | 1.210 / 1.162 |
| Cycles issuing 0 / 1 / 2 | 22.3 % / 27.5 % / 50.2 % | 10.4 % / 32.4 % / 57.1 % | 24.8 % / 29.4 % / 45.8 % |
| ROB full | 8.40 % of cycles | 0.02 % of cycles | 1.35 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 273 (2.48 per 1000 instr.) | 4284 (3.83 per 1000 instr.) | 16990 (20.63 per 1000 instr.) |
| Walkback (rollback) | 0.16 % (0.50 cycles/mispredict) | 1.40 % (2.52 cycles/mispredict) | 5.17 % (2.16 cycles/mispredict) |
| Front-end empty | 2.62 % (8.26 cycles/mispredict) | 3.48 % (6.26 cycles/mispredict) | 17.16 % (7.16 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.04 % | 0.30 % |
| No free physical register | 0.37 % | 2.44 % | 0.08 % |
| ROB full | 8.16 % | 0.01 % | 1.31 % |
| RS0 (FLU) full | 0.11 % | 0.00 % | 1.52 % |
| RS1 (ALU2) full | 6.86 % | 0.00 % | 1.81 % |
| lsq_bypass full | 4.49 % | 0.00 % | 0.14 % |
| No load credit | 4.66 % | 8.89 % | 3.38 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 12.56 % | 28.08 % | 8.70 % |
| No store credit at dispatch (non-exclusive) | 40.08 % | 0.00 % | 5.92 % |
| Load credit held by loads in lsq_bypass | 2.14 % | 1.60 % | 0.63 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 5.38 % | 0.02 % | 0.08 % |
| Nothing ready | 16.64 % | 8.60 % | 17.73 % |
| Candidate rejected by read-operands | 0.14 % | 0.42 % | 1.82 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 22327 / 38097 (37.0 % to RS0) | 12260 / 316211 (3.7 % to RS0) | 124756 / 323719 (27.8 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7863 | 243562 | 28188 |
| Consumers issued at WB+1 | 2659 (3.09 % of cycles) | 216949 (28.17 % of cycles) | 20237 (2.86 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 20340 | 515485 | 176939 |
| Consumers issued at WB+1 | 9030 (10.50 % of cycles) | 179117 (23.26 % of cycles) | 143956 (20.32 % of cycles) |
| of which loads/stores | 0 | 0 | 8581 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 2.60 | 8.29 | 1.37 |
| Mean time in store buffer (cycles) | 4.79 | 8.30 | 1.62 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 1248 | 1 | 471 |
| Loads sent to cache | 28707 | 543371 | 190130 |
| of which wrong-path | 0 | 1004 | 1952 |
| Age inversions | 0 | 0 | 41 |
| Store entries waiting for address (entry x cycles) | 19062 | 5324 | 148262 |
| Store entries waiting for data (entry x cycles) | 23857 | 1422 | 40769 |
| Store entries waiting for commit (entry x cycles) | 41503 | 13647 | 124891 |
| Committed, not yet drained (entry x cycles) | 97316 | 44676 | 111457 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 88 | 0 | 1224 |
| Store-to-load forwarding (total) | 88 | 0 | 1666 |
| Byte loads (lb/lbu) | 0 | 494121 | 29812 |
| Half-word loads (lh/lhu) | 14849 | 0 | 54631 |
| Word loads (lw) | 5629 | 22088 | 97654 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 155 | 231110 |
| Waiting for translation | 32436 | 605746 | 189979 |
| Translated, not yet sent to cache | 17725 | 125279 | 24543 |
| Sent, in the cache | 26049 | 572444 | 178413 |
| Result ready, waiting for write-back | 20475 | 515747 | 177294 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 6781 |
| Selected, waiting for cache grant | 8308 | 27218 | 13132 |
| Ready, load buffer full | 1332 | 34290 | 127 |
| Ready, another load selected | 8073 | 63771 | 4493 |
| Forwarding this cycle | 0 | 0 | 0 |
| Forwarding: store data missing | 0 | 0 | 10 |
| Forwarding: blocked by another store | 12 | 0 | 0 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 45 / 45 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 45 (0.01 % of cycles) |
| Result blocked by speculation | 0 | 0 | 13 |
| Speculative but not yet issued (entry x cycles) | 75 | 1 | 84395 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20398 / 0 / 0 (100.0 % in 1 cycle) | 515747 / 0 / 0 (100.0 % in 1 cycle) | 176131 / 3 / 7 (100.0 % in 1 cycle) |
| Forwarded loads | 77 | 0 | 828 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 3.17 % of cycles (mean occupancy 1.12 / 4) | 10.42 % of cycles (mean occupancy 2.36 / 4) | 3.82 % of cycles (mean occupancy 1.13 / 4) |
| SQ full | 16.65 % of cycles (mean occupancy 2.10 / 4) | 0.00 % of cycles (mean occupancy 0.08 / 4) | 3.18 % of cycles (mean occupancy 0.60 / 4) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

### OoO single-issue ROB16

*Parameters:* 48 phys. reg., RS 8, LSQ 4, lsq_bypass 4, rollback 2.

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 30 / 0 | 301 / 0 | 246 / 0 |
| Measured cycles | 122880 | 1232896 | 1007616 |
| Committed instructions | 108499 | 1118319 | 821639 |
| IPC issue / commit | 0.883 / 0.883 | 0.909 / 0.907 | 0.821 / 0.815 |
| Cycles issuing 0 / 1 / 2 | 11.7 % / 88.3 % / 0.0 % | 9.1 % / 90.9 % / 0.0 % | 17.9 % / 82.1 % / 0.0 % |
| ROB full | 0.88 % of cycles | 0.00 % of cycles | 0.00 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 273 (2.52 per 1000 instr.) | 4286 (3.83 per 1000 instr.) | 14225 (17.31 per 1000 instr.) |
| Walkback (rollback) | 0.25 % (1.12 cycles/mispredict) | 0.45 % (1.29 cycles/mispredict) | 1.53 % (1.09 cycles/mispredict) |
| Front-end empty | 3.68 % (16.59 cycles/mispredict) | 3.95 % (11.36 cycles/mispredict) | 13.66 % (9.68 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.00 % | 0.00 % |
| No free physical register | 0.14 % | 0.00 % | 0.00 % |
| ROB full | 0.77 % | 0.00 % | 0.00 % |
| RS0 (FLU) full | 0.60 % | 0.00 % | 0.20 % |
| RS1 (ALU2) full | 0.00 % | 0.00 % | 0.00 % |
| lsq_bypass full | 3.54 % | 0.00 % | 0.07 % |
| No load credit | 2.35 % | 4.24 % | 0.86 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 2.58 % | 4.24 % | 0.86 % |
| No store credit at dispatch (non-exclusive) | 6.06 % | 0.00 % | 0.22 % |
| Load credit held by loads in lsq_bypass | 2.12 % | 1.42 % | 0.82 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 0.33 % | 0.00 % | 0.00 % |
| Nothing ready | 10.93 % | 8.43 % | 15.32 % |
| Candidate rejected by read-operands | 0.18 % | 0.26 % | 1.07 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 59711 / 0 (100.0 % to RS0) | 325357 / 0 (100.0 % to RS0) | 424470 / 0 (100.0 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7732 | 243408 | 28188 |
| Consumers issued at WB+1 | 1258 (1.02 % of cycles) | 105756 (8.58 % of cycles) | 1183 (0.12 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 20103 | 510828 | 172785 |
| Consumers issued at WB+1 | 7810 (6.36 % of cycles) | 152626 (12.38 % of cycles) | 92893 (9.22 % of cycles) |
| of which loads/stores | 0 | 0 | 46 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 2.37 | 2.17 | 1.19 |
| Mean time in store buffer (cycles) | 3.82 | 2.18 | 1.30 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 693 | 1 | 245 |
| Loads sent to cache | 26333 | 534274 | 176201 |
| of which wrong-path | 0 | 104 | 378 |
| Age inversions | 0 | 0 | 8 |
| Store entries waiting for address (entry x cycles) | 16806 | 4808 | 43359 |
| Store entries waiting for data (entry x cycles) | 16342 | 0 | 15944 |
| Store entries waiting for commit (entry x cycles) | 57086 | 6301 | 92663 |
| Committed, not yet drained (entry x cycles) | 80998 | 15279 | 97999 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 0 | 0 | 260 |
| Store-to-load forwarding (total) | 124 | 0 | 330 |
| Byte loads (lb/lbu) | 0 | 489382 | 28554 |
| Half-word loads (lh/lhu) | 14848 | 0 | 54146 |
| Word loads (lw) | 5628 | 22087 | 92006 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 0 | 73291 |
| Waiting for translation | 20476 | 511469 | 192768 |
| Translated, not yet sent to cache | 12644 | 101844 | 7192 |
| Sent, in the cache | 25870 | 564127 | 175672 |
| Result ready, waiting for write-back | 20475 | 511397 | 172924 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 3083 |
| Selected, waiting for cache grant | 5919 | 22836 | 3551 |
| Ready, load buffer full | 1349 | 31072 | 82 |
| Ready, another load selected | 5376 | 47936 | 476 |
| Forwarding this cycle | 0 | 0 | 0 |
| Forwarding: store data missing | 0 | 0 | 0 |
| Forwarding: blocked by another store | 0 | 0 | 0 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) |
| Result blocked by speculation | 0 | 0 | 0 |
| Speculative but not yet issued (entry x cycles) | 0 | 0 | 8 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20413 / 0 / 0 (100.0 % in 1 cycle) | 511397 / 0 / 0 (100.0 % in 1 cycle) | 172621 / 6 / 0 (100.0 % in 1 cycle) |
| Forwarded loads | 62 | 0 | 262 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 1.13 % of cycles (mean occupancy 0.63 / 4) | 2.92 % of cycles (mean occupancy 1.37 / 4) | 0.35 % of cycles (mean occupancy 0.62 / 4) |
| SQ full | 6.80 % of cycles (mean occupancy 1.37 / 4) | 0.00 % of cycles (mean occupancy 0.02 / 4) | 0.19 % of cycles (mean occupancy 0.25 / 4) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

### OoO dual-issue ROB8

*Parameters:* 40 phys. reg., RS 3, LSQ 2, lsq_bypass 2, rollback 2.

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 29 / 0 | 313 / 0 | 208 / 0 |
| Measured cycles | 118784 | 1282048 | 851968 |
| Committed instructions | 110425 | 1119456 | 821905 |
| IPC issue / commit | 0.930 / 0.930 | 0.877 / 0.873 | 0.991 / 0.965 |
| Cycles issuing 0 / 1 / 2 | 35.2 % / 36.6 % / 28.2 % | 32.3 % / 47.7 % / 20.0 % | 32.4 % / 36.2 % / 31.4 % |
| ROB full | 7.62 % of cycles | 0.75 % of cycles | 7.31 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 339 (3.07 per 1000 instr.) | 4284 (3.83 per 1000 instr.) | 16844 (20.49 per 1000 instr.) |
| Walkback (rollback) | 0.08 % (0.27 cycles/mispredict) | 0.25 % (0.75 cycles/mispredict) | 2.23 % (1.13 cycles/mispredict) |
| Front-end empty | 1.70 % (5.94 cycles/mispredict) | 1.99 % (5.96 cycles/mispredict) | 10.78 % (5.45 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.00 % | 0.00 % |
| No free physical register | 15.14 % | 19.36 % | 3.23 % |
| ROB full | 3.42 % | 0.00 % | 6.18 % |
| RS0 (FLU) full | 0.00 % | 0.00 % | 0.96 % |
| RS1 (ALU2) full | 0.01 % | 0.00 % | 0.79 % |
| lsq_bypass full | 9.55 % | 0.00 % | 0.51 % |
| No load credit | 9.64 % | 20.57 % | 12.10 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 23.15 % | 58.96 % | 23.33 % |
| No store credit at dispatch (non-exclusive) | 34.20 % | 0.00 % | 6.57 % |
| Load credit held by loads in lsq_bypass | 0.00 % | 0.57 % | 0.01 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 4.01 % | 0.43 % | 1.78 % |
| Nothing ready | 31.11 % | 31.40 % | 27.10 % |
| Candidate rejected by read-operands | 0.01 % | 0.24 % | 1.26 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 18541 / 42086 (30.6 % to RS0) | 8008 / 316113 (2.5 % to RS0) | 96140 / 336468 (22.2 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7911 | 243670 | 28188 |
| Consumers issued at WB+1 | 2400 (2.02 % of cycles) | 188232 (14.68 % of cycles) | 14100 (1.65 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 20426 | 513030 | 174225 |
| Consumers issued at WB+1 | 8079 (6.80 % of cycles) | 165725 (12.93 % of cycles) | 125588 (14.74 % of cycles) |
| of which loads/stores | 0 | 0 | 8790 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 1.76 | 1.95 | 1.18 |
| Mean time in store buffer (cycles) | 2.27 | 1.95 | 1.19 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 0 | 0 | 0 |
| Loads sent to cache | 22698 | 520296 | 187441 |
| of which wrong-path | 0 | 1921 | 2177 |
| Age inversions | 0 | 0 | 0 |
| Store entries waiting for address (entry x cycles) | 19570 | 5043 | 45344 |
| Store entries waiting for data (entry x cycles) | 2532 | 0 | 16204 |
| Store entries waiting for commit (entry x cycles) | 19771 | 7055 | 87660 |
| Committed, not yet drained (entry x cycles) | 54930 | 14161 | 93446 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 0 | 0 | 538 |
| Store-to-load forwarding (total) | 0 | 0 | 781 |
| Byte loads (lb/lbu) | 0 | 491204 | 29156 |
| Half-word loads (lh/lhu) | 14848 | 0 | 54309 |
| Word loads (lw) | 5628 | 22089 | 94473 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 149 | 36697 |
| Waiting for translation | 31699 | 514067 | 183455 |
| Translated, not yet sent to cache | 3042 | 7597 | 16883 |
| Sent, in the cache | 24817 | 563513 | 176309 |
| Result ready, waiting for write-back | 20475 | 513078 | 174318 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 3216 |
| Selected, waiting for cache grant | 2222 | 7045 | 12111 |
| Ready, load buffer full | 0 | 0 | 0 |
| Ready, another load selected | 820 | 552 | 1554 |
| Forwarding this cycle | 0 | 0 | 0 |
| Forwarding: store data missing | 0 | 0 | 2 |
| Forwarding: blocked by another store | 0 | 0 | 0 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) |
| Result blocked by speculation | 0 | 0 | 0 |
| Speculative but not yet issued (entry x cycles) | 0 | 1 | 0 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20475 / 0 / 0 (100.0 % in 1 cycle) | 513078 / 0 / 0 (100.0 % in 1 cycle) | 173927 / 0 / 0 (100.0 % in 1 cycle) |
| Forwarded loads | 0 | 0 | 391 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 22.61 % of cycles (mean occupancy 0.67 / 2) | 34.86 % of cycles (mean occupancy 1.25 / 2) | 17.28 % of cycles (mean occupancy 0.69 / 2) |
| SQ full | 31.17 % of cycles (mean occupancy 0.81 / 2) | 0.05 % of cycles (mean occupancy 0.02 / 2) | 5.33 % of cycles (mean occupancy 0.28 / 2) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

### OoO single-issue ROB8

*Parameters:* 40 phys. reg., RS 4, LSQ 2, lsq_bypass 2, rollback 2.

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 34 / 0 | 367 / 0 | 261 / 0 |
| Measured cycles | 139264 | 1503232 | 1069056 |
| Committed instructions | 107382 | 1119220 | 821539 |
| IPC issue / commit | 0.771 / 0.771 | 0.746 / 0.745 | 0.774 / 0.768 |
| Cycles issuing 0 / 1 / 2 | 22.9 % / 77.1 % / 0.0 % | 25.4 % / 74.6 % / 0.0 % | 22.6 % / 77.4 % / 0.0 % |
| ROB full | 1.64 % of cycles | 0.06 % of cycles | 0.87 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 271 (2.52 per 1000 instr.) | 4284 (3.83 per 1000 instr.) | 15542 (18.92 per 1000 instr.) |
| Walkback (rollback) | 0.01 % (0.05 cycles/mispredict) | 0.25 % (0.87 cycles/mispredict) | 1.49 % (1.02 cycles/mispredict) |
| Front-end empty | 1.74 % (8.94 cycles/mispredict) | 1.62 % (5.67 cycles/mispredict) | 10.11 % (6.95 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.00 % | 0.00 % |
| No free physical register | 1.92 % | 1.40 % | 0.38 % |
| ROB full | 0.95 % | 0.00 % | 0.65 % |
| RS0 (FLU) full | 0.52 % | 0.00 % | 1.43 % |
| RS1 (ALU2) full | 0.00 % | 0.00 % | 0.00 % |
| lsq_bypass full | 10.77 % | 1.15 % | 0.38 % |
| No load credit | 6.81 % | 20.86 % | 6.66 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 7.23 % | 22.02 % | 6.69 % |
| No store credit at dispatch (non-exclusive) | 11.95 % | 0.00 % | 1.14 % |
| Load credit held by loads in lsq_bypass | 1.18 % | 4.44 % | 1.26 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 0.15 % | 0.01 % | 0.02 % |
| Nothing ready | 22.72 % | 24.95 % | 20.04 % |
| Candidate rejected by read-operands | 0.01 % | 0.21 % | 1.09 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 58754 / 0 (100.0 % to RS0) | 323744 / 0 (100.0 % to RS0) | 427051 / 0 (100.0 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7635 | 243612 | 28188 |
| Consumers issued at WB+1 | 1288 (0.92 % of cycles) | 150995 (10.04 % of cycles) | 2049 (0.19 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 19910 | 511179 | 172440 |
| Consumers issued at WB+1 | 7801 (5.60 % of cycles) | 163011 (10.84 % of cycles) | 93424 (8.74 % of cycles) |
| of which loads/stores | 0 | 0 | 293 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 1.71 | 1.74 | 1.08 |
| Mean time in store buffer (cycles) | 2.18 | 1.74 | 1.10 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 0 | 0 | 0 |
| Loads sent to cache | 22585 | 519044 | 178342 |
| of which wrong-path | 0 | 1920 | 376 |
| Age inversions | 0 | 0 | 0 |
| Store entries waiting for address (entry x cycles) | 16806 | 4805 | 42696 |
| Store entries waiting for data (entry x cycles) | 1659 | 0 | 10397 |
| Store entries waiting for commit (entry x cycles) | 25095 | 6144 | 85101 |
| Committed, not yet drained (entry x cycles) | 53364 | 13184 | 89294 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 0 | 0 | 692 |
| Store-to-load forwarding (total) | 0 | 0 | 716 |
| Byte loads (lb/lbu) | 0 | 489286 | 28245 |
| Half-word loads (lh/lhu) | 14848 | 0 | 54125 |
| Word loads (lw) | 5628 | 22086 | 91752 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 0 | 16700 |
| Waiting for translation | 20476 | 511372 | 174137 |
| Translated, not yet sent to cache | 3027 | 7683 | 7891 |
| Sent, in the cache | 24629 | 561701 | 173496 |
| Result ready, waiting for write-back | 20475 | 511330 | 172546 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 1992 |
| Selected, waiting for cache grant | 2109 | 7673 | 5780 |
| Ready, load buffer full | 0 | 0 | 0 |
| Ready, another load selected | 918 | 10 | 119 |
| Forwarding this cycle | 0 | 0 | 0 |
| Forwarding: store data missing | 0 | 0 | 0 |
| Forwarding: blocked by another store | 0 | 0 | 0 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) |
| Result blocked by speculation | 0 | 0 | 0 |
| Speculative but not yet issued (entry x cycles) | 0 | 0 | 0 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20475 / 0 / 0 (100.0 % in 1 cycle) | 511330 / 0 / 0 (100.0 % in 1 cycle) | 172186 / 0 / 0 (100.0 % in 1 cycle) |
| Forwarded loads | 0 | 0 | 360 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 13.20 % of cycles (mean occupancy 0.48 / 2) | 25.87 % of cycles (mean occupancy 1.06 / 2) | 9.84 % of cycles (mean occupancy 0.51 / 2) |
| SQ full | 24.33 % of cycles (mean occupancy 0.68 / 2) | 0.00 % of cycles (mean occupancy 0.02 / 2) | 2.89 % of cycles (mean occupancy 0.21 / 2) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

### OoO dual-issue ROB8, 44 physical registers

*Parameters:* 44 phys. reg., RS 3, LSQ 2, lsq_bypass 2, rollback 2.

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 27 / 0 | 292 / 0 | 205 / 0 |
| Measured cycles | 110592 | 1196032 | 839680 |
| Committed instructions | 107167 | 1117317 | 823518 |
| IPC issue / commit | 0.969 / 0.969 | 0.938 / 0.934 | 1.007 / 0.981 |
| Cycles issuing 0 / 1 / 2 | 34.9 % / 33.4 % / 31.8 % | 28.8 % / 48.6 % / 22.6 % | 32.3 % / 34.8 % / 33.0 % |
| ROB full | 11.84 % of cycles | 5.75 % of cycles | 9.22 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 339 (3.16 per 1000 instr.) | 4281 (3.83 per 1000 instr.) | 16846 (20.46 per 1000 instr.) |
| Walkback (rollback) | 0.08 % (0.27 cycles/mispredict) | 0.32 % (0.89 cycles/mispredict) | 2.45 % (1.22 cycles/mispredict) |
| Front-end empty | 1.91 % (6.24 cycles/mispredict) | 2.13 % (5.96 cycles/mispredict) | 11.01 % (5.49 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.00 % | 0.00 % |
| No free physical register | 0.00 % | 0.00 % | 0.00 % |
| ROB full | 11.84 % | 5.75 % | 9.11 % |
| RS0 (FLU) full | 0.00 % | 0.00 % | 0.98 % |
| RS1 (ALU2) full | 0.26 % | 0.00 % | 0.76 % |
| lsq_bypass full | 12.65 % | 0.00 % | 0.54 % |
| No load credit | 9.50 % | 26.70 % | 12.20 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 24.46 % | 70.63 % | 24.25 % |
| No store credit at dispatch (non-exclusive) | 37.80 % | 0.00 % | 6.73 % |
| Load credit held by loads in lsq_bypass | 0.00 % | 0.61 % | 0.01 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 6.21 % | 2.05 % | 2.68 % |
| Nothing ready | 28.55 % | 26.18 % | 25.81 % |
| Candidate rejected by read-operands | 0.01 % | 0.27 % | 1.32 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 17089 / 41620 (29.1 % to RS0) | 11572 / 311937 (3.6 % to RS0) | 108883 / 326649 (25.0 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7611 | 243181 | 28188 |
| Consumers issued at WB+1 | 2516 (2.28 % of cycles) | 191851 (16.04 % of cycles) | 14098 (1.68 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 19872 | 510308 | 174285 |
| Consumers issued at WB+1 | 7800 (7.05 % of cycles) | 184170 (15.40 % of cycles) | 126488 (15.06 % of cycles) |
| of which loads/stores | 0 | 0 | 8784 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 1.77 | 1.95 | 1.14 |
| Mean time in store buffer (cycles) | 2.27 | 1.95 | 1.15 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 0 | 0 | 0 |
| Loads sent to cache | 22978 | 520296 | 188505 |
| of which wrong-path | 0 | 1921 | 2296 |
| Age inversions | 0 | 0 | 0 |
| Store entries waiting for address (entry x cycles) | 17251 | 5043 | 45380 |
| Store entries waiting for data (entry x cycles) | 2779 | 0 | 17696 |
| Store entries waiting for commit (entry x cycles) | 23544 | 7076 | 88125 |
| Committed, not yet drained (entry x cycles) | 54920 | 14163 | 91767 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 0 | 0 | 537 |
| Store-to-load forwarding (total) | 0 | 0 | 776 |
| Byte loads (lb/lbu) | 0 | 491205 | 29157 |
| Half-word loads (lh/lhu) | 14848 | 0 | 54328 |
| Word loads (lw) | 5628 | 22089 | 94461 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 149 | 37373 |
| Waiting for translation | 28723 | 513328 | 182571 |
| Translated, not yet sent to cache | 3324 | 7595 | 17834 |
| Sent, in the cache | 24786 | 563568 | 176427 |
| Result ready, waiting for write-back | 20475 | 511333 | 174320 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 3216 |
| Selected, waiting for cache grant | 2502 | 7043 | 13057 |
| Ready, load buffer full | 0 | 0 | 0 |
| Ready, another load selected | 822 | 552 | 1557 |
| Forwarding this cycle | 0 | 0 | 0 |
| Forwarding: store data missing | 0 | 0 | 4 |
| Forwarding: blocked by another store | 0 | 0 | 0 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) |
| Result blocked by speculation | 0 | 0 | 0 |
| Speculative but not yet issued (entry x cycles) | 0 | 1 | 0 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20475 / 0 / 0 (100.0 % in 1 cycle) | 511333 / 0 / 0 (100.0 % in 1 cycle) | 173931 / 0 / 0 (100.0 % in 1 cycle) |
| Forwarded loads | 0 | 0 | 389 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 21.69 % of cycles (mean occupancy 0.68 / 2) | 43.21 % of cycles (mean occupancy 1.33 / 2) | 17.36 % of cycles (mean occupancy 0.70 / 2) |
| SQ full | 31.21 % of cycles (mean occupancy 0.86 / 2) | 0.05 % of cycles (mean occupancy 0.02 / 2) | 5.51 % of cycles (mean occupancy 0.29 / 2) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

### OoO dual-issue ROB32 (scaling study)

*Parameters:* 70 phys. reg., RS 8, LSQ 8, lsq_bypass 8, rollback 8.

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 18 / 0 | 171 / 0 | 170 / 0 |
| Measured cycles | 73728 | 700416 | 696320 |
| Committed instructions | 107678 | 1116888 | 818402 |
| IPC issue / commit | 1.464 / 1.460 | 1.619 / 1.595 | 1.239 / 1.175 |
| Cycles issuing 0 / 1 / 2 | 18.5 % / 16.7 % / 64.8 % | 7.6 % / 22.9 % / 69.5 % | 24.7 % / 26.7 % / 48.6 % |
| ROB full | 7.92 % of cycles | 0.00 % of cycles | 0.99 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 334 (3.10 per 1000 instr.) | 4310 (3.86 per 1000 instr.) | 16885 (20.63 per 1000 instr.) |
| Walkback (rollback) | 0.60 % (1.33 cycles/mispredict) | 0.83 % (1.36 cycles/mispredict) | 2.51 % (1.04 cycles/mispredict) |
| Front-end empty | 5.59 % (12.35 cycles/mispredict) | 6.42 % (10.43 cycles/mispredict) | 22.13 % (9.13 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.00 % | 0.00 % |
| No free physical register | 0.00 % | 0.00 % | 0.00 % |
| ROB full | 7.92 % | 0.00 % | 0.99 % |
| RS0 (FLU) full | 0.31 % | 0.00 % | 0.35 % |
| RS1 (ALU2) full | 1.12 % | 0.00 % | 1.04 % |
| lsq_bypass full | 0.81 % | 0.00 % | 0.09 % |
| No load credit | 5.02 % | 5.01 % | 0.12 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 11.39 % | 15.08 % | 0.23 % |
| No store credit at dispatch (non-exclusive) | 22.17 % | 0.00 % | 4.63 % |
| Load credit held by loads in lsq_bypass | 2.37 % | 0.82 % | 0.05 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 6.71 % | 0.00 % | 0.20 % |
| Nothing ready | 10.83 % | 6.31 % | 20.12 % |
| Candidate rejected by read-operands | 0.32 % | 0.47 % | 1.83 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 21513 / 37993 (36.2 % to RS0) | 11798 / 318557 (3.6 % to RS0) | 132834 / 319542 (29.4 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7659 | 243084 | 28188 |
| Consumers issued at WB+1 | 2968 (4.03 % of cycles) | 214757 (30.66 % of cycles) | 23244 (3.34 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 19960 | 515772 | 175907 |
| Consumers issued at WB+1 | 9356 (12.69 % of cycles) | 218178 (31.15 % of cycles) | 145362 (20.88 % of cycles) |
| of which loads/stores | 0 | 0 | 9094 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 2.90 | 12.86 | 1.34 |
| Mean time in store buffer (cycles) | 6.76 | 12.89 | 1.80 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 11473 | 4 | 4076 |
| Loads sent to cache | 28533 | 544617 | 190650 |
| of which wrong-path | 0 | 3015 | 1732 |
| Age inversions | 147 | 0 | 93 |
| Store entries waiting for address (entry x cycles) | 22596 | 5332 | 370034 |
| Store entries waiting for data (entry x cycles) | 42453 | 5681 | 44743 |
| Store entries waiting for commit (entry x cycles) | 128297 | 15221 | 155196 |
| Committed, not yet drained (entry x cycles) | 130384 | 66724 | 119304 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 4848 | 983 | 1226 |
| Store-to-load forwarding (total) | 5646 | 983 | 1611 |
| Byte loads (lb/lbu) | 0 | 499355 | 30294 |
| Half-word loads (lh/lhu) | 14877 | 0 | 54913 |
| Word loads (lw) | 5745 | 22091 | 100779 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 1983 | 494552 |
| Waiting for translation | 42568 | 996107 | 217458 |
| Translated, not yet sent to cache | 43962 | 440911 | 28893 |
| Sent, in the cache | 24661 | 575544 | 178747 |
| Result ready, waiting for write-back | 21459 | 517508 | 176757 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 4464 |
| Selected, waiting for cache grant | 11028 | 25188 | 13485 |
| Ready, load buffer full | 8101 | 62499 | 408 |
| Ready, another load selected | 24002 | 353224 | 10517 |
| Forwarding this cycle | 119 | 0 | 1 |
| Forwarding: store data missing | 0 | 0 | 2 |
| Forwarding: blocked by another store | 712 | 0 | 16 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 63 / 63 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 63 (0.01 % of cycles) |
| Result blocked by speculation | 0 | 0 | 61 |
| Speculative but not yet issued (entry x cycles) | 705 | 1 | 287354 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 17287 / 200 / 18 (98.8 % in 1 cycle) | 516042 / 477 / 1 (99.9 % in 1 cycle) | 175523 / 13 / 25 (100.0 % in 1 cycle) |
| Forwarded loads | 2971 | 479 | 799 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 2.70 % of cycles (mean occupancy 1.76 / 8) | 4.44 % of cycles (mean occupancy 3.60 / 8) | 0.38 % of cycles (mean occupancy 1.57 / 8) |
| SQ full | 11.37 % of cycles (mean occupancy 4.29 / 8) | 0.00 % of cycles (mean occupancy 0.13 / 8) | 2.66 % of cycles (mean occupancy 0.98 / 8) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

### OoO dual-issue ROB16, LSQ 8

*Parameters:* ROB16 reference with LSQ 8 (FFT only).

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 20 / 0 | — | — |
| Measured cycles | 81920 | — | — |
| Committed instructions | 109060 | — | — |
| IPC issue / commit | 1.332 / 1.331 | — | — |
| Cycles issuing 0 / 1 / 2 | 22.1 % / 22.6 % / 55.3 % | — | — |
| ROB full | 11.97 % of cycles | — | — |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 275 (2.52 per 1000 instr.) | — | — |
| Walkback (rollback) | 0.16 % (0.47 cycles/mispredict) | — | — |
| Front-end empty | 2.44 % (7.26 cycles/mispredict) | — | — |
| Flush cycles | 0 | — | — |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | — | — |
| No free physical register | 1.17 % | — | — |
| ROB full | 11.10 % | — | — |
| RS0 (FLU) full | 0.12 % | — | — |
| RS1 (ALU2) full | 5.70 % | — | — |
| lsq_bypass full | 2.31 % | — | — |
| No load credit | 0.38 % | — | — |
| Other | 0.00 % | — | — |
| No load credit (all ports, non-exclusive) | 1.78 % | — | — |
| No store credit at dispatch (non-exclusive) | 10.14 % | — | — |
| Load credit held by loads in lsq_bypass | 0.24 % | — | — |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 9.60 % | — | — |
| Nothing ready | 12.09 % | — | — |
| Candidate rejected by read-operands | 0.27 % | — | — |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 20815 / 39109 (34.7 % to RS0) | — | — |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7791 | — | — |
| Consumers issued at WB+1 | 2482 (3.03 % of cycles) | — | — |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 20196 | — | — |
| Consumers issued at WB+1 | 10110 (12.34 % of cycles) | — | — |
| of which loads/stores | 0 | — | — |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | — | — |
| Cycles per store at buffer head | 2.64 | — | — |
| Mean time in store buffer (cycles) | 5.65 | — | — |
| Store buffer stall (pending) | 0 | — | — |
| Store buffer full (cycles) | 7445 | — | — |
| Loads sent to cache | 30663 | — | — |
| of which wrong-path | 1 | — | — |
| Age inversions | 0 | — | — |
| Store entries waiting for address (entry x cycles) | 21105 | — | — |
| Store entries waiting for data (entry x cycles) | 34207 | — | — |
| Store entries waiting for commit (entry x cycles) | 82944 | — | — |
| Committed, not yet drained (entry x cycles) | 111748 | — | — |
| Stores drained | 16806 | — | — |
| Forwarding from committed stores | 294 | — | — |
| Store-to-load forwarding (total) | 294 | — | — |
| Byte loads (lb/lbu) | 0 | — | — |
| Half-word loads (lh/lhu) | 14849 | — | — |
| Word loads (lw) | 5632 | — | — |
| Potential partial forwarding | 0 | — | — |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | — | — |
| Waiting for translation | 38376 | — | — |
| Translated, not yet sent to cache | 32492 | — | — |
| Sent, in the cache | 26884 | — | — |
| Result ready, waiting for write-back | 20475 | — | — |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | — | — |
| Selected, waiting for cache grant | 10478 | — | — |
| Ready, load buffer full | 3610 | — | — |
| Ready, another load selected | 17485 | — | — |
| Forwarding this cycle | 0 | — | — |
| Forwarding: store data missing | 0 | — | — |
| Forwarding: blocked by another store | 919 | — | — |
| Partial match (wait for drain) | 0 | — | — |
| Older store without address | 0 | — | — |
| Other | 0 | — | — |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | — | — |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | — | — |
| Result blocked by speculation | 0 | — | — |
| Speculative but not yet issued (entry x cycles) | 1 | — | — |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20183 / 0 / 0 (100.0 % in 1 cycle) | — | — |
| Forwarded loads | 292 | — | — |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 0.23 % of cycles (mean occupancy 1.42 / 8) | — | — |
| SQ full | 4.10 % of cycles (mean occupancy 3.01 / 8) | — | — |
| LQ / SQ rejections | 0 / 0 | — | — |

### OoO dual-issue ROB16 + early load wakeup

*Parameters:* ROB16 reference + consumers woken on the cache response.

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 21 / 0 | 186 / 0 | 169 / 0 |
| Measured cycles | 86016 | 761856 | 692224 |
| Committed instructions | 110595 | 1116513 | 818210 |
| IPC issue / commit | 1.286 / 1.286 | 1.480 / 1.466 | 1.225 / 1.182 |
| Cycles issuing 0 / 1 / 2 | 22.1 % / 27.3 % / 50.7 % | 14.8 % / 22.5 % / 62.8 % | 24.2 % / 29.1 % / 46.7 % |
| ROB full | 8.51 % of cycles | 0.02 % of cycles | 1.40 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 336 (3.04 per 1000 instr.) | 4280 (3.83 per 1000 instr.) | 16830 (20.57 per 1000 instr.) |
| Walkback (rollback) | 0.25 % (0.63 cycles/mispredict) | 1.33 % (2.37 cycles/mispredict) | 4.76 % (1.96 cycles/mispredict) |
| Front-end empty | 3.10 % (7.95 cycles/mispredict) | 3.55 % (6.32 cycles/mispredict) | 17.85 % (7.34 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.00 % | 0.27 % |
| No free physical register | 0.38 % | 0.01 % | 0.07 % |
| ROB full | 8.23 % | 0.01 % | 1.36 % |
| RS0 (FLU) full | 0.00 % | 0.00 % | 0.98 % |
| RS1 (ALU2) full | 6.12 % | 0.00 % | 1.43 % |
| lsq_bypass full | 4.41 % | 0.00 % | 0.14 % |
| No load credit | 4.61 % | 10.19 % | 3.48 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 13.21 % | 34.32 % | 8.88 % |
| No store credit at dispatch (non-exclusive) | 39.76 % | 0.00 % | 6.06 % |
| Load credit held by loads in lsq_bypass | 2.48 % | 0.97 % | 0.56 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 5.55 % | 0.01 % | 0.38 % |
| Nothing ready | 16.14 % | 12.98 % | 17.36 % |
| Candidate rejected by read-operands | 0.12 % | 0.43 % | 1.69 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 22476 / 38437 (36.9 % to RS0) | 12148 / 315277 (3.7 % to RS0) | 121329 / 319054 (27.6 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7934 | 243001 | 28188 |
| Consumers issued at WB+1 | 2642 (3.07 % of cycles) | 218453 (28.67 % of cycles) | 20237 (2.92 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 20460 | 513741 | 176017 |
| Consumers issued at WB+1 | 5806 (6.75 % of cycles) | 129162 (16.95 % of cycles) | 41799 (6.04 % of cycles) |
| of which loads/stores | 0 | 0 | 8352 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 2.56 | 8.18 | 1.33 |
| Mean time in store buffer (cycles) | 4.79 | 8.19 | 1.57 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 1465 | 1 | 509 |
| Loads sent to cache | 28663 | 544327 | 189944 |
| of which wrong-path | 0 | 1923 | 1705 |
| Age inversions | 0 | 0 | 44 |
| Store entries waiting for address (entry x cycles) | 18745 | 5324 | 148952 |
| Store entries waiting for data (entry x cycles) | 21526 | 10 | 28968 |
| Store entries waiting for commit (entry x cycles) | 43002 | 12612 | 121283 |
| Committed, not yet drained (entry x cycles) | 97223 | 44145 | 109643 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 99 | 8 | 1161 |
| Store-to-load forwarding (total) | 99 | 8 | 1420 |
| Byte loads (lb/lbu) | 0 | 495072 | 29555 |
| Half-word loads (lh/lhu) | 14849 | 0 | 54609 |
| Word loads (lw) | 5629 | 22088 | 96490 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 461 | 220729 |
| Waiting for translation | 31248 | 723431 | 191599 |
| Translated, not yet sent to cache | 17801 | 126382 | 23023 |
| Sent, in the cache | 26458 | 573368 | 179260 |
| Result ready, waiting for write-back | 20591 | 515134 | 176906 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 5060 |
| Selected, waiting for cache grant | 8265 | 27279 | 13345 |
| Ready, load buffer full | 1934 | 34987 | 131 |
| Ready, another load selected | 7602 | 64116 | 4487 |
| Forwarding this cycle | 0 | 0 | 0 |
| Forwarding: store data missing | 0 | 0 | 0 |
| Forwarding: blocked by another store | 0 | 0 | 0 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 46 / 46 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 46 (0.01 % of cycles) |
| Result blocked by speculation | 0 | 0 | 13 |
| Speculative but not yet issued (entry x cycles) | 55 | 1 | 77080 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20398 / 0 / 0 (100.0 % in 1 cycle) | 515126 / 0 / 0 (100.0 % in 1 cycle) | 175980 / 1 / 7 (100.0 % in 1 cycle) |
| Forwarded loads | 77 | 8 | 531 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 3.49 % of cycles (mean occupancy 1.12 / 4) | 13.86 % of cycles (mean occupancy 2.54 / 4) | 4.01 % of cycles (mean occupancy 1.14 / 4) |
| SQ full | 16.58 % of cycles (mean occupancy 2.10 / 4) | 0.00 % of cycles (mean occupancy 0.08 / 4) | 4.19 % of cycles (mean occupancy 0.59 / 4) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

### OoO dual-issue ROB16 + early load wakeup, no LSQ store-credit register

*Parameters:* as above, store-credit return register removed in the LSQ (issue-stage register kept).

#### Throughput

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Windows kept / discarded | 20 / 0 | 186 / 0 | 170 / 0 |
| Measured cycles | 81920 | 761856 | 696320 |
| Committed instructions | 105211 | 1116507 | 823592 |
| IPC issue / commit | 1.285 / 1.284 | 1.480 / 1.466 | 1.226 / 1.183 |
| Cycles issuing 0 / 1 / 2 | 22.3 % / 27.0 % / 50.7 % | 14.8 % / 22.5 % / 62.8 % | 24.1 % / 29.3 % / 46.6 % |
| ROB full | 8.62 % of cycles | 0.02 % of cycles | 1.37 % of cycles |

#### Branch mispredictions

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Mispredictions | 334 (3.17 per 1000 instr.) | 4280 (3.83 per 1000 instr.) | 16872 (20.49 per 1000 instr.) |
| Walkback (rollback) | 0.26 % (0.63 cycles/mispredict) | 1.33 % (2.37 cycles/mispredict) | 4.75 % (1.96 cycles/mispredict) |
| Front-end empty | 3.07 % (7.54 cycles/mispredict) | 3.55 % (6.32 cycles/mispredict) | 17.93 % (7.40 cycles/mispredict) |
| Flush cycles | 0 | 0 | 0 |

#### Decode stalls (port 0, exclusive, by priority)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Walkback (rollback) | 0.00 % | 0.00 % | 0.27 % |
| No free physical register | 0.35 % | 0.01 % | 0.08 % |
| ROB full | 8.35 % | 0.01 % | 1.34 % |
| RS0 (FLU) full | 0.00 % | 0.00 % | 0.97 % |
| RS1 (ALU2) full | 6.57 % | 0.00 % | 1.45 % |
| lsq_bypass full | 4.15 % | 0.00 % | 0.12 % |
| No load credit | 4.45 % | 10.20 % | 3.44 % |
| Other | 0.00 % | 0.00 % | 0.00 % |
| No load credit (all ports, non-exclusive) | 13.00 % | 34.32 % | 8.85 % |
| No store credit at dispatch (non-exclusive) | 38.42 % | 0.00 % | 3.48 % |
| Load credit held by loads in lsq_bypass | 2.67 % | 0.97 % | 0.53 % |

#### Cycles without issue

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ROB head blocked (ROB full, nothing to issue) | 5.37 % | 0.01 % | 0.11 % |
| Nothing ready | 16.51 % | 12.98 % | 17.53 % |
| Candidate rejected by read-operands | 0.12 % | 0.43 % | 1.69 % |

#### ALU steering

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| ALU instructions to RS0 / RS1 | 21557 / 36188 (37.3 % to RS0) | 12147 / 315275 (3.7 % to RS0) | 123254 / 321498 (27.7 % to RS0) |

#### MUL early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| MUL write-backs | 7431 | 242998 | 28188 |
| Consumers issued at WB+1 | 2519 (3.07 % of cycles) | 218450 (28.67 % of cycles) | 20242 (2.91 % of cycles) |

#### Load early-wakeup potential (upper bound)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Load write-backs | 19538 | 513741 | 176493 |
| Consumers issued at WB+1 | 5424 (6.62 % of cycles) | 129154 (16.95 % of cycles) | 41859 (6.01 % of cycles) |
| of which loads/stores | 0 | 0 | 8360 |

#### Store buffer and memory operations

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Stores sent by the store buffer | 16806 | 4805 | 42590 |
| Cycles per store at buffer head | 2.64 | 8.18 | 1.34 |
| Mean time in store buffer (cycles) | 5.16 | 8.19 | 1.61 |
| Store buffer stall (pending) | 0 | 0 | 0 |
| Store buffer full (cycles) | 2358 | 2 | 842 |
| Loads sent to cache | 29630 | 544343 | 190311 |
| of which wrong-path | 0 | 1923 | 1708 |
| Age inversions | 0 | 0 | 24 |
| Store entries waiting for address (entry x cycles) | 20079 | 5325 | 156968 |
| Store entries waiting for data (entry x cycles) | 24250 | 10 | 29053 |
| Store entries waiting for commit (entry x cycles) | 46099 | 12612 | 121435 |
| Committed, not yet drained (entry x cycles) | 86799 | 39343 | 68676 |
| Stores drained | 16806 | 4805 | 42590 |
| Forwarding from committed stores | 72 | 0 | 1131 |
| Store-to-load forwarding (total) | 72 | 0 | 1394 |
| Byte loads (lb/lbu) | 0 | 495072 | 29561 |
| Half-word loads (lh/lhu) | 14849 | 0 | 54611 |
| Word loads (lw) | 5628 | 22088 | 96490 |
| Potential partial forwarding | 0 | 0 | 0 |

#### Load lifetime in the LQ (entry x cycles)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Waiting for virtual address | 0 | 461 | 220940 |
| Waiting for translation | 31363 | 723416 | 190760 |
| Translated, not yet sent to cache | 21147 | 126404 | 24213 |
| Sent, in the cache | 26994 | 573366 | 179488 |
| Result ready, waiting for write-back | 20583 | 515134 | 176915 |

#### Breakdown of 'not yet sent to cache'

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Non-idempotent (I/O) region | 0 | 0 | 5060 |
| Selected, waiting for cache grant | 9190 | 27287 | 13685 |
| Ready, load buffer full | 2984 | 34977 | 135 |
| Ready, another load selected | 8703 | 64140 | 5333 |
| Forwarding this cycle | 0 | 0 | 0 |
| Forwarding: store data missing | 0 | 0 | 0 |
| Forwarding: blocked by another store | 270 | 0 | 0 |
| Partial match (wait for drain) | 0 | 0 | 0 |
| Older store without address | 0 | 0 | 0 |
| Other | 0 | 0 | 0 |

#### Speculative loads

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Issued / won / cancelled / rolled back | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 47 / 47 / 0 / 0 |
| Cache-access cycles hidden | 0 (0.00 % of cycles) | 0 (0.00 % of cycles) | 47 (0.01 % of cycles) |
| Result blocked by speculation | 0 | 0 | 13 |
| Speculative but not yet issued (entry x cycles) | 55 | 1 | 77078 |

#### Cache response to write-back (non-forwarded loads)

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| 1 cycle / 2 / 3+ | 20440 / 0 / 0 (100.0 % in 1 cycle) | 515134 / 0 / 0 (100.0 % in 1 cycle) | 176005 / 1 / 7 (100.0 % in 1 cycle) |
| Forwarded loads | 35 | 0 | 513 |

#### Queue occupancy

| Counter | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| LQ full | 4.43 % of cycles (mean occupancy 1.17 / 4) | 13.86 % of cycles (mean occupancy 2.54 / 4) | 4.02 % of cycles (mean occupancy 1.14 / 4) |
| SQ full | 14.75 % of cycles (mean occupancy 2.07 / 4) | 0.00 % of cycles (mean occupancy 0.07 / 4) | 2.84 % of cycles (mean occupancy 0.54 / 4) |
| LQ / SQ rejections | 0 / 0 | 0 / 0 | 0 / 0 |

## Benchmark characterisation

Profile of the committed instruction stream, measured in the commit stage of the in-order
core (architectural registers). It depends only on the program, not on the core.
The ideal dataflow ILP assumes unlimited issue width, perfect branch prediction, fixed
latencies (ALU 1, load 2, MUL 2, DIV 20 cycles) and a window of W instructions (an
instruction cannot start before the one W positions earlier has finished); dependences
through memory are not tracked, so it is an upper bound.

### Size

| Metric | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Committed instructions | 124143 | 1119565 | 824067 |

### Instruction mix (% of instructions)

| Metric | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Conditional branches | 3.02 % | 3.38 % | 17.86 % |
| Jumps (jal / jalr) | 1.03 % | 0.06 % | 2.23 % |
| Loads | 17.39 % | 45.50 % | 20.91 % |
| Stores | 13.68 % | 0.43 % | 5.17 % |
| MUL / DIV | 6.39 % / 0.00 % | 21.77 % / 0.00 % | 3.42 % / 0.00 % |
| ALU | 58.49 % | 28.86 % | 50.42 % |
| CSR | 0.00 % | 0.00 % | 0.00 % |

### Producer to consumer distance (instructions)

| Metric | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| Distance 1 / 2 / 3-4 / 5-8 / 9-16 / >16 (% of sources) | 15.1 / 15.6 / 7.2 / 10.0 / 11.9 / 40.2 | 5.6 / 14.5 / 23.3 / 11.5 / 16.9 / 28.2 | 16.2 / 19.1 / 16.7 / 18.4 / 12.1 / 17.5 |

### Ideal dataflow ILP

| Metric | FFT | MNIST | CoreMark |
|---|---:|---:|---:|
| W = 8 | 2.98 | 3.28 | 2.85 |
| W = 16 | 3.98 | 3.97 | 3.60 |
| W = 32 | 5.76 | 4.60 | 4.25 |
| W = infinite | 148.85 | 2065.62 | 108.53 |
