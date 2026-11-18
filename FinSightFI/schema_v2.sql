-- FinSight FI v2: biblioteca de editais, seções redigidas e log de uso da IA. Importar após schema.sql.
SET NAMES utf8mb4;
CREATE TABLE IF NOT EXISTS editais (
  id INT AUTO_INCREMENT PRIMARY KEY, entidade VARCHAR(60), nome VARCHAR(255), texto LONGTEXT,
  regras LONGTEXT, formulario LONGTEXT, vigencia_ate DATE NULL, extra LONGTEXT, criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP, KEY (entidade)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS secoes (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NOT NULL, edital_id INT NULL, chave VARCHAR(80), titulo VARCHAR(200),
  conteudo LONGTEXT, status VARCHAR(20) DEFAULT 'rascunho', versao INT DEFAULT 1, extra LONGTEXT,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, KEY (oportunidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS ia_logs (
  id INT AUTO_INCREMENT PRIMARY KEY, oportunidade_id INT NULL, agente VARCHAR(30), entrada_chars INT, saida_chars INT, extra LONGTEXT,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
