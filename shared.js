const cfg=window.HOUSE_CONFIG||{};let sb=null;
if(window.supabase&&cfg.supabaseUrl?.startsWith('https://')&&cfg.supabaseAnonKey&&!cfg.supabaseAnonKey.includes('YOUR_'))sb=window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey);
const $=s=>document.querySelector(s);const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function toast(s){const t=$('#toast');if(!t)return;t.textContent=s;t.classList.add('show');setTimeout(()=>t.classList.remove('show'),2800)}
function header(active=''){return `<div class="topline">Independent minds · Singular commissions · For the love of the uncommon</div><header><a class="brand" href="index.html">THE HOUSE OF DUMB S#iT<small>FOR THE LOVE OF THE UNCOMMON</small></a><nav class="nav"><a href="artists.html" ${active==='artists'?'aria-current="page"':''}>Artists</a><a href="patronage.html" ${active==='patronage'?'aria-current="page"':''}>Patronage</a><a href="commissions.html" ${active==='commissions'?'aria-current="page"':''}>Commissions</a></nav><div class="actions"><a href="artist.html">Artist login</a><a class="btn dark" href="patron.html">Patron login</a><button class="theme-toggle" id="themeToggle" type="button" aria-label="Switch to dark mode" title="Switch theme">◐</button></div></header>`}
function footer(){return `<footer class="footer"><div>THE HOUSE OF DUMB S#iT · For the love of the uncommon.</div><div>Independent patronage · Creative expression · Est. 2026</div></footer><div class="toast" id="toast"></div>`}

function applyTheme(theme){
  document.documentElement.dataset.theme=theme;
  const button=document.getElementById('themeToggle');
  if(button){button.textContent=theme==='dark'?'☼':'◐';button.setAttribute('aria-label',theme==='dark'?'Switch to light mode':'Switch to dark mode');button.title=theme==='dark'?'Switch to light mode':'Switch to dark mode'}
}
(function initTheme(){
  const saved=localStorage.getItem('thods-theme');
  const preferred=window.matchMedia&&window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';
  applyTheme(saved||preferred);
  document.addEventListener('click',e=>{
    if(e.target.closest('#themeToggle')){
      const next=document.documentElement.dataset.theme==='dark'?'light':'dark';
      localStorage.setItem('thods-theme',next);applyTheme(next);
    }
  });
})();

async function currentUser(){if(!sb)return null;const {data:{user}}=await sb.auth.getUser();return user}
async function getArtistForUser(user){if(!sb||!user)return null;const {data,error}=await sb.from('artists').select('*').eq('user_id',user.id).maybeSingle();if(error)throw error;return data}
async function getPatronForUser(user){if(!sb||!user)return null;const {data,error}=await sb.from('patron_profiles').select('*').eq('user_id',user.id).maybeSingle();if(error)throw error;return data}
