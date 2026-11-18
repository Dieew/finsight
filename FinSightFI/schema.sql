-- FinSight FI - esquema MySQL (Locaweb: MySQL 5.7+/MariaDB). Importar via phpMyAdmin.
-- Estratégia de flexibilidade: cada tabela tem colunas-chave + coluna `extra` (JSON em LONGTEXT).
-- Campos novos de tela vão em `extra` automaticamente (api.php) sem alterar o banco.
-- Para campos que precisem de filtro/índice, use ALTER TABLE ... ADD COLUMN; a api.php detecta sozinha.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY, nome VARCHAR(150), email VARCHAR(150) UNIQUE,
  senha_hash VARCHAR(255), perfil VARCHAR(30) DEFAULT 'consultor', ativo TINYINT DEFAULT 1,
  extra LONGTEXT, criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS empresas (
  id INT AUTO_INCREMENT PRIMARY KEY, razao_social VARCHAR(200), cnpj VARCHAR(20), setor VARCHAR(100),
  porte VARCHAR(10), uf CHAR(2), faturamento DECIMAL(16,2), extra LONGTEXT,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP, atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY (cnpj), KEY (setor), KEY (porte)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS oportunidades (
  id INT AUTO_INCREMENT PRIMARY KEY, empresa_id INT NULL, usuario_id INT NULL,
  titulo VARCHAR(200), etapa VARCHAR(40) DEFAULT 'diagnostico', valor_total DECIMAL(16,2) DEFAULT 0,
  extra LONGTEXT, criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP, atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY (empresa_id), KEY (etapa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS orcamento (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, categoria VARCHAR(60), descricao VARCHAR(255),
  valor DECIMAL(16,2) DEFAULT 0, status VARCHAR(20) DEFAULT 'estimado', fornecedor VARCHAR(150), evidencia_id INT NULL,
  extra LONGTEXT, KEY (oportunidade_id), KEY (categoria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS linhas (
  id INT AUTO_INCREMENT PRIMARY KEY, instituicao VARCHAR(60), nome VARCHAR(200), finalidade TEXT,
  valor_min DECIMAL(16,2), valor_max DECIMAL(16,2), participacao_pct DECIMAL(5,2), vigencia_ate DATE NULL,
  fonte_url VARCHAR(255), ativo TINYINT DEFAULT 1,
  extra LONGTEXT, -- portes, ufs, setores, itens financiáveis, restrições, garantias, documentação
  KEY (instituicao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cenarios (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, tipo VARCHAR(30), linha_id INT NULL,
  valor_financiado DECIMAL(16,2), prazo_meses INT, carencia_meses INT, taxa_aa DECIMAL(7,3),
  resultado LONGTEXT, extra LONGTEXT, KEY (oportunidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cronograma (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, etapa VARCHAR(200), inicio_mes INT, fim_mes INT,
  entrega VARCHAR(255), marco VARCHAR(255), categoria VARCHAR(60), valor DECIMAL(16,2), evidencia VARCHAR(255), extra LONGTEXT,
  KEY (oportunidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS riscos (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, tipo VARCHAR(40), descricao TEXT, causa TEXT,
  probabilidade TINYINT, impacto TINYINT, mitigacao TEXT, responsavel VARCHAR(100), evidencia VARCHAR(255),
  extra LONGTEXT, KEY (oportunidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS impactos (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, dimensao VARCHAR(30), situacao_atual TEXT,
  resultado_esperado TEXT, indicador VARCHAR(150), linha_base VARCHAR(60), meta VARCHAR(60), prazo VARCHAR(40),
  comprovacao VARCHAR(255), extra LONGTEXT, KEY (oportunidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS documentos (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NULL, empresa_id INT NULL, tipo VARCHAR(60), nome VARCHAR(200),
  status VARCHAR(20) DEFAULT 'pendente', versao VARCHAR(20), validade DATE NULL, responsavel VARCHAR(100),
  criticidade VARCHAR(10) DEFAULT 'media', arquivo VARCHAR(255), extra LONGTEXT, KEY (oportunidade_id), KEY (empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS casos (
  id INT AUTO_INCREMENT PRIMARY KEY, titulo VARCHAR(200), setor VARCHAR(100), porte VARCHAR(10), finalidade VARCHAR(150),
  categoria_investimento VARCHAR(60), faixa_valor VARCHAR(60), instrumento VARCHAR(100),
  extra LONGTEXT, -- requisitos, dificuldades, argumentos, evidências, aprendizados
  KEY (setor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS validacoes (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, linha_id INT NULL,
  aderencia TINYINT, prontidao TINYINT, consistencia TINYINT, confianca TINYINT,
  achados LONGTEXT, extra LONGTEXT, criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP, KEY (oportunidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS versoes ( -- histórico: snapshot completo a cada salvamento
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, snapshot LONGTEXT, autor VARCHAR(100),
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP, KEY (oportunidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabela genérica para campos novos criados em telas futuras (entidade/chave/valor)
CREATE TABLE IF NOT EXISTS campos_extras (
  id INT AUTO_INCREMENT PRIMARY KEY, entidade VARCHAR(40), entidade_id INT, chave VARCHAR(80), valor LONGTEXT,
  extra LONGTEXT, UNIQUE KEY u (entidade, entidade_id, chave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Linhas de exemplo (ILUSTRATIVAS: validar valores, regras e vigência na fonte oficial antes de usar)
INSERT INTO linhas (instituicao,nome,finalidade,valor_min,valor_max,participacao_pct,fonte_url,extra) VALUES
('FINEP','Inovação (exemplo)','Projetos de P&D e inovação',1000000,150000000,80,'https://www.finep.gov.br','{"portes":["M","G"],"ufs":"*","setores":"*","itens":["Software","Equipe técnica","Laboratórios","Pilotos","Máquinas e equipamentos","Serviços tecnológicos"]}'),
('BNDES','Modernização Produtiva (exemplo)','Máquinas, expansão e transformação digital',1000000,300000000,80,'https://www.bndes.gov.br','{"portes":["M","G"],"ufs":"*","setores":"*","itens":["Máquinas e equipamentos","Software","Instalações","Obras civis","Treinamento"]}'),
('Embrapii','Projetos cooperativos (exemplo)','P&D com unidades credenciadas',300000,20000000,33,'https://embrapii.org.br','{"portes":["P","M","G"],"ufs":"*","setores":"*","itens":["Equipe técnica","Serviços tecnológicos","Pilotos"]}'),
('Sebrae','Inovação para pequenas empresas (exemplo)','Subvenção/consultoria para PMEs',20000,500000,50,'https://www.sebrae.com.br','{"portes":["P"],"ufs":"*","setores":"*","itens":["Serviços tecnológicos","Software","Treinamento"]}'),
('FAPESP','PIPE (exemplo)','P&D em pequenas empresas',100000,3000000,100,'https://fapesp.br','{"portes":["P"],"ufs":["SP"],"setores":"*","itens":["Equipe técnica","Serviços tecnológicos","Laboratórios"]}'),
('BRDE','Investimento regional (exemplo)','Expansão industrial no Sul',500000,100000000,80,'https://www.brde.com.br','{"portes":["P","M","G"],"ufs":["RS","SC","PR"],"setores":"*","itens":["Máquinas e equipamentos","Obras civis","Instalações","Infraestrutura"]}');
