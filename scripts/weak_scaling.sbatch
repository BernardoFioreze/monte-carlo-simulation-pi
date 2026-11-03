#!/usr/bin/env bash
# Escalabilidade FRACA: o trabalho POR ESCRAVO fica constante enquanto P cresce.
# No mestre/escravo só P-1 processos calculam (o 0 coordena), então N cresce ∝ (P-1),
# não ∝ P. Com GRAN fixo, o nº de tarefas cresce ∝ (P-1). Eficiência = T(P=2) / T_P.
# Submeta da RAIZ:  sbatch scripts/weak_scaling.sbatch
#SBATCH --job-name=mc_fraca
#SBATCH --nodes=4
#SBATCH --exclusive
#SBATCH --time=04:00:00
#SBATCH --output=slurm-%x-%j.out

set -euo pipefail
source scripts/config.sh

OUTDIR="results/fraca/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"
{ echo "MPI_BIN=$MPI_BIN  N_base=$N_REF  GRAN=$GRAN  REPS=$REPS"; echo "PLIST=$PLIST"; echo "regra: N_P = N_base * (P-1) (GRAN fixo => trabalho por escravo constante)"; echo "nós: $SLURM_JOB_NODELIST"; } | tee "$OUTDIR/info.txt"
lscpu > "$OUTDIR/lscpu.txt" || true

for P in $PLIST; do
  N_P=$(( N_REF * (P - 1) ))    # P-1 escravos computam => trabalho por escravo = N_base constante
  TASKS=$(( N_P / GRAN ))       # medida de trabalho: nº de tarefas (deve crescer ~(P-1))
  echo "[fraca] P=$P  N_P=$N_P  tarefas=$TASKS" | tee -a "$OUTDIR/info.txt"
  for r in $(seq 1 "$REPS"); do
    out="$OUTDIR/P${P}_rep${r}.out"
    echo "[fraca] P=$P rep=$r -> $out"
    mpirun --use-hwthread-cpus --map-by core -np "$P" "$MPI_BIN" "$N_P" "$GRAN" > "$out" 2>&1
  done
done

echo "Concluído. Saídas em $OUTDIR"
python3 scripts/summarize.py "$OUTDIR" | tee "$OUTDIR/resumo.txt" || true
