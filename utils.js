/* ============================================================
   AURON HOME SYSTEMS — utils.js
   Cliente Supabase, guard de sessao, topbar, helpers.
   Requer: <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
   ============================================================ */

const SUPABASE_URL = 'https://ahxlnebxffkrkacnacss.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFoeGxuZWJ4ZmZrcmthY25hY3NzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MzE5MjQsImV4cCI6MjA5NzIwNzkyNH0.q1WzhwsE2nwJPIfM1EzQ1w7YbiRKOM7pn_exE75le0g';

const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
const EQUIP_BUCKET = 'equipamentos';

// ── DADOS FIXOS DA EMPRESA ──
const EMPRESA = {
  nome:        'Auron Home Systems',
  responsavel: 'Gustavo Martins Costa',
  cnpj:        '50.081.460/0001-60',
  endereco:    'Rua Tenente Eulalio Guerra, no 502, Cuiaba - MT',
  pix:         '50.081.460/0001-60 (CNPJ) - Banco Sicredi',
  banco:       'Banco Sicredi',
};

// ── NAV ──
const NAV_LINKS = [
  {id:'dashboard',  href:'dashboard.html',  label:'Dashboard'},
  {id:'clientes',   href:'clientes.html',   label:'Clientes'},
  {id:'orcamentos', href:'orcamentos.html', label:'Orcamentos'},
  {id:'contratos',  href:'contratos.html',  label:'Contratos'},
  {id:'recibos',    href:'recibos.html',    label:'Recibos'},
];

// Logo em SVG (fallback caso logo.png nao exista na pasta)
function svgLogo(size){
  size = size || 34;
  return `<svg viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg" style="height:${size}px;width:${size}px;">
    <circle cx="100" cy="100" r="78" stroke="#c8a96e" stroke-width="6"/>
    <path d="M100 26 C100 26 158 76 158 113 C158 147 132 170 100 170 C68 170 42 147 42 113 C42 76 100 26 100 26Z" stroke="#c8a96e" stroke-width="6" fill="none"/>
    <line x1="100" y1="26" x2="42" y2="170" stroke="#c8a96e" stroke-width="6" stroke-linecap="round"/>
    <line x1="100" y1="26" x2="158" y2="170" stroke="#c8a96e" stroke-width="6" stroke-linecap="round"/>
    <line x1="61" y1="128" x2="139" y2="128" stroke="#c8a96e" stroke-width="6" stroke-linecap="round"/>
  </svg>`;
}

// Logo oficial: usa logo.png da pasta; se faltar, cai no SVG.
function logoHTML(size){
  size = size || 34;
  return `<img src="logo.png" alt="Auron" style="height:${size}px;width:auto;object-fit:contain;display:block;" `
    + `onerror="this.style.display='none';this.nextElementSibling.style.display='inline-block';">`
    + `<span style="display:none;line-height:0;">${svgLogo(size)}</span>`;
}

const LOGO_SVG = svgLogo(34); // compat

// ── GUARD: protege a pagina. Redireciona pro login se nao houver sessao. ──
async function requireAuth(){
  const { data:{ session } } = await db.auth.getSession();
  if(!session){ location.replace('login.html'); return null; }
  return session;
}

// ── TOPBAR ──
async function renderTopbar(activeId){
  const session = await requireAuth();
  if(!session) return;
  const email = session.user?.email || '';
  const links = NAV_LINKS.map(l =>
    `<a href="${l.href}" class="${l.id===activeId?'active':''}">${l.label}</a>`
  ).join('');
  const bar = document.createElement('div');
  bar.id = 'topbar';
  bar.innerHTML = `
    <div class="tb-brand">${logoHTML(36)}</div>
    <nav>${links}</nav>
    <div class="tb-user">
      <span class="tb-email">${email}</span>
      <button class="tb-logout" onclick="logout()">Sair</button>
    </div>`;
  document.body.insertBefore(bar, document.body.firstChild);
}

async function logout(){
  await db.auth.signOut();
  location.replace('login.html');
}

// ── HELPERS ──
function fmtBRL(n){
  return new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(Number(n)||0);
}
function today(){
  return new Date().toLocaleDateString('pt-BR',{day:'2-digit',month:'long',year:'numeric'});
}
function fmtData(str){
  if(!str) return '-';
  const [y,m,d] = str.split('-');
  const meses = ['janeiro','fevereiro','marco','abril','maio','junho','julho','agosto','setembro','outubro','novembro','dezembro'];
  return `${parseInt(d)} de ${meses[parseInt(m)-1]} de ${y}`;
}
function fmtDataCurta(str){
  if(!str) return '-';
  const d = new Date(str);
  if(isNaN(d)) return str;
  return d.toLocaleDateString('pt-BR');
}

// Valor por extenso (reais)
function extenso(valor){
  const inteiro = Math.floor(valor);
  const cents = Math.round((valor - inteiro)*100);
  const unidades=['','um','dois','tres','quatro','cinco','seis','sete','oito','nove','dez','onze','doze','treze','quatorze','quinze','dezesseis','dezessete','dezoito','dezenove'];
  const dezenas=['','','vinte','trinta','quarenta','cinquenta','sessenta','setenta','oitenta','noventa'];
  const centenas=['','cem','duzentos','trezentos','quatrocentos','quinhentos','seiscentos','setecentos','oitocentos','novecentos'];
  function g3(n){
    if(n===0)return'';if(n===100)return'cem';
    let r='';const c=Math.floor(n/100),res=n%100;
    if(c)r+=centenas[c];if(c&&res)r+=' e ';
    if(res<20)r+=unidades[res];
    else{r+=dezenas[Math.floor(res/10)];if(res%10)r+=' e '+unidades[res%10];}
    return r;
  }
  if(inteiro===0&&cents===0)return'zero reais';
  let partes=[],n=inteiro,gi=0;
  const grupos=['','mil','milhao','bilhao'];
  while(n>0){const g=n%1000;if(g){let t=g3(g);if(gi>0)t+=' '+grupos[gi]+(g>1&&gi>1?'es':'');partes.unshift(t);}n=Math.floor(n/1000);gi++;}
  let r=partes.join(', ')+' '+(inteiro===1?'real':'reais');
  if(cents)r+=' e '+g3(cents)+' '+(cents===1?'centavo':'centavos');
  return r;
}

// ── TOAST ──
function showToast(msg, isErr){
  let wrap = document.getElementById('toast-wrap');
  if(!wrap){ wrap = document.createElement('div'); wrap.id='toast-wrap'; document.body.appendChild(wrap); }
  const t = document.createElement('div');
  t.className = 'toast' + (isErr?' err':'');
  t.textContent = msg;
  wrap.appendChild(t);
  setTimeout(()=>{ t.style.opacity='0'; t.style.transition='opacity .3s'; setTimeout(()=>t.remove(),300); }, 3200);
}

// ── MODAL ──
function openModal(id){ document.getElementById(id).classList.add('open'); }
function closeModal(id){ document.getElementById(id).classList.remove('open'); }

// ── UPLOAD DE FOTO PARA O STORAGE ──
// Comprime no cliente e sobe pro bucket 'equipamentos'. Retorna a URL publica.
async function uploadFotoEquip(file){
  const blob = await comprimirImagem(file, 1280, 0.82);
  const ext = 'jpg';
  const path = `${Date.now()}_${Math.random().toString(36).slice(2,8)}.${ext}`;
  const { error } = await db.storage.from(EQUIP_BUCKET).upload(path, blob, { contentType:'image/jpeg', upsert:false });
  if(error) throw error;
  const { data } = db.storage.from(EQUIP_BUCKET).getPublicUrl(path);
  return data.publicUrl;
}

function comprimirImagem(file, maxDim, quality){
  return new Promise((resolve,reject)=>{
    const img = new Image();
    const reader = new FileReader();
    reader.onload = e => { img.src = e.target.result; };
    reader.onerror = reject;
    img.onload = () => {
      let { width:w, height:h } = img;
      if(w > maxDim || h > maxDim){
        if(w >= h){ h = Math.round(h*maxDim/w); w = maxDim; }
        else { w = Math.round(w*maxDim/h); h = maxDim; }
      }
      const canvas = document.createElement('canvas');
      canvas.width = w; canvas.height = h;
      canvas.getContext('2d').drawImage(img,0,0,w,h);
      canvas.toBlob(b => b ? resolve(b) : reject(new Error('Falha ao comprimir')), 'image/jpeg', quality);
    };
    img.onerror = reject;
    reader.readAsDataURL(file);
  });
}

// Lista de clientes para selects (reutilizado em orcamento/contrato/recibo)
async function carregarClientesSelect(selectEl, selectedId){
  const { data, error } = await db.from('clientes').select('id,nome').order('nome');
  if(error){ showToast('Erro ao carregar clientes', true); return; }
  selectEl.innerHTML = '<option value="">- Selecione o cliente -</option>'
    + (data||[]).map(c => `<option value="${c.id}" ${String(c.id)===String(selectedId)?'selected':''}>${c.nome}</option>`).join('');
}
