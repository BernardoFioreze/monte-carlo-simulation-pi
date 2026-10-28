// Estimativa de pi por Monte Carlo — versão SEQUENCIAL de referência (T1) do T2.
//
// Uso:   ./montecarlo_seq <N>
//        N = número total de amostras (pontos). Aceita "1000000000" ou "1e9".
//
// Imprime (contrato dos scripts de medição):
//   CHECK=<pontos dentro do círculo>   grandeza verificável (tem que bater com a versão MPI)
//   TIME=<segundos>                    só do laço de amostragem; o parse da entrada fica de fora
//   PI=<estimativa>                    informativo
//
// Decisões de desempenho (ver a validação feita antes de começar o MPI):
//   - RNG: xorshift64 inline (~3 ns/amostra), ~7x mais rápido que rand() e portável.
//     O MESMO gerador deve ser usado nos escravos MPI, senão o T1 fica injusto.
//   - Zero I/O dentro do laço (cout por iteração deixava a versão antiga ~200x mais lenta).
//   - Compile com as MESMAS flags da versão MPI (ver Makefile; -O2 já captura quase tudo).
//
// Equivalência com a MPI (a decidir na hora do MPI): como a amostragem é aleatória, o CHECK
// só bate bit a bit se cada tarefa usar uma semente determinística derivada do seu índice.
// Alternativa mais simples: definir equivalência por tolerância no valor estimado de pi.

#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <chrono>

// xorshift64: gera um double em [0,1) com 53 bits de mantissa. Estado != 0.
static inline double u01(uint64_t& s) {
    s ^= s << 13;
    s ^= s >> 7;
    s ^= s << 17;
    return (s >> 11) * (1.0 / 9007199254740992.0);  // 2^53
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "uso: %s <N>  (N = numero de amostras)\n", argv[0]);
        return 1;
    }
    const long long N = (long long)strtod(argv[1], nullptr);  // aceita 1e9 ou 1000000000
    if (N <= 0) {
        fprintf(stderr, "erro: N deve ser > 0\n");
        return 1;
    }

    uint64_t state = 88172645463325252ULL;  // semente fixa -> CHECK reproduzível
    long long inside = 0;

    const auto t0 = std::chrono::steady_clock::now();
    for (long long i = 0; i < N; i++) {
        const double x = u01(state);
        const double y = u01(state);
        if (x * x + y * y <= 1.0) inside++;
    }
    const auto t1 = std::chrono::steady_clock::now();

    const double secs = std::chrono::duration<double>(t1 - t0).count();
    printf("CHECK=%lld\n", inside);
    printf("TIME=%.6f\n", secs);
    printf("PI=%.10f\n", 4.0 * (double)inside / (double)N);
    return 0;
}
