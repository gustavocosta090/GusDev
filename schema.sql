-- ============================================================
-- AURON HOME SYSTEMS — Schema do banco (Supabase / PostgreSQL)
-- Rodar no painel: SQL Editor > New query > colar tudo > Run
-- ============================================================

-- CLIENTES (entidade central)
CREATE TABLE IF NOT EXISTS clientes (
  id BIGSERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  doc TEXT,                      -- CPF/CNPJ
  email TEXT, telefone TEXT, endereco TEXT,
  tipo_imovel TEXT,
  entregue BOOLEAN DEFAULT false,
  entregue_em TIMESTAMPTZ,
  observacoes TEXT,
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- EQUIPAMENTOS (catalogo + dashboard de fotos; alimenta os orcamentos)
CREATE TABLE IF NOT EXISTS equipamentos (
  id BIGSERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  categoria TEXT,                -- seguranca, automacao, som, rede, outros
  descricao TEXT,
  preco NUMERIC(12,2),
  foto_url TEXT,                 -- Supabase Storage
  ativo BOOLEAN DEFAULT true,
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- ORCAMENTOS
CREATE TABLE IF NOT EXISTS orcamentos (
  id BIGSERIAL PRIMARY KEY,
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,
  numero TEXT, projeto TEXT, validade TEXT,
  itens JSONB DEFAULT '[]',      -- [{nome,qtd,preco,categoria,img}]
  desconto NUMERIC(5,2) DEFAULT 0,
  subtotal NUMERIC(12,2), total NUMERIC(12,2),
  prazo TEXT, pagamento TEXT, garantia TEXT, observacoes TEXT,
  status TEXT DEFAULT 'aberto',  -- aberto, aprovado, recusado
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- CONTRATOS
CREATE TABLE IF NOT EXISTS contratos (
  id BIGSERIAL PRIMARY KEY,
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,
  numero TEXT, data DATE, cidade TEXT,
  tipo TEXT, servicos TEXT, materiais TEXT,
  valor_total NUMERIC(12,2), forma_pagamento TEXT,
  parcelas JSONB DEFAULT '[]',
  multa TEXT, garantia TEXT, suporte TEXT,
  intermediador JSONB, exigencias JSONB, fotos JSONB,
  testemunhas JSONB,
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- RECIBOS
CREATE TABLE IF NOT EXISTS recibos (
  id BIGSERIAL PRIMARY KEY,
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,
  numero TEXT, data DATE,
  servicos JSONB DEFAULT '[]',   -- [{nome,desc,valor}]
  total NUMERIC(12,2),
  forma_pagamento TEXT, status TEXT DEFAULT 'pago',
  observacoes TEXT,
  criado_em TIMESTAMPTZ DEFAULT now()
);

-- RLS: somente usuarios autenticados (sistema tem login)
ALTER TABLE clientes     ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE orcamentos   ENABLE ROW LEVEL SECURITY;
ALTER TABLE contratos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE recibos      ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "auth_all" ON clientes;
DROP POLICY IF EXISTS "auth_all" ON equipamentos;
DROP POLICY IF EXISTS "auth_all" ON orcamentos;
DROP POLICY IF EXISTS "auth_all" ON contratos;
DROP POLICY IF EXISTS "auth_all" ON recibos;

CREATE POLICY "auth_all" ON clientes     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON equipamentos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON orcamentos   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON contratos    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON recibos      FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- MIGRACAO: ABA FINANCEIRA (rodar 1x no SQL Editor)
-- Uma tabela unica cobre contas a pagar e a receber.
-- ============================================================
CREATE TABLE IF NOT EXISTS lancamentos (
  id BIGSERIAL PRIMARY KEY,
  tipo TEXT NOT NULL,                       -- 'pagar' | 'receber'
  descricao TEXT NOT NULL,
  categoria TEXT,                           -- dinamica (vem dos proprios registros)
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,  -- usado em 'receber'
  fornecedor TEXT,                          -- usado em 'pagar'
  valor NUMERIC(12,2) NOT NULL DEFAULT 0,
  vencimento DATE,
  pago BOOLEAN DEFAULT false,               -- quitado (pago ou recebido)
  pago_em DATE,
  origem TEXT DEFAULT 'manual',             -- 'manual' | 'contrato'
  origem_id BIGINT,                         -- id do contrato de origem
  parcela_idx INT,                          -- indice da parcela (evita duplicar)
  observacoes TEXT,
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE lancamentos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_all" ON lancamentos;
CREATE POLICY "auth_all" ON lancamentos FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- MIGRACAO: TIPO no catalogo (produto x servico/mao de obra)
-- 'servico' = servico de instalacao (entra como mao de obra nas metricas)
-- ============================================================
ALTER TABLE equipamentos ADD COLUMN IF NOT EXISTS tipo TEXT DEFAULT 'produto';

-- ============================================================
-- MIGRACAO: renomear categoria 'cameras' -> 'seguranca' (rodar 1x)
-- Atualiza o catalogo e os itens (JSONB) dos orcamentos ja salvos.
-- ============================================================
UPDATE equipamentos SET categoria = 'seguranca' WHERE categoria = 'cameras';

UPDATE orcamentos
SET itens = (
  SELECT jsonb_agg(
    CASE WHEN elem->>'categoria' = 'cameras'
         THEN jsonb_set(elem, '{categoria}', '"seguranca"')
         ELSE elem END
  )
  FROM jsonb_array_elements(itens) elem
)
WHERE itens @> '[{"categoria":"cameras"}]';

-- ============================================================
-- MIGRACAO: produtos do orcamento no contrato (rodar 1x)
-- itens = itens vinculados do orcamento; garantia_produto = prazo dos produtos
-- ============================================================
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS itens JSONB DEFAULT '[]';
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS garantia_produto TEXT;

-- ============================================================
-- MIGRACAO: forma de pagamento, recorrencia e parcelamento (rodar 1x)
-- forma_pagamento (pagar/receber); recorrente = gera a proxima ao pagar;
-- parcela_total = total de parcelas (parcela_idx ja existe).
-- ============================================================
ALTER TABLE lancamentos ADD COLUMN IF NOT EXISTS forma_pagamento TEXT;
ALTER TABLE lancamentos ADD COLUMN IF NOT EXISTS recorrente BOOLEAN DEFAULT false;
ALTER TABLE lancamentos ADD COLUMN IF NOT EXISTS parcela_total INT;

-- ============================================================
-- MIGRACAO: contrato de servico/manutencao (rodar 1x)
-- modalidade 'padrao' | 'servico'; servico = config do pacote mensal (JSONB)
-- ============================================================
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS modalidade TEXT DEFAULT 'padrao';
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS servico JSONB;

-- ============================================================
-- MIGRACAO: custo/margem no equipamento + compras (rodar 1x)
-- preco = preco de venda; preco_custo = custo; margem = markup % sobre custo.
-- ============================================================
ALTER TABLE equipamentos ADD COLUMN IF NOT EXISTS preco_custo NUMERIC(12,2);
ALTER TABLE equipamentos ADD COLUMN IF NOT EXISTS margem NUMERIC(5,2);

CREATE TABLE IF NOT EXISTS compras (
  id BIGSERIAL PRIMARY KEY,
  descricao TEXT NOT NULL,
  insumo BOOLEAN DEFAULT false,                 -- true = insumo geral (sem cliente)
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,
  equipamento_id BIGINT REFERENCES equipamentos(id) ON DELETE SET NULL,
  orcamento_id BIGINT REFERENCES orcamentos(id) ON DELETE SET NULL,
  quantidade NUMERIC(12,2) DEFAULT 1,
  custo_unit NUMERIC(12,2) DEFAULT 0,
  fornecedor TEXT,
  data DATE,
  forma_pagamento TEXT,
  lancamento_id BIGINT REFERENCES lancamentos(id) ON DELETE SET NULL,  -- conta a pagar gerada
  observacoes TEXT,
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE compras ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_all" ON compras;
CREATE POLICY "auth_all" ON compras FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- MIGRACAO: lucro real por cliente (rodar 1x)
-- custo_atualizado_em = data da ultima cotacao do custo;
-- comprometido = custo de atendimento reservado/previsto (ainda nao pago);
-- config = parametros globais (gasolina, consumo, reserva).
-- ============================================================
ALTER TABLE equipamentos ADD COLUMN IF NOT EXISTS custo_atualizado_em DATE;
ALTER TABLE lancamentos  ADD COLUMN IF NOT EXISTS comprometido BOOLEAN DEFAULT false;

CREATE TABLE IF NOT EXISTS config (
  chave TEXT PRIMARY KEY,
  valor TEXT
);
ALTER TABLE config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_all" ON config;
CREATE POLICY "auth_all" ON config FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO config (chave, valor) VALUES
  ('gasolina_litro','6.00'), ('consumo_kml','10'), ('reserva_padrao','150')
  ON CONFLICT (chave) DO NOTHING;

-- ============================================================
-- STORAGE (rodar depois de criar o bucket no painel)
-- Storage > New bucket > nome: "equipamentos" > marcar Public
-- Policies para upload/update/delete por usuarios logados:
-- ============================================================
-- (Se preferir por SQL, rode tambem:)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('equipamentos','equipamentos',true)
--   ON CONFLICT (id) DO NOTHING;
-- CREATE POLICY "equip_read"   ON storage.objects FOR SELECT USING (bucket_id = 'equipamentos');
-- CREATE POLICY "equip_write"  ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'equipamentos');
-- CREATE POLICY "equip_update" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'equipamentos');
-- CREATE POLICY "equip_delete" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'equipamentos');
