# Interfaces de análise e dependências

[English](../english%20version/ANALYSES.md) · [Índice](INDEX_PT_BR.md)

Cada análise exige entradas explícitas, novo destino e `jwpe_job(job,'prepare')` antes de `jwpe_job(job,'execute')`. Executar pode ter custo elevado; não há encadeamento automático de reatores ou análises. `jwpe_job_contract` lista os campos superiores; `jwpe_job_template` oferece campos vazios para preenchimento. Cada `b.campo` no controlador corresponde ao payload salvo.

| analysis | Campos específicos | Dependência ou saída |
|---|---|---|
| calibration_m1_fixed | inputs,action | Dados/configuração/inícios; parâmetros e predições |
| observation_error_selection | inputs | Comparação histórica separada de M0; cfg,data,settings,reactor,nObs,isCensored,isQuantified,nCensored,role,identity; três famílias e quatro inícios |
| observation_error_joint | csRun,pfRun | Fontes históricas com 50 observações/reator e horizonte de 145 d; comparação conjunta |
| capacity_g1_a1 | context,core,capacityBase,capacityConfig,thetaRef | 33 observações quantificadas de I–II acima do LOD; ajustes G1/A1 |
| capacity_log2 | Campos anteriores,g1,g1Reference | G1 próprio congelado e ajuste LOG2 |
| capacity_joint | csBase,csLog2,pfBase,pfLog2 | Quatro fontes próprias concluídas |
| pl_m0 | forcing,observations,settings,core,catalogue,caseConfig | Âncora e inícios próprios; uma coordenada |
| pl_m1_free/pl_m1_fixed | context,caseConfig,catalogSHA256 | Busca condicional ou âncora elegível |
| pl_m1_free_closure | context,caseConfig,catalogSHA256 | Fechamento local explícito |
| pl_m1_fixed_closure | Campos anteriores,anchor,candidate,campaignID | Fontes elegíveis; máximo de um fechamento por campanha/reator |
| pl_finalize | model,nativeRuns,catalogSHA256,requiredOrigins,anchorCaseId,points,D95 | Envelope inferior e preservação de incompletude |
| gsa | context,inputs | Configuração e desenho Monte Carlo, históricos SRRC |
| mcmc | context,config,initial,action,sweepLimit | Quatro cadeias, diagnósticos e checkpoints |
| selection | config,chains,chainCertification | Seleção de linhas físicas conjuntas |
| propagation | context,config,selected | Bandas média e preditiva |
| temporal_holdout | context,config,selected,reference,responseFile | Predição fechada antes de avaliar respostas |
| external_smx | context,config,selected,study,responseFile | Física/calendário do estudo independente, sem ajuste |
| ofl_calibration/ofl_g1_screen | context,config | Ajustes A=1 ou G1, separados |
| ofl_holdout | config,acceptedCalibration,responseFile | Estado, parâmetros e erro congelados |
| cs_time_equivalence | chainsCS,chainsPF,config | Resumos algébricos com cadeias completas separadas |
| pf_dispersion | context,config,selected,baseline | Linha de base pareada e multiplicadores incluindo zero |
| numeric_products | product,numericInput,numericPolicy | Atividade, correlações, marginais, diagnósticos ou bandas numéricas |

O construtor de cinco arquivos cobre somente a calibração M1 com Kd fixo. As outras rotas exigem configurações internas explícitas, não uma conversão automática desses arquivos.

## Comparações e inferência

A comparação opcional dos modelos de erro é uma análise histórica separada de M0. Seu finalizador conjunto exige 50 observações por reator e horizonte de origem de 145 d, incluindo os registros históricos da Fase III. Ela não corresponde à calibração M1 de 33 observações das Fases I–II. Suas fontes históricas não substituem as fontes da calibração final ou da posterior; os cinco arquivos do exemplo M1 não configuram diretamente essa rota.

A comparação de erro exige referência própria em `cfg.anchorHistoricalEngine.(reactor)`, na ordem `[Kd,kSigma,Fdir,kG,tinf,Ai]`. O nome histórico descreve a formulação, não carrega um ajuste do artigo. Consulte `jwpe_inf_config`, `jwpe_capacity_core_config`, `jwpe_03b_config_v1` e `jwpe_03b_log2_config_v1`. Reutilizar G1 exige observações compatíveis e fonte própria concluída.

O adaptador atual da comparação de capacidade exige 33 observações quantificadas estritamente acima do limite de detecção configurado. As entradas censuradas do exemplo M1 não são diretamente compatíveis com a comparação G1/A1/LOG2. A inclusão de censura nessa comparação exige adaptação explícita; não exclua ou impute observações apenas para satisfazer a verificação. Um contexto de capacidade construído manualmente também exige `dataFile` e `harmonization` com a procedência e o preparo efetivos das entradas, conforme [Contratos de entrada](INPUTS_PT_BR.md).

MCMC exige `config.sampler.ramSweeps`, `config.sampler.productionRows`, `config.sampler.checkpointEvery`, `config.maximumRawPerChain` e os campos de suporte, prior, solver e diagnóstico. `initial.physical` e `initial.sampled` são matrizes 4×7; `initial.Qm0` é 5×5 e `initial.Qe0` é 2×2. Para CS, `initial.rng` é uma célula de quatro elementos, com um estado RNG por cadeia. PF usa as quatro sementes em `config.rng.fullSeeds`. Covariâncias devem ser positivas definidas nas coordenadas amostradas. Não são fornecidas propostas ou condições iniciais ajustadas do artigo. `tb_xform_v1.m`, `tb_prior_v1.m`, `tb_like_v1.m` e o adaptador PF `pftb_like_v1.m` implementam transformações, prior físico, jacobiano e verossimilhança. O aquecimento RAM precede produção MH com proposta congelada, sem thinning rotineiro.

Use `action='start'` ou `'resume'`. `sweepLimit` aceita `Inf` ou, se finito, inteiro positivo múltiplo de `config.sampler.checkpointEvery`. O trabalho termina em checkpoints completos, sem descartar ou reiniciar blocos incompletos. A certificação exige Rhat<1.01 e ESS bulk/tail>400 nos sete parâmetros. Testes curtos não demonstram isso.

## Fontes e predição

A seleção de produção identifica `chainSourceFolder`, com cadeias fechadas e certificadas. São 500 linhas conjuntas, 125 de cada cadeia, em estratos completos. Os sete parâmetros permanecem pareados e não há mistura CS/PF. Propagação, holdout, avaliação externa e cenário PF exigem `selectionSourceFolder` em produção; uma tabela menor não substitui essa seleção. Erro observacional e incerteza paramétrica são distintos.

O holdout não reajusta parâmetros nem escalas de erro. OFL exige `acceptedFitFolder`. O cenário CS exige `chainSourceCS`/`chainSourcePF`, com cadeias fornecidas idênticas às fontes. PF altera apenas Dax, verifica a linha de base pareada e admite Dax=0 sem zerar a velocidade. Fontes sintéticas não certificam produção; uma pasta existente não prova completude.

## Campanhas e alterações

Defina dados, equações, suportes ou priors, opções numéricas, esforço e critérios antes de iniciar. Para M1 medido compatível:

```matlab
[job,inputs] = jwpe_prepare_m1(inputFolder,outputRoot,'CS','run01','production');
plan = jwpe_job(job,'prepare');
disp(inputs.cfg.budget)
disp(plan)
```

Esse bloco prepara e inspeciona o job sem avaliar o reator. Após revisar a configuração e aceitar até 251 forwards brutos, execute separadamente:

```matlab
result = jwpe_job(job,'execute');
```

Use caminhos absolutos próprios. Produção tem 250 chamadas e uma rechecagem, até 251 forwards, sem limite temporal finito do otimizador. Alterar `inputs.cfg` após salvar não modifica o job. Um orçamento diferente exige configuração e verificações de código coerentes, nova identidade e novo destino; consulte [Orçamentos](CAMPAIGN_BUDGETS_PT_BR.md).

Um PL completo envolve vários pontos e finalizador. Uma cadeia maior não elimina requisitos de convergência. `code_manifest.json` vincula código, não textos; editar códigos ou receitas exige atualizar a identidade sem substituir a de resultados antigos. Somente calibração M1 e MCMC oferecem a [retomada genérica](RESUMING_RUNS_PT_BR.md).
