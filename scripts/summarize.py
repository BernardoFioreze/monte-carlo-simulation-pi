#!/usr/bin/env python3
"""Resume os tempos brutos de um diretório de resultados em mediana/mín/máx.

Uso:
    python3 scripts/summarize.py results/forte/<timestamp>

Lê todos os arquivos *.out, extrai de cada um:
    TIME=<segundos>              (linha gerada pelo seu programa)
    CHECK=<grandeza verificável> (idem)
Agrupa por configuração (o prefixo antes de "_rep", ex.: P16, gran1000000, seq),
reporta mediana, mínimo e máximo de TIME e confere se CHECK é igual em tudo
(equivalência sequencial x paralelo — exigência do feedback do T1).
"""
import re
import sys
import statistics
from pathlib import Path

TIME_RE = re.compile(r"TIME\s*=\s*([0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)")
CHECK_RE = re.compile(r"CHECK\s*=\s*(\S+)")


def config_key(name: str) -> str:
    """P16_rep3.out -> 'P16'; gran1000000_rep2.out -> 'gran1000000'; seq_rep1.out -> 'seq'."""
    stem = name[:-4] if name.endswith(".out") else name
    return stem.split("_rep")[0]


def natural(key: str):
    """Ordena P2,P4,...,P64 e gran10000,... numericamente pelo número no fim."""
    m = re.search(r"(\d+)$", key)
    prefix = re.sub(r"\d+$", "", key)
    return (prefix, int(m.group(1)) if m else -1)


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 1
    d = Path(argv[1])
    if not d.is_dir():
        print(f"erro: {d} não é um diretório", file=sys.stderr)
        return 1

    groups: dict[str, list[float]] = {}
    checks: dict[str, set[str]] = {}
    for f in sorted(d.glob("*.out")):
        text = f.read_text(errors="replace")
        tm = TIME_RE.findall(text)
        ck = CHECK_RE.findall(text)
        key = config_key(f.name)
        if tm:
            groups.setdefault(key, []).append(float(tm[-1]))
        else:
            print(f"aviso: sem TIME= em {f.name}", file=sys.stderr)
        if ck:
            checks.setdefault(key, set()).add(ck[-1])

    if not groups:
        print("Nenhum TIME= encontrado. O programa imprimiu 'TIME=<segundos>'?",
              file=sys.stderr)
        return 1

    print(f"Resumo de {d}\n")
    print(f"{'config':<14}{'n':>4}{'mediana':>14}{'mín':>14}{'máx':>14}")
    print("-" * 60)
    for key in sorted(groups, key=natural):
        xs = groups[key]
        print(f"{key:<14}{len(xs):>4}{statistics.median(xs):>14.4f}"
              f"{min(xs):>14.4f}{max(xs):>14.4f}")

    # Equivalência: CHECK deve ser o mesmo em todas as configurações.
    all_checks = set().union(*checks.values()) if checks else set()
    print()
    if not all_checks:
        print("CHECK: nenhum valor encontrado (adicione 'CHECK=' à saída do programa).")
    elif len(all_checks) == 1:
        print(f"CHECK: OK, único em todas as execuções = {next(iter(all_checks))}")
    else:
        print(f"CHECK: ATENÇÃO, valores divergentes: {sorted(all_checks)}")
        for key in sorted(checks, key=natural):
            print(f"  {key}: {sorted(checks[key])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
