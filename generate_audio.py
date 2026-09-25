"""Generate Hindi pronunciation clips using Kokoro-82M (Apache-2.0).

Requires kokoro-onnx==0.6.1, soundfile, ffmpeg, node, and the two model files
in .models/. See README for downloads. No network calls during generation.
"""
import json, subprocess, tempfile
from pathlib import Path
import soundfile as sf
from kokoro_onnx import Kokoro

root = Path(__file__).resolve().parent
source = subprocess.check_output(['node', '--input-type=module', '-e',
    "import {verses} from './dist/verses.js'; console.log(JSON.stringify(verses));"], cwd=root, text=True)
verses = json.loads(source)
output = root / 'dist' / 'audio'
output.mkdir(parents=True, exist_ok=True)
model = Kokoro(str(root / '.models/kokoro-v1.0.onnx'), str(root / '.models/voices-v1.0.bin'))
manifest = {'engine': 'Kokoro-82M v1.0 via kokoro-onnx 0.6.1', 'voice': 'hm_omega', 'language': 'hi', 'speed': 0.85, 'clips': []}
with tempfile.TemporaryDirectory(prefix='chalisa-kokoro-') as temporary:
    for verse in verses:
        for line_index, text in enumerate(verse['hindi']):
            name = f"{verse['id']:02d}-{line_index}.mp3"
            target = output / name
            intermediate = Path(temporary) / 'line.wav'
            samples, rate = model.create(text, voice='hm_omega', speed=0.85, lang='hi')
            if len(samples) < rate * 0.5:
                raise RuntimeError(f'Unexpectedly short clip: {name}')
            sf.write(str(intermediate), samples, rate)
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(intermediate), '-af', 'loudnorm=I=-18:TP=-2:LRA=7', '-ar', '24000', '-codec:a', 'libmp3lame', '-b:a', '96k', str(target)], check=True)
            manifest['clips'].append({'file':name, 'text':text, 'duration':round(len(samples)/rate,3)})
        print(f"Audio {verse['id']+1}/43 complete", flush=True)
(output / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
