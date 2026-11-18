# FinSight FI — entrega visual final

## Arquivo principal
- `index.html`: aplicação integrada, com visual alinhado ao MVP de referência enviado.
- `assets/fini-avatar.png`: avatar oficial da Fini utilizado no botão e na janela de conversa.

## O que esta entrega preserva
- Pipeline de financiamento em quatro macroetapas.
- Carteira de demonstração com 36 empresas fictícias e oportunidades.
- Radar de financiamento com fontes identificadas como aguardando API.
- Diagnóstico financeiro, documentos, garantias, desembolsos e prestação de contas.
- Estruturação do pleito: orçamento, cronograma, riscos, impactos, plano de negócios, edital, revisão e entregável.
- Simulador estratégico financiamento + CDI com premissas editáveis.
- Fini com conversa, confirmação de propostas, ditado e resposta falada, conforme suporte do navegador e configuração de IA.
- Modo local com persistência no navegador.

## Execução
Abra `index.html` em um navegador moderno. Para servir os endpoints PHP e MySQL, publique também `backend/`, `schema.sql` e `schema_v2.sql`, configure o servidor e defina credenciais próprias em arquivo de configuração fora da pasta pública.

## Limites demonstrativos
A carteira e os valores iniciais são fictícios. A conexão com Woody/SSO e as APIs de financiamento não está ativa; o radar mostra explicitamente `Aguardando API`. A Fini usa o modo local demonstrativo quando o backend de IA não estiver configurado. Os resultados do simulador são estimativas condicionadas às premissas, não promessa de rendimento, crédito ou aprovação.
