# Monte Carlo Simulation for Pi

Estimativa de π pelo método de Monte Carlo. Este repositório contém **apenas a versão
sequencial**, que serve de base para o Trabalho 2 (T2): a implementação MPI mestre/escravo.

> As versões paralelas anteriores (Threaded, OpenMP e um esboço de MPI) e os gráficos de
> resultados do repositório original foram removidos do working tree, mas continuam preservados
> no histórico do git. Veja `CLAUDE.md` para as regras de trabalho neste repositório.

## Conteúdo

### Versão sequencial (C++)

`Pi/Serial/montecarlo_seq.cpp` — baseline de referência (T1) do T2. Recebe `<N>` (nº de amostras),
usa um RNG xorshift inline, não faz I/O dentro do laço medido e imprime `CHECK=`/`TIME=`/`PI=`
(ver o contrato de interface abaixo). As versões anteriores (`MonteCarloPi*.cpp`) foram removidas
por não servirem como baseline honesto; continuam no histórico do git.

### Visualização (Python)

`Pi/Matplotlib/plot.py` plota a convergência da estimativa de π ao longo das tentativas
(pede o número de rodadas e mostra o gráfico com matplotlib).

## Rodando no cluster (T2 — MPI mestre/escravo)

Fluxo de trabalho: editar no notebook → `git push` → no cluster `git pull` → `make` →
`sbatch` → trazer os resultados de volta com `rsync`.

### 0. Contrato de interface do programa

Os scripts de medição assumem esta interface (ajuste em `scripts/config.sh` se a sua for diferente):

- MPI: `mpirun -np P ./montecarlo_mpi <N> <GRAN>`
- Sequencial: `./montecarlo_seq <N>`

E que **cada execução imprime duas linhas** (exigências do feedback do T1):

- `CHECK=<grandeza verificável>` — ex.: pontos dentro do círculo; tem que bater sequencial × MPI.
- `TIME=<segundos>` — no MPI, `MPI_Wtime()` no mestre, só da distribuição ao último resultado.

### 1. Sincronizar o código no cluster

```bash
# no cluster, uma vez:
git clone https://github.com/BernardoFioreze/monte-carlo-simulation-pi.git
cd monte-carlo-simulation-pi
# a cada mudança:
git pull
```

Se o cluster não tiver internet de saída, envie por `rsync` pelo ProxyJump, do notebook:

```bash
rsync -avz --exclude '.git' --exclude 'results' ./ atlantica:~/monte-carlo-simulation-pi/
```

### 2. Compilar

```bash
make        # gera montecarlo_mpi e montecarlo_seq (ajuste MPI_SRC/SEQ_SRC no Makefile)
```

### 3. Rodar as medições (as 10 repetições são automáticas)

Sempre a partir da **raiz do repositório**:

```bash
sbatch scripts/sequential.sbatch      # T1 de referência (ajuste N_REF p/ 30–60 s)
sbatch scripts/strong_scaling.sbatch  # escalabilidade forte (P = 2,4,8,16,32,64)
sbatch scripts/weak_scaling.sbatch    # escalabilidade fraca (N cresce na proporção de P)
sbatch scripts/granularity.sbatch     # granularidade/balanceamento (P = 32)
```

Os parâmetros (`N_REF`, `GRAN`, `PLIST`, `REPS`, `GRAN_LIST`) ficam em `scripts/config.sh`.
Cada job cria `results/<tipo>/<timestamp>/` com uma saída por execução, além de `lscpu.txt`,
`info.txt` e `resumo.txt`. Acompanhe a fila com `squeue -u $USER`.

### 4. Resumir e trazer os resultados

```bash
python3 scripts/summarize.py results/forte/<timestamp>   # mediana/mín/máx + confere o CHECK
```

Do notebook, para trazer os brutos de volta:

```bash
rsync -avz atlantica:~/monte-carlo-simulation-pi/results/ ./results/
```

Guarde `results/` e os arquivos `slurm-*.out` no repositório: são os tempos brutos da entrega.
