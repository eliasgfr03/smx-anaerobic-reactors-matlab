# Execução dos cenários de dispersão axial PF

[English](../english%20version/PF_DISPERSION.md) · [Índice](INDEX_PT_BR.md)

O cenário transfere as mesmas linhas conjuntas de parâmetros a cada multiplicador e altera somente Dax. Para cada linha, simula o histórico completo nas condições diferentes da linha de base e reutiliza a curva de resposta dessa própria amostra, salva sem erro observacional em f=1. Não se trata de uma única curva média da posterior compartilhada entre todas as amostras. O cenário não reajusta parâmetros nem acrescenta erros observacionais; as saídas salvas contêm resumos, não curvas simuladas individuais.

## Execução curta

Para um payload próprio já preparado:

```matlab
b.analysis = 'pf_dispersion';
b.mode = 'test';
b.shortBudget = struct('selectedRows',4,'rawMax',8);
```

A configuração deve conter `f=[0 1 2]`, `baselineIndex=2`, `selectedRows=4`, `logicalPairs=12`, `rawForwardHardMax=8`. Forneça rótulos, dispersão/velocidade/comprimento de referência, política de quantis, quatro linhas em `selected` e a linha de base exata correspondente. `baseline` contém `times_d`, `selected`, `mu`; curvas e identidades devem coincidir com contexto e seleção. O contexto não contém respostas e fornece histórico e tempos de monitoramento.

São quatro simulações em f=0 e quatro em f=2. Em f=1, as quatro curvas são reutilizadas sem forward. Isso verifica execução e agregação, não uma posterior ou intervalo científico calibrado. A configuração curta é recusada em produção antes de criar saídas.

## Campanha completa e saídas

Sem `shortBudget`, permanecem 500 linhas selecionadas, 12 coordenadas, 6000 pares lógicos e exatamente 5500 novos forwards. A configuração completa e as fontes congeladas continuam necessárias; remover o campo curto não as constrói. Produção exige seleção própria certificada.

Use novos jobs e pastas para entradas ou modos diferentes. `latest.mat` registra coordenadas concluídas e `result.mat` contém resumos, diferenças pareadas, remoções médias e coordenadas. Não são salvas curvas individuais, nem é emitido recibo de fonte fechada pelo controlador; o despachante acrescenta o modo de execução. Efeitos são calculados contra a linha de base de cada amostra antes de resumir. f=0 tem dispersão nula e Peclet infinito; não é substituído por um valor positivo pequeno.
