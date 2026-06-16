# CONTEXT_BACKUP — AURON HOME SYSTEMS
> Criado em: 2026-06-16 | Sessao 1 (sistema novo, do zero)

---

## 1. Resumo Executivo

**Sistema:** Auron Home Systems — gestao de orcamentos, contratos, recibos, clientes e catalogo de equipamentos (automacao residencial / CFTV / rede / audio).
**Empresa:** Auron Home Systems — CNPJ 50.081.460/0001-60 — resp. Gustavo Martins Costa — Cuiaba/MT.
**Diretorio local:** `C:\Users\gusta\Documents\Sistema\`
**Deploy:** Vercel via GitHub Desktop (mesmo fluxo do SAOS — commit + push, CI auto-deploy).

**Stack:** HTML/CSS/JS vanilla (sem framework) · Supabase (PostgreSQL + Auth + Storage) · supabase-js v2 via CDN · Vercel (static + headers/CSP). Sem serverless por enquanto (upload de foto vai direto do client pro Storage).

**Origem:** evolucao de 3 geradores standalone (orcamento.html, recibo.html, contrato.html em `Documents/`) que usavam localStorage e catalogo hardcoded. Agora tudo persiste no Supabase, com login, clientes vinculados e catalogo no banco.

---

## 2. Supabase

- **URL:** `https://ahxlnebxffkrkacnacss.supabase.co`
- **anon key:** inline em `utils.js` (`SUPABASE_KEY`).
- **Auth:** e-mail/senha (`signInWithPassword`). Usuarios criados no painel Supabase (Authentication > Users > Add user) — **nao ha cadastro publico**.
- **Storage bucket:** `equipamentos` (publico) — fotos de equipamentos E fotos de contrato. Upload client-side com compressao (`comprimirImagem` 1280px q0.82).
- **RLS:** todas as tabelas `FOR ALL TO authenticated USING(true)` — qualquer usuario logado le/escreve tudo.

### Tabelas (ver schema.sql)
`clientes` (central, flag `entregue`) · `equipamentos` (catalogo + fotos) · `orcamentos` · `contratos` · `recibos`. Os 3 documentos referenciam `cliente_id` (ON DELETE SET NULL).

### SETUP pendente no painel Supabase (rodar 1x)
1. **SQL Editor:** colar e rodar `schema.sql` (cria tabelas + RLS).
2. **Storage:** New bucket > nome `equipamentos` > marcar **Public**. (ou rodar o bloco comentado de storage no fim do schema.sql)
3. **Authentication > Users:** criar o(s) usuario(s) com e-mail/senha.

---

## 3. Preferencias do usuario (herdadas do SAOS)

- **Sem emojis no codigo.**
- Respostas curtas e diretas.
- **Nao implementar nada antes de confirmar** (sobretudo dinheiro, exclusao de dados, schema).
- Filtros dinamicos (do banco, nao hardcoded).
- **Registrar toda alteracao neste CONTEXT_BACKUP.md** e, ao terminar, **dizer quais arquivos precisam de deploy**.
- Bumpar o `<!-- build: AAAA-MM-DD... -->` (linha 1) das paginas HTML a cada alteracao, para conferir no view-source se a versao nova esta no ar.

---

## 4. Arquivos

| Arquivo | Papel |
|---|---|
| `login.html` | Login Supabase Auth. Se ja logado, redireciona pro dashboard. build 2026-06-16a |
| `dashboard.html` | KPIs (clientes/aberto/entregue/orcamentos/contratos/equipamentos) + CRUD de equipamentos com upload de foto pro Storage. build 2026-06-16a |
| `clientes.html` | Abas Em aberto / Entregues, busca, CRUD, marcar entregue/reabrir, links pro historico (orcamentos/contratos/recibos do cliente). build 2026-06-16a |
| `orcamentos.html` | Gerador (catalogo vem de `equipamentos`) + salvar/abrir/excluir no banco + imprimir. build 2026-06-16a |
| `recibos.html` | Gerador de recibo (valor por extenso) + salvar/abrir/excluir + imprimir. build 2026-06-16a |
| `contratos.html` | Gerador completo (clausulas, intermediador, exigencias, parcelas, testemunhas, fotos no Storage) + salvar/abrir/excluir + imprimir. build 2026-06-16a |
| `utils.js` | Cliente Supabase, `requireAuth`, `renderTopbar`, helpers (fmtBRL, extenso, fmtData, showToast, modal, uploadFotoEquip, comprimirImagem, carregarClientesSelect), const EMPRESA, LOGO_SVG, NAV_LINKS. |
| `app-shell.css` | Estilo compartilhado: topbar, layout, cards/KPIs, form, botoes, tabela, badges, abas, modal, toast. Identidade navy #0d1b2a + dourado #c8a96e. |
| `schema.sql` | DDL completo (tabelas + RLS + bloco de storage comentado). |
| `vercel.json` | Redirect / -> login.html + headers de seguranca + CSP (libera supabase.co, jsdelivr, google fonts). |

**Logo:** os geradores originais usavam `minha-logo.jpg` na pasta; aqui o sistema usa o **LOGO_SVG** (em utils.js) por padrao. Se quiser a logo em imagem, colocar o arquivo e ajustar.

---

## 5. Padroes tecnicos

- Toda pagina protegida chama `renderTopbar('<id>')` no init, que por sua vez chama `requireAuth()` (redireciona pro login se sem sessao).
- supabase-js carregado via `<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>` ANTES de `utils.js`.
- Geradores (orcamento/recibo/contrato): layout `#gen` = sidebar 380px + preview; ao salvar gravam JSONB (itens/servicos/parcelas/fotos). `editId` controla insert vs update; "Abrir" dos salvos carrega no form e regenera o preview.
- Catalogo do orcamento vem de `equipamentos` agrupado por `categoria` (cameras/automacao/som/rede/outros). Selecionar item preenche o preco automaticamente.
- Impressao: `@media print` esconde topbar/sidebar e imprime so o `#...-doc`. Usar hifen `-` (nao em-dash).
- "Em aberto" vs "Entregues" = filtro do campo `clientes.entregue` (decisao do usuario: flag no cliente, nao status por projeto).

---

## 6. Pendencias / proximos passos

1. **Rodar o setup do Supabase** (schema.sql + bucket `equipamentos` Public + criar usuario) — sem isso o login e os dados nao funcionam.
2. Testar login e fluxo completo em producao apos deploy.
3. (Opcional) Vincular orcamento aprovado -> gerar contrato/recibo do mesmo cliente automaticamente.
4. (Opcional) Logo em imagem no lugar do SVG.
5. (Opcional) Numeracao sequencial real de orcamento/recibo/contrato (hoje usa timestamp; sem contador atomico no banco).

---

## 7. Deploy

Arquivos a subir (todos novos): `login.html, dashboard.html, clientes.html, orcamentos.html, recibos.html, contratos.html, utils.js, app-shell.css, vercel.json, package.json, .gitignore`. `schema.sql` e doc de setup (nao precisa ir, mas nao atrapalha).
