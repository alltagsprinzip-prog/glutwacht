#!/usr/bin/env python3
"""Package tested Godot export while preserving the Site window and save namespace."""
from pathlib import Path
import sys, shutil, hashlib, json
source=Path(__file__).resolve().parents[1]/'dist/v08'
site=Path(sys.argv[1]);target=site/'dist/v08';target.mkdir(parents=True,exist_ok=True)
build=hashlib.sha256((source/'index.pck').read_bytes()).hexdigest()[:12]
for name in ['index.js','index.pck','index.png','index.audio.worklet.js','index.audio.position.worklet.js']:
 if (source/name).exists():shutil.copy2(source/name,target/name)
wasm=(source/'index.wasm').read_bytes()
parts=[]
for i,start in enumerate(range(0,len(wasm),24000000)):
 name=f'index.wasm.part{i}';(target/name).write_bytes(wasm[start:start+24000000]);parts.append(name)
loader='''const gwNativeFetch=window.fetch.bind(window);
window.fetch=async function(resource,options){
 const raw=typeof resource==='string'?resource:resource instanceof URL?resource.href:resource.url;
 const u=new URL(raw,location.href);
 if(u.origin===location.origin && /index\\.wasm$/.test(u.pathname)){
  const parts=PARTS;
  const buffers=await Promise.all(parts.map(async name=>{const r=await gwNativeFetch(new URL(name+'?build=BUILD',location.href),{cache:'no-store'});if(!r.ok)throw Error('Spielpaket konnte nicht geladen werden');return r.arrayBuffer()}));
  return new Response(new Blob(buffers),{headers:{'Content-Type':'application/wasm'}});
 }
 if(u.origin===location.origin && /index\\.(pck|js|png)$/.test(u.pathname)){u.searchParams.set('build','BUILD');return gwNativeFetch(u,{...options,cache:'no-store'});}
 return gwNativeFetch(resource,options);
};'''.replace('PARTS',json.dumps(parts)).replace('BUILD',build)
(target/'wasm-loader.js').write_text(loader)
s=(source/'index.html').read_text().replace('<head>',f'<head><script src="wasm-loader.js?build={build}"></script>')
s=s.replace('src="index.js"',f'src="index.js?build={build}"').replace("window.__glutwachtBuild='0.8'",f"window.__glutwachtBuild='{build}'")
(target/'game.html').write_text(s)
wrapper=target/'index.html';s=wrapper.read_text()
import re
s=re.sub(r"frame.src='game.html'.*?;",f"frame.src='game.html?build={build}'+(location.search?'&'+location.search.slice(1):'')+location.hash;",s)
s=s.replace('iframe{display:block;','iframe{padding-left:env(safe-area-inset-left);padding-right:env(safe-area-inset-right);display:block;')
wrapper.write_text(s)
(site/'dist/_headers').write_text('/*\n  Cache-Control: no-store\n  Referrer-Policy: no-referrer\n')
(site/'dist/build.json').write_text(json.dumps({'build':build,'version':'0.10'}))
print('SITE_BUILD',build,'WASM_PARTS',len(parts))
