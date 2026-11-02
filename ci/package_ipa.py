"""Package Flutter's unsigned physical-device .app as an IPA for iLoader."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile

if sys.platform != 'darwin':
    raise SystemExit('IPA packaging must run on macOS after flutter build ios --release --no-codesign.')

root = Path(__file__).resolve().parents[1]
app = root / 'build/ios/iphoneos/Runner.app'
with (app / 'Info.plist').open('rb') as file:
    info = plistlib.load(file)
assert info['CFBundleIdentifier'] == 'com.mavens.attendance', 'Unexpected application identifier'
assert info.get('CFBundleSupportedPlatforms') == ['iPhoneOS'], 'A simulator app cannot be sideloaded'
executable = app / info['CFBundleExecutable']
assert 'arm64' in subprocess.check_output(['lipo', '-archs', str(executable)], text=True)

output = root / 'artifacts'
output.mkdir(exist_ok=True)
ipa = output / 'mavens-attendance-ios-unsigned.ipa'
with tempfile.TemporaryDirectory(prefix='mavens-ipa-') as temporary:
    payload = Path(temporary) / 'Payload'
    payload.mkdir()
    shutil.copytree(app, payload / app.name, symlinks=True)
    subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(payload), str(ipa)], check=True)
print(f'IPA packaged: {ipa.name}; version {info["CFBundleShortVersionString"]}+{info["CFBundleVersion"]}; arm64 iPhoneOS')
