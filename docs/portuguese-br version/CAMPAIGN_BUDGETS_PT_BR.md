# Ampliação dos orçamentos das campanhas

[English](../english%20version/CAMPAIGN_BUDGETS.md) · [Índice](INDEX_PT_BR.md)

Este guia identifica campos e verificações que devem concordar ao aumentar o esforço de uma nova campanha. Não altera os padrões distribuídos. Trabalhe em cópia separada, com novos jobs e resultados. Nunca amplie esforço editando checkpoint, estado, contador ou resultado existente. Mais avaliações não demonstram convergência nem compatibilidade experimental.

## Tipos de limite

Chamadas da função objetivo incluem solicitações com acerto de cache; forwards brutos contabilizam simulações, rechecagens e repetições explicitamente previstas. Os limites internos de estimação das escalas de erro não são forwards extras. A opção temporal pode encerrar uma busca antes do limite de avaliações, mas não necessariamente interrompe um forward ou rechecagem em andamento. Comprimento de MCMC, trabalho por invocação, seleção posterior e réplicas de erro têm custos distintos. Para estudar somente orçamento, preserve modelo, suportes, priors, divisão dos dados, verossimilhança, tolerâncias e critérios, mantendo tentativas malsucedidas nos registros.

## Calibração M1 com Kd fixo

O construtor usa 250 chamadas e uma rechecagem em produção; demo usa 24 e uma. Não existe argumento de orçamento arbitrário em `jwpe_prepare_m1`.

| Arquivo | Ajustes coerentes |
|---|---|
| src/kernels/jwpe_m1_calibration_config.m | cfg.budget.optimizerCalls,rawForwards,recheck,retries e cfg.surrogate.MaxTime |
| src/api/jwpe_prepare_m1.m | Produção força MaxTime=Inf; demo força 24,25,900; verificar tamanho do banco inicial |
| src/kernels/jwpe_m1_calibration_state.m | Igualdades explícitas de produção 250/251 devem acompanhar a configuração |
| analyses/run_m1_own_v1.m | Transmissão de MaxFunctionEvaluations/MaxTime, igualdade da cfg salva e consumo |
| src/kernels/jwpe_calibration_record.m | Contadores contra state.cfg.budget |
| src/kernels/jwpe_m1_calibration_result.m | Limites finais e rechecagem, já dependentes da cfg |

Exemplo de nova configuração, não edição de job iniciado nem recomendação de convergência:

```matlab
cfg.budget.optimizerCalls = 1000;
cfg.budget.recheck = 1;
cfg.budget.rawForwards = 1001;
cfg.budget.retries = 0;
```

A condição de produção em `jwpe_m1_calibration_state` deve exigir 1000/1001, preservando as verificações de Kd, índices livres, modo e rechecagem. Atualize o comentário e a versão da configuração. Alterar `inputs.cfg` retornado não atualiza um job já salvo. Gere outra identidade e outro job.

## PL

Orçamentos pertencem a cada busca de coordenada. Aumentá-los não acrescenta coordenadas, outro reator ou campanha automática.

| Formulação | Campos | Consumidores |
|---|---|---|
| M0 CS | caseConfig.config.maxFunctionEvaluations,minSurrogatePoints,allowNonstandardBudget; cap bruto derivado +1 | m0_cs_context_own_v1,run_m0_cs_own_v1,jwpe_pl_m0_run_surrogate |
| M0 PF | maxFunctionEvaluations,totalNewObjectiveCap; sementes novas e rechecagem | m0_pf_context_own_v1,run_m0_pf_own_v1,pf_pl_prepare_seeds |
| M1 livre/fixo | caseConfig.options.MaxFunctionEvaluations,MinSurrogatePoints,MaxTime; objectiveCap,hardBudget | jwpe_m1_pl_search.m, jwpe_m1_pl_session.m, jwpe_fixed_search_v1.m, jwpe_fixed_session_v1.m |
| Fechamentos M1 | closure.MaxFunctionEvaluations,maxPollForwards,maxCompletePollsPerMesh,hardBudget | jwpe_m1_pl_closure,jwpe_fixed_closure_v1 e sessões |

As funções de contexto/controlador ficam em `analyses`; os algoritmos e sessões ficam em `src/kernels`. Para uma busca simples, reserve ao menos chamadas+1; fechamentos também contabilizam pattern search, sondagens determinísticas e rechecagem. `MinSurrogatePoints` deve caber no orçamento. Um teto conservador para sondagens é número de malhas × sondagens completas por malha × duas vezes a dimensão livre; exclusões de fronteira podem reduzi-lo. Preserve malhas, tolerância de movimento e número permitido de fechamentos quando alterar somente esforço.

Em M0 PF, o caminho de inícios normalizados explícitos usa `maxFunctionEvaluations` diretamente; outros caminhos descontam novas sementes de `totalNewObjectiveCap`. Confira o caminho efetivo. As receitas são `analyses/recipes/M0_CS.json`, `M0_PF.json`, `M1_FREE.json`, `M1_FIXED.json`. Editar receita exige atualizar sua identidade; modificar um caso depois da leitura exige identidade do método efetivo, não apenas hash do catálogo. Preserve política da âncora, elegibilidade e D95. Não substitua a procedência de endpoints antigos.

## Comparações de erro e capacidade

`src/kernels/JWPE_OEM_optimize_v1_3.m` lê `cfg.optimizer.MaxFunctionEvaluations.CS/PF`, `polishMaxFunctionEvaluations.CS/PF`, `MaxIterations`, `polishMaxIterations`. O teto bruto `cfg.public.rawForwardHardMax` também é aplicado em `analyses/run_oem_own_v1.m`, `src/kernels/jwpe_oem_problem.m` e `jwpe_oem_assemble.m`. São três famílias e quatro inícios; contabilize referência, buscas, refinamentos e rechecagens, sem conversão universal entre chamadas de fmincon e forwards.

As comparações de capacidade G1/A1 e LOG2 usam `jwpe_opt_master_config`, `jwpe_opt_run_surrogate`, `jwpe_03b_make_problem_v1`, `jwpe_03b_log2_make_problem_v1`, `capacity_inputs_own_v1`, `run_capacity_own_v1`, `run_log2_own_v1` e `jwpe_capacity_assemble`. Os construtores e contadores aplicam 50 chamadas e 51 forwards por modelo; G1/A1 totaliza 102, LOG2 51 novos com G1 reutilizado. Para B chamadas, alinhe verificações, metadados e limites de avaliações B+1, ou 2×(B+1) para dois modelos. A opção `allowNonstandardBudget=true` não atualiza outros limites. O modo curto explícito de teste usa 24 chamadas; confira os campos efetivos do `run_spec`, não apenas os padrões do método.

Perfilamento interno: revise `jwpe_inf_config` (`errorProfile.MaxIterations/MaxFunctionEvaluations`), `m1pl_sb_cfg_v3` (`blockMaxIterations/blockMaxFunctionEvaluations`) e `jwpe_sigma_config`. OFL usa `analyses/ofl_sigcfg_own_v1.m` e `ofl_sigma_own_v1.m`. Preserve verificações de consistência e tolerâncias; não relaxe a verossimilhança para compensar esforço insuficiente.

## GSA

`prepare_gsa_own_v1` constrói `cfg.rng.rows` amostras de seis coordenadas. `run_gsa_own_v1` verifica produção a cada 250 e reserva rechecagens; `src/kernels/g2_conv.m` usa `cfg.(reactor).budget.mcMax`. Aumente rows/mcMax conjuntamente, em múltiplos de 250 compatíveis com o histórico. `hardTotal` deve cobrir desenho, `cfg.qa.count` e `retryReserve`. Só existe a repetição idêntica única de falhas classificadas; reserva maior não permite repetir arbitrariamente. Reconstrua matrizes com a nova cfg e preserve distribuições, mapa, 18 saídas e critérios. Mais amostras ainda podem exigir revisão de convergência.

## MCMC

Em `analyses/run_mcmc_own_v1.m`, forneça `config.sampler.ramSweeps`, `config.sampler.productionRows`, `config.sampler.checkpointEvery`, `config.maximumRawPerChain` e `b.sweepLimit`. Com uma proposta mecanística por sweep, sem repetições ou economia de cache, reserve ao menos `1+ramSweeps+productionRows` forwards por cadeia. `sweepLimit` aceita `Inf` ou, se finito, inteiro positivo múltiplo de `config.sampler.checkpointEvery`; a invocação pode abranger mais de uma cadeia, mas não amplia o comprimento total.

`tb_cfg_v1` também contém `sampler.mhSweeps` e `budget.*` descritivos, que não substituem os campos efetivos. Atualize totais de propostas/forwards e prefixos diagnósticos dentro do comprimento retido. Por exemplo, 2000 warmups e 20000 linhas implicam até 22001 forwards por cadeia, 88004 em quatro, sob essas hipóteses. É limite aritmético, não custo medido ou recomendação de convergência. Planeje memória e armazenamento das duas representações de sete colunas.

Não altere comprimento, warmup, método ou cfg durante retomada. Planeje a campanha maior antes do início; `sweepLimit` apenas a divide entre sessões. Preserve quatro cadeias independentes, sem thinning rotineiro, e critérios originais de convergência.

## Seleção e propagação

Mantendo 500 selecionadas, atualize `config.(reactor).rowsPerChain` e `stratumWidth` para `strataPerChain*stratumWidth==rowsPerChain`. São quatro cadeias e 125 estratos iguais por cadeia; não descarte linhas silenciosamente para satisfazer divisibilidade. Revise `run_selection_own_v1` e `ppu_select_v1` com nova fonte fechada.

Mudar o número selecionado exige adaptação conjunta: `run_selection_own_v1`, `jwpe_own_production_guard_v1`, `run_propagation_own_v1`, `run_holdout_own_v1`, `run_external_own_v1` e `jwpe_eval_noise`. O padrão é 500 linhas e 20 erros por linha. Réplicas afetam matrizes e RNG, não o número de forwards para seleção fixa. A avaliação externa acrescenta duas simulações de sensibilidade inicial e usa a linha 426 para esse diagnóstico: ajuste índice e teto conjuntamente, mantendo as duas verificações, D+2 forwards no caso sem cache. Preserve parâmetros pareados, certificação e distinção entre erros e incerteza paramétrica.

## OFL e cenários

`run_ofl_own_v1` usa A1 `[200 200 125]`, teto 528, ou G1 `[100 60]`, teto 162. Opções relacionadas: `ofl_options_v1`, `pa_options_v1`, `g1s_options_v1`. Alinhe blocos e teto, reservando uma rechecagem por bloco. `jwpe_ofl_own_evaluate_v1` contabiliza forwards. Mudar apenas solver não muda o controlador; preserve blocos, cache e modelo de erro.

`run_pf_dispersion_own_v1` aloca 6000 pares, usa 500 linhas e exige 5500 forwards novos com linha de base reutilizada. Para D amostras e C coordenadas, são D×C pares e D×(C−1) forwards novos. Revise constantes, `config.f`, `selectedRows`, `logicalPairs`, `pf_dax_math_v1` e `pf_dax_coordinates_v1`, preservando referência pareada e dispersão nula.

`run_cs_time_own_v1` usa cadeias completas com álgebra e integrais de capacidade, sem orçamento de otimização mecanística. Ajuste `chains`, `csRowsPerChain` e `pfRowsPerChain` às células fornecidas, com comprimentos iguais dentro de cada reator. Holdout também não precisa de otimização: preserve o ajuste e as escalas de erro congelados.

## Identidade após edição

`code_manifest.json` contém `files` e `assets`, com tamanho e SHA-256. O hash desse manifesto é a identidade do código. A versão inglesa do procedimento está em [Atualização da identidade de uma cópia modificada](../english%20version/CAMPAIGN_BUDGETS.md#update-the-identity-of-a-modified-code-copy); os comandos completos também estão abaixo e são os mesmos em ambos os idiomas. Selecione a cópia modificada, preserve `code_manifest.before_budget_changes.json`, gere `code_manifest.updated.json` e revise a lista antes de substituir o manifesto nessa cópia. O procedimento cobre edições de arquivos listados; novos módulos exigem atualizar explicitamente o inventário e revisar dependências e nomes únicos. Abra uma sessão nova, confira setup/caminhos e prepare novos jobs. Atualizar hashes não demonstra equivalência científica.

O procedimento completo para gerar o manifesto revisado é:

```matlab
modifiedRoot = uigetdir(pwd,'Select your modified package copy');
assert(ischar(modifiedRoot),'No folder selected.');
manifestFile = fullfile(modifiedRoot,'code_manifest.json');
backupFile = fullfile(modifiedRoot,'code_manifest.before_budget_changes.json');
nextFile = fullfile(modifiedRoot,'code_manifest.updated.json');
assert(isfile(manifestFile) && ~isfile(backupFile) && ~isfile(nextFile));
[ok,msg] = copyfile(manifestFile,backupFile);
assert(ok,'%s',msg);
binding = jsondecode(fileread(manifestFile));
assert(strcmp(binding.schemaVersion,'JWPE_EXECUTION_CODE_v1'));
groups = {'files','assets'};
for g = 1:numel(groups)
    group = groups{g};
    for k = 1:numel(binding.(group))
        relative = binding.(group)(k).path;
        assert(~java.io.File(relative).isAbsolute() && ~contains(relative,'..'));
        file = fullfile(modifiedRoot,relative);
        details = dir(file);
        assert(isscalar(details) && ~details.isdir);
        fid = fopen(file,'rb');
        assert(fid>=0);
        bytes = fread(fid,Inf,'*uint8');
        fclose(fid);
        md = java.security.MessageDigest.getInstance('SHA-256');
        if ~isempty(bytes), md.update(typecast(bytes,'int8')); end
        digest = typecast(md.digest(),'uint8');
        binding.(group)(k).bytes = details.bytes;
        binding.(group)(k).sha256 = ...
            lower(reshape(dec2hex(digest,2).',1,[]));
    end
end
fid = fopen(nextFile,'w');
assert(fid>=0);
fprintf(fid,'%s\n',jsonencode(binding));
fclose(fid);
```

Antes de ampliar: revise diff e limites vinculados; confirme novas identidades e destinos; confira opções salvas; faça QA técnica e teste sintético limitado da parte alterada; estime tempo e armazenamento, preserve falhas e confira contagens, rechecagens e diagnósticos. Um limite atingido não autoriza relaxar critérios.
