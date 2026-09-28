"""Render the original geometric rickshaw icon to platform-required sizes."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
im = Image.new('RGB', (1024, 1024), '#102d29')
d = ImageDraw.Draw(im)
d.ellipse((116,116,908,908), fill='#24483b')
for x in (355,655):
    d.rounded_rectangle((x,0,x+14,170),7,fill='#566548')
    d.rounded_rectangle((x,854,x+14,1024),7,fill='#566548')
d.rounded_rectangle((455,235,569,410),35,fill='#081d19')
d.rounded_rectangle((304,593,373,755),24,fill='#081d19')
d.rounded_rectangle((651,593,720,755),24,fill='#081d19')
d.rounded_rectangle((340,315,684,798),80,fill='#ffc83d')
d.rounded_rectangle((365,305,659,515),64,fill='#edb535')
d.rounded_rectangle((383,339,641,489),35,fill='#102d29')
d.rounded_rectangle((402,354,622,464),22,fill='#91c3ad')
d.line((512,350,512,469),fill='#102d29',width=12)
d.rounded_rectangle((369,523,655,733),35,fill='#102d29')
d.rounded_rectangle((389,544,635,701),22,fill='#205344')
d.line((407,565,616,565),fill='#39715d',width=10)
for x in (302,681):
    d.rounded_rectangle((x,439,x+41,476),12,fill='#ffc83d')
for x in (397,603):
    d.ellipse((x,308,x+30,338),fill='#fff1cd')
for x in (378,599):
    d.rounded_rectangle((x,750,x+43,772),5,fill='#f07c45')
d.rounded_rectangle((468,750,556,777),5,fill='#fff1cd')

def save(path, size):
    im.resize((size,size),Image.Resampling.LANCZOS).save(root/path)

for size in (192,512):
    save(f'web/icons/Icon-{size}.png',size)
    save(f'web/icons/Icon-maskable-{size}.png',size)
save('web/favicon.png',48)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    save(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png',size)
folder=root/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((folder/'Contents.json').read_text())['images']:
    if 'filename' in item:
        size=round(float(item['size'].split('x')[0])*float(item['scale'].removesuffix('x')))
        save(str((folder/item['filename']).relative_to(root)),size)
print('Generated original app icons for Android, iOS, and web.')
