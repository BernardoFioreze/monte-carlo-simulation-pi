# CLAUDE.md

Guia de trabalho para a IA neste repositório. Leia antes de qualquer tarefa.

## Contexto

Repositório de estimativa de π por Monte Carlo. Era um fork com versões sequencial, Threaded,
OpenMP e um esboço de MPI. As versões **não-sequenciais foram removidas de propósito**: o
working tree agora tem só a versão sequencial (`Pi/Serial/`), que é a base para o **Trabalho 2
(T2): MPI mestre/escravo** no cluster Atlântica do LAD.

O enunciado está em `t2-mpi-mestre-escravo.pdf` e o feedback do T1 em
`t1-feedback-geral-turma.pdf`. **Eu (o aluno) vou escrever o MPI.** O papel da IA aqui é
orientar, revisar e tirar dúvidas — não entregar a solução pronta.

## Restrição principal: não use o histórico do git para o MPI

As implementações paralelas antigas continuam no histórico do git, mas foram tiradas de
propósito para eu aprender fazendo. Portanto:

- **Não** leia, recupere, reconstrua ou mostre o código paralelo removido a partir do histórico
  (`git log`, `git show`, `git checkout`, `git restore`, `git diff` de commits antigos,
  `git cat-file`, blobs, etc.), em especial o antigo `Pi/MPI/`, `Pi/OpenMP/` e `Pi/Threaded/`.
- **Não** use esse código antigo como fonte, base, "referência" ou inspiração para a minha
  implementação de MPI. A solução do T2 tem que sair da minha cabeça, com orientação sua.
- Operações normais de git no estado atual (status, diff do working tree, commit do meu trabalho)
  estão liberadas. A restrição é só sobre **ressuscitar as soluções paralelas antigas**.
- Se por algum motivo for mesmo necessário olhar algo do histórico, **pare e me pergunte antes**,
  explicando o porquê. O padrão é não olhar.

Ajuda esperada da IA: explicar conceitos de MPI, revisar o código que eu escrevi, apontar bugs,
sugerir como estruturar/medir, responder "o que essa chamada faz". Não: escrever o mestre/escravo
por mim nem colar a versão antiga.

## O que o T2 exige (resumo do enunciado)

Modelo **mestre/escravo** em C + MPI. Requisitos obrigatórios (seção 2 do enunciado):

1. Iniciativa é do escravo: cada escravo pede trabalho; cada resultado devolvido já vale como
   pedido da próxima tarefa.
2. Mestre (processo 0) recebe por ordem de chegada com `MPI_ANY_SOURCE`.
3. A ordem original do saco de tarefas é mantida: cada resultado volta para a posição de origem.
4. Saco vazio encerra os escravos com uma mensagem de término distinguida por **tag**.
5. Funciona com qualquer nº de processos (≥ 2) e qualquer nº de tarefas, sem exigir múltiplo.
6. Granularidade (unidades de trabalho por mensagem) é lida da **linha de comando**.

Medições (seção 5): escalabilidade **forte** (P = 2, 4, 8, 16, 32 e 64 com HT), escalabilidade
**fraca**, e estudo de **granularidade/balanceamento** com 32 processos. Região medida com
`MPI_Wtime()` no mestre, do início da distribuição até o último resultado (sem contar a
geração/leitura da entrada). T1 de referência = melhor versão sequencial, com as mesmas flags,
dimensionada para 30–60 s.

## Lições do feedback do T1 (aplicar desde já)

Estas foram as falhas mais comuns da turma; a partir do T2 os critérios são aplicados por inteiro:

- **Equivalência demonstrada, não afirmada.** Toda execução (sequencial e MPI) imprime uma
  grandeza verificável (checksum / contagem de pontos dentro do círculo / soma) e ela tem que
  coincidir. Se não bate bit a bit (ordem de soma em float), defina e verifique uma tolerância.
- **Reprodutibilidade completa.** Entregar: fontes das duas versões, Makefile, entradas ou
  gerador, scripts `sbatch`, saídas do Slurm com os tempos brutos, e um README com os comandos
  exatos — incluindo parâmetros que mudam o comportamento (ex.: a granularidade).
- **Protocolo de medição.** 10 repetições por configuração; **mediana, mínimo e máximo em todas
  as tabelas**. Nó ocioso / `--exclusive`, sempre nos mesmos 2 nós. Mesma entrada em todos os
  pontos da forte; mesma série de processos na forte e na fraca.
- **Consistência dos números.** A mesma configuração tem o mesmo tempo em todas as tabelas. Os
  gráficos principais usam a melhor variante medida. Uma tabela rotulada "mediana" traz medianas.
- **Escalabilidade fraca (ponto mais frágil da turma).** Só o tamanho cresce (P× mais tarefas),
  demais parâmetros iguais. Eficiência > 1 é sinal de erro no T1 de referência. Prove com uma
  medida de trabalho (nº de tarefas/iterações/operações) que o trabalho cresceu na proporção de P.
- **Previsão antes da medição.** No mestre/escravo, o gargalo central é a **comunicação**: meça o
  tempo de processar uma tarefa e o de uma ida-e-volta de mensagem, e **preveja** a partir de
  quantos escravos o mestre satura. Depois compare com o medido e **explique a diferença**.
- **Causas com medição, não suposição.** Nada de "provavelmente", "pode estar ligado a". Resultado
  inesperado → hipótese → teste (prender processos a núcleos, repetir, variar um parâmetro por vez).
  Distinga causa na aplicação (custo irregular, comunicação, sincronização) da causa no ambiente.
- **Domínio na apresentação.** Qualquer integrante pode ser questionado sobre **qualquer chamada
  MPI**: de quem um `MPI_Recv` espera, com que tag, o que acontece se a mensagem não vier. Código
  com apoio de IA conta igual — tenho que saber explicar linha a linha.
- **Formato do relatório.** No máximo **2 páginas** (inclui referências), cabeçalho com integrantes
  e link do repositório, toda figura/tabela referenciada no texto.

### Checklist antes de entregar

- [ ] Sequencial e MPI produzem o mesmo resultado, registrado em cada execução.
- [ ] Alguém de fora compila e reproduz as tabelas só com o que foi entregue + README.
- [ ] Toda tabela tem mediana, mínimo e máximo de 10 repetições.
- [ ] A mesma configuração tem o mesmo tempo em todo o relatório.
- [ ] Nenhuma eficiência passa de 1 sem explicação.
- [ ] O trabalho da escalabilidade fraca cresce na proporção de P, e isso foi medido.
- [ ] Toda previsão (saturação do mestre, razão computação/comunicação) foi comparada com o medido.
- [ ] Cada conclusão se apoia em uma medição, não em "pode ser".
- [ ] Eu sei explicar cada chamada MPI e cada gráfico.
- [ ] Relatório com no máximo 2 páginas e link do repositório no cabeçalho.

## Estrutura atual

```
Pi/Serial/        montecarlo_seq.cpp                    # baseline sequencial (T1) — xorshift, <N>, CHECK/TIME
Pi/Matplotlib/    plot.py                               # visualização da convergência
Makefile                                                # compila montecarlo_seq e montecarlo_mpi
scripts/          config.sh + sbatch (forte/fraca/gran/seq) + summarize.py
```

O código MPI do T2 ainda vai ser escrito por mim. Os gráficos antigos (resultados do
repositório original) foram removidos; os gráficos do T2 serão gerados a partir das minhas
próprias medições em `results/`.
