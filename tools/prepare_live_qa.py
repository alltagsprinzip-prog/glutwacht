"""Generate disposable QA credentials without sending mail or exposing passwords."""
import crypt
import json
import os
from pathlib import Path
import secrets
import uuid

root=Path(os.environ['RUNNER_TEMP'])/'glutwacht-qa'
root.mkdir(mode=0o700,exist_ok=True)
private=[];provision=[]
for _ in range(2):
    uid=str(uuid.uuid4());email='qa017-'+uid+'@example.invalid';password=secrets.token_urlsafe(36)
    private.append({'id':uid,'email':email,'password':password})
    provision.append({'id':uid,'email':email,'password_hash':crypt.crypt(password,crypt.mksalt(crypt.METHOD_BLOWFISH))})
path=root/'credentials.json';path.write_text(json.dumps(private));path.chmod(0o600)
(root/'provision.json').write_text(json.dumps(provision))
print('Two isolated QA identities prepared; passwords stay in the runner.')
