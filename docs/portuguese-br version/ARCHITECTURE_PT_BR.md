# Arquitetura dos códigos

[English](../english%20version/ARCHITECTURE.md) · [Índice](INDEX_PT_BR.md)

O pacote separa interfaces de uso, controladores de análises e funções numéricas. Um job é uma configuração salva para uma invocação, não uma cópia do modelo nem necessariamente uma campanha inteira. Uma campanha de PL, por exemplo, reúne vários jobs de coordenadas e um finalizador.

| Local | Responsabilidade | Exemplos |
|---|---|---|
| setup_jwpe.m | Configurar caminhos explícitos da sessão e verificar a identidade | setup_jwpe |
| src/api | Preparar entradas, consultar esquemas e gerenciar jobs | jwpe_package_info, jwpe_prepare_m1, jwpe_job_contract, jwpe_job_template, jwpe_save_job, jwpe_job, jwpe_resume_job |
| src/kernels | Equações, integração, verossimilhança, transformações, otimização e estatística | m1_cs_sim_v1, m1_pf_sim_v1, JWPE_activity_G1, tb_*, pftb_* |
| analyses | Compor entradas, chamar núcleos, controlar orçamentos, salvar e verificar fontes | run_m1_own_v1, run_m1_pl_own_v1, run_mcmc_own_v1, jwpe_own_route_v1 |
| analyses/recipes | Coordenadas, suportes e opções do desenho de PL do artigo | Quatro catálogos JSON |
| examples | Gerar entradas fictícias sem avaliar o modelo | jwpe_make_demo_inputs |
| docs | Instruções científicas e de uso | INDEX_PT_BR.md |
| code_manifest.json | Tamanhos e hashes dos códigos e das receitas | Verificado no setup e na preparação |

A API não contém apenas configurações: também lê entradas e gerencia execuções. As configurações residem nas funções e estruturas explícitas dos jobs. Os kernels são funções numéricas reutilizáveis; os controladores definem quais executar, em que ordem e com quais verificações.

## Sequência de execução

1. `setup_jwpe` verifica a cópia e disponibiliza a API.
2. Um construtor, como `jwpe_prepare_m1`, ou o usuário avançado define dados, método, identidade, custo e destino.
3. `jwpe_save_job` salva o payload e retorna um descritor. O construtor M1 já realiza isso.
4. `jwpe_job(job,'prepare')` valida o contrato superior sem forward ou otimização; as escolhas científicas internas ainda precisam de revisão.
5. `jwpe_job(job,'execute')` chama explicitamente o controlador e pode ter custo elevado.
6. Confira resultado, contadores, rechecagens e diagnósticos antes de usar a saída em outra análise.

O MAT contém `payload`; o descritor retorna `file`, `sha256`, `analysis`, `reactor` e `outputFolder`. Preserve ambos. Arquivos MAT com objetos ou funções devem vir de fontes confiáveis. Hashes identificam alterações, mas não autenticam um download desconhecido.

## Dependências

Comparações de erro e capacidade, GSA e PL são análises distintas, não etapas automáticas obrigatórias de um lançador. PL exige âncora rechecada e buscas condicionais próprias. A calibração determinística fornece informações iniciais à inferência bayesiana. Quatro cadeias separadas alimentam diagnósticos e seleção de linhas conjuntas; a seleção alimenta propagação, holdout, avaliação externa e dispersão PF. A equivalência CS usa todas as amostras retidas, mantendo os reatores separados. OFL tem ajuste e holdout próprios.

O despachante não executa automaticamente outro reator ou análise. `numeric_products` calcula resumos numéricos, sem renderizar figuras. Mantenha entradas geradas, jobs, checkpoints e resultados em uma pasta de trabalho externa.

## Alterações

Identifique os chamadores e as verificações vinculadas antes de alterar um núcleo. Preserve uma cópia original. [Orçamentos](CAMPAIGN_BUDGETS_PT_BR.md) inclui o procedimento MATLAB para atualizar o inventário após editar arquivos existentes. Novos módulos exigem revisar a lista e a unicidade dos nomes. Código modificado exige nova identidade e novos jobs, não alteração de checkpoints antigos. Edições dos textos não mudam a identidade executável.

## Glossário

| Termo | Significado no pacote |
|---|---|
| PL | Verossimilhança de perfil: fixa uma coordenada e reestima os demais parâmetros para avaliar o suporte da verossimilhança. |
| GSA | Análise de sensibilidade global: avalia a sensibilidade da resposta em uma distribuição declarada de parâmetros, não a identificabilidade prática. |
| MCMC | Monte Carlo via cadeias de Markov: amostra a posterior conjunta sob a verossimilhança, os priors e o modelo numérico declarados. |
| NLL | Negativo do logaritmo da verossimilhança, usado como objetivo inferencial. Um valor menor representa melhor verossimilhança para os mesmos dados e modelo observacional. |
| LOD | Limite de detecção aplicável às medições, usado com a convenção explícita de censura. |
| TSS | Sólidos suspensos totais, base de massa usada na partição sólido-líquido. Não é intercambiável com VSS. |
| VSS | Sólidos suspensos voláteis, base de massa usada para normalizar o coeficiente aparente de biotransformação. |
| RNG | Gerador de números aleatórios. Sementes e estados salvos permitem reproduzir sequências aleatórias em implementações compatíveis. |
| SRRC | Coeficiente de regressão por postos padronizado, medida de sensibilidade com sinal baseada em variáveis ordenadas por postos. |
| ESS | Tamanho efetivo da amostra, considerando a dependência da cadeia. ESS bulk e tail avaliam regiões diferentes da distribuição amostrada. |
| Rhat | Diagnóstico de convergência baseado em postos e cadeias divididas, comparando o comportamento dentro e entre cadeias. Deve ser avaliado com ESS e outros diagnósticos. |
| Forward | Simulação numérica do reator para um vetor de parâmetros e contexto de entrada. Rechecagens independentes da simulação também consomem o orçamento de forwards brutos. |
| Warmup | Etapa de amostragem usada para adaptação. Suas linhas não integram a produção retida da posterior. |
| Bracket | Duas coordenadas avaliadas que delimitam um cruzamento de limiar; não equivale a um limite de confiança interpolado exato. |
| Fonte fechada | Saída salva cujos arquivos necessários estão vinculados por um recibo de integridade. O fechamento, isoladamente, não demonstra adequação científica. |
| Fonte certificada | Fonte compatível que passou nas verificações exigidas pelo controlador, como diagnósticos das cadeias. Não certifica o modelo para outro experimento. |
| HOLD ou STOP | Estado do algoritmo que exige revisão ou indica cálculo incompleto/interrompido. Não demonstra convergência ou limite de confiança aceito. |
| Descritor de job | Pequena estrutura com caminho, hash e destino de um job salvo. O payload MAT separado contém sua configuração; nenhum dos dois é um resultado científico calculado. |
