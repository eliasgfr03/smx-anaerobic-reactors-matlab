# Uso dos modelos com dados próprios

[English](../english%20version/USING_YOUR_OWN_DATA.md) · [Índice](INDEX_PT_BR.md)

Os códigos implementam métodos específicos do estudo, não um aplicativo universal de ajuste de qualquer composto ou reator. Equações e análises podem ser reutilizadas, mas as interfaces preservam hipóteses do SMX. Comece pelo [exemplo fictício](GETTING_STARTED_PT_BR.md): uma execução curta demonstra funcionamento, não adequação do modelo ou convergência.

## Compatibilidade experimental

O construtor `jwpe_prepare_m1` prepara somente M1 com Kd fixo. Seus requisitos não são propriedades universais dos micropoluentes.

| Item | Implementação atual | Avaliação necessária |
|---|---|---|
| Reator | CS com tanques em série ou PF com dispersão axial | Representatividade da hidráulica |
| Calendário | Origem no dia 0, fases até 49 e 94 d | Relógio e mudanças operacionais |
| Amostragem | 33 tempos coincidentes, 17/16 por fase | Frequência, afluente e respostas disponíveis |
| Estado inicial | Concentração interna zero | Presença anterior do composto |
| Biomassa | TSS e VSS escalares, constantes no tempo/espaço | Suporte experimental dessa aproximação |
| Hidráulica CS | 2, 2 e 3 tanques por fase | Estrutura e residência de cada fase |
| Hidráulica PF | 71 nós, 69 estados internos | Geometria, velocidade, dispersão e resolução |
| Capacidade | Gompertz normalizada G1 | Evidência de capacidade aparente variável |
| Kd | Fixo em 0.020 L/gTSS | Evidência específica e tratamento da incerteza |
| Erro | Gaussiano aditivo/proporcional com censura à esquerda | Erro experimental e convenção analítica |
| LOD | 0.0163 microgramas/L | Limite real das suas medições |

As três condições hidráulicas atendem também ao período posterior; a calibração usa apenas I–II. Fornecer física da terceira fase não inclui suas respostas no ajuste. Valores diferentes de concentração podem ser fornecidos se os demais requisitos forem apropriados. Outro calendário, contagem, LOD ou Kd exige adaptação explícita. Não descarte, duplique, renomeie fases ou reescale o tempo apenas para passar nas verificações.

## Preparação das entradas

Preserve medições originais e crie pastas separadas por reator e para resultados. Obtenha as permissões de [Acesso aos dados](DATA_ACCESS_PT_BR.md). Os campos estão em [Contratos](INPUTS_PT_BR.md).

1. `forcing.csv`: afluente e tempos, sem resposta efluente. Confira a adequação da reconstrução pelo próximo valor ao procedimento experimental.
2. `observations.csv`: efluente, fases, LOD e censura. Ausência não é zero. Esta receita armazena censurados como zero sinalizado e recusa valores positivos abaixo do LOD sem preparo explícito; preserve os valores brutos.
3. `phases.csv`: períodos de calibração com os limites e as contagens exigidos.
4. `physical.json`: biomassa e hidráulica em dias, microgramas/L, g/L, horas, m/dia, m²/dia. Não substitua TSS por VSS.
5. `initialization.json`: pontos, nomes, semente e origem real; exemplos continuam `SYNTHETIC`.

A ordem é `[Kd,kb,kG,tinf,Ai]`; somente os quatro últimos são ajustados pelo construtor.

| Parâmetro | CS | PF | Unidade |
|---|---|---|---|
| Kd | Fixo 0.020 | Fixo 0.020 | L/gTSS |
| kb | 0–6.250 | 0–0.240 | L/(gVSS dia) |
| kG | 0.030–2.000 | 0.030–2.000 | dia⁻¹ |
| tinf | 10–60 | 10–60 | dia |
| Ai | 0–0.300 | 0–0.300 | Adimensional |

Esses suportes são da receita determinística, não limites gerais ou priors de todas as análises. `points` contém vetores completos dentro deles. Inícios, priors e faixas devem refletir a pergunta científica, não a intenção de reproduzir estimativas do artigo.

`production` prepara entradas medidas compatíveis com 250 chamadas e uma rechecagem, até 251 forwards, sem limite temporal finito do otimizador. `demo` usa 24 e uma. Trocar o modo não adapta dados incompatíveis nem certifica convergência. Consulte [Primeiros passos](GETTING_STARTED_PT_BR.md).

## Adaptações científicas

Mudar o nome do composto não muda as equações. M1 representa um sumidouro aparente irreversível do composto original com partição sólido-líquido e capacidade temporal; não resolve cinética explícita de transferência de massa líquido-sólido. G1 representa capacidade aparente, não crescimento medido de biomassa ou eficiência de remoção.

| Arquivo ou pasta | O que revisar |
|---|---|
| src/api/jwpe_prepare_m1.m | Leitura, fases, censura, contexto e job |
| src/kernels/jwpe_interface_tables_v1.m | Esquemas e validação de tabelas |
| src/kernels/jwpe_interface_settings_v1.m | Física e hidráulica |
| src/kernels/jwpe_m1_calibration_config.m | Kd, suportes, solver e orçamento |
| src/kernels/m1_cs_sim_v1.m e m1_pf_sim_v1.m | Estados iniciais, horizonte e simulação |
| src/kernels/JWPE_activity_G1.m | Lei de capacidade |
| analyses | Configuração e fontes de cada análise |

Outro calendário exige concordância entre construtor, horizonte, contexto e análises posteriores, não apenas outro `phases.csv`. Concentração inicial não nula precisa de implementação explícita: não há campo nos cinco arquivos que substitua o estado zero. Biomassa espacialmente variável, outra hidráulica ou outra capacidade também exigem adaptação.

Trabalhe em cópia separada, preserve unidades e verossimilhança, confira entradas e configurações antes de um teste sintético limitado. Mudanças exigem nova identidade e novos jobs. Não elimine verificações nem retome checkpoints sob método alterado; hashes não validam equações.

## Outras análises e registros

[Interfaces](ANALYSES_PT_BR.md) descreve dependências e estruturas que não são construídas automaticamente pelos cinco arquivos. PL exige âncora própria, coordenadas, inícios e suportes adequados; a grade do artigo não é universal e um perfil com Kd fixo é condicional. MCMC exige priors, suportes, propostas e condições iniciais justificadas; não transfira o prior SMX de Kd ou escalas de erro sem evidência. Cadeias curtas não certificam convergência.

A comparação histórica opcional de erro de M0 tem fontes próprias, com finalizador conjunto para 50 observações por reator até 145 d, e é separada da inferência final I–II. O adaptador atual de capacidade G1/A1/LOG2 exige 33 observações quantificadas acima do LOD, não as entradas censuradas do exemplo M1. Confira essas distinções em [Interfaces](ANALYSES_PT_BR.md) antes de reutilizar um contexto.

Análises de produção posteriores exigem fontes fechadas compatíveis; várias usam 500 linhas conjuntas e mantêm reatores separados. No holdout e em dados independentes, mantenha respostas fora da inferência e do forçamento. Bandas médias e preditivas são distintas.

Antes da campanha registre composto, reator, procedência/permissão, unidades, relógio, estado inicial, fases, física, LOD, censura, equações, parâmetros fixos/livres, suportes ou priors, solver, orçamento, RNG e critérios de aceitação. Mudanças de entrada/método exigem outro destino. Artigo e material suplementar são referências metodológicas, não validação automática de outro experimento. Reprodução completa depende de solicitação e permissões dos materiais correspondentes.
