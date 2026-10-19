# Interpretação dos resultados e diagnóstico de erros

[English](../english%20version/RESULTS_AND_TROUBLESHOOTING.md) · [Índice](INDEX_PT_BR.md)

Concluir um cálculo não significa obter resultado cientificamente adequado. Confira configuração efetiva, contadores, rechecagem independente, estado e identidades antes de interpretar parâmetros ou usar a fonte em outra análise. Um ajuste sintético curto testa funcionamento, não recuperação de parâmetros ou convergência.

## Otimização e suportes

Examine trace, saída do solver, rechecagem NLL e estimativas em relação aos suportes. Soluções na fronteira são preservadas, mas podem indicar pouca informação, busca restrita ou inadequação do modelo. Não as descarte nem amplie suportes apenas para obter uma solução interna. Compare inícios e hipóteses cientificamente justificadas com orçamento separado. RMSE descreve o ajuste; NLL é o objetivo inferencial. NLL negativa não é necessariamente inválida: densidades contínuas dependem de unidades e escalas de erro.

## PL

Reestime os demais parâmetros a cada coordenada fixa e preserve o envelope inferior validado. Soluções numéricas diferentes na mesma coordenada não são limites de confiança distintos. Use `D=2*(NLL_profile-NLL_min)` e o limiar pretendido; o original de um parâmetro é 3.84145882069412. Uma solução condicional inferior pode desafiar a âncora; siga a política declarada sem truncar deviances negativas.

Permanecer abaixo do limiar na borda não fecha o intervalo nessa borda. Refine regiões de cruzamento com resolução adequada, preserve não monotonicidade e regiões desconectadas, e diferencie bracket de valor interpolado. Compensação mostra trajetórias dos ótimos reestimados, não correlação posterior. Intervalos com Kd fixo excluem a incerteza desse valor. Sensibilidade não é identificabilidade.

Fechamentos são buscas locais limitadas, não provas globais. HOLD, STOP, origens ausentes e malhas incompletas devem permanecer incompletos na consolidação. Aumentar um ponto não preenche o restante do perfil.

## MCMC

Confira quatro cadeias, mistura, Rhat por postos e ESS bulk/tail para todos os parâmetros. Os critérios originais são Rhat<1.01 e ambos ESS>400. Trace suave, aceitação ou histograma agrupado isoladamente não bastam. Revise propostas transformadas, suportes, priors, jacobiano, inícios e escalas relativas se a mistura for ruim. Adaptação pertence ao warmup; produção usa propostas congeladas. Não misture CS/PF nem use thinning para ocultar dependência.

Cadeias maiores podem reduzir erro Monte Carlo, mas não acrescentam informação ausente na verossimilhança. Prior informativo de Kd não equivale a identificação independente por dados aquosos. Não enfraqueça critérios para aprovar testes curtos. Preserve linhas conjuntas na seleção.

## Predição e cenários

Bandas da resposta média quantificam incerteza paramétrica sob o modelo; bandas preditivas também incluem erro observacional. Coberturas têm significados distintos. Respostas holdout devem ser lidas somente depois de fixar predições, sem reajustar parâmetros ou escalas de erro. Estudos externos exigem adaptações próprias de calendário, física, unidades e LOD.

Equivalência de escala temporal é uma normalização do coeficiente que preserva exposição, não decomposição causal ou recalibração. Redução da razão e redução da diferença de médias usam denominadores distintos. Dispersão nula em PF preserva advecção, sem parar o líquido. Como não há cinética explícita de transferência de massa líquido-sólido, uma interpretação física da mistura não é uma taxa de transferência simulada.

## Erros frequentes

| Sintoma | Verificação e ação |
|---|---|
| Identidade de código divergente | Confira cópia, códigos e receitas. Não ignore a checagem. Em cópia intencionalmente editada, revise alterações e inventário antes de novos jobs. Texto não altera identidade executável. |
| Destino existente | Examine a execução anterior. Use destino/runID novo ou retomada suportada de estado incompleto elegível. |
| Função ou licença ausente | Confira `which functionName -all`, `ver`, setup e licença MATLAB/toolbox. Instalação não garante licença disponível. |
| Campo interno ausente após preparo | O contrato superior não constrói a configuração. Consulte controlador, auxiliares e guia, sem inventar valores científicos. |
| Fonte de produção recusada | Confira identidade fechada, modo, convergência e linhas correspondentes. Renomear estado ou certificado não promove testes sintéticos. |
| Estado inválido ou negativo | Confira unidades, física, estado inicial, solver e política declarada. Não relaxe tolerâncias para ocultar falhas. |
| Erro de censura ou fase | Confira esquema, LOD, zeros, contagens e datas. Não duplique medições ou renomeie fases para satisfazer verificações. |
| Tempo ou orçamento esgotado | Preserve logs e tentativas. Avalie completude/retomada; a opção temporal não interrompe necessariamente um solver em andamento. |

Ao pedir ajuda, informe versão MATLAB, caminho da função, erro e stack exatos, análise/modo, orçamento/consumo, esquema das entradas e último estado coerente. Compartilhe apenas dados autorizados e prepare exemplo mínimo em pasta separada.
