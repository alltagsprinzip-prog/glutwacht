#!/usr/bin/env python3
"""Add a small, accessible startup/error surface to Godot's generated web shell."""
from pathlib import Path
import sys
p=Path(sys.argv[1])/'index.html'
s=p.read_text()
if 'glutwacht-start-watch' in s:raise SystemExit('bootstrap already installed')
s=s.replace('<html lang="en">','<html lang="de">')
s=s.replace('<head>', '<head><script>'+Path(__file__).with_name('auth_callback.js').read_text()+'</script>')
s=s.replace('<head>','<head>\n<meta name="theme-color" content="#193943"><style>html,body,canvas{touch-action:none;overscroll-behavior:none}#glutwacht-start-watch{position:fixed;z-index:9999;left:50%;top:48%;transform:translate(-50%,-50%);padding:22px 30px;background:#193943;color:#f6e9c7;border:2px solid #bd9c5d;border-radius:16px;font:18px system-ui;max-width:80vw;box-shadow:0 8px 40px #071e28aa}#glutwacht-start-watch[hidden]{display:none}</style>')
s=s.replace('<body>','<body>\n<div id="glutwacht-start-watch" role="status">Glutwacht wird vorbereitet …</div>')
s=s.replace('</body>','<script>'+Path(__file__).with_name('web_account.js').read_text()+'</script></body>')
script=r'''
window.__glutwachtErrors=[];
window.__glutwachtBuild='0.8';
const gwBox=document.getElementById('glutwacht-start-watch');
function gwFail(message){
 const text=String(message);
 window.__glutwachtErrors.push(text);
 gwBox.hidden=false;gwBox.textContent='Startfehler: '+text;gwBox.style.background='#783f36';
}
window.addEventListener('error',e=>gwFail(e.message));
window.addEventListener('unhandledrejection',e=>gwFail(e.reason));
GODOT_CONFIG.onPrintError=(...args)=>{
 const text=args.join(' ');console.error(text);
 if(/SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:/.test(text))gwFail(text);
};
const gwWatch=setInterval(()=>{
 if(window.__glutwacht && !window.__glutwachtErrors.length){gwBox.hidden=true;clearInterval(gwWatch);}
},250);
setTimeout(()=>{
 if(!window.__glutwacht && !window.__glutwachtErrors.length)gwBox.textContent='Die Spielwelt lädt noch. Bitte diese Seite geöffnet lassen …';
},15000);
'''
s=s.replace('const engine = new Engine(GODOT_CONFIG);',script+'\nconst engine = new Engine(GODOT_CONFIG);')
p.write_text(s)
print('Web startup monitor installed')
