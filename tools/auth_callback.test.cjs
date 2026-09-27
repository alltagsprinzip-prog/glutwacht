const {readFileSync} = require('node:fs');
const {runInNewContext} = require('node:vm');
const assert = require('node:assert/strict');
const source = readFileSync(__dirname + '/auth_callback.js', 'utf8');
function capture(hash) {
  const calls = [];
  const window = {location:{hash,pathname:'/v08/',search:'?qa=1'},history:{replaceState(...args){calls.push(args);}}};
  runInNewContext(source, {window,URLSearchParams});
  return {window,calls};
}
for (const type of ['signup','magiclink','recovery']) {
  const {window,calls}=capture(`#access_token=private-test&refresh_token=refresh-test&type=${type}&user=forged`);
  assert.equal(calls.length,1);
  assert.equal(calls[0][2],'/v08/?qa=1');
  assert.equal(window.__glutwachtEmailLink.type,type);
  assert.equal(window.__glutwachtEmailLink.user,undefined);
  assert.equal(window.__glutwachtEmailLink.access_token,'private-test');
}
const error=capture('#error=access_denied&error_code=otp_expired&error_description=untrusted');
assert.equal(error.calls.length,1);
assert.equal(error.window.__glutwachtEmailLink.error_code,'otp_expired');
assert.equal(error.window.__glutwachtEmailLink.error_description,undefined);
const plain=capture('#village');
assert.equal(plain.calls.length,0);
assert.equal(plain.window.__glutwachtEmailLink,undefined);
console.log('EMAIL_CALLBACK_OK: signup, magiclink, recovery, expired links, URL cleanup, unrelated hashes');
