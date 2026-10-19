# Modelos MATLAB para remoção de SMX em reatores anaeróbios de leito fixo

[English](README.md) · [Índice da documentação](docs/portuguese-br%20version/INDEX_PT_BR.md)

O pacote oferece as implementações MATLAB de calibração, verossimilhança de perfil, sensibilidade global, inferência bayesiana, propagação de incertezas, avaliações com dados independentes, aplicabilidade para OFL e análises de cenários do estudo associado ao Journal of Water Process Engineering. Os modelos CS-AnFBR e PF-AnFBR compartilham a estrutura cinética, mas usam representações hidráulicas diferentes. O estudo de caracterização hidrodinâmica não está incluído.

## Requisitos

MATLAB R2022b ou posterior, com Global Optimization Toolbox para `surrogateopt` e `patternsearch`, e Optimization Toolbox para a comparação dos modelos de erro com `fmincon`. MATLAB e toolboxes não são redistribuídos. São necessários recursos de tabelas e JVM. O ambiente de referência verificado é MATLAB R2022b no Windows; outras versões e sistemas não foram qualificados independentemente nesta distribuição. Instalação e disponibilidade da licença são condições diferentes.

## Primeiros passos

Abra a pasta que contém `setup_jwpe.m` e execute:

```matlab
previousPath = path;
info = setup_jwpe();
disp(info)
which jwpe_prepare_m1 -all
which jwpe_job -all
```

Isso configura a sessão e verifica os arquivos, sem simulação ou ajuste. Siga o [guia inicial](docs/portuguese-br%20version/GETTING_STARTED_PT_BR.md) para gerar entradas fictícias e preparar uma calibração curta. A preparação e a execução são comandos separados. Use uma pasta de trabalho externa ao pacote para entradas geradas, jobs e resultados. Ao terminar, `path(previousPath)` restaura o caminho anterior.

A primeira função efetiva indicada por `which -all` deve pertencer a esta cópia. Entradas posteriores marcadas como `Shadowed` não são usadas. Se outra cópia estiver efetiva, use uma sessão limpa ou remova somente os caminhos dessa cópia na sessão, sem excluir arquivos ou redefinir configurações não relacionadas do MATLAB.

## Conteúdo e acesso aos dados

A distribuição contém códigos, configurações de método e um gerador de entradas sintéticas. Não contém medições experimentais, condições hidráulicas ou de biomassa medidas, cadeias retidas do artigo, resultados calculados ou figuras. Os exemplos não reproduzem os números do artigo. Otimizações e métodos de Monte Carlo podem produzir resultados diferentes entre execuções.

Para reprodução numérica completa, solicite explicitamente os materiais ao autor correspondente do artigo, observadas as permissões dos proprietários dos dados. A licença do código não concede acesso nem direitos sobre esses materiais. Consulte [Acesso aos dados](docs/portuguese-br%20version/DATA_ACCESS_PT_BR.md). Antes de usar outro experimento ou composto, leia [Uso com dados próprios](docs/portuguese-br%20version/USING_YOUR_OWN_DATA_PT_BR.md).

## Organização

- `src/api`: interfaces de preparação, inspeção e gerenciamento de jobs.
- `src/kernels`: equações, integração, verossimilhança, otimização e funções estatísticas.
- `analyses`: controladores e verificações das fontes de resultados.
- `analyses/recipes`: catálogos das coordenadas e opções dos perfis.
- `examples`: geração de entradas fictícias.
- `docs`: instruções em inglês e português.
- `code_manifest.json`: identidade dos códigos e receitas, independente dos textos.

Consulte [Arquitetura](docs/portuguese-br%20version/ARCHITECTURE_PT_BR.md), [Exemplos de jobs](docs/portuguese-br%20version/JOB_EXAMPLES_PT_BR.md) e [Orçamentos de campanhas](docs/portuguese-br%20version/CAMPAIGN_BUDGETS_PT_BR.md).

## Interpretação e licença

As interfaces preservam hipóteses específicas do estudo, incluindo calendários e contagens de observações quando exigidos. As respostas da Fase III não entram no fluxo final de calibração M1, PL, GSA ou MCMC. Uma execução curta não demonstra convergência ou identificabilidade. Resultados incompletos não podem ser tratados como inferências aceitas; bandas da resposta média e preditivas têm significados diferentes.

A comparação opcional dos modelos de erro é uma análise histórica separada de M0. Seu finalizador conjunto exige 50 observações por reator e horizonte de origem de 145 d, incluindo os registros históricos da Fase III. Ela não corresponde à calibração M1 de 33 observações das Fases I–II; suas fontes históricas não substituem as fontes da calibração final ou da posterior. Consulte [Interfaces de análise](docs/portuguese-br%20version/ANALYSES_PT_BR.md#comparações-e-inferência).

O código próprio é disponibilizado sob a licença MIT. `LICENSE` e `THIRD_PARTY_NOTICES.md` contêm os termos e avisos aplicáveis; esta explicação não os substitui. Cite o artigo associado e os estudos experimentais pertinentes ao utilizar seus métodos ou dados.
