# Makefile do T2 — compila a versão sequencial (referência T1) e a MPI.
# IMPORTANTE: as DUAS versões usam as MESMAS flags de otimização (exigência do enunciado).

MPICC    ?= mpicc
CXX      ?= g++
OPT      ?= -O2
CFLAGS   ?= $(OPT) -Wall -Wextra
CXXFLAGS ?= $(OPT) -Wall -Wextra

# >>> AJUSTE os caminhos dos fontes quando criar/adaptar o código. <<<
MPI_SRC  ?= Pi/MPI/montecarlo_mpi.c          # seu programa MPI mestre/escravo (a criar)
SEQ_SRC  ?= Pi/Serial/montecarlo_seq.cpp     # sequencial adaptado ao contrato (args + CHECK/TIME)

all: montecarlo_mpi montecarlo_seq

montecarlo_mpi: $(MPI_SRC)
	$(MPICC) $(CFLAGS) $< -o $@ -lm

montecarlo_seq: $(SEQ_SRC)
	$(CXX) $(CXXFLAGS) $< -o $@

clean:
	rm -f montecarlo_mpi montecarlo_seq

.PHONY: all clean
