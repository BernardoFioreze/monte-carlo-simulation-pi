#!/usr/bin/env bash
# Referência sequencial (T1): roda a melhor versão sequencial REPS vezes.
# Objetivo: obter T1 entre 30 e 60 s, com as MESMAS flags de otimização da versão MPI.
# Submeta a partir da RAIZ do repositório:  sbatch scripts/sequential.sbatch
#SBATCH --job-name=mc_seq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --exclusive
#SBATCH --time=00:30:00
#SBATCH --output=slurm-%x-%j.out

set -euo pipefail
source scripts/config.sh

OUTDIR="results/seq/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"
{ echo "SEQ_BIN=$SEQ_BIN  N_REF=$N_REF  REPS=$REPS"; echo "host: $(hostname)"; } | tee "$OUTDIR/info.txt"
lscpu > "$OUTDIR/lscpu.txt" || true

for r in $(seq 1 "$REPS"); do
  out="$OUTDIR/seq_rep${r}.out"
  echo "[seq] rep=$r -> $out"
  "$SEQ_BIN" "$N_REF" > "$out" 2>&1
done

echo "Concluído. Saídas em $OUTDIR"
python3 scripts/summarize.py "$OUTDIR" | tee "$OUTDIR/resumo.txt" || true
