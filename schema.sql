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
  categoria TEXT,                -- cameras, automacao, som, rede, outros
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
