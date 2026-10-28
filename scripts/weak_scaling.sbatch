#!/usr/bin/env bash
# Escalabilidade FRACA: o trabalho cresce na proporção de P, mantendo o custo por tarefa.
# Como GRAN (amostras por tarefa) é fixo, crescemos N na proporção de P -> nº de tarefas ~ P.
# Eficiência fraca = T1 / T_P (T_P = tempo com P processos e trabalho P vezes maior).
# Submeta da RAIZ:  sbatch scripts/weak_scaling.sbatch
#SBATCH --job-name=mc_fraca
#SBATCH --nodes=2
#SBATCH --exclusive
#SBATCH --time=04:00:00
#SBATCH --output=slurm-%x-%j.out

set -euo pipefail
source scripts/config.sh

OUTDIR="results/fraca/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"
{ echo "MPI_BIN=$MPI_BIN  N_base=$N_REF  GRAN=$GRAN  REPS=$REPS"; echo "PLIST=$PLIST"; echo "regra: N_P = N_base * P (GRAN fixo => tarefas ~ P)"; echo "nós: $SLURM_JOB_NODELIST"; } | tee "$OUTDIR/info.txt"
lscpu > "$OUTDIR/lscpu.txt" || true

for P in $PLIST; do
  N_P=$(( N_REF * P ))          # trabalho cresce na proporção de P
  TASKS=$(( N_P / GRAN ))       # medida de trabalho: nº de tarefas (deve crescer ~P)
  echo "[fraca] P=$P  N_P=$N_P  tarefas=$TASKS" | tee -a "$OUTDIR/info.txt"
  for r in $(seq 1 "$REPS"); do
    out="$OUTDIR/P${P}_rep${r}.out"
    echo "[fraca] P=$P rep=$r -> $out"
    mpirun -np "$P" "$MPI_BIN" "$N_P" "$GRAN" > "$out" 2>&1
  done
done

echo "Concluído. Saídas em $OUTDIR"
python3 scripts/summarize.py "$OUTDIR" | tee "$OUTDIR/resumo.txt" || true
