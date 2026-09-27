"""Read-only Apple processing/group check. Does not assign builds or notify testers."""
import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

APP = '6816498028'
HOST = 'https://api.appstoreconnect.apple.com'

def b64(value):
    return base64.urlsafe_b64encode(value).decode().rstrip('=')

def raw_signature(der):
    # P-256 ECDSA signatures fit the short-form DER length encoding.
    if len(der) < 8 or der[0] != 48 or der[1] != len(der)-2:
        raise ValueError('Invalid ECDSA signature')
    offset = 2
    parts = []
    for _ in range(2):
        if offset+2 > len(der) or der[offset] != 2:
            raise ValueError('Invalid ECDSA integer')
        size = der[offset+1]
        value = der[offset+2:offset+2+size]
        if len(value) != size or not 1 <= size <= 33 or value[0] & 128:
            raise ValueError('Invalid ECDSA scalar')
        parts.append(int.from_bytes(value, 'big').to_bytes(32, 'big'))
        offset += size+2
    if offset != len(der):
        raise ValueError('Unexpected ECDSA data')
    return b''.join(parts)

def token():
    now = int(time.time())
    header = b64(json.dumps({'alg':'ES256','kid':os.environ['ASC_KEY_ID'].strip(),'typ':'JWT'}).encode())
    claims = b64(json.dumps({'iss':os.environ['ASC_ISSUER_ID'].strip(),'iat':now-10,'exp':now+600,'aud':'appstoreconnect-v1'}).encode())
    payload = (header+'.'+claims).encode()
    with tempfile.TemporaryDirectory(prefix='glutwacht-apple-check-') as folder:
        key = Path(folder)/'api.p8'
        key.write_text(os.environ['GLUTWACHT'].strip()+'\n');key.chmod(0o600)
        signed = subprocess.run(['openssl','dgst','-sha256','-sign',str(key)],input=payload,capture_output=True)
        if signed.returncode:
            raise RuntimeError('Apple API signing failed')
    return payload.decode()+'.'+b64(raw_signature(signed.stdout))

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise RuntimeError('Unexpected Apple API redirect')

def get(path, bearer):
    url = HOST+path
    request = urllib.request.Request(url,headers={'Authorization':'Bearer '+bearer,'Accept':'application/json'})
    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=25) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Never dump request headers or raw server response containing account data.
        raise RuntimeError('Apple read-only request rejected: HTTP '+str(error.code)) from None

def summarize(response, target):
    included = {(x['type'],x['id']):x.get('attributes',{}) for x in response.get('included',[])}
    for build in response.get('data',[]):
        rel = build.get('relationships',{})
        version = rel.get('preReleaseVersion',{}).get('data') or {}
        marketing = included.get(('preReleaseVersions',version.get('id')),{}).get('version')
        if marketing != target or (os.environ.get('TARGET_BUILD') and build['attributes']['version'] != os.environ['TARGET_BUILD']):
            continue
        attrs = build['attributes']
        groups = [included.get(('betaGroups',x['id']),{}).get('name','Unknown group') for x in rel.get('betaGroups',{}).get('data',[])]
        detail = rel.get('buildBetaDetail',{}).get('data') or {}
        state = included.get(('buildBetaDetails',detail.get('id')),{}).get('internalBuildState','unknown')
        return {'version':marketing,'build':attrs['version'],'processing':attrs.get('processingState'),
                'expired':attrs.get('expired'), 'internal_state':state,'groups':groups,
                'public_testflight_links':[a['publicLink'] for (kind,_),a in included.items() if kind=='betaGroups' and a.get('publicLinkEnabled') and a.get('publicLink')],
                'external_state':included.get(('buildBetaDetails',detail.get('id')),{}).get('externalBuildState','unknown'),
                'assigned_to_glutwacht_test':any(x.casefold()=='glutwacht test' for x in groups)}
    return {'version':target,'processing':'NOT_VISIBLE_YET','groups':[],'assigned_to_glutwacht_test':False}

def main():
    target = os.environ.get('TARGET_VERSION','0.13.1')
    query = urllib.parse.urlencode({'filter[app]':APP,'sort':'-uploadedDate','limit':'20','include':'preReleaseVersion,betaGroups,buildBetaDetail'})
    # Short, bounded polling; no build/upload is triggered by this workflow.
    for attempt in range(15):
        report = summarize(get('/v1/builds?'+query, token()),target)
        print(json.dumps(report),flush=True)
        Path('apple-status.json').write_text(json.dumps(report,indent=2)+'\n')
        ready = report.get('processing') == 'VALID' and not report.get('expired') and report.get('internal_state') == 'IN_BETA_TESTING' and report.get('assigned_to_glutwacht_test')
        if report['processing'] in ('FAILED','INVALID') or (report['processing'] == 'VALID' and (os.environ.get('REQUIRE_READY') != '1' or ready)):
            break
        if attempt < 14:
            time.sleep(30)
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary,'a') as out:
            out.write('Apple read-only verification\n\n```json\n'+json.dumps(report,indent=2)+'\n```\n')
    if report['processing'] in ('FAILED','INVALID'):
        raise SystemExit('Apple rejected build processing')
    if os.environ.get('REQUIRE_READY') == '1' and not ready:
        raise SystemExit('Upload is not yet confirmed available in the existing Glutwacht test group; check Apple processing/group status before announcing an update.')

if __name__=='__main__':
    try:
        main()
    except (RuntimeError, ValueError, KeyError, OSError) as error:
        raise SystemExit(str(error))
