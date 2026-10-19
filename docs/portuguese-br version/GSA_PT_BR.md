# Análise de sensibilidade global

[English](../english%20version/GSA.md) · [Índice](INDEX_PT_BR.md)

A interface avalia M0 com seis parâmetros nativos em 18 tempos, dos dias 5 a 90. A amostragem usa Kd, kSigma, Fdir, kG, tinf, Ai; o modelo usa Kd, kb, krev, kG, tinf, Ai. São calculados coeficientes de regressão por postos padronizados com sinal e R² da regressão por postos. Sensibilidade não demonstra identificabilidade.

## Entradas

Forneça `context` compatível e configuração completa `cfg`. O contexto inclui reator, `settings` hidráulicos e numéricos, função `engine`, `outputTimes_d=(5:5:90).'` e `forcingData` com `Time_d`, `Cin_ug_L` e `Cout_ug_L` inteiramente NaN. Não coloque respostas experimentais no forçamento.

A configuração define suportes e nomes amostrais, grade de tempos, métrica, regras de convergência, RNG, orçamentos por reator e rechecagens. `prepare_gsa_own_v1(cfg,reactor)` prepara o desenho Monte Carlo sem simular; alternativamente forneça `uniform`, `sampled`, `native`, `cfg`, `reactor` em `inputs` para reutilizá-lo.

## Exemplo curto

O modo curto exige `payload.mode='test'`, com 32 amostras e duas rechecagens escolhidas pela rotina Kennard-Stone. Para um contexto e configuração já completos:

```matlab
cfg.rng.rows = 32;
cfg.qa.count = 2;
cfg.retry.maxIdenticalRetries = 0;
cfg.(reactor).budget.mcMax = 32;
cfg.(reactor).budget.retryReserve = 0;
cfg.(reactor).budget.hardTotal = 34;
cfg.shortTest = struct('sampleCount',32,'recheckCount',2,'maxSeconds',900);
```

Preserve `cfg.qa.maxAbsDiff_ug_L=1e-12`, tolerâncias e critérios originais. Produção verifica blocos de 250 e pode parar por convergência apenas a partir de N=1000. Prefixos 16, 24 e 32 são diagnósticos, não checkpoints de convergência de produção.

Após completar o payload e suas identidades, salve e inspecione o job sem executar o reator:

```matlab
job = jwpe_save_job(payload,jobFile);
plan = jwpe_job(job,'prepare');
disp(plan.status)
```

Use um novo arquivo de job e um diretório de saída ainda inexistente, dentro de uma pasta de trabalho externa, existente e gravável. O controlador cria a pasta da execução. A preparação confere o contrato superior, não todas as escolhas científicas. Revise a configuração completa antes de executar.

Após conferir o plano e aceitar até 34 forwards para esse reator, execute o exemplo curto separadamente:

```matlab
result = jwpe_job(job,'execute');
```

O estado curto esperado após a execução é `TEST_ONLY_GSA_COMPLETE_NOT_CONVERGENCE`: saídas 32×18, históricos SRRC, índices/diferenças das duas rechecagens e contadores. São 34 forwards por reator, sem repetições ou outro reator automático; `scientificConvergenceCertified` e `productionCheckpointsReached` são falsos.

Os arquivos incluem `configuration.mat`, `result.mat`, `ledger.mat`, `outputs.csv`, `native_srrc.csv`, `summary.json`, `manifest.csv`, `execution_mode.json`. A checagem temporal ocorre antes de cada forward, sem interrupção rígida de uma integração em andamento. Preserve execuções interrompidas. Produção exige desenho e orçamento completos e os critérios originais: não reduza limiares para aprovar um exemplo. Consulte [Orçamentos](CAMPAIGN_BUDGETS_PT_BR.md).
