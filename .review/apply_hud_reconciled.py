"""Restore the reviewed patch against its exact source archive, then reconcile.
Existing later joystick ownership, test additions and class descriptions remain.
Never change production refs or replace a concurrently modified source file.
"""
import base64, hashlib, json, lzma, pathlib, shutil, subprocess, tarfile, tempfile
root=pathlib.Path.cwd()
manifest=json.loads((root/'.review/hud-ready.json').read_text())
packed=base64.b64decode(''.join((root/p).read_text().strip() for p in manifest['parts']),validate=True)
assert hashlib.sha256(packed).hexdigest()==manifest['compressed_sha256']
patch=lzma.decompress(packed)
assert len(patch)==manifest['patch_bytes'] and hashlib.sha256(patch).hexdigest()==manifest['patch_sha256']
paths=[line[6:] for line in patch.decode().splitlines() if line.startswith('+++ b/')]
assert len(paths)==27 and len(set(paths))==27
for name in paths:
    assert not pathlib.PurePosixPath(name).is_absolute() and '..' not in pathlib.PurePosixPath(name).parts
    assert name.startswith(('game3d/','assets3d/','tests3d/','tools/','docs/','PROJECT_STATE.md'))
    original=subprocess.run(['git','show','bc56dbee2a0205b830253b2e53af82cc501fc583:'+name],capture_output=True)
    actual=root/name
    assert (not actual.exists() if original.returncode else actual.read_bytes()==original.stdout), 'Concurrent edit: '+name
with tempfile.TemporaryDirectory() as temporary:
    tmp=pathlib.Path(temporary)
    with tarfile.open('/tmp/hud-toolchain/source.tar.gz') as archive:archive.extractall(tmp,filter='data')
    patch_file=tmp/'change.patch';patch_file.write_bytes(patch)
    subprocess.run(['git','init','-q'],cwd=tmp,check=True)
    subprocess.run(['git','apply','--check',str(patch_file)],cwd=tmp,check=True)
    subprocess.run(['git','apply',str(patch_file)],cwd=tmp,check=True)
    name='game3d/stick.gd';old=(root/name).read_text();new=(tmp/name).read_text()
    assert 'func set_direction(' in old and 'func _draw():' in new
    (tmp/name).write_text(old[:old.index('func _draw():')]+new[new.index('func _draw():'):])
    (tmp/'game3d/catalog.gd').write_bytes((root/'game3d/catalog.gd').read_bytes())
    shutil.copy2(root/'docs/HUD_REVIEW_2026-09-25.md',root/'docs/HUD_CONTINUATION_ARCHIVE.md')
    for name in paths:
        dest=root/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(tmp/name,dest)
for name in manifest['parts']:(root/name).unlink()
(root/'.review/hud-ready.json').unlink()
print('RECONCILED_HUD_FILES',len(paths),'Existing extra regression tests untouched.')
