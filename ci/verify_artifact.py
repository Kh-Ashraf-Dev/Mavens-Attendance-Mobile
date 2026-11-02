"""Verify the actual delivered release APK/IPA and its compiled API endpoint."""
import json
from pathlib import Path
import plistlib
import sys
import zipfile

artifact = Path(sys.argv[1])
root = Path(__file__).resolve().parents[1]
endpoint = json.loads((root / 'config/testing.json').read_text())['API_URL'].encode()
assert endpoint.startswith(b'https://'), 'Testing API must use HTTPS'
with zipfile.ZipFile(artifact) as archive:
    names = archive.namelist()
    assert archive.testzip() is None, 'Corrupt application archive'
    if artifact.suffix == '.apk':
        assert 'AndroidManifest.xml' in names
        libraries = [name for name in names if name.startswith('lib/') and name.endswith('/libapp.so')]
        assert libraries, 'APK must contain compiled release code'
        assert 'assets/flutter_assets/kernel_blob.bin' not in names, 'A debug APK was packaged'
        for name in libraries:
            assert endpoint in archive.read(name), f'Hosted API missing from {name}'
    elif artifact.suffix == '.ipa':
        prefix = 'Payload/Runner.app/'
        info = plistlib.loads(archive.read(prefix + 'Info.plist'))
        assert info['CFBundleIdentifier'] == 'com.mavens.attendance'
        assert info.get('CFBundleSupportedPlatforms') == ['iPhoneOS']
        assert prefix + info['CFBundleExecutable'] in names
        assert endpoint in archive.read(prefix + 'Frameworks/App.framework/App'), 'Hosted API missing from iOS compiled app'
    else:
        raise AssertionError('Expected an APK or IPA')
print(f'VERIFIED {artifact.name}: valid release archive and hosted HTTPS API')
