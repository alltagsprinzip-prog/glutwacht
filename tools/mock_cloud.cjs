// Test transport only. Never bundled into the exported game; no real accounts.
const assert=require('node:assert/strict');
const users=new Map(), saves=new Map(), requests=new Map();
async function install(context,{compressed=false}={}){
 await context.route('https://*.supabase.co/**',async route=>{
  const req=route.request(),url=new URL(req.url());
  const headers={'access-control-allow-origin':'*','access-control-allow-headers':'*'};
  // Interception supplies the Fetch-visible body (already decoded by the browser),
  // while exposed Content-Encoding can still say gzip. Never feed wire bytes here.
  const send=(data,status=200)=>route.fulfill({status,headers:compressed?{...headers,'content-encoding':'gzip','access-control-expose-headers':'content-encoding'}:headers,contentType:'application/json',body:JSON.stringify(data)});
  if(req.method()==='OPTIONS')return send({});
  const body=req.postDataJSON()||{};
  if(url.pathname==='/auth/v1/token'||url.pathname==='/auth/v1/signup'){
   const email=body.email;
   if(!users.has(email))users.set(email,`00000000-0000-4000-8000-${String(users.size+1).padStart(12,'0')}`);
   const id=users.get(email);
   return send({access_token:id,refresh_token:id,expires_in:3600,user:{id}});
  }
  const id=(req.headers().authorization||'').replace('Bearer ','');
  assert.ok([...users.values()].includes(id),'authenticated test request');
  if(url.pathname==='/auth/v1/user')return send({id});
  if(url.pathname==='/auth/v1/logout')return send({});
  if(url.pathname==='/rest/v1/player_saves'){
   assert.equal(url.searchParams.get('user_id'),`eq.${id}`,'account-owned read');
   return send(saves.has(id)?[saves.get(id)]:[]);
  }
  if(url.pathname==='/rest/v1/rpc/save_private_village'){
   if(requests.has(body.p_request))return send(requests.get(body.p_request));
   const revision=saves.get(id)?.revision||0;
   if(body.p_revision!==revision)return send({message:'revision_conflict'},409);
   const next={revision:revision+1};saves.set(id,{...next,snapshot:body.p_snapshot});requests.set(body.p_request,next);return send(next);
  }
  throw Error(`Unmocked endpoint: ${url.pathname}`);
 });
}
module.exports={install,users,saves};
