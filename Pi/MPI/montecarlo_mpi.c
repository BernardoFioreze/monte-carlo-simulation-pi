#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <mpi.h>

#define TAG_TAREFA    1
#define TAG_RESULTADO 2
#define TAG_STOP      3

static inline double u01(uint64_t *s) {
    *s ^= *s << 13;
    *s ^= *s >> 7;
    *s ^= *s << 17;
    return (*s >> 11) * (1.0 / 9007199254740992.0);
}

static inline uint64_t seed_from_id(long long id) {
    uint64_t z = (uint64_t)id + 0x9E3779B97F4A7C15ULL;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    z = z ^ (z >> 31);
    return z ? z : 0x9E3779B97F4A7C15ULL;
}

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc < 3) {
        if (rank == 0) fprintf(stderr, "uso: %s <N> <GRAN>\n", argv[0]);
        MPI_Finalize();
        return 1;
    }
    const long long N    = (long long)strtod(argv[1], NULL);
    const long long GRAN = (long long)strtod(argv[2], NULL);
    if (N <= 0 || GRAN <= 0) {
        if (rank == 0) fprintf(stderr, "erro: N e GRAN devem ser > 0\n");
        MPI_Finalize();
        return 1;
    }
    if (size < 2) {
        if (rank == 0) fprintf(stderr, "erro: precisa de >= 2 processos (1 mestre + 1 escravo)\n");
        MPI_Finalize();
        return 1;
    }

    if (rank == 0) {
        const long long num_task = (N + GRAN - 1) / GRAN;

        long long *resultado = (long long *) calloc((size_t) num_task, sizeof(long long));
        if (resultado == NULL) {
            fprintf(stderr, "erro: sem memoria para %lld tarefas\n", num_task);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        long long next = 0;
        long long received = 0;

        double t0 = MPI_Wtime();

        for (int i = 1; i < size; i++) {
            if (next < num_task) {
                MPI_Send(&next, 1, MPI_LONG_LONG, i, TAG_TAREFA, MPI_COMM_WORLD);
                next++;
            } else {
                MPI_Send(&next, 1, MPI_LONG_LONG, i, TAG_STOP, MPI_COMM_WORLD);
            }
        }

        while (received < num_task) {
            long long res[2];
            MPI_Status status;

            MPI_Recv(res, 2, MPI_LONG_LONG, MPI_ANY_SOURCE, TAG_RESULTADO, MPI_COMM_WORLD, &status);

            resultado[res[0]] = res[1];
            received++;

            int origem = status.MPI_SOURCE;
            if (next < num_task) {
                MPI_Send(&next, 1, MPI_LONG_LONG, origem, TAG_TAREFA, MPI_COMM_WORLD);
                next++;
            } else {
                MPI_Send(&next, 1, MPI_LONG_LONG, origem, TAG_STOP, MPI_COMM_WORLD);
            }
        }

        double t1 = MPI_Wtime();

        long long inside_total = 0;
        for (long long id = 0; id < num_task; id++) inside_total += resultado[id];
        free(resultado);

        printf("CHECK=%lld\n", inside_total);
        printf("TIME=%.6f\n", t1 - t0);
        printf("PI=%.10f\n", 4.0 * (double) inside_total / (double) N);

    } else {
        while (1) {
            long long id;
            MPI_Status status;

            MPI_Recv(&id, 1, MPI_LONG_LONG, 0, MPI_ANY_TAG, MPI_COMM_WORLD, &status);

            if (status.MPI_TAG == TAG_STOP) break;

            long long start = id * GRAN;
            long long count = (N - start < GRAN) ? (N - start) : GRAN;

            uint64_t s = seed_from_id(id);
            long long inside = 0;
            for (long long k = 0; k < count; k++) {
                const double x = u01(&s);
                const double y = u01(&s);
                if (x * x + y * y <= 1.0) inside++;
            }

            long long res[2] = { id, inside };
            MPI_Send(res, 2, MPI_LONG_LONG, 0, TAG_RESULTADO, MPI_COMM_WORLD);
        }
    }

    MPI_Finalize();
    return 0;
}
