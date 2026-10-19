// =====================================================================================
//  membench.c : micro-benchmarks de defauts de cache, bare-metal RISC-V (rv32 / rv64)
//  Trois noyaux qui ne different que par la DEPENDANCE entre les defauts :
//    1. stream  : parcours sequentiel        -> defauts independants et previsibles
//    2. gather  : sum += A[idx[i]] aleatoire -> defauts independants, imprevisibles
//    3. chase   : p = next[p] aleatoire      -> defauts DEPENDANTS (en serie)
//  L'OoO doit gagner nettement sur gather (il lance plusieurs defauts en parallele),
//  un peu sur stream, et rien sur chase (chaque adresse depend du load precedent).
//
//  Taille : la RAM programme de la plateforme fait 192 Kio (0x80000000-0x80030000,
//  BRAM on-chip) : tableau + index + code + pile doivent y tenir. ARRAY_BYTES doit
//  quand meme etre nettement plus grand que le D$ (verifier la config hpdcache).
//  Un seul tableau A sert aux 3 noyaux : il contient une permutation (Sattolo) qui sert
//  de valeurs pour stream/gather et de "pointeurs" pour chase.
//  Compilation : meme environnement que CoreMark / MNIST (crt, syscalls, printf).
// =====================================================================================
#include <stdint.h>
#include <stdio.h>

#ifndef ARRAY_BYTES
#define ARRAY_BYTES (80 * 1024)         // 80 Kio : 2.5x un D$ de 32 Kio, tient en 192 Kio avec le code
#endif
#ifndef ACCESSES
#define ACCESSES    (4 * 1024)          // acces mesures par noyau (idx[] = 16 Kio)
#endif

#define N ((uint32_t)(ARRAY_BYTES / sizeof(uint32_t)))

static uint32_t A[N];                   // permutation en un seul cycle
static uint32_t idx[ACCESSES];

// unsigned long = largeur du registre (32 bits en rv32 : mcycle bas, suffisant ici)
static inline unsigned long rdcycle(void)   { unsigned long v; asm volatile("csrr %0, mcycle"   : "=r"(v)); return v; }
static inline unsigned long rdinstret(void) { unsigned long v; asm volatile("csrr %0, minstret" : "=r"(v)); return v; }

static uint32_t rng = 2463534242u;                       // xorshift32
static inline uint32_t xorshift(void) { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return rng; }

static void report(const char *name, unsigned long c, unsigned long i, unsigned long chk) {
  // affichage en entiers (pas de float en bare-metal) : IPC x1000, cycles par acces x10
  printf("%s cycles=%lu instr=%lu IPCx1000=%lu cyc/acces x10=%lu (chk=%lu)\n",
         name, c, i, (unsigned long)((unsigned long long)i * 1000 / c),
         (unsigned long)((unsigned long long)c * 10 / ACCESSES), chk);
}

int main(void) {
  // ---- initialisation (non mesuree)
  for (uint32_t k = 0; k < ACCESSES; k++) idx[k] = xorshift() % N;
  // Sattolo : permutation en un seul cycle -> le pointer chase visite tout le tableau
  for (uint32_t k = 0; k < N; k++) A[k] = k;
  for (uint32_t k = N - 1; k > 0; k--) {
    uint32_t j = xorshift() % k;
    uint32_t t = A[k]; A[k] = A[j]; A[j] = t;
  }

  unsigned long c0, i0, chk;

  // ---- 1. stream : une ligne de cache = plusieurs elements consecutifs
  chk = 0; c0 = rdcycle(); i0 = rdinstret();
  for (uint32_t k = 0; k < ACCESSES; k++) chk += A[(k * 16) % N];  // pas de 64 o = 1 ligne
  report("stream", rdcycle() - c0, rdinstret() - i0, chk);

  // ---- 2. gather : adresses aleatoires connues a l'avance -> defauts independants
  chk = 0; c0 = rdcycle(); i0 = rdinstret();
  for (uint32_t k = 0; k < ACCESSES; k++) chk += A[idx[k]];
  report("gather", rdcycle() - c0, rdinstret() - i0, chk);

  // ---- 3. chase : l'adresse suivante est le resultat du load -> defauts en serie
  uint32_t p = 0;
  c0 = rdcycle(); i0 = rdinstret();
  for (uint32_t k = 0; k < ACCESSES; k++) p = A[p];
  report("chase", rdcycle() - c0, rdinstret() - i0, p);

  return 0;
}
