# Primeiros passos com entradas fictícias

[English](../english%20version/GETTING_STARTED.md) · [Índice](INDEX_PT_BR.md)

## 1 Conferir a sessão

Abra no MATLAB a pasta que contém `README.md` e `setup_jwpe.m`:

```matlab
previousPath = path;
info = setup_jwpe();
disp(info)
ver
which jwpe_prepare_m1 -all
which jwpe_job -all
```

O campo `scientificExecutionPerformed` deve ser falso, e os primeiros caminhos efetivos devem apontar para esta cópia. Entradas posteriores de `which -all` marcadas como `Shadowed` não são usadas. Se outra cópia estiver efetiva, use uma sessão limpa ou remova somente seus caminhos na sessão, sem excluir arquivos ou redefinir configurações não relacionadas. `ver` é um comando MATLAB que lista a versão e os produtos instalados. Os campos de disponibilidade dos otimizadores devem ser verdadeiros para executar as análises correspondentes. Uma instalação disponível não garante uma licença acessível no momento da execução. Nenhum resultado é criado.

## 2 Gerar entradas sintéticas

Selecione uma pasta externa gravável com caminho razoavelmente curto e use um novo nome de subpasta:

```matlab
workRoot = uigetdir(pwd,'Choose an external working folder');
assert(ischar(workRoot));
folders = jwpe_make_demo_inputs(fullfile(workRoot,'synthetic_inputs_01'));
disp(folders)
F = readtable(fullfile(folders.CS,'forcing.csv'));
O = readtable(fullfile(folders.CS,'observations.csv'));
disp(size(F))
disp(size(O))
disp(F(1:3,:))
disp(O(1:3,:))
```

Espera-se `33 3` para F e `33 6` para O. Cada pasta CS/PF contém `forcing.csv`, `observations.csv`, `phases.csv`, `physical.json` e `initialization.json`. O gerador usa expressões aritméticas, sem simular reatores, sortear números, calibrar ou gerar cadeias. Ele recusa um destino existente.

## 3 Preparar e conferir o job

```matlab
outputRoot = fullfile(workRoot,'outputs_01');
[jobCS,inputsCS] = jwpe_prepare_m1(folders.CS,outputRoot,'CS','demo01','demo');
planCS = jwpe_job(jobCS,'prepare');
disp(planCS)
disp(inputsCS.cfg.parameterNames)
disp(inputsCS.cfg.freeIndices)
disp(inputsCS.cfg.budget)
disp(inputsCS.context.phaseAudit)
disp(isfolder(jobCS.outputFolder))
descriptorFile = fullfile(workRoot,'descriptor_CS_demo01.mat');
assert(~isfile(descriptorFile) && ~isfolder(descriptorFile));
job = jobCS;
save(descriptorFile,'job');
```

Resultado esperado: `OWN_EXECUTOR_BOUND_NOT_RUN`, sem execução científica. A ordem é `[Kd,kb,kG,tinf,Ai]`, os índices livres são 2:5 e Kd é fixado em 0.020. O orçamento é de 24 chamadas do otimizador e uma rechecagem independente, até 25 forwards e nenhuma repetição. Há 17 observações na Fase I e 16 na Fase II, até o dia 94, sem respostas no forçamento. A existência da pasta de resultados retorna 0.

A preparação salva `outputs_01/jobs/CS_demo01.mat`, identifica os cinco arquivos e o código, e devolve as entradas para inspeção. Não calcula a resposta do reator. O arquivo de descritor armazena uma variável chamada `job`, que aponta para esse job CS. O [guia de retomadas](RESUMING_RUNS_PT_BR.md) carrega o mesmo nome de variável em outra sessão; preserve o caminho absoluto `descriptorFile` nos seus registros.

## 4 Execução explícita

Somente depois de revisar a configuração e aceitar seu custo, execute separadamente:

```matlab
resultCS = jwpe_job(jobCS,'execute');
```

O exemplo usa os núcleos reais de M1, verossimilhança e otimização. A opção temporal de 900 s não interrompe necessariamente uma avaliação em andamento ou a rechecagem final. Espere resultados finitos e uma rechecagem, não um ótimo específico. O estado curto é `DEMO_CALIBRATION_COMPLETE`, com `testOnly=true` e `productionCertified=false`. Contagens exatas e saída do otimizador podem variar dentro do limite.

Confira `result.mat`, `summary.json`, `parameters.csv`, `prediction.csv`, `trace.csv` e `manifest.csv`. `run_spec.mat`, `run_state.mat` e o checkpoint nativo, quando gerado, apoiam a inspeção e retomadas compatíveis. Para PF, prepare outro job com `folders.PF` e `'PF'`. Use novos identificadores e destinos. Entradas medidas compatíveis usam `'production'`, com 250 chamadas e uma rechecagem, não um exemplo curto.

## 5 Retomada

Somente M1 e MCMC têm a interface genérica de retomada. Para preparar um novo descritor de uma execução incompleta compatível:

```matlab
resumeFile = fullfile(outputRoot,'jobs','CS_demo01_resume.mat');
resumeJob = jwpe_resume_job(jobCS,resumeFile);
resumePlan = jwpe_job(resumeJob,'prepare');
disp(resumePlan.status)
disp(resumePlan.scientificExecutionPerformed)
```

Espera-se `OWN_EXECUTOR_BOUND_NOT_RUN` e falso. Isso confere a interface, mas não garante que qualquer checkpoint seja retomável. Somente para um estado incompleto coerente e elegível, a continuação é `resultCS = jwpe_job(resumeJob,'execute');`. Não reexecute uma execução concluída para testar retomada. Preserve configuração, dados, caminhos, código e orçamento total. Uma interrupção durante uma avaliação pode impedir a retomada segura. Consulte [Retomadas](RESUMING_RUNS_PT_BR.md).

## 6 Campanhas e encerramento

Para alterar os limites dos códigos, leia [Orçamentos](CAMPAIGN_BUDGETS_PT_BR.md). Aumentar esforço não demonstra convergência. O construtor M1 não oferece um argumento de orçamento arbitrário: mudanças maiores exigem código e verificações coerentes em uma cópia separada.

```matlab
path(previousPath)
```

O comando restaura o caminho da sessão; os arquivos gerados continuam na pasta de trabalho.
