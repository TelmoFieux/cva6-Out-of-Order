#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [A superscalar Out of Order design for the RISC-V CVA6 Core],
  abstract: [
This small article presents an Out of Order implementation for the RISC-V open source processor named CVA6. First we will go over the specifics of this processor, then we will explain the details of the micro-architecture developed. Finally, we will discuss our results: compared to the dual-issue in-order core, +32 % IPC at equal frequency, +5 % performance with each core at its own Fmax, and 1.62× fewer cycles on independent cache misses. And, analyze them as well as talk about the limits and future possible improvements of this design.
  ],
  authors: (
    (
      name: "Telmo Fieux",
      organization: [Université Toulouse III – Paul Sabatier],
      location: [Toulouse, France],
      email: "fieuxtelmo@gmail.com"
    ),
  ),
  index-terms: ("Micro-architecture", "Chip design", "Out of Order execution", "CVA6"),
)


#set figure(placement: none)

// =====================================================================================
//  Result tables: CVA6 in-order vs out-of-order, single / dual issue, 8 / 16 entries
//  In-order versions: scoreboard (SB) size; OoO versions: reorder buffer (ROB) size.
//  (`sb` field below = number of SB entries for in-order, ROB entries for OoO)
//  Every derived value (IPC, speedups, Fmax, geometric means...) is COMPUTED from the
//  raw measurements below: fixing a number in `configs`, `sim` or `ablation` updates
//  every table.
//
//  Layout: written for a two-column paper template. Wide tables span both columns
//  (`wide` below); narrow ones stay in a single column.
//  Each table is stored in a variable (fig_<name>) and placed in the text where it is
//  first cited (#fig_<name>); placement then floats it to the top of a column / page.
// =====================================================================================

// ---------- figure placement ----------
// wide tables float to the top of a page and span both columns
#let wide = (placement: top, scope: "parent")
// narrow tables float to the top of their column, near where they are cited
#let narrow = (placement: top)

// ---------- raw FPGA measurements (Zybo Z7-20, 40 MHz, GCC 15.2) ----------
// period / wns: routed out-of-context Vivado report, Tmin = period - WNS
// CoreMark: instructions of the timed region (minstret), cycles = CoreMark ticks (mcycle)
#let n_instr = (fft: 110651, mnist: 1119565, cm: 824071)
#let cm_iter = 3                                   // CoreMark iterations per run

#let configs = (
  (ooo: false, w: 1, sb: 16, phys: none, rs: none, lsq: none, byp: none,
   lut: 14381, period: 20, wns: -0.111,
   fft: (145873, 141714), mnist: (1710682, 1712009), cm: (1179058, 1178094)),
  (ooo: false, w: 1, sb: 8, phys: none, rs: none, lsq: none, byp: none,
   lut: 10933, period: 15, wns: -4.625,
   fft: (145873, 141714), mnist: (1710682, 1712009), cm: (1179058, 1178094)),
  (ooo: false, w: 2, sb: 16, phys: none, rs: none, lsq: none, byp: none,
   lut: 23269, period: 22, wns: -1.529,
   fft: (118889, 114650), mnist: (1280114, 1281671), cm: (952299, 951078)),
  (ooo: false, w: 2, sb: 8, phys: none, rs: none, lsq: none, byp: none,
   lut: 18410, period: 18, wns: -0.812,
   fft: (118674, 114431), mnist: (1282048, 1283608), cm: (952865, 952003)),
  (ooo: true, w: 1, sb: 16, phys: 48, rs: 8, lsq: 4, byp: 4,
   lut: 21838, period: 21, wns: -1.404,
   fft: (134454, 130081), mnist: (1255334, 1257587), cm: (1058544, 1057841)),
  (ooo: true, w: 1, sb: 8, phys: 40, rs: 4, lsq: 2, byp: 2,
   lut: 16344, period: 18, wns: -1.596,
   fft: (153743, 149545), mnist: (1523091, 1525026), cm: (1124909, 1124136)),
  (ooo: true, w: 2, sb: 16, phys: 48, rs: 4, lsq: 4, byp: 4,
   lut: 33794, period: 22, wns: -1.710,
   fft: (102260, 98665), mnist: (789820, 792622), cm: (774474, 774115)),
  (ooo: true, w: 2, sb: 8, phys: 40, rs: 3, lsq: 2, byp: 2,
   lut: 25261, period: 20, wns: -3.884,
   fft: (132625, 127714), mnist: (1302189, 1303950), cm: (919179, 918677)),
)

// ---------- simulation counters (OoO versions), in % of measured cycles ----------
// ipc: commit IPC; iss2: cycles issuing 2 instructions; idle: no ready candidate;
// fe: front-end empty; decode stalls (port 0): reg, sb, rs (RS0 + RS1),
// lsq (lsq_bypass full + load credit); lq / sq: queue full;
// upper bounds: mul / ld = consumers issued at WB+1 (ft: fallthrough potential, unused:
// every measurement was made with fallthrough enabled)
#let sim = (
  ((w: 1, sb: 16), (
    fft:   (ipc: 0.883, iss2: 0.0,  idle: 10.93, fe: 3.68,  reg: 0.14,  sb: 0.77, rs: 0.60, lsq: 5.89,  lq: 1.13,  sq: 6.80,  mul: 1.02,  ld: 6.36,  ft: 1.32),
    mnist: (ipc: 0.907, iss2: 0.0,  idle: 8.43,  fe: 3.95,  reg: 0.00,  sb: 0.00, rs: 0.00, lsq: 4.24,  lq: 2.92,  sq: 0.00,  mul: 8.58,  ld: 12.38, ft: 1.21),
    cm:    (ipc: 0.815, iss2: 0.0,  idle: 15.32, fe: 13.66, reg: 0.00,  sb: 0.00, rs: 0.20, lsq: 0.93,  lq: 0.35,  sq: 0.19,  mul: 0.12,  ld: 9.22,  ft: 2.36),
  )),
  ((w: 1, sb: 8), (
    fft:   (ipc: 0.771, iss2: 0.0,  idle: 22.72, fe: 1.74,  reg: 1.92,  sb: 0.95, rs: 0.52, lsq: 17.58, lq: 13.20, sq: 24.33, mul: 0.92,  ld: 5.60,  ft: 1.64),
    mnist: (ipc: 0.745, iss2: 0.0,  idle: 24.95, fe: 1.62,  reg: 1.40,  sb: 0.00, rs: 0.00, lsq: 22.01, lq: 25.87, sq: 0.00,  mul: 10.04, ld: 10.84, ft: 0.86),
    cm:    (ipc: 0.768, iss2: 0.0,  idle: 20.04, fe: 10.11, reg: 0.38,  sb: 0.65, rs: 1.43, lsq: 7.04,  lq: 9.84,  sq: 2.89,  mul: 0.19,  ld: 8.74,  ft: 2.82),
  )),
  ((w: 2, sb: 16), (
    fft:   (ipc: 1.278, iss2: 50.2, idle: 16.64, fe: 2.62,  reg: 0.37,  sb: 8.16, rs: 6.97, lsq: 9.15,  lq: 3.17,  sq: 16.65, mul: 3.09,  ld: 10.50, ft: 0.14),
    mnist: (ipc: 1.453, iss2: 57.1, idle: 8.60,  fe: 3.48,  reg: 2.44,  sb: 0.01, rs: 0.00, lsq: 8.89,  lq: 10.42, sq: 0.00,  mul: 28.17, ld: 23.26, ft: 2.70),
    cm:    (ipc: 1.162, iss2: 45.8, idle: 17.73, fe: 17.16, reg: 0.08,  sb: 1.31, rs: 3.33, lsq: 3.52,  lq: 3.82,  sq: 3.18,  mul: 2.86,  ld: 20.32, ft: 3.40),
  )),
  ((w: 2, sb: 8), (
    fft:   (ipc: 0.930, iss2: 28.2, idle: 31.11, fe: 1.70,  reg: 15.14, sb: 3.42, rs: 0.01, lsq: 19.19, lq: 22.61, sq: 31.17, mul: 2.02,  ld: 6.80,  ft: 4.18),
    mnist: (ipc: 0.873, iss2: 20.0, idle: 31.40, fe: 1.99,  reg: 19.36, sb: 0.00, rs: 0.00, lsq: 20.57, lq: 34.86, sq: 0.05,  mul: 14.68, ld: 12.93, ft: 4.82),
    cm:    (ipc: 0.965, iss2: 31.4, idle: 27.10, fe: 10.78, reg: 3.23,  sb: 6.18, rs: 1.75, lsq: 12.61, lq: 17.28, sq: 5.33,  mul: 1.65,  ld: 14.74, ft: 4.93),
  )),
  // scaling study: phys 70, RS 8, LSQ 8, bypass 8, rollback 8 (simulation only)
  ((w: 2, sb: 32), (
    fft:   (ipc: 1.460, iss2: 64.8, idle: 10.83, fe: 5.59,  reg: 0.00,  sb: 7.92, rs: 1.43, lsq: 5.83,  lq: 2.70,  sq: 11.37, mul: 4.03,  ld: 12.69, ft: 1.35),
    mnist: (ipc: 1.595, iss2: 69.5, idle: 6.31,  fe: 6.42,  reg: 0.00,  sb: 0.00, rs: 0.00, lsq: 5.01,  lq: 4.44,  sq: 0.00,  mul: 30.66, ld: 31.15, ft: 4.52),
    cm:    (ipc: 1.175, iss2: 48.6, idle: 20.12, fe: 22.13, reg: 0.00,  sb: 0.99, rs: 1.39, lsq: 0.21,  lq: 0.38,  sq: 2.66,  mul: 3.34,  ld: 20.88, ft: 2.64),
  )),
)

// ---------- ablation of the same-cycle paths (OoO, dual issue, ROB16) ----------
// rs_ft: RS fallthrough; byp_ft: lsq_bypass fallthrough; tr: translation -> cache bypass
// perf: none when the variant was not run on the board (one run per benchmark otherwise)
#let ablation = (
  (name: [Baseline], rs_ft: true, byp_ft: true, tr: true,
   period: 22, wns: -1.710, crit: [RS entry → tournament → IRO],
   perf: (fft: (102260, 98665), mnist: (789820, 792622), cm: (774474, 774115))),
  (name: [No RS fallthrough], rs_ft: false, byp_ft: true, tr: true,
   period: 22, wns: -1.262, crit: [RS entry → tournament → IRO], perf: none),
  (name: [No fallthrough], rs_ft: false, byp_ft: false, tr: true,
   period: 22, wns: -1.018, crit: [LSQ: translation → cache → LQ], perf: none),
  (name: [No fallthrough, no translation bypass], rs_ft: false, byp_ft: false, tr: false,
   period: 21, wns: -2.000, crit: [RS entry → tournament → IRO],
   perf: (fft: (114701,), mnist: (971865,), cm: (860285,))),
)

#let benchs = (("fft", "FFT"), ("mnist", "MNIST"), ("cm", "CoreMark"))

// speedup reference: original CVA6 (in-order, single issue, SB16)
#let ref = configs.at(0)

// ---------- computations ----------
#let avg(t) = t.sum() / t.len()
#let tmin(c) = c.period - c.wns                     // ns
#let fmax(c) = 1000 / tmin(c)                       // MHz
#let ipc(c, b) = n_instr.at(b) / avg(c.at(b))
#let su(c, b) = avg(ref.at(b)) / avg(c.at(b))       // speedup at equal frequency
#let geo(xs) = calc.pow(xs.fold(1.0, (a, x) => a * x), 1 / xs.len())
#let su_geo(c) = geo(benchs.map(((b, _)) => su(c, b)))
#let su_fmax(c) = su_geo(c) * fmax(c) / fmax(ref)   // time speedup, each at its own Fmax
#let perf_lut(c) = su_geo(c) / (c.lut / ref.lut)
#let cm_per_mhz(c) = cm_iter * 1e6 / avg(c.cm)       // CoreMark/MHz (ticks are cycles)

// ---------- formatting (decimal point, thin space as thousands separator) ----------
#let fmt(x, d: 2) = {
  let r = calc.round(float(x), digits: d)
  let s = str(calc.abs(r))
  let parts = s.split(".")
  let ip = parts.at(0)
  let fp = if parts.len() > 1 { parts.at(1) } else { "" }
  while fp.len() < d { fp += "0" }
  let out = ""
  let n = ip.len()
  for (i, ch) in ip.clusters().enumerate() {
    if i > 0 and calc.rem(n - i, 3) == 0 { out += "\u{2009}" }
    out += ch
  }
  (if r < 0 { "−" } else { "" }) + out + (if d > 0 { "." + fp } else { "" })
}
#let pct(x, d: 1) = (if x >= 1 { "+" } else { "" }) + fmt((x - 1) * 100, d: d) + "%"
#let times(x) = fmt(x, d: 2) + "×"
#let opt(v) = if v == none { [—] } else { str(v) }
// in-order: SB<n> (scoreboard); OoO: ROB<n> (reorder buffer)
#let qname(ooo) = if ooo { "ROB" } else { "SB" }
#let lbl(c) = [#if c.ooo [OoO] else [In-order] #str(c.w)-way #qname(c.ooo)#str(c.sb)]
#let is_ref(c) = c.ooo == ref.ooo and c.w == ref.w and c.sb == ref.sb
#let yesno(b) = if b [✓] else [—]

#set table(stroke: none, inset: (x: 4pt, y: 3pt))
#let head(..cols) = table.header(table.hline(stroke: 0.8pt), ..cols, table.hline(stroke: 0.5pt))
#let foot = table.hline(stroke: 0.8pt)
#let thin = table.hline(stroke: 0.3pt)

// =====================================================================================
//  Table: configurations, area and frequency
// =====================================================================================
#let fig_config = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: 10,
    align: (left,) + (center,) * 4 + (right,) * 5,
    head([*Version*], [*Phys. reg.*], [*RS*], [*LSQ*], [*Bypass*],
         [*Core LUTs*], [*vs. ref.*], [*Constraint (ns)*], [*$T_"min"$ (ns)*], [*$F_"max"$ (MHz)*]),
    ..configs.map(c => (
      lbl(c), opt(c.phys), opt(c.rs), opt(c.lsq), opt(c.byp),
      fmt(c.lut, d: 0),
      if is_ref(c) { [ref.] } else { pct(c.lut / ref.lut) },
      fmt(c.period, d: 0), fmt(tmin(c), d: 2), fmt(fmax(c), d: 1),
    )).flatten(),
    foot,
  )),
  caption: [Parameters, area (core LUTs after out-of-context place and route) and maximum
            frequency ($T_"min"$ = constrained period − WNS) of each version.
            SB: scoreboard entries (in-order); ROB: reorder buffer entries (OoO).
            RS, LSQ and Bypass give the number of entries of each structure.],
) <tab-config>]

// =====================================================================================
//  Table: cycles and IPC
// =====================================================================================
#let fig_cycles = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: 8,
    align: (left,) + (right,) * 7,
    head(
      table.cell(rowspan: 2, align: left + horizon)[*Version*],
      table.cell(colspan: 2, align: center)[*FFT*],
      table.cell(colspan: 2, align: center)[*MNIST*],
      table.cell(colspan: 3, align: center)[*CoreMark*],
      [*Cycles*], [*IPC*], [*Cycles*], [*IPC*], [*Cycles*], [*IPC*], [*CM/MHz*],
    ),
    ..configs.map(c => (
      lbl(c),
      fmt(avg(c.fft), d: 0), fmt(ipc(c, "fft"), d: 3),
      fmt(avg(c.mnist), d: 0), fmt(ipc(c, "mnist"), d: 3),
      fmt(avg(c.cm), d: 0), fmt(ipc(c, "cm"), d: 3), fmt(cm_per_mhz(c), d: 2),
    )).flatten(),
    foot,
  )),
  caption: [Cycles measured on the FPGA (mean of two consecutive runs) and IPC.
            CoreMark cycles cover the timed region (#cm_iter iterations, read from
            `mcycle`); CM/MHz is the resulting CoreMark/MHz score, given for comparison
            only (the run is shorter than the 10 s required by the EEMBC reporting rules).],
) <tab-cycles>]

// =====================================================================================
//  Table: speedup over the original CVA6
// =====================================================================================
#let fig_speedup = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: 7,
    align: (left,) + (right,) * 6,
    head(
      table.cell(rowspan: 2, align: left + horizon)[*Version*],
      table.cell(colspan: 4, align: center)[*At equal frequency*],
      table.cell(rowspan: 2, align: horizon)[*Each at its $F_"max"$*],
      table.cell(rowspan: 2, align: horizon)[*Perf. / LUT*],
      [*FFT*], [*MNIST*], [*CoreMark*], [*Geomean*],
    ),
    ..configs.map(c => (
      lbl(c),
      times(su(c, "fft")), times(su(c, "mnist")), times(su(c, "cm")),
      strong(times(su_geo(c))), times(su_fmax(c)), fmt(perf_lut(c), d: 2),
    )).flatten(),
    foot,
  )),
  caption: [Speedup over the reference (in-order, single issue, SB16). "Each at its
            $F_"max"$" multiplies the cycle speedup by the ratio of maximum frequencies;
            "Perf. / LUT" divides the geometric mean by the area ratio.],
) <tab-speedup>]

// =====================================================================================
//  Table: benefit of out-of-order execution at equal width and SB size
// =====================================================================================
#let pairs = ((1, 16), (1, 8), (2, 16), (2, 8)).map(((w, sb)) => {
  let io = configs.find(c => not c.ooo and c.w == w and c.sb == sb)
  let oo = configs.find(c => c.ooo and c.w == w and c.sb == sb)
  (io: io, oo: oo)
})
#let ratio_su(p, b) = avg(p.io.at(b)) / avg(p.oo.at(b))
#let ratio_geo(p) = geo(benchs.map(((b, _)) => ratio_su(p, b)))

#let fig_ooo_vs_io = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: 8,
    align: (left,) + (right,) * 7,
    head([*Issue width, size*], [*FFT*], [*MNIST*], [*CoreMark*], [*Geomean*],
         [*LUTs*], [*$F_"max"$*], [*Gain at $F_"max"$*]),
    ..pairs.map(p => (
      [#str(p.oo.w)-way, SB#str(p.io.sb) / ROB#str(p.oo.sb)],
      pct(ratio_su(p, "fft")), pct(ratio_su(p, "mnist")), pct(ratio_su(p, "cm")),
      strong(pct(ratio_geo(p))),
      pct(p.oo.lut / p.io.lut),
      pct(fmax(p.oo) / fmax(p.io)),
      pct(ratio_geo(p) * fmax(p.oo) / fmax(p.io)),
    )).flatten(),
    foot,
  )),
  caption: [Benefit of out-of-order execution: each OoO version compared with the in-order
            version of the same issue width, with a ROB as large as the in-order scoreboard
            (cycle gain, LUT overhead,
            $F_"max"$ change, and execution-time gain at $F_"max"$).],
) <tab-ooo-vs-io>]

// =====================================================================================
//  Early load wakeup variants of the OoO dual issue ROB16 (simulation only)
//  ew: early wakeup of load consumers (consumers woken by the cache response)
//  ipc: commit IPC in simulation; FPGA cycles are ESTIMATED by scaling the measured
//  ROB16 cycles by the simulated IPC ratio (cycles = ROB16 cycles × IPC_ROB16 / IPC_var)
// =====================================================================================
#let find(ooo, w, sb) = configs.find(c => c.ooo == ooo and c.w == w and c.sb == sb)
#let rob16 = find(true, 2, 16)
#let rob16_sim = sim.find(((k, r)) => k.w == 2 and k.sb == 16).at(1)
#let variant(name, short, lut, period, wns, ipc) = {
  let c = (name: name, short: short, ooo: true, w: 2, sb: 16, lut: lut,
           period: period, wns: wns, ipc_sim: ipc, estimated: true)
  for (b, _) in benchs {
    c.insert(b, (avg(rob16.at(b)) * rob16_sim.at(b).ipc / ipc.at(b),))
  }
  c
}
#let ew = variant([OoO ROB16 + early wakeup], "+ EW", 33573, 23, -0.968,
                  (fft: 1.286, mnist: 1.466, cm: 1.182))

// =====================================================================================
//  Table: OoO dual issue ROB16 (and its EW variant) vs. the cheapest in-order dual issue
//  (in-order SB8 and SB16 perform identically: SB8 is the cheapest point)
// =====================================================================================
#let cmp_a = find(false, 2, 8)
#let cmp_list = (rob16, ew)                      // OoO versions compared with cmp_a
#let exec_time(c, b) = avg(c.at(b)) / fmax(c)       // µs: cycles / MHz
#let cmp_row(name, f, va, vfun, ratio) = (name, f(va)) + cmp_list.map(c => (f(vfun(c)), pct(ratio(c)))).flatten()
#let speed_geo(c) = geo(benchs.map(((b, _)) => avg(cmp_a.at(b)) / avg(c.at(b))))
#let time_geo(c) = geo(benchs.map(((b, _)) => exec_time(cmp_a, b) / exec_time(c, b)))
#let ncol = 2 + 2 * cmp_list.len()
#let dash_row(name, ratio, bold: false) = (name, [—]) + cmp_list.map(c =>
  ([—], if bold { strong(pct(ratio(c))) } else { pct(ratio(c)) })).flatten()

#let fig_ooo_vs_io_sb8 = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: ncol,
    align: (left,) + (right,) * (ncol - 1),
    head([], [*In-order 2-way SB8*],
         ..cmp_list.map(c => ([*#if c.at("short", default: none) == none [OoO 2-way ROB16] else [OoO ROB16 #c.short#super[a]]*], [*Diff.*])).flatten()),
    table.cell(colspan: ncol)[_Hardware cost_],
    ..cmp_row([Core LUTs], x => fmt(x, d: 0), cmp_a.lut, c => c.lut, c => c.lut / cmp_a.lut),
    ..cmp_row([$T_"min"$ (ns)], x => fmt(x, d: 2), tmin(cmp_a), c => tmin(c), c => tmin(c) / tmin(cmp_a)),
    ..cmp_row([$F_"max"$ (MHz)], x => fmt(x, d: 1), fmax(cmp_a), c => fmax(c), c => fmax(c) / fmax(cmp_a)),
    thin,
    table.cell(colspan: ncol)[_Performance at equal frequency_],
    ..benchs.map(((b, nb)) => cmp_row([#nb IPC], x => fmt(x, d: 3), ipc(cmp_a, b),
        c => ipc(c, b), c => ipc(c, b) / ipc(cmp_a, b))).flatten(),
    ..dash_row([Geomean], speed_geo, bold: true),
    thin,
    table.cell(colspan: ncol)[_Execution time, each at its $F_"max"$_],
    ..benchs.map(((b, nb)) => cmp_row([#nb (µs)], x => fmt(x, d: 0), exec_time(cmp_a, b),
        c => exec_time(c, b), c => exec_time(cmp_a, b) / exec_time(c, b))).flatten(),
    ..dash_row([Geomean], time_geo, bold: true),
    thin,
    ..dash_row([Perf. at $F_"max"$ / LUT], c => time_geo(c) / (c.lut / cmp_a.lut)),
    foot,
  )),
  caption: [OoO dual issue (ROB16) against the cheapest in-order dual-issue version (SB8,
            same performance as SB16 within 0.2%). A positive difference favours the OoO
            version, except on cost rows (LUTs, $T_"min"$) where it is the increase.
            #super[a] Early load wakeup (@tab-early-wakeup):
            not run on the board, its cycles are estimated from the measured ROB16 cycles
            scaled by the IPC ratio observed in simulation.],
) <tab-ooo-vs-io-sb8>]

// =====================================================================================
//  Table: cycle breakdown (simulation, OoO versions)
// =====================================================================================
#let sim_rows(cells) = sim.enumerate().map(((k, (cfg, res))) => {
  let rows = benchs.enumerate().map(((i, (b, nb))) => {
    let head_cell = if i == 0 {
      (table.cell(rowspan: 3, align: left + horizon)[#str(cfg.w)-way ROB#str(cfg.sb)],)
    } else { () }
    head_cell + (nb,) + cells(res.at(b))
  }).flatten()
  (if k > 0 { (thin,) } else { () }) + rows
}).flatten()

#let fig_sim_cycles = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: 12,
    align: (left, left) + (right,) * 10,
    head(
      table.cell(rowspan: 2, align: left + horizon)[*OoO*],
      table.cell(rowspan: 2, align: left + horizon)[*Bench.*],
      table.cell(rowspan: 2, align: horizon)[*IPC*],
      table.cell(rowspan: 2, align: horizon)[*Dual issue*],
      table.cell(rowspan: 2, align: horizon)[*Nothing ready*],
      table.cell(rowspan: 2, align: horizon)[*Front-end empty*],
      table.cell(colspan: 4, align: center)[*Decode stalled by*],
      table.cell(rowspan: 2, align: horizon)[*LQ full*],
      table.cell(rowspan: 2, align: horizon)[*SQ full*],
      [*Phys. reg.*], [*ROB full*], [*RS full*], [*LSQ#super[a]*],
    ),
    ..sim_rows(r => (fmt(r.ipc, d: 3), fmt(r.iss2, d: 1), fmt(r.idle, d: 1), fmt(r.fe, d: 1),
                     fmt(r.reg, d: 1), fmt(r.sb, d: 1), fmt(r.rs, d: 1), fmt(r.lsq, d: 1),
                     fmt(r.lq, d: 1), fmt(r.sq, d: 1))),
    foot,
  )),
  caption: [Cycle breakdown in simulation (% of measured cycles; commit IPC). Decode stall
            causes are exclusive and checked in priority order on port 0.
            #super[a] `lsq_bypass` full or no load credit available.
            The 2-way ROB32 version is the scaling study of @tab-scaling (every structure
            doubled; simulation only). Decode-side columns (front-end empty and decode stall causes) are mutually exclusive. Nothing ready is measured at issue and may overlap with them, typically with front-end empty after a misprediction.],
) <tab-sim-cycles>]

// =====================================================================================
//  Table: potential of non-implemented optimisations (upper bounds)
// =====================================================================================
#let fig_potential = [#figure(
  ..narrow,
  text(size: 8pt, table(
    columns: 4,
    align: (left, left) + (right,) * 2,
    head([*OoO*], [*Bench.*], [*MUL wakeup*], [*Load wakeup*]),
    ..sim_rows(r => (fmt(r.mul, d: 1) + "%", fmt(r.ld, d: 1) + "%")),
    foot,
  )),
  caption: [Upper bound of the gain of optimisations evaluated by instrumentation, in % of
            cycles: instructions issued the cycle after their producer's write-back (MUL or
            load).],
) <tab-potential>]

// =====================================================================================
//  Table: timing ablation of the same-cycle paths (OoO dual issue ROB16)
// =====================================================================================
#let base = ablation.at(0)

#let fig_ablation_timing = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: 8,
    align: (left, center, center, center, right, right, right, left),
    head(
      table.cell(rowspan: 2, align: left + horizon)[*Variant*],
      table.cell(colspan: 3, align: center)[*Same-cycle path kept*],
      table.cell(rowspan: 2, align: horizon)[*$T_"min"$ (ns)*],
      table.cell(rowspan: 2, align: horizon)[*$F_"max"$ (MHz)*],
      table.cell(rowspan: 2, align: horizon)[*$F_"max"$ vs. base*],
      table.cell(rowspan: 2, align: left + horizon)[*Critical path*],
      [*RS FT*], [*Bypass FT*], [*Transl.→cache*],
    ),
    ..ablation.map(a => (
      a.name, yesno(a.rs_ft), yesno(a.byp_ft), yesno(a.tr),
      fmt(tmin(a), d: 2), fmt(fmax(a), d: 1),
      if a == base { [—] } else { pct(fmax(a) / fmax(base)) },
      a.crit,
    )).flatten(),
    foot,
  )),
  caption: [Timing cost of the same-cycle paths of the OoO dual-issue ROB16 version:
            fallthrough of the reservation stations (RS FT) and of `lsq_bypass` (Bypass FT),
            and sending a load to the cache in the cycle of its address translation
            (Transl.→cache). Each line removes one more path.],
) <tab-ablation-timing>]

// =====================================================================================
//  Table: is it worth it? performance of the variant without any same-cycle path
// =====================================================================================
#let measured = ablation.filter(a => a.perf != none)
#let last = measured.last()
#let cyc_ratio(a, b) = avg(a.perf.at(b)) / avg(base.perf.at(b))   // > 1 = more cycles
#let cyc_geo(a) = geo(benchs.map(((b, _)) => cyc_ratio(a, b)))
#let net(a) = (fmax(a) / fmax(base)) / cyc_geo(a)                   // > 1 = faster

#let fig_ablation_perf = [#figure(
  ..narrow,
  text(size: 8pt, table(
    columns: 4,
    align: (left, right, right, right),
    head([], [*Baseline*], [*No FT, no bypass*], [*Diff.*]),
    ..benchs.map(((b, nb)) => (
      [#nb (cycles)],
      fmt(avg(base.perf.at(b)), d: 0), fmt(avg(last.perf.at(b)), d: 0),
      pct(cyc_ratio(last, b)),
    )).flatten(),
    ..([Cycles, geomean], [—], [—], pct(cyc_geo(last))),
    thin,
    ..([$F_"max"$ (MHz)], fmt(fmax(base), d: 1), fmt(fmax(last), d: 1),
       pct(fmax(last) / fmax(base))),
    thin,
    ..([*Execution time at $F_"max"$*], [—], [—], strong(pct(1 / net(last)))),
    foot,
  )),
  caption: [Performance cost of removing every same-cycle path (OoO dual issue ROB16).
            Positive differences mean more cycles or a longer execution time.
            Baseline: mean of two runs; variant: single run.],
) <tab-ablation-perf>]

// =====================================================================================
//  Table: scaling study — large OoO configuration vs. OoO 2-way ROB16 (simulation IPC)
//  Large config: OoC synthesis not completed -> LUT and T_min are bounds (estimates)
// =====================================================================================
#let big = (
  name: [OoO 2-way ROB32], phys: 70, rs: 8, lsq: 8, byp: 8, rollback: 8,
  lut_min: 60000, tmin_min: 30,                       // bounds: > 60 000 LUTs, T_min > 30 ns
  ipc: (fft: 1.460, mnist: 1.595, cm: 1.175),         // commit IPC, simulation
)
#let base = find(true, 2, 16)
#let base_sim = sim.find(((k, r)) => k.w == 2 and k.sb == 16).at(1)
#let ipc_ratio(b) = big.ipc.at(b) / base_sim.at(b).ipc
#let ipc_geo = geo(benchs.map(((b, _)) => ipc_ratio(b)))
#let lut_ratio = big.lut_min / base.lut              // lower bound
#let f_ratio = tmin(base) / big.tmin_min             // upper bound
#let le(s) = [≤ #s]
#let ge(s) = [≥ #s]

#let fig_scaling = [#figure(
  ..narrow,
  text(size: 8pt, table(
    columns: 4,
    align: (left, right, right, right),
    head([], [*OoO 2-way ROB16*], [*#big.name*], [*Diff.*]),
    table.cell(colspan: 4)[_Parameters_],
    [Reg / RS / LSQ / Byp], [48 / 4 / 4 / 4],
      [#big.phys / #big.rs / #big.lsq / #big.byp], [—],
    thin,
    table.cell(colspan: 4)[_IPC (simulation)_],
    ..benchs.map(((b, nb)) => ([#nb], fmt(base_sim.at(b).ipc, d: 3), fmt(big.ipc.at(b), d: 3),
                               pct(ipc_ratio(b)))).flatten(),
    [Geomean], [—], [—], strong(pct(ipc_geo)),
    thin,
    table.cell(colspan: 4)[_Hardware cost (large configuration: estimates)_],
    [Core LUTs], fmt(base.lut, d: 0), [> #fmt(big.lut_min, d: 0)], ge(pct(lut_ratio)),
    [$T_"min"$ (ns)], fmt(tmin(base), d: 2), [> #fmt(big.tmin_min, d: 0)], ge(pct(big.tmin_min / tmin(base))),
    [$F_"max"$ (MHz)], fmt(fmax(base), d: 1), [< #fmt(1000 / big.tmin_min, d: 1)], le(pct(f_ratio)),
    thin,
    table.cell(colspan: 4)[_Performance at $F_"max"$ (upper bound)_],
    ..benchs.map(((b, nb)) => ([#nb], [—], [—],
                               le(pct(ipc_ratio(b) * f_ratio)))).flatten(),
    [Geomean], [—], [—], strong(le(pct(ipc_geo * f_ratio))),
    [IPC / LUT], [—], [—], le(pct(ipc_geo / lut_ratio)),
    foot,
  )),
  caption: [Scaling study: OoO dual issue with every structure doubled (rollback 8)
            against ROB16. IPC from simulation for both. The synthesis of the large
            version did not complete: its LUTs and $T_"min"$ are lower bounds, so its
            gains are upper bounds.],
) <tab-scaling>]

// =====================================================================================
//  Area breakdown: in-order dual issue (SB8, SB16) vs. OoO dual issue ROB16
//  Source: hierarchical utilization (report_utilization -hierarchical) of the full SoC
//  implementation (not out-of-context), Total LUTs of each instance under i_cva6.
//  Totals therefore differ slightly from @tab-config (OoC flow).
//  Vivado optimises across module boundaries: combinational logic can be counted in a
//  neighbouring block (e.g. the decoder is absorbed by the issue stage in the SB8 run:
//  id_stage = 8 LUTs). Stage totals and the back-end subtotal are the robust figures.
// =====================================================================================
#let area_cfg = (
  io8:  (name: [In-order SB8],  core: 18252, ff: 8192),
  io16: (name: [In-order SB16], core: 22420, ff: 9479),
  oo:   (name: [OoO ROB16],     core: 32039, ff: 9905),
)
#let area_ref = "io16"                                // change computed against this one

// lvl 0: pipeline stage; lvl 1: block inside the stage above; Total LUTs per instance
#let area = (
  (lvl: 0, name: [Front-end],                     io8: 3427, io16: 3345, oo: 3245),
  (lvl: 0, name: [Decode (`id_stage`)],          io8: 8,    io16: 1212, oo: 1274),
  (lvl: 0, name: [Issue stage],                   io8: 9011, io16: 9668, oo: 15048),
  (lvl: 1, name: [Scoreboard / ROB],              io8: 2671, io16: 4885, oo: 6967),
  (lvl: 1, name: [RAT (speculative + commit)],    io8: 0,    io16: 0,    oo: 1618 + 39),
  (lvl: 1, name: [Reservation stations#super[a]], io8: 0,    io16: 0,    oo: 382 + 947,
   short: [Reservation stations (2)]),
  (lvl: 1, name: [`lsq_bypass`],                  io8: 0,    io16: 0,    oo: 534),
  (lvl: 1, name: [Read operands + regfile],       io8: 6341, io16: 4783, oo: 4568),
  (lvl: 0, name: [Execute stage],                 io8: 1446, io16: 3769, oo: 8763),
  (lvl: 1, name: [LSQ / `lsu_bypass`],            io8: 212,  io16: 297,  oo: 7330,
   short: [Load/store queue]),
  (lvl: 1, name: [Load, store units, PMP],        io8: 554,  io16: 2618, oo: 702),
  (lvl: 1, name: [MUL / DIV],                     io8: 281,  io16: 456,  oo: 376),
  (lvl: 1, name: [CSR buffer],                    io8: 401,  io16: 398,  oo: 394),
  (lvl: 0, name: [CSR register file],             io8: 1094, io16: 1140, oo: 873),
  (lvl: 0, name: [Caches (I\$ + D\$)],            io8: 3505, io16: 3522, oo: 3129),
)
#let backend(k) = area.filter(r => r.lvl == 0 and (r.name == [Decode (`id_stage`)]
  or r.name == [Issue stage] or r.name == [Execute stage])).map(r => r.at(k)).sum()
#let area_delta = area_cfg.oo.core - area_cfg.at(area_ref).core
#let share(x, tot) = fmt(100 * x / tot, d: 1) + "%"
#let growth(a, b) = if a == 0 { [new] } else if a < 100 { [≫] } else { times(b / a) }
#let signed(x) = (if x > 0 { "+" } else { "" }) + fmt(x, d: 0)
#let lut0(x, tot) = if x == 0 { ([—], [—]) } else { (fmt(x, d: 0), share(x, tot)) }
#let cfg_keys = ("io8", "io16", "oo")
#let change(a, b) = (growth(a, b), signed(b - a), share(b - a, area_delta))

#let fig_area_stages = [#figure(
  ..wide,
  text(size: 8pt, table(
    columns: 10,
    align: (left,) + (right,) * 9,
    head(
      table.cell(rowspan: 2, align: left + horizon)[*Block*],
      ..cfg_keys.map(k => table.cell(colspan: 2, align: center)[*#area_cfg.at(k).name*]),
      table.cell(colspan: 3, align: center)[*OoO vs. #area_cfg.at(area_ref).name*],
      ..cfg_keys.map(k => ([*LUTs*], [*% core*])).flatten(),
      [*Ratio*], [*LUTs*], [*% of increase*],
    ),
    ..area.map(r => {
      let nm = if r.lvl == 0 { strong(r.name) } else { h(0.8em) + r.name }
      let cells = cfg_keys.map(k => lut0(r.at(k), area_cfg.at(k).core)).flatten()
      let row = (nm,) + cells + change(r.at(area_ref), r.oo)
      if r.lvl == 0 and r != area.first() { (thin,) + row } else { row }
    }).flatten(),
    thin,
    emph[Back-end (decode + issue + execute)],
      ..cfg_keys.map(k => (fmt(backend(k), d: 0), share(backend(k), area_cfg.at(k).core))).flatten(),
      ..change(backend(area_ref), backend("oo")),
    thin,
    strong[Core total],
      ..cfg_keys.map(k => (strong(fmt(area_cfg.at(k).core, d: 0)), [100%])).flatten(),
      strong(times(area_cfg.oo.core / area_cfg.at(area_ref).core)), strong(signed(area_delta)), [100%],
    [Flip-flops],
      ..cfg_keys.map(k => (fmt(area_cfg.at(k).ff, d: 0), [—])).flatten(),
      times(area_cfg.oo.ff / area_cfg.at(area_ref).ff),
      signed(area_cfg.oo.ff - area_cfg.at(area_ref).ff), [—],
    foot,
  )),
  caption: [LUTs per pipeline stage of the dual-issue cores (hierarchical report of the full
            SoC implementation); the change is computed against the in-order version with the
            same queue size (SB16). Indented lines detail the stage above. Vivado optimises
            across module boundaries, so logic can be counted in a neighbouring block (in the
            SB8 run, the decoder is absorbed by the issue stage); the back-end subtotal is
            the most reliable comparison. Blocks add up to slightly more than the core total
            because LUTs shared by two instances are counted in both.
            #super[a] Including their tournament trees. ≫: block almost empty in the reference.],
) <tab-area-stages>]

// =====================================================================================
//  Share of the OoO core spent on out-of-order structures
// =====================================================================================
// structures that do not exist in the in-order core, plus the LSQ (replaces lsu_bypass)
#let ooo_new = area.filter(r => r.lvl == 1 and r.io16 == 0) + (area.find(r => r.name == [LSQ / `lsu_bypass`]),)
#let ooo_new_sum = ooo_new.map(r => r.oo).sum()
#let rob = area.find(r => r.name == [Scoreboard / ROB])
#let lsq_row = area.find(r => r.name == [LSQ / `lsu_bypass`])

#let fig_area_ooo = [#figure(
  ..narrow,
  text(size: 8pt, table(
    columns: 3,
    align: (left, right, right),
    head([*OoO structure*], [*LUTs*], [*% of OoO core*]),
    ..ooo_new.map(r => (r.at("short", default: r.name), fmt(r.oo, d: 0), share(r.oo, area_cfg.oo.core))).flatten(),
    thin,
    strong[New OoO structures], strong(fmt(ooo_new_sum, d: 0)),
      strong(share(ooo_new_sum, area_cfg.oo.core)),
    [ROB (in-order SB16: #fmt(rob.io16, d: 0))], fmt(rob.oo, d: 0), share(rob.oo, area_cfg.oo.core),
    thin,
    strong[OoO structures + ROB], strong(fmt(ooo_new_sum + rob.oo, d: 0)),
      strong(share(ooo_new_sum + rob.oo, area_cfg.oo.core)),
    foot,
  )),
  caption: [Area of the out-of-order structures in the OoO dual-issue ROB16 core. The LSQ
            replaces the in-order `lsu_bypass` (#fmt(lsq_row.io16, d: 0) LUTs in SB16);
            the ROB replaces the scoreboard. Reservation stations include their
            tournament trees.],
) <tab-area-ooo>]

// =====================================================================================
//  Table: physical-register bottleneck of the OoO dual issue ROB8 (simulation IPC)
//  40 registers: version of @tab-config (sim entry w: 2, sb: 8); 44: same version, 4 more
// =====================================================================================
#let rob8_sim = sim.find(((k, r)) => k.w == 2 and k.sb == 8).at(1)
#let rob8_44 = (fft: 0.969, mnist: 0.934, cm: 0.981)     // commit IPC, 44 phys. registers
#let reg_ratio(b) = rob8_44.at(b) / rob8_sim.at(b).ipc

#let fig_phys_reg = [#figure(
  ..narrow,
  text(size: 8pt, table(
    columns: 4,
    align: (left, right, right, right),
    head([*Benchmark*], [*40 phys. reg.*], [*44 phys. reg.*], [*Diff.*]),
    ..benchs.map(((b, nb)) => ([#nb], fmt(rob8_sim.at(b).ipc, d: 3), fmt(rob8_44.at(b), d: 3),
                               pct(reg_ratio(b)))).flatten(),
    thin,
    [Geomean], [—], [—], strong(pct(geo(benchs.map(((b, _)) => reg_ratio(b))))),
    foot,
  )),
  caption: [Commit IPC in simulation of the OoO dual-issue ROB8 version with 40 and 44
            physical registers. With 40 registers, only 40 − 32 − 2 = 6 can be renamed at
            once (32 architectural, 2 pre-allocated), fewer than the 8 ROB entries, and decode
            stalls for lack of a free register 3 to 19% of the time. With 44 registers this
            stall disappears.],
) <tab-phys-reg>]


// =====================================================================================
//  Table: early load wakeup (OoO dual issue ROB16, simulation IPC)
// =====================================================================================
#let ew_list = (ew,)
#let ew_ratio(c, b) = c.ipc_sim.at(b) / rob16_sim.at(b).ipc
#let ew_geo(c) = geo(benchs.map(((b, _)) => ew_ratio(c, b)))
#let ew_row(name, f, vb, vfun, ratio) = (name, f(vb)) + ew_list.map(c => (f(vfun(c)), pct(ratio(c)))).flatten()

#let fig_early_wakeup = [#figure(
  ..narrow,
  text(size: 8pt, table(
    columns: 4,
    align: (left,) + (right,) * 3,
    head([], [*ROB16*], [*+ early wakeup*], [*Diff.*]),
    table.cell(colspan: 4)[_Hardware cost_],
    ..ew_row([Core LUTs], x => fmt(x, d: 0), rob16.lut, c => c.lut, c => c.lut / rob16.lut),
    ..ew_row([$T_"min"$ (ns)], x => fmt(x, d: 2), tmin(rob16), c => tmin(c), c => tmin(c) / tmin(rob16)),
    ..ew_row([$F_"max"$ (MHz)], x => fmt(x, d: 1), fmax(rob16), c => fmax(c), c => fmax(c) / fmax(rob16)),
    thin,
    table.cell(colspan: 4)[_IPC (simulation)_],
    ..benchs.map(((b, nb)) => ew_row([#nb], x => fmt(x, d: 3), rob16_sim.at(b).ipc,
        c => c.ipc_sim.at(b), c => ew_ratio(c, b))).flatten(),
    [Geomean], [—], [—], strong(pct(ew_geo(ew))),
    thin,
    [Perf. at $F_"max"$], [—], [—], strong(pct(ew_geo(ew) * fmax(ew) / fmax(rob16))),
    foot,
  )),
  caption: [Early wakeup of load consumers (woken by the cache response, one cycle before
            write-back) on the OoO dual-issue ROB16. Perf. at $F_"max"$ = IPC ratio ×
            $F_"max"$ ratio.],
) <tab-early-wakeup>]

// =====================================================================================
//  Table: benchmark characterisation (commit-stage profile, architectural registers)
//  mix: % of committed instructions; dist: producer -> consumer distance, % of sources
//  ilp: ideal dataflow ILP (unlimited width, perfect prediction, ALU 1 / LD 2 / MUL 2,
//       window W = the instruction W positions earlier must have finished; no memory deps)
//  mpki: mispredictions per 1000 instructions (OoO dual issue ROB16 simulation)
// =====================================================================================
#let profile = (
  fft:   (n: 124143,  br: 3.02,  jmp: 1.03, ld: 17.39, st: 13.68, mul: 6.39,  alu: 58.49,
          dist: (15.1, 15.6, 7.2, 10.0, 11.9, 40.2), ilp: (2.98, 3.98, 5.76, 148.85), mpki: 2.48),
  mnist: (n: 1119565, br: 3.38,  jmp: 0.06, ld: 45.50, st: 0.43,  mul: 21.77, alu: 28.86,
          dist: (5.6, 14.5, 23.3, 11.5, 16.9, 28.2),  ilp: (3.28, 3.97, 4.60, 2065.62), mpki: 3.83),
  cm:    (n: 824067,  br: 17.86, jmp: 2.23, ld: 20.91, st: 5.17,  mul: 3.42,  alu: 50.42,
          dist: (16.2, 19.1, 16.7, 18.4, 12.1, 17.5), ilp: (2.85, 3.60, 4.25, 108.53), mpki: 20.63),
)
#let prow(name, f) = (name,) + benchs.map(((b, _)) => f(b)).flatten()
#let pc1(x) = fmt(x, d: 1) + "%"
#let sec(t) = table.cell(colspan: 4)[_#t _]

#let fig_benchmarks = [#figure(
  ..narrow,
  text(size: 8pt, table(
    columns: 4,
    align: (left, right, right, right),
    head([], ..benchs.map(((_, nb)) => [*#nb*])),
    sec[Instruction mix (% of instructions)],
    ..prow([Conditional branches], b => pc1(profile.at(b).br)),
    ..prow([Jumps (jal / jalr)],   b => pc1(profile.at(b).jmp)),
    ..prow([Loads],                b => pc1(profile.at(b).ld)),
    ..prow([Stores],               b => pc1(profile.at(b).st)),
    ..prow([MUL],                  b => pc1(profile.at(b).mul)),
    ..prow([ALU],                  b => pc1(profile.at(b).alu)),
    thin,
    sec[Branch prediction],
    ..prow([Mispredictions / 1000 instr.], b => fmt(profile.at(b).mpki, d: 1)),
    ..prow([Mispredicted branches],        b => pc1(profile.at(b).mpki / 10 / profile.at(b).br * 100)),
    ..prow([Instr. between mispredictions], b => fmt(1000 / profile.at(b).mpki, d: 0)),
    thin,
    sec[Producer → consumer distance (% of sources)],
    ..prow([1 instruction],        b => pc1(profile.at(b).dist.at(0))),
    ..prow([2],                    b => pc1(profile.at(b).dist.at(1))),
    ..prow([3–4],                  b => pc1(profile.at(b).dist.at(2))),
    ..prow([5–8],                  b => pc1(profile.at(b).dist.at(3))),
    ..prow([9–16],                 b => pc1(profile.at(b).dist.at(4))),
    ..prow([> 16],                 b => pc1(profile.at(b).dist.at(5))),
    thin,
    sec[Ideal dataflow ILP (window of $W$ instructions)],
    ..prow([$W = 8$],              b => fmt(profile.at(b).ilp.at(0), d: 2)),
    ..prow([$W = 16$],             b => fmt(profile.at(b).ilp.at(1), d: 2)),
    ..prow([$W = 32$],             b => fmt(profile.at(b).ilp.at(2), d: 2)),
    ..prow([$W = infinity$],       b => fmt(profile.at(b).ilp.at(3), d: 0)),
    foot,
  )),
  caption: [Characterisation of the benchmarks from the committed instruction stream
            (independent of the core). Ideal ILP assumes unlimited issue width, perfect
            branch prediction, fixed latencies (ALU 1, load 2, MUL 2 cycles) and ignores
            dependences through memory; it is an upper bound.],
) <tab-benchmarks>]



= Introduction

The CVA6 is an open source RISC-V processor originally developed by the University of Bologna and ETH Zurich. Later, the OpenHW Group was created as a non-profit organization to continue the development and make it a usable industrial product. As a final project for my master's degree I developed an Out of Order version of this processor that I will present in this article.

= The base architecture

The CVA6 is a 6-stage pipelined CPU. These stages are: PC, Fetch, Decode, Issue, Execute, Commit.
It is highly customizable and thus supports a lot of features. To name a few: branch prediction, multiple levels of privilege, memory virtualization, memory management unit... It has different types of cache, the one used in our configuration being the HPD cache. It supports 32-bit mode (the one used in this architecture) as well as 64-bit mode. It also implements various RISC-V extensions such as floating-point instructions or compressed instructions, to mention a few. And finally it supports a superscalar mode which only supports dual issue, adds a new ALU module and will be the configuration that we will be interested in. In the next section we will explain in detail the base architecture of some parts of the CVA6 that have been heavily modified to implement the Out of Order (OoO) execution. Those parts are mainly: the issue stage, the execute stage and the load store unit.

== Issue Stage

The main purpose of this stage is to be the center of the CPU. It tracks the progress of each decoded instruction until its commit. It performs forwarding, access to the registers and commit in order. In the base design, the issue stage is composed of 2 modules: a *Scoreboard* (SB) and *Issue_Read_Operands* (IRO). The Scoreboard's main purpose is to resolve dependencies and ensure in-order commit, since the write back can be done out of order. Thus it holds a lot of status information for each instruction. It is basically a circular buffer with one entry for each instruction between the issue stage and the commit stage. For each instruction it contains various important data such as exception state, result, operands to verify dependencies, branch prediction validity etc. Plus, in combination with IRO, it helps track the state of each instruction through the pipeline to perform data forwarding. This structure will be the foundation of our Reorder Buffer.
As for IRO, it accesses the registers, builds the instruction payload that will be sent next cycle to the execute stage, checks the availability of each functional unit and, finally, also has a big portion dedicated to tracking the state of each instruction through the pipeline to perform forwarding.
We will not go over the forwarding and bypass mechanism since they have been entirely removed from the OoO design and, therefore, are irrelevant to this article.

== Execution Stage

The CVA6, being a modular CPU, has multiple functional units (FU) that will be disabled or not depending on the configuration. First, it has a maximum of 5 write back ports. The first one is shared between all the fixed latency units which are: ALU, Branch unit, CSR buffer, Multiplier and Division. The division is the only one that's not fixed. The multiplier lasts 2 cycles and the CSR buffer blocks the write back until this instruction has been committed. As for the other FUs, they have no particularity and last one cycle. The next two write back ports are for the load and store units, coming from the load store unit (LSU).
The fourth port is only synthesized if the floating point operations are enabled or if the superscalar configuration is enabled. In one case it writes back the floating point unit results and in the other the second ALU results. It is worth noting that the FPU is not officially supported in superscalar mode (issue_read_operands.sv line 875).
Finally the last write back port is only synthesized if a coprocessor is connected to either the accelerator or the CV-X-IF channel. Both cannot be instantiated at the same time since they share the same write back port. Moreover the accelerator is not officially supported in superscalar mode as stated in the original codebase (cva6.sv line 1850).


== Load Store Unit (LSU)

#figure(
  image("lsu.png", width: 120%),
  caption: [LSU instruction flow],
) <fig-lsu>

This is the final module of the original design that will be detailed. It handles all the memory operations. It is composed of multiple submodules: *Memory Management Unit* (MMU), *Physical Memory Protection* (PMP), *lsu_bypass*, load unit, store unit and a store buffer. In order to understand what really changed from one design to another we will need to detail the instruction flow in the LSU. First, instructions are added to the *lsu_bypass* which is a simple First In First Out buffer. One instruction is dispatched per cycle with fall-through enabled. When an instruction is dispatched, the corresponding unit starts the translation by sending the virtual address to the MMU. From that point the behavior differs between the load and store unit. First we will take a look at the store unit. It simply waits for the response of the PMP and writes back immediately upon reception. If an exception has occurred the instruction is not added to the store buffer. Otherwise it is added to the speculative queue of the store buffer. When a commit signal is received, the instruction is transferred from the speculative queue to the commit queue and the request is sent to the cache in order.
As for the load unit it is a bit more complicated. The data cache is virtually indexed, physically tagged (VIPT): the index used to select the cache set only uses bits that are inside the page offset, and these bits are the same in the virtual and in the physical address. So the load unit sends the index to the cache at the same time as the start of the translation, and the cache can start reading the set. It is an optimization to gain 1 cycle. When the physical address is received, if an exception has occurred we write back the exception data and cancel the request. Otherwise the tag of the physical address is sent to the cache which completes the access. If the translation is not ready (TLB miss) the request is also cancelled and replayed later. When the data is received we write it back the same cycle.
For both units the write back goes through a shift register. It helps with lengthy data paths. The store shift register is usually disabled because the timing does not require it. However the load shift register is necessary because traversing the cache and the execute stage all the way to the issue stage and scoreboard, to then perform forwarding, is not possible due to timing constraints.
It is worth noting that even on bare metal, when no MMU is synthesized, to keep compatibility between different configurations, instructions have to spend one cycle in the MMU.
Finally the load and store units also communicate in order not to send a load to the cache if a store needs to write to that same address before. It only blocks the load and does not perform any sort of store-to-load forwarding.


= Out of Order Design

In this section we will go over the implementation of the Out of Order execution. First we will explain how the different modules developed work and then how they are linked by looking at the global design. There are 3 new modules: a *register allocation table* (RAT), *reservation stations* (RS) and a *load store queue* (LSQ). There is also the *Reorder Buffer* (ROB) which reuses a lot of the old scoreboard code.

== Register Allocation Table

The register allocation table renames instructions sent from the decode stage. It keeps a table with the correspondence between architectural registers and physical registers as well as a list of available registers. Each instruction is given a new destination register picked among the available registers and all the operands are renamed by the physical register holding the real value of the architectural one.
There are 2 types of RAT, the commit RAT and the speculative RAT. The speculative one is updated speculatively every time an instruction is renamed. The commit RAT is updated only when an instruction is committed. It allows us to restore the RAT state in one cycle after an exception by simply replacing it by the commit RAT data.
It is a very simple module. However there is one important optimization used to reduce the critical path. In superscalar mode, the RAT uses 2 priority encoders in cascade to elect 2 free registers that will be used as a destination for the renamed instructions. This step is registered. The two registers are elected using the registered correspondence table minus the registers allocated in the current cycle. Then, the next cycle, the elected registers are either the currently selected ones from the registered correspondence table or the previously selected ones if they were not used for some reason (for example the ROB is full).
This optimization evicts the priority encoder cascade from the issue stage critical path. The only downside is that a freed register becomes available 1 cycle later.

== Reservation Station

The reservation station (RS) tracks all the dependencies for each instruction inside it. Each operand of each instruction has a bit attached saying if it is available or not. Validity is updated in various ways. The first one is using a table called *is_result_available*, updated each cycle within the issue stage and sent to all the units in need of it. This structure keeps track of which physical register has a valid value. However it is registered so it takes one cycle to update and then one cycle for the RS to update its dependencies. This is why we also update the dependencies based on write backs received this cycle by snooping the *Common Data Bus* (CDB). We also check RAW dependencies between the 2 newly renamed instructions in the superscalar configuration. And finally, we implemented an early wakeup only for fixed latency single cycle instructions. This means we update dependencies based on currently dispatched instructions. For example, if an add is issued, we know its result will be ready next cycle so we already mark it as such. It is very useful: since the dependency state of each operand is registered, we gain one cycle for each fixed single cycle latency operation.
All these updates are computed in parallel and in the end a final mux selects the right value for each operand and each entry in the reservation station with a priority: RAW updates > early wakeup > write back > is_result_available.
In order to add an instruction to the RS we use a cascade of two priority encoders like in the RAT. And to choose which one to issue we use one tournament tree to compare the id of each instruction and elect the oldest ready one.
This module also has a *fall-through* mode in which an instruction renamed this cycle can be dispatched the same cycle only if is_result_available already marks all its operands as ready. It lengthens the critical path by a small margin but gains performance.

== Reorder Buffer

The ReOrder Buffer (ROB) is a central data structure which is similar to a scoreboard but with more features. Like the scoreboard it holds status information for every instruction and commits them in order. But in Out of Order we need to store more information and also have access to more information. For example, in our design we have a number of physical registers greater than the number of architectural registers. And thanks to the renaming we can write data into the registers as soon as the data is produced whereas in the original design results are written during the commit stage. This change means we need new logic in the ROB to extract the destination register for each write back port. But the real new job of the ROB is to control the *rollback*. In an Out of Order pipeline, if a branch misprediction occurs we have to roll back to a state before the branch and undo the changes made by the speculative instructions as well as squash the speculative instructions still executing. The ROB is the module that pilots this signal. It sends a signal to the controller which stalls the front-end (PC, Fetch, Decode) and then sends the rollback information to all the modules in need of it. This includes the RS, LSQ_bypass, RAT, LSQ as well as all functional units. This also means the ROB needs to store information such as the architectural destination register of each instruction or the previous physical register holding the real value of the architectural register.

== Load Store Queue (LSQ)

#figure(
  image("lsu_OoO.png", width: 125%),
  caption: [OoO LSU instruction flow],
) <fig-lsu-ooo>

This is the biggest module implemented for this design so we will spend more time explaining the design choices. It is instantiated inside the LSU and replaces the lsu_bypass as well as some functionality previously handled by the load/store units.
Let's break down the new instruction flow inside the LSQ and LSU. First, the LSQ can receive up to two instructions per cycle in superscalar configuration. When instructions are received, they are added to either the *load queue* or the *store queue* which are 2 distinct data structures of equal size. The store queue is a circular buffer whose pointers rely on natural binary wrap-around, which restricts its size to powers of two. Store commit being in order allows us to use such a data structure. As for the load queue, since loads can be retired from the queue out of order, we cannot do the same. It is managed using a free list and a cascade of two priority encoders to elect a free entry. Thus it is not required to be a power of two. But the current design has only one parameter shared between the 2 queues. Instructions dispatched to the LSQ can either have their data valid (virtual address for loads and stores and data to store only for stores) or not. If they do not have all their data valid then the LSQ snoops the CDB for them starting the same cycle that the instructions are being dispatched. Then, during the same cycle, we elect the instruction to be sent to the MMU. This means that for each instruction (including the ones dispatched this cycle) we check the virtual address validity and, using an *age matrix*, we compare the age of the instructions and elect the oldest one.
Then, when the virtual address is translated, it goes through the PMP which is only combinational and verifies potentially unauthorized accesses. During this cycle, we verify address dependencies between stores and loads, and from now on the behavior varies between store operations and load operations. Store operations always write back at this moment as in the original design. If an exception has occurred the instruction is flagged as invalid and the store queue entry is freed. If no exception occurs it is flagged as valid and will be sent to the store unit in order when a store commit is received. The speculative queue in the store buffer has been removed so it is immediately inserted in the commit queue of the store buffer. This also means that the store unit is basically useless as it does nothing meaningful. But it was kept for simplicity. Stores are freed from the LSQ only when they have been successfully sent to the cache. We cannot release them before without missing potential address dependencies between loads and stores.
Now let's take a look at the load instruction flow. If an exception occurs they will be flagged as result ready and the result will be written back next cycle (here the result is the exception information). If no exception occurred, we verify address dependencies with all older stores, perform store-to-load forwarding if necessary (only with same width operations), block the instruction in case of partial address match and, finally, if no match has been found or not all previous stores have their address translated we flag this load as valid. We then send the oldest load to the load unit. This new flow implies that the old optimization where the cache index is sent before the translation is no longer used. We even suppressed the handshake with the HPD cache to gain one cycle since we don't need the handshake anymore. When the result is received we store it in the LSQ and send the result the next cycle. This mechanism replaces the load shift register which is now disabled in OoO. If a load has been sent to the load unit before all previous stores had a valid physical address, we cancel it if a dependency is found later. This also means we do not write back until all dependencies have been resolved. But this happens extremely rarely since address translation is done by starting with the oldest instruction.

= Global overview

#figure(
  image("Issue_stage_edited.png", width: 100%),
  caption: [Issue stage instruction flow],
) <fig-issue-stage>

Now that we have seen in detail all the OoO modules, we will discuss the global design.
You can see above a simplified version of the issue stage. It lacks some small details but retains the important flow and stays simple.
First, instructions are issued from the decode stage. They are immediately renamed by the speculative RAT. Renamed instructions are then sent to the RS, ROB and LSQ_BYPASS where they are added to the ROB if it is not full and to the corresponding RS or to LSQ_BYPASS in case of memory operations.
There is one RS (RS0) for the fixed latency units write back port and one for the ALU2 (RS1) in superscalar configuration. It was done so each reservation station can elect one instruction for its write back port and maximize the usage in dual issue while maintaining a healthy timing by not having one big RS. But this means we have to ensure a relatively even dispatch of instructions between the two RS, which both can store ALU operations. We do this by always adding ALU operations to the RS1 first. Then if there is another ALU instruction the same cycle we store it in the RS0. This simple method proved itself very effective, even more than a version optimized for an even distribution between the RS.
As for the rest of the write back ports, the LSQ_BYPASS plays the role of a stripped down reservation station.
It is a simple module that stores memory operations in order and shows them as candidates to the top-2 tournament tree, also in order. It possesses a fall-through mode just as the RS but unlike them it can present up to two instructions per cycle to the tournament.
The protocol we chose to issue instructions to the load store queue is *token based* and works differently for stores and loads. For loads the number of tokens is updated based on write backs and rollbacks. Meaning the token counter is updated combinatorially in the same cycle and then also used the same cycle. Once the token count is updated, we only add a load to LSQ_BYPASS if a token is available. The potential issue is that a load would block the front-end because of a lack of tokens while there is still space in LSQ_bypass. But our measurements showed this particular scenario frequency only ranged from 0% to 4.4% of the time depending on the benchmark across all configurations. Plus this choice was made to allow the use of a combinatorially updated token counter. Otherwise it would not fit in the tight timing constraint of the instruction selection path.
As for store operations, the token update is done upon reception of a signal from the LSQ because only this module knows when a store has successfully been sent to the cache. The update is registered in the LSQ as well as in the issue stage to cope with the lengthy critical path. And unlike the load insertion, the token number is decreased only when a store has been elected to be dispatched. Thus, we do not have the same issue as with the load tokens.
In addition to these data structures, as mentioned previously, whenever an instruction is renamed and successfully added to the corresponding units, a small buffer named *is_result_available* updates which physical register has a valid value. It is crucial to verify dependencies in the reservation stations and to determine if an instruction sent to the LSQ already has valid data or a valid address, or if it needs to be snooped by this module.
After all modules have sent their candidates to the tournament, 2 instructions are elected and sent to IRO. A part of the data required to form the data payload is sent from LSQ_BYPASS or the RS and the rest is fetched from the ROB. This separation helps reduce the critical path by not waiting for the ROB data to compute all the early information in IRO.
Finally another advantage of this architecture is that the renaming ensures that the destination register of an instruction is no longer needed. This means we can write into the register bank as soon as the result is ready and remove the old forwarding system. We replace it by a very simple comparison between the registers to write this cycle and the registers to read the same cycle.

= Results and Analysis

We will now present the results obtained with this design through various configurations. We will discuss IPC gains, LUT consumption, and timing.
The design has been synthesized on a Digilent Zybo Z7-20 (Xilinx Zynq-7020) using the tools provided in the Thales CVA6 softcore contest GitHub repository [2].
Except for the OoO parameters, the rest of the CPU configuration is identical across all versions. It is in 32-bit mode with no FPU and no MMU but with non-idempotent memory enabled, and the HPD cache is used. As for the OoO parameters, here is the list:
- Number of physical registers
- Reservation stations size
- Number of rolled back instructions per cycle
- LSQ_BYPASS size
- LSQ size (same for the load queue and store queue, and must be a power of 2)
- Fall-through for RS and LSQ_BYPASS

As for the parameters used for the configurations tested, it was decided mainly by the synthesis results and the usefulness. But we did have some guidelines that helped pick the size of each data structure. For the number of physical registers we followed the rule: number of architectural registers + size of the ROB (the number of architectural registers being 32 on RISC-V). For the RS we chose half of the size of the ROB. So for example with a ROB of 16 entries we will have 2 RS of size 4. The size of the rollback is arbitrarily set to 2. The LSQ_BYPASS and LSQ are set to the same size as the RS. And the fall-throughs are all enabled. Finally the measurements are done using a ROB size of 8 and 16 to see how the increased context can help the out of order execution. A recap of the configurations is shown here (@tab-config) along with some design information.

#fig_config

All the configurations are tested on 3 benchmarks that show different types of workload. The fast Fourier transform (FFT) which is mainly computations with very few big chains of dependencies. A small convolutional neural network (MNIST) which relies heavily on memory operations. And finally CoreMark which contains a lot of branches.
The performance data are measured on the FPGA after flashing the design and all benchmarks have been compiled with GCC 15.2.0. The timing data are measured with Vivado reports in out of context mode with the same parameters, and LUT consumption is measured with the post-implementation report from Vivado for the whole CPU numbers (@tab-area-stages) but in out of context mode for the core numbers (all the other figures). Finally the performance counters are measured in simulation using Questa.
Throughout this analysis all configurations will be mentioned but we will mainly focus on the superscalar OoO configuration with a ROB16 which is the subject of this article, the most effective configuration and the focus of the development.


== Instructions per cycle (IPC)


First let's take a look at the results we obtained from an IPC gain standpoint. You can see the raw IPC of each benchmark for each configuration as well as their speedup compared to the base configuration here (@tab-cycles and @tab-speedup). All the OoO versions perform better than their in-order counterpart on all benchmarks except for the superscalar version with a ROB size of 8 (@tab-ooo-vs-io). This version is heavily bottlenecked by the number of physical registers (between 3% and 20% of the time as shown here @tab-sim-cycles). This is because the formula we used to compute the number of physical registers needed does not take into account the pre-allocation in the RAT as well as the latency of liberation. For the registers to never be an issue we would need to have 32 + ROB + 4 physical registers. We measured the impact of increasing the number by 4 (@tab-phys-reg). The results are modest because the bottleneck has now shifted to other structures, mainly the LSQ. This problem is shared between the two ROB 8 configurations. The small window on all data structures does not allow extracting the parallelism of the running program. As for the single issue configuration with a ROB of size 16 shows good gains for all benchmarks. FFT reaches 0.837, CoreMark 0.779 and MNIST even reaches 0.891 IPC. For a single issue configuration with a maximum theoretical IPC of 1 it is a good result. We are mostly bottlenecked by the single issue.

#fig_speedup

However, in some cases, the OoO configuration can even perform worse than the in-order version. When the data structure sizes do not allow for parallelism, not only do we see no gain but the downsides of the OoO architecture, such as rollback or the latency of dependency updates (load-to-use latency for example), can add up and ruin the potential gains.
But there is one configuration performing best by far: the dual issue ROB 16 superscalar, by a factor of 1.32 when compared to its in-order counterpart (@tab-ooo-vs-io). We will now take a closer look at this configuration and try to explain the results.


The OoO gain is set by how badly the in-order core handles their latencies and by which machine resource they hit first. So let's analyze the benchmarks (@tab-benchmarks). FFT is already performing very well in the in-order single issue configuration with an IPC of 0.77. This is because 40% of the operations had their sources computed more than 16 instructions earlier. Thus, the in-order core rarely stumbles upon short chains of dependencies. The dual issue mode and the OoO design extract a little more IPC. But the OoO version suffers from a big store bottleneck. This benchmark has 13.7% of stores and stores wait for a token 40% of the time. Doubling only the LSQ raises FFT IPC by 4.1% and store credit stalls fall from 40% to 10% of cycles, but the bottleneck moves to the ROB, blocked by stores waiting for the single-store-per-cycle drain. This means that the design is probably restricted by the single issue cache. A dual issue cache could probably significantly improve the performance.

#fig_benchmarks
#fig_sim_cycles

The next benchmark is MNIST. This is by far the best performing, mainly because it is memory intensive (45.5% of loads). This is both the worst in-order scenario and the best Out of Order scenario. In OoO we can exploit the load latency and make use of the short chains of instruction dependencies (about 38% between 2 and 4 instructions of length) where the in-order core struggles a lot. This benchmark ends up as the one with the best IPC by a fair amount with 1.4 and few visible bottlenecks due to the data structure size. The only visible one is the load queue being full about 10% of the time.
CoreMark is the last benchmark and shows a different picture. It is heavily branched (17.9% of branches) and with an 11.5% misprediction rate we have one misprediction every 49 instructions. This penalizes our CPU not only because of the multicycle rollback (about 2 cycles of rollback on average) but we also have to refill the ROB and all the data structures again to make use of the OoO design. So the front-end and the branch prediction end up being the biggest bottleneck of this benchmark.

Now let's compare this configuration to the in-order superscalar ones.
The first thing we notice is that the base CVA6 has the same performance regardless of the scoreboard size so we will ignore the configuration with a scoreboard of size 16.
In @tab-ooo-vs-io-sb8 we can clearly see the performances compared at the same clock frequency and then at their own maximum clock frequency. The results are rather mixed. When compared at the same clock frequency the OoO clearly outperforms the in-order core by an average of *+32%*. But when compared each at their own clock frequency, the average drops down to only *+5%*. The MNIST benchmark still shows great gains with +28.6% but both FFT and CoreMark are at a loss.

#fig_ooo_vs_io_sb8

However, these benchmarks do not show the biggest strength of the OoO, the ability to hide the cache miss latency. They all fit entirely in the data cache so this is never observed. We made a short program to test this with 3 functions iterating over an array bigger than the data cache. The first function iterates over the array by steps of 64 bytes and thus reads one element per cache line (stream). This causes regular independent cache misses. The second function does a sum but using precomputed addresses chosen seemingly at random (gather). This causes irregular independent cache misses. The last one always uses the data of the previous load (pointer chasing). The OoO core ends up *1.62×* faster in cycles (*1.28×* at Fmax) when cache misses are independent (stream, gather), because it overlaps several misses. When each address depends on the previous load (pointer chasing), it is 6% slower, paying a longer load-to-use latency. To sum it up, the OoO core clearly outperforms the in-order core in benchmarks where data latency and cache misses play a big role, which is exactly the main purpose of this architecture.

== LUT consumption

After analyzing the performance we also have to take into account the design area. The OoO core uses significantly more LUTs in every configuration. To identify where the main source of LUT consumption is, we will take a closer look at the changes between In order and Out of Order shown here (@tab-area-stages). The LSQ alone represents about 52% of the global LUT increase compared to the In Order SB8. It is no surprise, it is full of associative structures that map poorly to LUTs. The Scoreboard/ROB also sees a big increase. In the original design, few accesses to its data were necessary. The accesses were needed to perform write back, forwarding or issue/dispatch/commit instructions. But now the rollback needs to iterate over the entire structure and the write back also needs to access the destination registers to write into the right register. This added logic has a cost. It is probably the part that could benefit the most from a refactor. Some data are never accessed multiple times. So a portion of the ROB could be turned into LUTRAM to save some space. Finally the reservation stations, LSQ_bypass and register allocation tables are pretty cheap.

#fig_area_stages

Overall, in the superscalar ROB16 configuration, the design can present small congestion spots, especially around the LSU. The design when fully implemented uses 42,099 LUTs out of the 53,200 LUTs available on the Zybo Z7-20. And the OoO data structures now represent 55.6% of the core (@tab-area-ooo).


It is clear that the LUT consumption is a lot bigger, especially when comparing the ROB 16 OoO superscalar with the in-order SB 8 superscalar (@tab-ooo-vs-io-sb8). It is a fair comparison since the in-order version has the same performance with a scoreboard equal to 8 or 16. If we account for Pollack's rule, which states that the performance increase from micro-architectural improvements is roughly proportional to the square root of the increase in complexity (processor logic area), the result is to be expected. The OoO superscalar ROB16 configuration consumes 1.84 times more LUTs than the in-order superscalar configuration. The square root of 1.84 is approximately 1.36 which is almost the same as the geometric mean we obtained (1.323). Plus we have to bear in mind that the processor was synthesized on an FPGA. Data structures such as CAM memories, which are heavily used in the LSQ, and associative structures in general that are used throughout the design are way more optimized on ASIC than on FPGA and thus consume less logic area.


== Timing analysis

We already established that the design has good performance, with a reasonable area increase, but is held back by its clock frequency. So let's see why the timing is so tight.
First, let's take a look at the critical path of the original design.
The single issue SB8 configuration starts in the scoreboard, commits an instruction then ends in it.
As for the other configurations, they always start from the PMP and can end, for example, in lsu_bypass to validate the dispatch to the load unit in the case of single issue mode. Or, for the superscalar version, it can end in the scoreboard where it validates or not the addition of a new instruction as well as compares the operands of the newly added instruction. This is because the PMP response triggers a write back the same cycle for stores. Note that this path is actually not necessary. The write back is necessary to validate a commit and send exception data to the scoreboard but we do not need to compare operands since a store does not return any value. But this is not an issue for us since we will be comparing the OoO version to the in-order version with a scoreboard size equal to 8. And the critical path previously mentioned only appears because of the scoreboard size and the increased number of comparators due to the dual issue mode.
Now let's take a look at the OoO version critical path. The single issue ROB8 configuration critical path is similar to the original design, it starts from the PMP and ends in the cache. It can be explained because it only needs one small RS and a small LSQ_bypass as well as fewer comparators due to the single issue mode. And for the single issue ROB16 configuration the critical path becomes the bypass translation -> same cycle issue in the LSQ and ends in the cache.
For all superscalar versions, the critical path is the selection of the next instruction to dispatch in the issue stage and varies very little in length with RS size changes or ROB size changes. As shown by the superscalar version with ROB8 which has the same timing as the one with ROB16 but with every data structure length divided by two (the slight increase in data path is very likely due to Vivado run-to-run variance and the fact that the design is very congested). It is to be expected from our design: the selection of an instruction becomes an essential part of the pipeline, especially with fall-through enabled. The instruction has to be renamed, go through the dependency check, the tournament tree and read the registers as well as perform forwarding, all in one cycle. Now let's take a closer look at the superscalar version with a ROB size of 16 which is the subject of this article.
We can try to shorten this path by reducing the size of the RS or LSQ_bypass. But it would only hurt performance, at least for the reduction of the RS size. As shown here (@tab-sim-cycles) the RS can end up full for up to 7% of the time. Moreover the gain in clock time would be either non-existent, as shown by the ROB8 configuration critical path, or negligible because of the second critical path of the design.
When the fall-through is completely disabled, the critical path becomes the translation bypass and issue in the same cycle to the load unit (@tab-ablation-timing).

This is also an expensive path (@tab-ablation-perf). It needs to go through the PMP, to the LSQ, then to the load unit, the cache where we get a cache hit and the data is sent back to the load queue.
But it earns more IPC than it loses clock frequency. Note that even when the fall-through and the translation bypass are entirely disabled, the issue stage path is still around *23 ns* which means it is still a big bottleneck in terms of timing despite all the already implemented optimizations to reduce it, such as multiple RS to reduce their length, precomputed registers to evict the RAT from the critical path or even a top-2 tournament tree to avoid a cascade of two top-1 tournament trees. And reducing the size of the data structures inside it would only hurt performance.

The final result is that this configuration, despite showing a good gain in IPC, proves itself useful only on memory intensive applications such as MNIST or when the data is large enough to provoke cache misses.
To improve the timing in a significant way we would probably need to modify heavily the current design.
We could probably add a new stage by splitting the issue stage in half. One stage would only manage the allocation and the other the dispatch. This would cut this critical path almost in the middle (the tournament tree appears around 12.5 ns in the timing report).
As for the critical path induced by the translation bypass in the LSQ, it could be shortened easily. Currently, we wait to resolve dependencies between loads and stores before dispatching to the load unit. We could ignore that verification. When a load is translated, we flag it as valid as soon as the physical address is received and no exception has occurred. And 1 cycle later we cancel it if a dependency has been found. We still perform forwarding the same cycle when receiving the physical address of a store or a load and give this value precedence over cache data. And if the PMP costs too much time we can do the same and wait only the next cycle to cancel the faulty load. This means we lose time only when a partial match occurs, which never happens across all benchmarks. And if necessary we could implement byte-to-byte store-to-load forwarding to resolve this issue.


== Potential optimizations

To give an idea of the theoretical limit of this design we ran a simulation with these parameters: ROB=32, Rollback=8, REG=70, LSQ_BYPASS=8, LSQ=8, RS=8. This configuration consumes more than 60,000 LUTs for the core only and we could not get accurate timing data since the implementation did not finish, but it is safe to assume that the critical path would exceed 30 ns. This version could not even get an average of +10% IPC (@tab-scaling). FFT gains the most with its store drain bottleneck greatly reduced (stores now wait for a token 22% of the time instead of 40%). MNIST shows good gains due to the larger windows, and CoreMark shows almost no gain, confirming it is heavily front-end bottlenecked (@tab-sim-cycles).
This simulation shows that the current configuration finds a good balance.

But it also proves that this design needs real modifications to be improved and we will go over some possible optimizations.
We could try to implement an early wakeup for loads which has a good upper bound gain (@tab-potential). We implemented a prototype with the results here (@tab-early-wakeup). On FFT the potential counter dropped from 10.5% to 6.75% but the IPC gain stayed below 1% (1.278 → 1.286). On CoreMark the potential counter dropped from 20% to 6% but again with no significant performance gain. And on MNIST from 23.3% to 17%, again with no real gain.
We could also extend the early wakeup from only fixed latency units to the multiplication. Just as the early load wakeup it has an interesting potential. But again this is an upper bound estimation calculated by checking if an instruction needs the result 1 cycle after the write back. It is possible that this operand is not the only one missing for the said instruction. And as seen with the early load wakeup the results can be mixed.

Another interesting modification could be adding a second address-translation port (duplicated PMP and, when enabled, a second DTLB lookup port). This would remove the contention between loads and stores on the single translation port, which accounts for up to 12–14% of load waiting time on FFT and MNIST. The PMP itself is purely combinational and easy to duplicate (≈1–2k LUTs). The main cost lies in the LSQ, which would have to select and process two translations per cycle on an already critical path. Since the data cache still accepts a single load per cycle, we expect a modest IPC gain (a few percent) unless a second cache load port is added as well.

To conclude, at this state, almost all easy optimizations have been done. We have seen that increasing data structure sizes even to a very high degree provides a small return in IPC/LUT or in IPC gains at maximum clock frequency. We have seen that decreasing data structure sizes does not return enough clock frequency to justify the loss in IPC. The only way to really push this design forward would be to implement big modifications: dual issue MMU and PMP, dual issue cache, speculative loads with replay or even a run-ahead mode. And timing-wise, a new stage and a refactoring of the LSQ. Moreover, simulation data shows a front-end bottleneck (between 3% and 17%), indicating that a deep rework of the design would be necessary to improve the current design and modifications should go beyond the issue stage and execute stage.

== Conclusion

This article serves as an interesting experience: implementing an Out of Order design on a small RISC-V CPU to see the results and try to identify the potential gains and limits. The implementation is successful, the results are good and show the real gain of the OoO architecture even on a small CPU. However, the FPGA platform holds back its potential. The frequency penalties are heavier on FPGA, where routing dominates and associative structures map poorly to LUTs. Moreover, on an ASIC with a memory hierarchy several hundred cycles deep, the trade-off would shift towards OoO execution even more.

#pagebreak()

= Appendix: detailed results

#fig_cycles
#fig_ooo_vs_io
#fig_phys_reg
#fig_area_ooo
#fig_ablation_timing
#fig_ablation_perf
#fig_scaling
#fig_potential
#fig_early_wakeup

#pagebreak()

= References

*[1]* #link("https://docs.openhwfoundation.org/projects/cva6-user-manual/")[Official documentation of the CVA6 architecture by the OpenHW Group (https://docs.openhwfoundation.org/projects/cva6-user-manual/)]

*[2]* #link("https://github.com/ThalesGroup/cva6-softcore-contest")[Official GitHub repository of the CV32A6 softcore contest by Thales (https://github.com/ThalesGroup/cva6-softcore-contest)]

*[3]* #link("https://github.com/TelmoFieux/cva6-custom-reg-instr")[GitHub repository of the CV32A6 Out of Order (https://github.com/TelmoFieux/cva6-custom-reg-instr)]
