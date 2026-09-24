from pathlib import Path
import zipfile, hashlib
root=Path(__file__).resolve().parents[1]
excludes={'.git','.godot','.openai','.sites-runtime','node_modules'}
source=root/'dist/Glutwacht_Source.zip'
web=root/'dist/Glutwacht_Web.zip'
source_tmp=source.with_name('.Glutwacht_Source.zip.tmp')
web_tmp=web.with_name('.Glutwacht_Web.zip.tmp')
with zipfile.ZipFile(source_tmp,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
 for p in sorted(root.rglob('*')):
  if not p.is_file():continue
  rel=p.relative_to(root)
  if rel.parts[0]=='dist' or any(x in rel.parts for x in excludes):continue
  z.write(p,'Glutwacht_Source/'+str(rel))
with zipfile.ZipFile(web_tmp,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
 for p in sorted((root/'dist').iterdir()):
  if p.is_file() and not p.name.endswith(('.zip','.import','.wasm')) and not p.name.startswith('.'):
   z.write(p,'Glutwacht_Web/'+p.name)
 z.write(root/'README.md','README.md')
for p,target in ((source_tmp,source),(web_tmp,web)):
 with zipfile.ZipFile(p) as z:
  assert z.testzip() is None
  assert not any('/.git/' in f or '/.godot/' in f or '/.openai/' in f for f in z.namelist())
  if target==source:assert 'Glutwacht_Source/project.godot' in z.namelist()
  else:assert 'Glutwacht_Web/index.wasm.gz' in z.namelist()
 assert p.stat().st_size<=25*1024*1024, 'Static asset exceeds host limit'
 p.replace(target)
 print('DELIVERY',target.name,target.stat().st_size,'sha256',hashlib.sha256(target.read_bytes()).hexdigest())
