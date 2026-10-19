# Uso de IA com o pacote

[English](../english%20version/AI_ASSISTANCE.md) · [Índice](INDEX_PT_BR.md)

IA pode ajudar a ler códigos, explicar configurações, propor adaptações e revisar erros. Não estabelece validade científica, não concede permissões dos dados e não substitui revisão humana. Não envie medições restritas, manuscritos ou dados pessoais a serviços de IA sem autorização. Revise códigos e comandos sugeridos antes de executar.

Use os prompts abaixo com acesso ao pacote ou forneça os arquivos relevantes. Substitua os trechos entre colchetes pelas suas informações. Os prompts não autorizam campanhas caras por padrão.

## Entender a arquitetura

> Leia README_PT_BR.md, docs/portuguese-br version/ARCHITECTURE_PT_BR.md, docs/portuguese-br version/INPUTS_PT_BR.md e docs/portuguese-br version/ANALYSES_PT_BR.md e confira as assinaturas reais das funções. Explique a rota para [análise e reator], distinguindo configuração, preparação, execução numérica e pós-processamento. Liste entradas, dependências, saídas e limitações. Não modifique arquivos nem execute modelos. Não infira dados ou padrões que não são fornecidos.

## Preparar um job

> Ajude a preparar um job [teste ou produção] para [análise e reator] com [pasta autorizada]. Leia docs/portuguese-br version/JOB_EXAMPLES_PT_BR.md e o controlador e auxiliares. Confira unidades, relógio, fases, LOD, estado inicial, ordem de parâmetros, suportes/priors, certificação de fontes e orçamento total. Mostre comandos, caminhos e saídas esperadas da preparação. Separe preparação de execução. Pergunte por escolhas científicas ausentes em vez de inventá-las. Não execute até eu aprovar explicitamente custo e destino.

## Adaptar a outro experimento

> Leia docs/portuguese-br version/USING_YOUR_OWN_DATA_PT_BR.md e a implementação. Compare [meu experimento] com o modelo. Separe entradas compatíveis de adaptações necessárias de relógio, fases, hidráulica, biomassa, estado inicial, capacidade, censura e priors. Proponha mudanças mínimas coerentes e testes em cópia separada. Preserve medições e resultados. Não transfira prior de Kd do SMX ou escalas de erro sem justificativa. Não execute otimização ou amostragem.

## Alterar código com segurança

> Para [alteração específica], identifique chamadores, verificações vinculadas, contadores, metadados e implicações do manifesto. Proponha alteração mínima em cópia separada, preservando o método salvo pedido explícito. Explique QA técnica e teste sintético limitado com tetos de tempo, forwards e armazenamento. Não remova assertivas nem retome checkpoints com código modificado. Aguarde autorização para cálculos científicos.

## Diagnosticar erro

> Examine [mensagem exata e arquivos salvos] e as funções relevantes sem repetir a execução científica. Distinga erros de entrada, esquema, caminho/licença, integridade, execução numérica e incompletude. Explique evidências, correção mínima e elegibilidade de retomada. Preserve tentativas, logs e checkpoints. Não fabrique sucesso, relaxe tolerâncias ou altere identidades de fontes para aprovar verificações.

## Revisar resultados

> Revise [pasta de saída] somente em leitura, usando configuração efetiva, contadores, traces, rechecagens e diagnósticos. Separe conclusão do software de convergência e adequação científica. Examine suportes, completude/compensação PL, convergência posterior e compatibilidade das fontes conforme aplicável. Distinga bandas paramétricas e preditivas. Cite valores efetivamente salvos e aponte evidência ausente sem inventá-la. Não reajuste, gere cadeias ou trate teste sintético como reprodução do artigo.

## Relatar assistência de IA

Descreva as tarefas efetivamente assistidas, mantendo responsabilidade humana pelos códigos, análises e interpretação. Se mencionar modelos ou ferramentas, use identificadores registrados, sem adivinhá-los pela interface ou por uma sessão posterior. Siga exigências da revista ou instituição. Este guia não afirma que todas as ferramentas, modelos ou prompts usados futuramente por terceiros foram utilizados no artigo associado.
