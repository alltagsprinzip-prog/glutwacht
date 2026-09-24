from pathlib import Path
import gzip, sys
p=Path(__file__).resolve().parents[1]/'dist'
wasm=p/'index.wasm'
if wasm.exists():
 (p/'index.wasm.gz').write_bytes(gzip.compress(wasm.read_bytes(),compresslevel=9,mtime=0))
 wasm.unlink()
h=p/'index.html'
s=h.read_text().replace('<html lang="en">','<html lang="de">')
s=s.replace('<title>Glutwacht</title>','<title>Glutwacht · Sonnenhain 0.4</title>')
injection='''
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<meta name="theme-color" content="#14201b">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230e1c26'/%3E%3Cpath d='M16 4L26 18L16 28L6 18Z' fill='%2378e2d1'/%3E%3Cpath d='M16 11L20 18L16 23L12 18Z' fill='%23ffb572'/%3E%3C/svg%3E">
<style>
html,body{background:#14201b!important;touch-action:none;overscroll-behavior:none;margin:0;height:100%;font-family:system-ui,sans-serif}
#canvas{display:block;outline:none}
#orientation{display:none;position:fixed;inset:0;z-index:30;background:#14201b;color:#eef3e6;align-items:center;justify-content:center;text-align:center;padding:30px;box-sizing:border-box;font-size:22px;line-height:1.6}
#orientation b{color:#d6b670;font-size:32px}
@media(orientation:portrait) and (max-width:900px){#orientation{display:flex}}
#status{color:#eef3e6!important}#status-notice{font:18px system-ui!important}
</style>
<script>
// Serve gzip-packed WASM below the static host's per-file limit, without HTTP header assumptions.
const gameFetch=window.fetch.bind(window);
window.fetch=async function(resource,options){
 const url=typeof resource==='string'?resource:resource instanceof URL?resource.href:resource.url;
 if(/index\\.wasm(?:[?#]|$)/.test(url)){
  const response=await gameFetch(url.replace('index.wasm','index.wasm.gz'),options);
  if(!response.ok) throw Error('Spieldaten konnten nicht geladen werden: '+response.status);
  if(!('DecompressionStream' in window)) throw Error('Bitte einen aktuellen Browser verwenden.');
  return new Response(response.body.pipeThrough(new DecompressionStream('gzip')),{status:200,headers:{'Content-Type':'application/wasm'}});
 }
 return gameFetch(resource,options);
};
document.addEventListener('contextmenu',e=>e.preventDefault());
const lifecycle=new AbortController();
if(document.modelContext?.registerTool){
 Promise.resolve(document.modelContext.registerTool({
  name:'read_expedition',title:'Spielstand lesen',
  description:'Liest den aktuellen lokalen Spielzustand. Verändert keine Spielregeln oder Gegenstände.',
  inputSchema:{type:'object',properties:{},additionalProperties:false},
  annotations:{readOnlyHint:true},
  execute(input){
   if(!input || typeof input!=='object' || Array.isArray(input) || Object.keys(input).length)throw Error('Keine Parameter erwartet.');
   if(!window.__glutwacht)throw Error('Spiel noch nicht geladen.');
   return structuredClone(window.__glutwacht);
  }
 },{signal:lifecycle.signal})).catch(()=>{});
}
window.addEventListener('pagehide',()=>lifecycle.abort(),{once:true});
</script>
'''
if 'const gameFetch=window.fetch.bind(window);' in s:
 h.write_text(s)
 print('WEB_ALREADY_PREPARED')
 sys.exit(0)
s=s.replace('</head>',injection+'</head>')
s=s.replace('<body>','<body><div id="orientation"><div><b>GLUTWACHT</b><br>Bitte drehe dein Handy ins Querformat.<br><small>Baue dein Dorf. Führe deine Armee.</small></div></div>')
h.write_text(s)
print('WEB_READY',sum(x.stat().st_size for x in p.iterdir() if x.is_file()))
