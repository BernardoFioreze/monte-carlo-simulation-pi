#!/usr/bin/env bash
# Escalabilidade FORTE: entrada de referência FIXA (N_REF), variando o nº de processos.
# Aloca 4 nós exclusivos (sempre os mesmos) e varia P dentro da mesma alocação, para o
# experimento ficar consistente. 4 nós E5520 = 32 núcleos físicos (P<=32 = 1/núcleo) e
# 64 threads lógicas (P=64 = HT). Submeta da RAIZ:  sbatch scripts/strong_scaling.sbatch
#SBATCH --job-name=mc_forte
#SBATCH --nodes=4
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH --output=slurm-%x-%j.out

set -euo pipefail
source scripts/config.sh

OUTDIR="results/forte/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"
{ echo "MPI_BIN=$MPI_BIN  N_REF=$N_REF  GRAN=$GRAN  REPS=$REPS"; echo "PLIST=$PLIST"; echo "nós: $SLURM_JOB_NODELIST"; } | tee "$OUTDIR/info.txt"
lscpu > "$OUTDIR/lscpu.txt" || true

for P in $PLIST; do
  for r in $(seq 1 "$REPS"); do
    out="$OUTDIR/P${P}_rep${r}.out"
    echo "[forte] P=$P rep=$r -> $out"
    # --use-hwthread-cpus: deixa o P=64 usar as threads lógicas (HT); --map-by core espalha
    # 1 processo por núcleo físico até P=32, só duplicando por núcleo quando P=64.
    mpirun --use-hwthread-cpus --map-by core -np "$P" "$MPI_BIN" "$N_REF" "$GRAN" > "$out" 2>&1
  done
done

echo "Concluído. Saídas em $OUTDIR"
python3 scripts/summarize.py "$OUTDIR" | tee "$OUTDIR/resumo.txt" || true
