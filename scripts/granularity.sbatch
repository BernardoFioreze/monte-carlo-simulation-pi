#!/usr/bin/env bash
# Estudo de GRANULARIDADE e balanceamento (P fixo = 32).
# Compara a granularidade escolhida com uma bem menor e uma bem maior (GRAN_LIST).
# Submeta da RAIZ:  sbatch scripts/granularity.sbatch
#SBATCH --job-name=mc_gran
#SBATCH --nodes=2
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH --output=slurm-%x-%j.out

set -euo pipefail
source scripts/config.sh

P=32
OUTDIR="results/gran/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"
{ echo "MPI_BIN=$MPI_BIN  N_REF=$N_REF  P=$P  REPS=$REPS"; echo "GRAN_LIST=$GRAN_LIST"; echo "nós: $SLURM_JOB_NODELIST"; } | tee "$OUTDIR/info.txt"
lscpu > "$OUTDIR/lscpu.txt" || true

for G in $GRAN_LIST; do
  for r in $(seq 1 "$REPS"); do
    out="$OUTDIR/gran${G}_rep${r}.out"
    echo "[gran] G=$G rep=$r -> $out"
    mpirun -np "$P" "$MPI_BIN" "$N_REF" "$G" > "$out" 2>&1
  done
done

echo "Concluído. Saídas em $OUTDIR"
python3 scripts/summarize.py "$OUTDIR" | tee "$OUTDIR/resumo.txt" || true
