# Exemplos de jobs por família

[English](../english%20version/JOB_EXAMPLES.md) · [Índice](INDEX_PT_BR.md)

Comece pelo exemplo M1 completo. Os demais exemplos são padrões de construção: variáveis nomeadas devem conter dados, configurações ou resultados próprios compatíveis. Campos vazios não são valores científicos padrão. A preparação não certifica todas as estruturas internas.

## Exemplo M1 completo com dados sintéticos

Na raiz do pacote, selecione uma pasta externa gravável:

```matlab
previousPath = path;
info = setup_jwpe();
workRoot = uigetdir(pwd,'Choose an external working folder');
assert(ischar(workRoot));
folders = jwpe_make_demo_inputs(fullfile(workRoot,'inputs01'));
[job,inputs] = jwpe_prepare_m1(folders.CS, ...
    fullfile(workRoot,'outputs01'),'CS','demo01','demo');
plan = jwpe_job(job,'prepare');
disp(inputs.cfg.budget)
disp(plan.status)
descriptorFile = fullfile(workRoot,'descriptor_CS_demo01.mat');
assert(~isfile(descriptorFile) && ~isfolder(descriptorFile));
save(descriptorFile,'job');
```

Espera-se `OWN_EXECUTOR_BOUND_NOT_RUN`, sem simulação, otimização ou pasta de resultados. O job fica em `outputs01/jobs`. São permitidas 24 chamadas e uma rechecagem, até 25 forwards. Somente o comando separado abaixo executa esse orçamento:

```matlab
result = jwpe_job(job,'execute');
disp(result)
```

Para PF, use `folders.PF` e `'PF'` em outro job. Entradas medidas compatíveis usam sua própria pasta de cinco arquivos e `'production'`, com 250 chamadas e uma rechecagem. Nunca reclassifique dados fictícios como produção. Ao terminar, restaure o caminho com `path(previousPath)`.

## Padrão avançado comum

```matlab
[b,contract] = jwpe_job_template('mcmc','CS');
disp(contract.target)
disp(contract.requiredFields)
disp(b)
```

Esse comando apenas cria um modelo incompleto de configuração. Preencha `runID`, `folder` absoluto, `identity.datasetID`, `identity.methodID` e todos os campos específicos. A identidade deve descrever dados e opções efetivas, não apenas o nome da receita. O escritor atribui o hash do código. Use `'test'` para entradas sintéticas e `'production'` para dados medidos compatíveis e fontes certificadas.

Para compatibilidade entre os controladores, comece `runID` com uma letra e use somente letras, números e sublinhado, com até 32 caracteres. GSA e MCMC recusam hífens mesmo que o validador genérico os aceite.

Somente depois de completar o payload, salve e inspecione o job:

```matlab
b.executeScientific = true;
job = jwpe_save_job(b,jobFile);
plan = jwpe_job(job,'prepare');
disp(plan)
save(descriptorFile,'job');
% result = jwpe_job(job,'execute');
```

`jobFile` e `descriptorFile` são novos caminhos absolutos escolhidos pelo usuário. O modelo inicia com `executeScientific=false`; alterar para verdadeiro não executa ao salvar ou preparar. Não percorra o registro inteiro em um laço sem definir dependências e custos.

## Erro e capacidade

`observation_error_selection` executa a comparação histórica separada de erro de M0. Forneça `inputs` com os campos de [Interfaces](ANALYSES_PT_BR.md), incluindo dados, configuração de erro e referência própria de seis coordenadas. Execute CS e PF separadamente. `observation_error_joint`, reator `'joint'`, recebe `csRun` e `pfRun`, pastas concluídas de fontes históricas próprias. Seu finalizador exige 50 observações por reator e horizonte de origem de 145 d, incluindo os registros históricos da Fase III; isso não corresponde à calibração final M1 de 33 observações. Essas fontes históricas não substituem as fontes da calibração final ou da posterior.

`capacity_g1_a1` recebe `context`, `core`, `capacityBase`, `capacityConfig`, `thetaRef`. `capacity_log2` também recebe `g1` e `g1Reference` salvos: reutilize G1 sem recalculá-lo. `capacity_joint`, reator `'joint'`, recebe `csBase`, `csLog2`, `pfBase`, `pfLog2`. Consulte os controladores e [Interfaces](ANALYSES_PT_BR.md) para configurações internas. Finalizadores de produção recusam fontes sintéticas ou não classificadas.

O adaptador de capacidade exige 33 respostas quantificadas estritamente acima de seu LOD e não aceita diretamente o exemplo censurado de M1. Um `context` construído manualmente deve incluir `dataFile` e `harmonization` com a procedência e o preparo efetivos. Não descarte ou impute observações para satisfazer o adaptador; outro padrão de censura exige adaptação explícita.

## Verossimilhança de perfil

```matlab
cases = jwpe_pl_cases('M1_FIXED','CS');
disp({cases.id}.')
```

Escolha `caseID` dessa lista e forneça sua âncora rechecada `anchor` e os pontos iniciais normalizados compatíveis:

```matlab
caseConfig = jwpe_pl_case( ...
    'M1_FIXED','CS',caseID,normalizedStarts,anchor);
caseConfig.sigma = jwpe_sigma_config();
caseConfig.freeIndices = caseConfig.freeIndices(:).';
caseConfig.lower = caseConfig.lower(:).';
caseConfig.upper = caseConfig.upper(:).';
[b,contract] = jwpe_job_template('pl_m1_fixed','CS');
b.context = context;
b.caseConfig = caseConfig;
b.catalogSHA256 = caseConfig.catalogSHA256;
```

Complete os campos comuns antes de salvar e preparar. PF também exige política explícita de classificação dos estados negativos. [PL](PROFILE_LIKELIHOOD_PT_BR.md) explica M0, Kd livre, fechamentos e finalização. Uma coordenada não é um perfil completo. Uma busca local limitada pode terminar incompleta, sem fornecer limites de confiança fechados.

## GSA e MCMC

Para `gsa`, forneça contexto sem respostas no forçamento e `inputs=prepare_gsa_own_v1(cfg,'CS')`. Revise o mapa amostral, 18 tempos e [Configuração GSA](GSA_PT_BR.md). Preparar o desenho aleatório não simula o reator.

Para `mcmc`, forneça `context`, `config`, `initial`, `action='start'`, `sweepLimit`. Revise `run_mcmc_own_v1` e [Interfaces](ANALYSES_PT_BR.md): quatro estados iniciais, covariâncias transformadas, priors, RNG e checkpoints completos. O teste curto não certifica a posterior. PF usa suas configurações e sementes; não misture as populações dos reatores.

## Seleção e incerteza

`selection` recebe `config`, `chains` físicas separadas e `chainCertification`; produção exige `chainSourceFolder`. `propagation` recebe `context`, `config`, `selected` e `selectionSourceFolder` em produção. Preserve linhas conjuntas; a seleção de produção atual tem 500 linhas, 125 por cadeia.

`temporal_holdout` acrescenta `reference` e `responseFile`; `external_smx`, `study` e `responseFile`. Não use respostas reservadas na inferência ou no forçamento preditivo. Esses adaptadores não são construídos automaticamente a partir dos cinco arquivos M1. A banda média representa incerteza paramétrica; a preditiva também inclui erro observacional.

## OFL e cenários

`ofl_calibration` e `ofl_g1_screen` recebem `context` e `config`, com [orçamentos próprios](OFL_CALIBRATION_PT_BR.md). `ofl_holdout` recebe `config`, `acceptedCalibration`, `responseFile` e `acceptedFitFolder` em produção. Congele estados, parâmetros e escalas de erro.

`cs_time_equivalence`, reator `'CS'`, recebe `chainsCS`, `chainsPF`, `config` e, em produção, `chainSourceCS`/`chainSourcePF`. As células de cadeias têm comprimentos iguais dentro de cada reator, coerentes com `config.chains`, `csRowsPerChain`, `pfRowsPerChain`. As contagens não precisam ser as do artigo. O cálculo integra a capacidade e produz resumos algébricos, sem forwards mecanísticos ou recalibração.

`pf_dispersion`, reator `'PF'`, recebe `context`, `config`, `selected`, `baseline` correspondente e a fonte de seleção de produção. Consulte [Dispersão PF](PF_DISPERSION_PT_BR.md).

`numeric_products` recebe `product`, `numericInput`, `numericPolicy`; consulte `run_numeric_own_v1` para produtos e dimensões. Produz números, não figuras. A pós-análise numérica também exige intenção explícita e revisão das entradas.
