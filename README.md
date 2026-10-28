# Monte Carlo Simulation for Pi

Estimativa de π pelo método de Monte Carlo. Este repositório contém **apenas a versão
sequencial**, que serve de base para o Trabalho 2 (T2): a implementação MPI mestre/escravo.

> As versões paralelas anteriores (Threaded, OpenMP e um esboço de MPI) foram removidas do
> working tree, mas continuam preservadas no histórico do git. Veja `CLAUDE.md` para as regras
> de trabalho neste repositório.

## Conteúdo

### 1. Versão sequencial — estimativa de π por Monte Carlo (C++)

Fontes em `Pi/Serial/`:

- `MonteCarloPi.cpp` — uma única rodada com `INTERVAL` amostras, imprimindo a estimativa a cada iteração.
- `MonteCarloPi2.cpp` — varre vários tamanhos de entrada (`1e3` … `1e9`) e imprime a estimativa final de cada um.

Compilar e executar:

```bash
g++ -O2 Pi/Serial/MonteCarloPi2.cpp -o montecarlo_pi
./montecarlo_pi
```

![demo](Pi/Graphs/Sequential%20-%20Iterations%20VS%20Pi.png)
![demo](Pi/Graphs/Sequential%20-%20Iterations%20VS%20Time.png)

### 2. Visualização com matplotlib (Python)

`Pi/Matplotlib/plot.py` plota a convergência da estimativa de π ao longo das tentativas.

10000 iterações
![demo](Pi/Graphs/10000.png)

100000 iterações
![demo](Pi/Graphs/100000.png)

100000 iterações (zoom)
![demo](Pi/Graphs/100000-2.png)
