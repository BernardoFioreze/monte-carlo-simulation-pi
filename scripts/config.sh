#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Configuração compartilhada pelos scripts de medição do T2 (MPI mestre/escravo).
# Todos os .sbatch fazem `source scripts/config.sh`.
#
# >>> AJUSTE OS VALORES DESTA SEÇÃO conforme o seu programa e o cluster. <<<
# ---------------------------------------------------------------------------

# Executáveis gerados por `make` (ver Makefile).
MPI_BIN=${MPI_BIN:-./montecarlo_mpi}      # seu programa MPI mestre/escravo
SEQ_BIN=${SEQ_BIN:-./montecarlo_seq}      # melhor versão sequencial (referência T1)

# Entrada de referência: nº TOTAL de amostras (pontos de Monte Carlo).
# Dimensione para o SEQUENCIAL ficar entre 30 e 60 s no nó do cluster.
# Base de cálculo: ~3 ns/amostra medido com o xorshift -> 30-60 s ~= 1e10 a 2e10 amostras.
# CALIBRE no cluster (CPU diferente): rode o sequential.sbatch e ajuste até cair em 30-60 s.
N_REF=${N_REF:-10000000000}

# Granularidade padrão: amostras por tarefa (quantas unidades vão em cada mensagem).
# nº de tarefas = N_REF / GRAN  -> deve ser bem maior que o nº de escravos.
GRAN=${GRAN:-1000000}

# Protocolo de medição (feedback do T1: 10 repetições, mediana/mín/máx).
REPS=${REPS:-10}

# Série de processos MPI (inclui o processo 0 = mestre).
# 2,4,8,16,32 = até 1 por núcleo físico (2 nós x 16); 64 = com Hyper-Threading.
PLIST=${PLIST:-"2 4 8 16 32 64"}

# Estudo de granularidade (P fixo = 32): uma bem menor, a escolhida, uma bem maior.
GRAN_LIST=${GRAN_LIST:-"10000 1000000 100000000"}

# ---------------------------------------------------------------------------
# CONTRATO DE INTERFACE que o seu código precisa respeitar para os scripts
# funcionarem sem alteração (o feedback do T1 exige grandeza verificável e
# região medida com MPI_Wtime):
#
#   MPI : mpirun -np P ./montecarlo_mpi <N> <GRAN>
#   SEQ : ./montecarlo_seq <N>
#
# Cada execução deve imprimir na saída padrão, uma por linha:
#   CHECK=<grandeza verificável>   # ex.: pontos dentro do círculo (tem que bater seq x MPI)
#   TIME=<segundos>                # MPI: MPI_Wtime() no mestre, só da distribuição ao último
#                                  #      resultado; SEQ: tempo da mesma região de cálculo.
#
# Se os argumentos ou os rótulos forem diferentes no seu programa, ajuste aqui,
# nos .sbatch e no regex do scripts/summarize.py.
# ---------------------------------------------------------------------------
