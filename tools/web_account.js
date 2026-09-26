// Native HTML controls: iOS needs a real, directly tapped input to open its keyboard.
// Credentials remain in the form/one-shot queue only; never in URLs or logs.
(() => {
 const style=document.createElement('style');
 style.textContent=`#gw-account{position:fixed;inset:0;z-index:9000;background:#102436;overflow:auto;overscroll-behavior:contain;touch-action:pan-y;padding:20px;box-sizing:border-box;color:#fff2dc;font:16px/1.45 system-ui;-webkit-overflow-scrolling:touch}#gw-account[hidden]{display:none}#gw-account form{box-sizing:border-box;width:min(100%,520px);margin:auto;background:#19354e;border:1px solid #cda763;border-radius:20px;padding:24px;box-shadow:0 16px 45px #0005}#gw-account h1{font-size:26px;margin:0 0 4px;color:#f6cf82}#gw-account p{margin:8px 0 18px}#gw-account label{display:block;margin:12px 0 5px}#gw-account input{box-sizing:border-box;width:100%;min-height:50px;border:1px solid #91a4af;border-radius:10px;background:#102331;color:white;padding:12px;font:18px system-ui;touch-action:manipulation;user-select:text;-webkit-user-select:text}#gw-account input:focus{outline:3px solid #ecc674;outline-offset:2px}#gw-account .actions{display:flex;gap:12px;flex-wrap:wrap}#gw-account button{min-height:48px;flex:1;border:1px solid #d9b46e;border-radius:12px;background:#284f6f;color:white;font:600 17px system-ui;padding:10px 16px;touch-action:manipulation}#gw-account button[type=submit]{background:#bc5a0b}#gw-account button:disabled{opacity:.55}#gw-account #gw-notice{min-height:44px;font-size:15px;color:#ffdfa6;overflow-wrap:anywhere}#gw-account .recovery{width:100%;margin-top:12px;background:transparent}#gw-account small{display:block;margin-top:7px;color:#c7d2d9}@media(min-height:600px){#gw-account{padding-top:8vh}}@media(max-height:440px){#gw-account form{padding:14px 20px}#gw-account h1{font-size:21px}#gw-account p{margin:4px 0 8px}}`;
 style.textContent+=`#gw-account{background:linear-gradient(145deg,#22646e,#428a78);color:#fff8e8}#gw-account form{background:#23565e;border:2px solid #f4d598;border-radius:26px;box-shadow:0 12px 32px #163a4244}#gw-account h1{color:#fff0b6}#gw-account input{background:#184851;border-color:#b7d6cb}#gw-account button{background:#286b78;border-color:#f4d598}#gw-account button[type=submit]{background:#c95b20}#gw-account small{color:#e0ede5}`;
 document.head.appendChild(style);
 const panel=document.createElement('section');panel.id='gw-account';panel.hidden=true;panel.setAttribute('aria-label','Glutwacht Konto');
 panel.innerHTML=`<form novalidate><h1>Glutwacht</h1><p>Anmelden oder ein eigenes Konto erstellen.</p><label for="gw-email">E-Mail</label><input id="gw-email" name="email" type="email" autocomplete="username" inputmode="email" autocapitalize="none" spellcheck="false" required><label for="gw-password">Passwort</label><input id="gw-password" name="password" type="password" autocomplete="current-password" required><small>Bei Registrierung mindestens 12 Zeichen.</small><p id="gw-notice" role="status" aria-live="polite"></p><div class="actions"><button type="submit">Anmelden</button><button type="button" id="gw-register">Registrieren</button></div><button type="button" id="gw-recover" class="recovery">Passwort vergessen</button></form>`;
 document.body.appendChild(panel);
 panel.querySelector('h1').textContent='Willkommen in Glutwacht';
 panel.querySelector('p').textContent='Dein Dorf. Deine Helden. Dein nächstes Abenteuer.';
 const email=panel.querySelector('#gw-email'),password=panel.querySelector('#gw-password'),notice=panel.querySelector('#gw-notice');
 let pending=null;
 function disabled(value){panel.querySelectorAll('button').forEach(b=>b.disabled=value);}
 function submit(action){
  if(pending)return;
  if(!email.checkValidity()){email.reportValidity();return;}
  if(action!=='recover'&&!password.value){notice.textContent='Bitte dein Passwort eingeben.';password.focus();return;}
  if(action==='register'&&password.value.length<12){notice.textContent='Bitte mindestens 12 Zeichen für dein neues Passwort verwenden.';password.focus();return;}
  pending={action,email:email.value.trim(),password:action==='recover'?'':password.value};password.value='';
  document.activeElement?.blur();disabled(true);notice.textContent='Verbindung wird hergestellt …';
 }
 panel.querySelector('form').addEventListener('submit',e=>{e.preventDefault();submit('login');});
 panel.querySelector('#gw-register').addEventListener('click',()=>submit('register'));
 panel.querySelector('#gw-recover').addEventListener('click',()=>submit('recover'));
 // Stop canvas keyboard handlers from consuming native form typing.
 for(const type of ['keydown','keyup','keypress'])panel.addEventListener(type,e=>e.stopPropagation());
 window.GlutwachtAccount={
  show(message){panel.hidden=false;notice.textContent=message||'Dein Fortschritt wird automatisch in deinem Konto gespeichert.';disabled(false);},
  hide(){panel.hidden=true;password.value='';},
  take(){const result=pending;pending=null;return result?JSON.stringify(result):null;}
 };
})();
