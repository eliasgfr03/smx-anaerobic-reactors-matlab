# Retomada de execuções incompletas

[English](../english%20version/RESUMING_RUNS.md) · [Índice](INDEX_PT_BR.md)

A interface pública de retomada suporta somente calibração M1 com Kd fixo e MCMC. Continua uma execução incompleta compatível, preservando seu orçamento total, sem concedê-lo novamente. Outros controladores podem salvar intermediários, mas isso não significa suporte de retomada nativa por `jwpe_resume_job`.

## Arquivos necessários

Preserve o job original, seu descritor, toda a pasta de resultados, a cópia dos códigos e as entradas. M1 usa `run_spec.mat`, `run_state.mat` e `surrogate_checkpoint.mat`, quando gerado. MCMC exige configuração, checkpoints completos das cadeias e RNG correspondentes. Não mova a pasta nem altere seus registros para forçar continuação.

A retomada requer estado coerente, sem avaliação pendente ou falha registrada. Não retome um resultado concluído como teste. Ctrl+C, encerramento do processo ou queda da máquina podem deixar um estado não retomável. Preserve-o e investigue, sem zerar contadores ou reiniciar na mesma pasta.

## Comandos

Ao preparar o job original, escolha um novo caminho absoluto e salve o descritor:

```matlab
save(descriptorFile,'job');
```

O exemplo de primeiros passos usa `job = jobCS` antes de salvar, de forma que o MAT contém `job`, não `jobCS`. Se um descritor anterior foi salvo com outro nome de variável, carregue esse nome exato e atribua-o explicitamente a `job`. Para um arquivo que contém `jobCS`, por exemplo, use `saved = load(descriptorFile,'jobCS'); job = saved.jobCS;` em vez da leitura genérica abaixo. Não sobrescreva um descritor existente apenas para renomeá-lo.

Em outra sessão, na cópia inalterada do pacote:

```matlab
info = setup_jwpe();
saved = load(descriptorFile,'job');
job = saved.job;
resumeJob = jwpe_resume_job(job,newResumeJobFile);
resumePlan = jwpe_job(resumeJob,'prepare');
disp(resumePlan.status)
disp(resumePlan.scientificExecutionPerformed)
```

`newResumeJobFile` é um novo caminho MAT absoluto. Preparar retorna `OWN_EXECUTOR_BOUND_NOT_RUN` e falso, mas não garante a coerência de todo checkpoint. A execução separada verifica o estado e continua se elegível:

```matlab
result = jwpe_job(resumeJob,'execute');
```

O destino permanece o original. Não altere dados, método, hash de código, modo, runID, suportes, verossimilhança, orçamentos ou tamanho total das cadeias. No MCMC, `sweepLimit` limita cada invocação em fronteiras completas de checkpoint e aceita `Inf` ou inteiro positivo finito múltiplo de `config.sampler.checkpointEvery`, sem ampliar a produção planejada.

## Casos não suportados

Buscas PL e fechamentos locais não oferecem retomada genérica. Uma coordenada interrompida antes de concluir a busca continua incompleta. LOG2 pode salvar checkpoint diagnóstico, mas sua continuação nativa não está qualificada nessa interface. Blocos do otimizador OFL também não implicam retomada genérica. Nesses casos, examine o que foi salvo e, se necessário, planeje uma nova execução distinta, sem chamá-la de retomada exata. Campanhas maiores exigem configurações coerentes e novos jobs; consulte [Orçamentos](CAMPAIGN_BUDGETS_PT_BR.md). Preserve todas as tentativas consumidas.
