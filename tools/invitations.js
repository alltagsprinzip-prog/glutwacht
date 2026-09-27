// A public player tag is an invitation target, never an authentication token.
(() => {
 const key='glutwacht.pending-invite.v1';
 const origin='https://glutwacht-spieltest.mg-automobile24.chatgpt.site';
 function tag(value){return /^[A-F0-9]{12}$/.test(String(value).toUpperCase())?String(value).toUpperCase():'';}
 const incoming=new URLSearchParams(location.search).get('invite');
 let memory='';
 try{memory=tag(localStorage.getItem(key)||'');}catch{}
 if(incoming!==null&&tag(incoming)){memory=tag(incoming);try{localStorage.setItem(key,memory);}catch{}}
 window.GlutwachtInvite={
  peek(){return memory;},
  clear(){memory='';try{localStorage.removeItem(key);}catch{}},
  url(value){const target=tag(value);return target?origin+'/v08/?invite='+target:'';},
  async share(value){
   const url=this.url(value);if(!url)return false;
   try{if(navigator.share){await navigator.share({title:'Glutwacht – zusammen spielen',url});return true;}}catch(e){if(e.name==='AbortError')return false;}
   try{await navigator.clipboard.writeText(url);return true;}catch{return false;}
  }
 };
})();
