"""Compile the actual Godot iOS export without Apple signing credentials."""
from pathlib import Path
import json
import subprocess
import zipfile

root = Path('builds/ios').resolve()
projects = list(root.rglob('*.xcodeproj'))
if not projects:
    archive = root / 'Glutwacht.zip'
    if not archive.is_file():
        raise SystemExit('No exported Xcode project found.')
    destination = root / 'xcode'
    with zipfile.ZipFile(archive) as source:
        for item in source.infolist():
            if not (destination / item.filename).resolve().is_relative_to(destination.resolve()):
                raise SystemExit('Unsafe export archive path.')
        source.extractall(destination)
    projects = list(destination.rglob('*.xcodeproj'))
if len(projects) != 1:
    raise SystemExit('Expected exactly one exported Xcode project.')
project = projects[0]
info = json.loads(subprocess.check_output(['xcodebuild', '-list', '-json', '-project', str(project)], text=True))
schemes = info.get('project', {}).get('schemes', [])
scheme = 'Glutwacht' if 'Glutwacht' in schemes else (schemes[0] if len(schemes) == 1 else None)
if not scheme:
    raise SystemExit('Unable to identify Glutwacht scheme.')
subprocess.run(['xcodebuild', '-project', str(project), '-scheme', scheme,
    '-configuration', 'Release', '-destination', 'generic/platform=iOS',
    '-archivePath', str(root / 'Glutwacht-unsigned.xcarchive'),
    'CODE_SIGNING_ALLOWED=NO', 'CODE_SIGNING_REQUIRED=NO', 'archive'], check=True)
print('Unsigned iPhone archive compiled. Apple signing and TestFlight upload are still required.')
