# Orçamentos da calibração OFL

[English](../english%20version/OFL_CALIBRATION.md) · [Índice](INDEX_PT_BR.md)

A calibração A=1 de OFL executa duas buscas globais e uma local, ajustando kb. Kd e o multiplicador de capacidade permanecem fixos conforme a configuração. As escalas do erro combinado são perfiladas, e cada bloco tem rechecagem independente.

## Exemplo curto

Para um payload próprio `b` já completo:

```matlab
b.analysis = 'ofl_calibration';
b.mode = 'test';
b.shortBudget = struct('outerCalls',[20 20 10],'rawMax',53);
```

São até 20 chamadas globais A, 20 globais B e 10 locais, mais três rechecagens, até 53 forwards. Acertos exatos de cache não gastam novo forward. Cada bloco global deve exercitar ao menos 10 chamadas e o local ao menos oito. Suportes, pontos iniciais, malha local, verossimilhança e perfilamento de erro não são relaxados. O teste não demonstra convergência ou qualidade científica do ajuste.

## Campanha completa

Sem `shortBudget`, os limites são 200, 200 e 125 chamadas, até 528 forwards com rechecagens. `shortBudget` é recusado em produção. Confira rechecagens, elegibilidade do perfilamento, suportes e diagnósticos. Novo método/configuração exige novo job e destino; consulte [Interfaces](ANALYSES_PT_BR.md) e [Orçamentos](CAMPAIGN_BUDGETS_PT_BR.md).

## OFL com G1

`ofl_g1_screen` estima kb, kG, tinf e Ai com Gompertz normalizada e Kd fixo, usando suportes, inícios, sementes e opções próprios. Para payload completo:

```matlab
b.analysis = 'ofl_g1_screen';
b.mode = 'test';
b.shortBudget = struct('outerCalls',[20 10],'rawMax',32);
```

São 20 chamadas globais e 10 locais, duas rechecagens, até 32 forwards, com mínimos de 10 globais e oito locais. Isso não certifica seleção de modelo ou convergência. Sem o campo curto, a rota usa 100 globais e 60 locais, até 162 forwards. Os limites A=1 permanecem separados e inalterados.
