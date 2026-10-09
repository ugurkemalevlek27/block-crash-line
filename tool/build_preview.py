from pathlib import Path
import base64,json
root=Path(__file__).resolve().parents[1]
assets={}
for p in (root/'assets/audio').glob('*.wav'): assets[p.stem]='data:audio/wav;base64,'+base64.b64encode(p.read_bytes()).decode()
for p in (root/'assets/backgrounds').glob('*.png'): assets[p.stem]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
s=(root/'preview/template.html').read_text().replace('__LEVELS__',(root/'assets/levels/levels.json').read_text()).replace('__ASSETS__',json.dumps(assets)).replace('__ENGINE__',(root/'preview/engine.js').read_text())
(root/'Block_Crash_Line_Playable_Preview.html').write_text(s)
print('Built self-contained offline browser rehearsal')
