"""Validate the Godot pack and give every runtime asset a build-specific URL."""
import hashlib
import json
from pathlib import Path
import re
import struct
import sys

root = Path(sys.argv[1])
pack = (root / 'index.pck').read_bytes()
assert pack[:4] == b'GDPC', 'Invalid Godot pack'
version = struct.unpack_from('<I', pack, 4)[0]
assert version == 3, f'Unexpected pack version {version}'
base, directory = struct.unpack_from('<QQ', pack, 24)
count = struct.unpack_from('<I', pack, directory)[0]
pos = directory + 4
found = False
for _ in range(count):
    length = struct.unpack_from('<I', pack, pos)[0]
    pos += 4
    name = pack[pos:pos + length].rstrip(b'\0').decode()
    pos += length
    offset, size = struct.unpack_from('<QQ', pack, pos)
    pos += 16
    digest = pack[pos:pos + 16]
    pos += 20
    content = pack[base + offset:base + offset + size]
    assert len(content) == size, f'Truncated resource: {name}'
    assert hashlib.md5(content).digest() == digest, f'Corrupt resource: {name}'
    if name == 'res://project.binary' or name == 'project.binary':
        assert content[:4] == b'ECFG', 'Invalid project configuration'
        found = True
assert found, 'Missing project.binary'
assets = sorted(p for p in root.glob('index.*') if p.suffix not in ('.html', '.import'))
fingerprint = hashlib.sha256(b''.join(hashlib.sha256(p.read_bytes()).digest() for p in assets)).hexdigest()[:16]
stem = f'game-{fingerprint}'
html_path = root / 'index.html'
html = html_path.read_text()
for path in assets:
    name = stem + path.name[len('index'):]
    html = html.replace(path.name, name)
    path.rename(root / name)
html = html.replace('"executable":"index"', f'"executable":"{stem}"')
config = json.loads(re.search(r'const GODOT_CONFIG = (.*);', html)[1])
for name, size in config['fileSizes'].items():
    assert (root / name).stat().st_size == size, f'Wrong size: {name}'
loader = Path(__file__).resolve().parents[1] / 'web/verified_startup.js'
code = loader.read_text().replace('__PACK_SHA256__', hashlib.sha256(pack).hexdigest())
html = html.replace('const engine = new Engine(GODOT_CONFIG);', 'const engine = new Engine(GODOT_CONFIG);\n' + code)
assert 'engine.startGame({' in html, 'Godot HTML template changed'
html = html.replace('engine.startGame({', 'startVerifiedGame({')
html_path.write_text(html)
print(f'Validated {count} resources; release {stem}')
