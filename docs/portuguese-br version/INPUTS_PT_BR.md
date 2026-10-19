# Contratos explícitos de entrada

[English](../english%20version/INPUTS.md) · [Índice](INDEX_PT_BR.md)

Use somente dados autorizados. Os exemplos gerados são fictícios. Uma resposta ausente não é zero nem uma observação censurada. Leia também [Dados próprios](USING_YOUR_OWN_DATA_PT_BR.md).

## Receita M1 com Kd fixo

| Arquivo | Campos | Significado |
|---|---|---|
| forcing.csv | Reactor,Time_d,Cin_ug_L | Dias estritamente crescentes e concentração afluente não negativa, sem resposta efluente |
| observations.csv | Reactor,Time_d,Phase,Cout_ug_L,CensorFlag,LOD_ug_L | Respostas medidas separadas, fases e censura explícitas |
| phases.csv | Reactor,Phase,Start_d,End_d,Use | I:[0,49], II:(49,94], Use=calibration |
| physical.json | Campos abaixo | Biomassa e hidráulica fornecidas pelo usuário |
| initialization.json | parameterNames,points,seed,dataOrigin | Linhas iniciais, semente e origem explícita |

Esta receita exige 33 tempos coincidentes entre forçamento e observações, 17 na Fase I e 16 na Fase II, até o dia 94. Os tempos são positivos e pertencem à grade de avaliação construída. Não inclua respostas da Fase III. A reconstrução usa retenção de ordem zero pelo próximo valor; não troque silenciosamente o método de interpolação.

Unidades: dias, microgramas/L, TSS e VSS em g/L, tempos de residência em horas, velocidade em m/dia e dispersão em m²/dia. TSS e VSS não são intercambiáveis.

Campos físicos comuns: `hydraulicModel`, `XTSS_g_L`, `XVSS_g_L`, `switchDays=[49,94]`. CS exige `hydraulicModel='CS_TIS'`, três valores positivos em `phaseResidenceTime_h` e `tanksPerPhase=[2,2,3]`. PF exige `hydraulicModel='PF_ADM'`, `length_m`, `reportingVolume_L`, três valores de `velocity_m_d` e três de `Dax_m2_d`. A discretização original tem 71 nós e 69 estados internos. Não há biomassa ou coeficientes hidráulicos medidos como valores padrão.

A ordem inicial é `[Kd,kb,kG,tinf,Ai]`. `points` é uma matriz N×5 dentro dos suportes, com Kd=0.020. `seed` é inteiro em [0,2^32−1]. `dataOrigin` descreve a origem e deve ser literalmente `'SYNTHETIC'` no modo demo. O gerador oferece exemplos completos dos esquemas.

### Censura

A verossimilhança determinística original representa uma resposta censurada por zero armazenado, `CensorFlag=true` e LOD=0.0163 microgramas/L. Isso não significa ausência medida. Preserve as medições brutas separadamente. A receita recusa valores positivos abaixo do LOD em vez de convertê-los silenciosamente. Prepare explicitamente a censura e mantenha os valores originais e sua procedência. Outro composto ou estudo pode exigir outro LOD; não transfira automaticamente este valor ou escalas de erro ajustadas.

## Jobs avançados

`jwpe_job_contract(analysis,reactor)` informa campos superiores e controlador. `jwpe_job_template` cria uma estrutura incompleta para preenchimento. Um job salvo contém `payload` escalar com `schemaVersion='JWPE_OWN_EXECUTION_v1'`, `analysis`, `reactor`, `mode`, `runID`, `folder` e `identity`. O modo é `'test'` ou `'production'`, e o destino é novo e absoluto. A identidade declara `datasetID` e `methodID`; `jwpe_save_job` atribui `codeHash`. A identidade dos dados deve representar todas as fontes reais.

Para compatibilidade de `runID` com todos os controladores documentados, comece com uma letra e use somente letras, números e sublinhado, com até 32 caracteres. O padrão correspondente é `^[A-Za-z][A-Za-z0-9_]{0,31}$`. Algumas verificações dos controladores são mais restritas que o validador superior; GSA e MCMC, em particular, não aceitam hífen no identificador.

`executeScientific=true` é necessário para executar, mas não elimina verificações de fonte, certificação e horizonte. O `context` reúne, conforme a análise, reator, condições físicas, `forcingData`, tempos e respostas observados, máscaras de fase, grade e auditoria. O preparo M1 devolve um contexto completo em `inputs.context`, cujo forçamento contém `Time_d`, `Cin_ug_L` e uma coluna de compatibilidade `Cout_ug_L` inteiramente NaN. Não inclua respostas futuras na inferência. Na predição, use apenas forçamento, condições físicas e estado inicial conhecidos até fechar as previsões.

O contexto M1 preparado também inclui `start_d`, `end_d`, `dataFile` e `harmonization`. O adaptador de comparação de capacidade usa `dataFile` como procedência das entradas e `harmonization` como registro do preparo efetivamente aplicado. Forneça esses campos ao construir esse contexto manualmente, sem inventar caminhos ou declarar ausência de preparo quando ele ocorreu.

A compatibilidade do contexto depende da análise. A comparação G1/A1/LOG2 exige atualmente 33 respostas quantificadas estritamente acima do LOD configurado; o contexto censurado do exemplo M1 não pode ser reutilizado sem adaptação. Não exclua ou impute observações para satisfazer essa restrição.

M0 tem seis parâmetros mecanísticos nativos, M1 tem cinco e o MCMC inclui duas escalas de erro. Os adaptadores externos e de OFL têm calendários, unidades e esquemas próprios. O escritor genérico não valida todas as escolhas científicas internas nem certifica funções arbitrárias fornecidas pelo usuário. Abra somente arquivos MAT confiáveis: hashes não autenticam um arquivo desconhecido.
