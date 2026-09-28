"""Package source and the compiled web game, excluding machine-local files."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
out = root / 'outputs'
out.mkdir(exist_ok=True)
excluded_dirs = {'.git', '.dart_tool', '.gradle', '.idea', '.symlinks',
                 'build', 'work', 'outputs', 'Pods', 'ephemeral', '__pycache__'}
excluded_files = {'local.properties', 'key.properties', '.flutter-plugins',
                  '.flutter-plugins-dependencies', '.packages', 'Generated.xcconfig',
                  'flutter_export_environment.sh', '.last_build_id'}

with zipfile.ZipFile(out / 'Pothole-Panic-source.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for file in sorted(root.rglob('*')):
        rel = file.relative_to(root)
        if not file.is_file() or set(rel.parts) & excluded_dirs:
            continue
        if file.name in excluded_files or file.suffix in {'.iml', '.jks', '.keystore'}:
            continue
        z.write(file, Path('pothole_panic') / rel)

web = root / 'build' / 'web'
if (web / 'main.dart.js').exists():
    with zipfile.ZipFile(out / 'Pothole-Panic-web.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for file in sorted(web.rglob('*')):
            if file.is_file():
                z.write(file, file.relative_to(web))
        z.writestr('PLAY.txt', 'Pothole Panic\n\nExtract this archive, then run:\n'
                   'python -m http.server 8765 --bind 127.0.0.1\n\n'
                   'Open http://127.0.0.1:8765 in a browser.\n'
                   'Arrow keys / A D: steer. Space / Up: horn. Esc / P: pause.\n'
                   'On a phone, swipe or use the on-screen buttons.\n')
for file in sorted(out.glob('*.zip')):
    print(f'{file.name}: {file.stat().st_size:,} bytes')
