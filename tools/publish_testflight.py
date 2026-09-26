"""Sign the exported iOS project and upload to App Store Connect on a macOS CI runner."""
import base64
import datetime
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import secrets
import shutil
import subprocess
import tempfile
import zipfile

TEAM = 'ZYCVLZJMPG'
BUNDLE = 'com.moratgalla.glutwacht'

def run(args, **kwargs):
    # Never print command arguments: security import includes a password.
    result = subprocess.run([str(a) for a in args], **kwargs)
    if result.returncode:
        raise RuntimeError(f'{args[0]} failed with exit code {result.returncode}')
    return result

def main():
    required = ['IOS_DISTRIBUTION_P12_BASE64', 'IOS_DISTRIBUTION_P12_PASSWORD',
                'IOS_PROVISION_PROFILE_BASE64', 'ASC_KEY_ID', 'ASC_ISSUER_ID', 'GLUTWACHT']
    missing = [key for key in required if not os.environ.get(key, '').strip()]
    if missing:
        raise RuntimeError('Missing GitHub secrets: ' + ', '.join(missing))
    key_id = os.environ['ASC_KEY_ID'].strip()
    if not re.fullmatch(r'[A-Z0-9]{10}', key_id):
        raise RuntimeError('Invalid ASC_KEY_ID')
    root = Path('builds/ios').resolve()
    projects = list(root.rglob('*.xcodeproj'))
    if not projects:
        destination = root / 'xcode'
        with zipfile.ZipFile(root / 'Glutwacht.zip') as source:
            for item in source.infolist():
                if not (destination / item.filename).resolve().is_relative_to(destination.resolve()):
                    raise RuntimeError('Unsafe archive path')
            source.extractall(destination)
        projects = list(destination.rglob('*.xcodeproj'))
    if len(projects) != 1:
        raise RuntimeError('Expected one exported Xcode project')
    project = projects[0]
    info = json.loads(run(['xcodebuild', '-list', '-json', '-project', project], capture_output=True, text=True).stdout)
    schemes = info.get('project', {}).get('schemes', [])
    scheme = 'Glutwacht' if 'Glutwacht' in schemes else (schemes[0] if len(schemes) == 1 else None)
    if not scheme:
        raise RuntimeError('Cannot identify app scheme')
    installed = []
    with tempfile.TemporaryDirectory(prefix='glutwacht-sign-', dir=os.environ['RUNNER_TEMP']) as scratch:
        temp = Path(scratch)
        keychain = temp / 'signing.keychain-db'
        old_keychains = re.findall(r'"([^"]+)"', run(['security', 'list-keychains', '-d', 'user'], capture_output=True, text=True).stdout)
        try:
            p12 = temp / 'distribution.p12'
            profile = temp / 'app.mobileprovision'
            for path, variable in [(p12, required[0]), (profile, required[2])]:
                path.write_bytes(base64.b64decode(''.join(os.environ[variable].split()), validate=True))
                path.chmod(0o600)
            data = plistlib.loads(run(['security', 'cms', '-D', '-i', profile], capture_output=True).stdout)
            ent = data['Entitlements']
            if data['TeamIdentifier'] != [TEAM] or ent['application-identifier'] != TEAM + '.' + BUNDLE:
                raise RuntimeError('Provisioning profile team or app mismatch')
            if ent.get('get-task-allow') or data.get('ProvisionedDevices') or data.get('ProvisionsAllDevices') or not ent.get('beta-reports-active'):
                raise RuntimeError('Expected App Store distribution profile')
            if data['ExpirationDate'] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
                raise RuntimeError('Provisioning profile expired')
            uuid = data['UUID']
            if not re.fullmatch(r'[a-fA-F0-9-]{36}', uuid):
                raise RuntimeError('Invalid profile UUID')
            for directory in [Path.home() / 'Library/MobileDevice/Provisioning Profiles', Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles']:
                directory.mkdir(parents=True, exist_ok=True)
                target = directory / (uuid + '.mobileprovision')
                if target.exists():
                    raise RuntimeError('Profile already exists on runner')
                shutil.copyfile(profile, target)
                installed.append(target)
            password = secrets.token_hex(24)
            run(['security', 'create-keychain', '-p', password, keychain], capture_output=True)
            run(['security', 'set-keychain-settings', '-lut', '21600', keychain], capture_output=True)
            run(['security', 'unlock-keychain', '-p', password, keychain], capture_output=True)
            run(['security', 'import', p12, '-k', keychain, '-P', os.environ[required[1]], '-T', '/usr/bin/codesign', '-T', '/usr/bin/security'], capture_output=True)
            run(['security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', password, keychain], capture_output=True)
            run(['security', 'list-keychains', '-d', 'user', '-s', keychain, *old_keychains], capture_output=True)
            identities = run(['security', 'find-identity', '-v', '-p', 'codesigning', keychain], capture_output=True, text=True).stdout
            candidates = [hashlib.sha1(cert).hexdigest().upper() for cert in data['DeveloperCertificates']]
            identity = next((digest for digest in candidates if digest in identities), None)
            if not identity:
                raise RuntimeError('No valid signing identity matching profile; check PFX and password')
            archive = root / 'Glutwacht.xcarchive'
            run(['xcodebuild', '-project', project, '-scheme', scheme, '-configuration', 'Release',
                 '-destination', 'generic/platform=iOS', '-archivePath', archive,
                 'CODE_SIGN_STYLE=Manual', 'DEVELOPMENT_TEAM=' + TEAM,
                 'CODE_SIGN_IDENTITY=' + identity, 'PROVISIONING_PROFILE_SPECIFIER=' + uuid,
                 'PRODUCT_BUNDLE_IDENTIFIER=' + BUNDLE, 'archive'])
            options = temp / 'ExportOptions.plist'
            options.write_bytes(plistlib.dumps({'method': 'app-store-connect', 'destination': 'export',
                'teamID': TEAM, 'signingStyle': 'manual', 'signingCertificate': identity,
                'provisioningProfiles': {BUNDLE: uuid}, 'manageAppVersionAndBuildNumber': False,
                'uploadSymbols': True}))
            output = root / 'signed'
            run(['xcodebuild', '-exportArchive', '-archivePath', archive, '-exportPath', output, '-exportOptionsPlist', options])
            ipas = list(output.glob('*.ipa'))
            if len(ipas) != 1:
                raise RuntimeError('Expected exactly one signed IPA')
            key_dir = temp / 'private_keys'
            key_dir.mkdir(mode=0o700)
            api_key = key_dir / ('AuthKey_' + key_id + '.p8')
            api_key.write_text(os.environ['GLUTWACHT'].strip() + '\n')
            api_key.chmod(0o600)
            if '-----BEGIN PRIVATE KEY-----' not in api_key.read_text():
                raise RuntimeError('GLUTWACHT secret must contain full App Store Connect p8 key')
            run(['xcrun', 'altool', '--upload-app', '--type', 'ios', '--file', ipas[0],
                 '--apiKey', key_id, '--apiIssuer', os.environ['ASC_ISSUER_ID'].strip()], cwd=temp)
            print('Upload completed. Apple processing and TestFlight availability must still be checked.')
        finally:
            subprocess.run(['security', 'list-keychains', '-d', 'user', '-s', *old_keychains], capture_output=True)
            subprocess.run(['security', 'delete-keychain', str(keychain)], capture_output=True)
            for path in installed:
                path.unlink(missing_ok=True)

if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, KeyError, OSError) as error:
        raise SystemExit(str(error))
