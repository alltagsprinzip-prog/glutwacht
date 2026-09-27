// Native HTML controls: iOS needs a real, directly tapped input to open its keyboard.
// Credentials remain in the form/one-shot queue only; never in URLs or logs.
(() => {
 const style=document.createElement('style');
 style.textContent=`#gw-account{position:fixed;inset:0;z-index:9000;background:#102436;overflow:auto;overscroll-behavior:contain;touch-action:pan-y;padding:20px;box-sizing:border-box;color:#fff2dc;font:16px/1.45 system-ui;-webkit-overflow-scrolling:touch}#gw-account[hidden]{display:none}#gw-account form{box-sizing:border-box;width:min(100%,520px);margin:auto;background:#19354e;border:1px solid #cda763;border-radius:20px;padding:24px;box-shadow:0 16px 45px #0005}#gw-account h1{font-size:26px;margin:0 0 4px;color:#f6cf82}#gw-account p{margin:8px 0 18px}#gw-account label{display:block;margin:12px 0 5px}#gw-account input{box-sizing:border-box;width:100%;min-height:50px;border:1px solid #91a4af;border-radius:10px;background:#102331;color:white;padding:12px;font:18px system-ui;touch-action:manipulation;user-select:text;-webkit-user-select:text}#gw-account input:focus{outline:3px solid #ecc674;outline-offset:2px}#gw-account .actions{display:flex;gap:12px;flex-wrap:wrap}#gw-account button{min-height:48px;flex:1;border:1px solid #d9b46e;border-radius:12px;background:#284f6f;color:white;font:600 17px system-ui;padding:10px 16px;touch-action:manipulation}#gw-account button[type=submit]{background:#bc5a0b}#gw-account button:disabled{opacity:.55}#gw-account #gw-notice{min-height:44px;font-size:15px;color:#ffdfa6;overflow-wrap:anywhere}#gw-account .recovery{width:100%;margin-top:12px;background:transparent}#gw-account small{display:block;margin-top:7px;color:#c7d2d9}@media(min-height:600px){#gw-account{padding-top:8vh}}@media(max-height:440px){#gw-account form{padding:14px 20px}#gw-account h1{font-size:21px}#gw-account p{margin:4px 0 8px}}`;
 style.textContent+=`#gw-account{background:linear-gradient(145deg,#102b49,#183f5f);color:#fff2dc}#gw-account form{background:#10263f;border:2px solid #dfb867;border-radius:14px;box-shadow:0 5px 0 #07182b,0 16px 36px #07182b88}#gw-account h1{color:#f6cf82}#gw-account input{background:#0c2036;border-color:#8fa6b6}#gw-account button{background:#163858;border-color:#e8c477;border-radius:10px;box-shadow:0 3px 0 #07182b}#gw-account button[type=submit]{background:#9c6b24}#gw-account small{color:#d2dbea}`;
 style.textContent+=`#gw-account{padding-left:max(16px,env(safe-area-inset-left));padding-right:max(16px,env(safe-area-inset-right));background:#153c30}#gw-account form{background:#193c30}#gw-account button{background:#efdfb9;color:#293322}#gw-account input{background:#102b25}#gw-keyboard-done{position:sticky;bottom:0;width:100%;margin-top:10px}#gw-keyboard-done[hidden]{display:none}`;
 document.head.appendChild(style);
 const panel=document.createElement('section');panel.id='gw-account';panel.hidden=true;panel.setAttribute('aria-label','Glutwacht Konto');
 panel.innerHTML=`<form novalidate><h1>Glutwacht</h1><p>Anmelden oder ein eigenes Konto erstellen.</p><label for="gw-email">E-Mail</label><input id="gw-email" list="gw-saved-emails" name="email" type="email" autocomplete="username" inputmode="email" autocapitalize="none" spellcheck="false" required><datalist id="gw-saved-emails"></datalist><label for="gw-password">Passwort</label><input id="gw-password" name="password" type="password" autocomplete="current-password" required><small>Bei Registrierung mindestens 12 Zeichen.</small><p id="gw-notice" role="status" aria-live="polite"></p><div class="actions"><button type="submit">Anmelden</button><button type="button" id="gw-register">Registrieren</button></div><button type="button" id="gw-recover" class="recovery">Passwort vergessen</button><button type="button" id="gw-keyboard-done" hidden>Fertig ✓ · Tastatur schließen</button></form>`;
 document.body.appendChild(panel);
 panel.querySelector('h1').textContent='Willkommen in Glutwacht';
 panel.querySelector('p').textContent='Dein Dorf. Deine Helden. Dein nächstes Abenteuer.';
 const email=panel.querySelector('#gw-email'),password=panel.querySelector('#gw-password'),notice=panel.querySelector('#gw-notice');
 function rememberedEmails(){try{const v=JSON.parse(localStorage.getItem('glutwacht.emails.v1')||'[]');return Array.isArray(v)?v.filter(x=>typeof x==='string'&&x.includes('@')).slice(0,5):[];}catch{return [];}}
 function refreshEmails(){const list=panel.querySelector('#gw-saved-emails');list.replaceChildren();for(const value of rememberedEmails()){const option=document.createElement('option');option.value=value;list.appendChild(option);}if(!email.value)email.value=rememberedEmails()[0]||'';}
 const done=panel.querySelector('#gw-keyboard-done');
 function dismissKeyboard(){document.activeElement?.blur();done.hidden=true;}
 for(const field of [email,password]){
  field.enterKeyHint='done';
  field.addEventListener('focus',()=>{done.hidden=false;});
  field.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();dismissKeyboard();}});
 }
 done.addEventListener('click',dismissKeyboard);
 let dismissedTap=false;
 panel.addEventListener('pointerdown',e=>{
  if([email,password].includes(document.activeElement)&&e.target!==email&&e.target!==password){
   dismissKeyboard();dismissedTap=true;e.preventDefault();e.stopImmediatePropagation();
  }
 },true);
 panel.addEventListener('click',e=>{if(dismissedTap){dismissedTap=false;e.preventDefault();e.stopImmediatePropagation();}},true);
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
  show(message){refreshEmails();panel.hidden=false;notice.textContent=message||'Dein Fortschritt wird automatisch in deinem Konto gespeichert.';disabled(false);},
  hide(){panel.hidden=true;password.value='';},
  take(){const result=pending;pending=null;return result?JSON.stringify(result):null;}
 };
})();
