"""Rebuild animation resources from the untouched original 32px sprite frames.

Equipment is rendered as a separate pixel layer by PixelAvatarVisual. This tool
only writes resource metadata; it never resamples or repaints the source art.
"""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
BASE = {
    'idle': ('Idle', 4, 8, True), 'run': ('Run', 6, 12, True),
    'attack': ('Attack1', 4, 14, False), 'heavy': ('Attack2', 6, 14, False),
    'jump': ('Jump', 8, 14, False), 'hurt': ('Hurt', 4, 12, False),
    'death': ('Death', 8, 10, False), 'push': ('Push', 6, 10, True),
    'stride': ('Walk+Attack', 6, 16, False),
}

for avatar in ['Owlet_Monster', 'Pink_Monster']:
    out = ['[gd_resource type="SpriteFrames" format=3]']
    animations = {}
    for name, (sheet, count, fps, loop) in BASE.items():
        out.append(f'[ext_resource type="Texture2D" path="res://assets/avatars/{avatar}/{avatar}_{sheet}_{count}.png" id="{name}"]')
        animations[name] = ([(name, i) for i in range(count)], fps, loop)
    for name, (_, count, _, _) in BASE.items():
        for i in range(count):
            out.append(f'[sub_resource type="AtlasTexture" id="{name}_{i}"]\natlas = ExtResource("{name}")\nregion = Rect2({i*32}, 0, 32, 32)')
    animations['build'] = ([(s, i) for s, i in [
        ('push',0),('push',1),('push',2),('attack',1),('attack',2),('push',3),
        ('push',4),('push',5),('push',4),('attack',1),('attack',2),('push',1)
    ]], 12, True)
    for weapon in ['brush','bubbles']:
        for state in ['idle','run','jump']:
            animations[f'{weapon}_{state}'] = animations[state]
        animations[f'{weapon}_idle'] = ([('idle',i) for i in [0,0,1,1,2,2,3,3]],5,True)
    animations['brush_attack'] = ([('idle',0),('run',0),('run',1),('run',2),
        ('stride',0),('stride',1),('stride',2),('stride',3),('stride',4),('stride',5),('run',4),('idle',0)],22,False)
    animations['brush_rise'] = ([('push',0),('push',1),('jump',0),('jump',1),
        ('heavy',1),('heavy',2),('jump',3),('jump',4),('jump',5),('run',0),('idle',1),('idle',0)],22,False)
    animations['brush_slam'] = ([('jump',0),('jump',1),('jump',2),('jump',3),
        ('heavy',0),('heavy',1),('heavy',2),('heavy',3),('heavy',4),('heavy',5),
        ('run',3),('run',4),('idle',1),('idle',0)],22,False)
    animations['brush_air'] = ([('jump',i) for i in [1,2,2,3,3,4,4,5,6,7]],22,False)
    animations['bubbles_attack'] = ([('attack',i) for i in [0,1,1,0]],16,False)
    animations['brush_spin'] = ([('stride',i%6) for i in range(12)],20,True)
    animations['brush_ultimate'] = ([('jump',i) for i in [0,1,2,3,4,4]]+[('heavy',i) for i in [2,3,4,5]]+[('idle',0),('idle',0)],12,False)
    animations['bubbles_special'] = ([('attack',i) for i in [0,1,1,0,0,1,1,0]],18,True)
    animations['bubbles_ultimate'] = ([('push',i) for i in [0,1,2]]+[('attack',i) for i in [1,2,2,3,0]],10,False)
    entries = []
    for name, (frames, speed, loop) in animations.items():
        textures = ','.join('{"texture": SubResource("%s_%d"), "duration": 1.0}' % (source,index) for source,index in frames)
        entries.append('{"name": &"%s", "speed": %s, "loop": %s, "frames": [%s]}' % (name,speed,str(loop).lower(),textures))
    out.append('[resource]\nmetadata/pixel_avatar = true\nanimations = [' + ',\n'.join(entries) + ']')
    (ROOT/'assets/avatars'/f'{avatar}.tres').write_text('\n\n'.join(out)+'\n',encoding='utf-8')
    print(f'{avatar}: original 32px body; 12 build frames; 12 + 12 + 14 brush combo frames; 10 airborne frames')

# Describe the opaque equipment bounds without modifying the generated PNGs.
for name in ['toothbrush_pixel','bubble_blaster_pixel','bubble_blaster_mechanical','training_robot']:
    pixels = np.array(Image.open(ROOT/'assets/animations'/f'{name}.png'))
    y, x = np.where(pixels[:,:,3] > 204)
    region = (int(x.min())-2,int(y.min())-2,int(x.max()-x.min())+5,int(y.max()-y.min())+5)
    text = f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/animations/{name}.png" id="1"]
[resource]
atlas = ExtResource("1")
region = Rect2({', '.join(map(str,region))})
'''
    (ROOT/'assets/animations'/f'{name}.tres').write_text(text,encoding='utf-8')
    print(name,region)
