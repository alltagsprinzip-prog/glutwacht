import fs from 'node:fs';
import zlib from 'node:zlib';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const html=fs.readFileSync('dist/index.html','utf8');
for(const m of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g))if(m[1].trim())new vm.Script(m[1]);
const bytes=zlib.gunzipSync(fs.readFileSync('dist/index.wasm.gz'));
assert(WebAssembly.validate(bytes),'WASM must validate');
assert(fs.statSync('dist/index.pck').size>1000);
for(const name of ['index.js','index.audio.worklet.js','index.audio.position.worklet.js'])assert(fs.existsSync('dist/'+name));
assert(html.includes("pipeThrough(new DecompressionStream('gzip'))"));
assert(!html.includes('$GODOT_'),'Unexpanded template variable');
assert(html.includes('viewport-fit=cover'));
assert(!fs.existsSync('dist/index.wasm'),'Only gzip-packed WASM may be deployed');
for(const name of fs.readdirSync('dist')) {
 const stat=fs.statSync('dist/'+name);
 if(stat.isFile())assert(stat.size<=25*1024*1024,'Static file exceeds host limit: '+name);
}
console.log('WEB_PACKAGE_PASS: inline JS syntax, gzip/WASM integrity, PCK, runtime assets, template substitution, mobile viewport');
