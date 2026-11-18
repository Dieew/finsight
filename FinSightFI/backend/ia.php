<?php
// FinSight FI — endpoint opcional da Fini.
// Copie config.example.php para config.php e configure a chave somente no servidor.
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

function respond($data, $status = 200) {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

$config = __DIR__ . '/config.php';
if (!is_file($config)) respond(['erro' => 'Backend não configurado. Copie config.example.php para config.php.'], 503);
require $config;

if (defined('API_TOKEN') && API_TOKEN !== '') {
    $provided = $_SERVER['HTTP_X_TOKEN'] ?? '';
    if (!hash_equals(API_TOKEN, $provided)) respond(['erro' => 'Não autorizado.'], 401);
}
if (!defined('ANTHROPIC_KEY') || ANTHROPIC_KEY === '' || ANTHROPIC_KEY === 'SUA_CHAVE_API') {
    respond(['erro' => 'Chave de IA não configurada no servidor.'], 503);
}
if (!defined('ANTHROPIC_MODEL') || ANTHROPIC_MODEL === '' || strpos(ANTHROPIC_MODEL, 'COLOQUE_') === 0) {
    respond(['erro' => 'Informe um identificador de modelo válido em config.php.'], 503);
}

$raw = file_get_contents('php://input');
if (strlen($raw) > 120000) respond(['erro' => 'Solicitação excede o limite de 120 KB.'], 413);
$input = json_decode($raw, true);
if (!is_array($input)) respond(['erro' => 'JSON inválido.'], 400);
$action = $input['acao'] ?? '';
$data = $input['dados'] ?? [];
if (!is_array($data)) respond(['erro' => 'Dados inválidos.'], 400);

$base = 'Responda em português do Brasil. Use somente os fatos enviados. Não invente dados, taxas, regras, garantias, valores, elegibilidade ou aprovação. Quando faltar informação, formule uma pergunta ou use [CONFIRMAR]. Não prometa aprovação de crédito nem retorno financeiro.';
$prompts = [
    'copiloto' => [
        'Você é Fini, copiloto de financiamento empresarial do FinSight FI. Sua tarefa é compreender a mensagem do consultor e organizar os dados para confirmação. Responda SOMENTE JSON válido no formato: {"resposta":"mensagem curta e acolhedora","campos":{"Investimento estimado":"R$ ...","Faturamento anual":"R$ ...","Setor":"...","UF":"...","Estágio do projeto":"...","Objetivo / desafio":"...","Prazo estimado":"...","Linha de referência":"...","Garantias mencionadas":"...","Regime tributário":"...","CNPJ":"..."},"orcamento":[{"category":"Máquinas e equipamentos|Equipe técnica|Laboratórios|Pilotos e protótipos|Software|Serviços tecnológicos|Instalações e infraestrutura|Obras civis|Treinamento|Capital de giro","description":"...","value":0,"status":"Estimado","evidence":"Informado em conversa; confirmar"}]}. Remova do objeto campos não identificados com segurança. Valores em reais devem ser números em orcamento e textos formatados em campos. Não duplique itens já existentes no contexto. Se nenhuma informação estruturável for identificada, retorne campos vazio e orçamento []. A mensagem deve dizer que tudo precisa ser confirmado antes de gravar.' . $base
    ],
    'edital' => [
        'Analise o edital/regulamento enviado e responda SOMENTE JSON válido: {"nome":"","entidade":"","criterios":[{"nome":"","peso":"","descricao":""}],"itens_financiaveis":[],"restricoes":[],"documentos":[],"secoes":[{"chave":"","titulo":"","orientacao":""}],"alertas":[]}. Extraia apenas o que estiver expressamente no texto. Quando não encontrar, deixe vazio. Inclua referências a seção/página quando o texto fornecer essa informação. ' . $base
    ],
    'redator' => [
        'Elabore o texto solicitado para um plano de negócios/carta-consulta de financiamento, em tom técnico e claro. Organize em seções, relacione problema, solução, atividades, equipe, orçamento, cronograma e impactos. Não preencha lacunas com invenções: marque [CONFIRMAR: ...]. Não declare elegibilidade nem aprovação. Responda somente com o texto. ' . $base
    ],
    'revisor' => [
        'Faça revisão crítica de consistência técnica, financeira e documental de uma oportunidade de financiamento. Responda SOMENTE JSON válido: {"resumo":"","achados":[{"gravidade":"alta|média|baixa","area":"...","descricao":"...","acao":"..."}],"pendencias":["..."],"pontos_fortes":["..."]}. Notas de qualidade não representam chance de aprovação. ' . $base
    ]
];
if (!isset($prompts[$action])) respond(['erro' => 'Ação não reconhecida.'], 400);

$payloadText = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
if ($payloadText === false) respond(['erro' => 'Não foi possível serializar os dados.'], 400);
if (strlen($payloadText) > 100000) respond(['erro' => 'Dados muito extensos para análise.'], 413);

$body = [
    'model' => ANTHROPIC_MODEL,
    'max_tokens' => ($action === 'edital' || $action === 'copiloto' || $action === 'revisor') ? 3500 : 5000,
    'system' => $prompts[$action],
    'messages' => [[ 'role' => 'user', 'content' => $payloadText ]]
];
$ch = curl_init('https://api.anthropic.com/v1/messages');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_CONNECTTIMEOUT => 15,
    CURLOPT_TIMEOUT => 90,
    CURLOPT_HTTPHEADER => [
        'content-type: application/json',
        'x-api-key: ' . ANTHROPIC_KEY,
        'anthropic-version: 2023-06-01'
    ],
    CURLOPT_POSTFIELDS => json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
]);
$response = curl_exec($ch);
$http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);
if ($response === false) respond(['erro' => 'Falha de conexão com o provedor de IA: ' . $error], 502);
$provider = json_decode($response, true);
if ($http < 200 || $http >= 300 || empty($provider['content'][0]['text'])) {
    respond(['erro' => $provider['error']['message'] ?? 'Provedor de IA não retornou conteúdo.'], 502);
}
$text = trim($provider['content'][0]['text']);
if ($action === 'redator') respond(['texto' => $text]);
$text = preg_replace('/^```(?:json)?\s*|\s*```$/m', '', $text);
$result = json_decode($text, true);
if (!is_array($result)) respond(['erro' => 'A IA retornou um formato inesperado. Tente novamente.'], 502);
respond(['dados' => $result]);
