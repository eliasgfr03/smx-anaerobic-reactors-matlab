# Receitas de verossimilhança de perfil

[English](../english%20version/PROFILE_LIKELIHOOD.md) · [Índice](INDEX_PT_BR.md)

Os quatro JSON em `analyses/recipes` contêm configurações do método: coordenadas fixas exatas, suportes, mapas, orçamentos e opções. Não contêm âncoras ajustadas, endpoints, valores da função objetivo, bancos iniciais ou identidades de arquivos do artigo. Há 92 receitas M0-CS, 46 M0-PF, 39 M1 livre e 50 M1 fixo, incluindo buscas e fechamentos. Coordenadas diagnósticas são distinguidas pelos campos de categoria e suporte oficial; nem todas pertencem aos intervalos reportados.

```matlab
cases = jwpe_pl_cases('M1_FIXED','CS');
disp({cases.id}.')
```

Isso lê receitas sem simular. `jwpe_pl_case(model,reactor,caseID,normalizedStarts,anchor)` completa uma receita com inícios normalizados em [0,1] e âncora própria rechecada com `theta`/`nll`. Um início não avaliado não recebe NLL inventado. Para M1, o construtor converte a opção simbólica de `MinSurrogatePoints` e inclui a identidade do catálogo. Para M0, fornece linhas iniciais normalizadas; o catálogo externo também precisa da âncora própria, `contextID` e `anchorChallengeTolerance=5e-4`. A âncora M0 pode vir de ajuste próprio compatível, não de endpoint publicado.

Antes de salvar um caso M1 executável, complete a configuração de erro e o formato em linha:

```matlab
caseConfig.sigma = jwpe_sigma_config();
caseConfig.freeIndices = caseConfig.freeIndices(:).';
caseConfig.lower = caseConfig.lower(:).';
caseConfig.upper = caseConfig.upper(:).';
```

`jwpe_sigma_config` somente constrói opções; não estima erro nem avalia verossimilhança. Seus padrões são específicos do SMX original e seu LOD. PF também exige `caseConfig.invalid` explícito para classificação de estados negativos conforme `jwpe_m1_pl_evaluate`. A preparação genérica não certifica todos os campos internos.

A receita é apenas parte do payload; forneça contexto, núcleo e demais campos de `jwpe_job_contract`. Fechamentos precisam de fontes elegíveis e orçamento próprio, sem descoberta automática. M0 usa `[Kd,kb,krev,kG,tinf,Ai]` ou `[Kd,kSigma,Fdir,kG,tinf,Ai]` conforme o mapa; M1 remove krev. Em Kd fixo, Ai como parâmetro de ajuste continua limitado a 0.300, mesmo quando a coordenada fixa de um perfil ultrapassa esse valor. Extensão de perfil não é suporte geral de prior.

O finalizador usa `model='M0'`, `'M1_FREE'` ou `'M1_FIXED'`, `nativeRuns` com arquivos e hashes, `requiredOrigins` com origens requeridas, `points` com coordenadas e origens, `anchorCaseId` e `D95=3.84145882069412`. Uma origem ausente deve permanecer ausente; HOLD/STOP não vira perfil completo. O finalizador não lança buscas, interpola limites automaticamente nem infere números do artigo. Execute cada caso em pasta distinta e reveja âncoras, inícios e suportes para outro conjunto de dados.
