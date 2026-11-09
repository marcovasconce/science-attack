"""Describe generated germ frames without modifying the original transparent PNG."""
from pathlib import Path
from PIL import Image
import numpy as np

root = Path(__file__).resolve().parents[1]
data = np.array(Image.open(root/'assets/animations/germs_laugh_breathe.png').convert('RGBA'))
out = ['[gd_resource type="SpriteFrames" format=3]',
       '[ext_resource type="Texture2D" path="res://assets/animations/germs_laugh_breathe.png" id="sheet"]']
animations = []
for row, (name, y0, y1, height) in enumerate([('green',0,368,28),('red',368,data.shape[0],46)]):
    regions = []
    for col in range(4):
        x0, x1 = col*448, min(data.shape[1], (col+1)*448)
        yy, xx = np.where(data[y0:y1,x0:x1,3] > 204)
        regions.append((int(xx.min())+x0,int(yy.min())+y0,int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)))
    scale = height/regions[0][3]
    for i, (x,y,w,h) in enumerate(regions):
        out.append(f'[sub_resource type="AtlasTexture" id="{name}_{i}"]\natlas = ExtResource("sheet")\nregion = Rect2({x}, {y}, {w}, {h})\nmetadata/draw_size = Vector2({w*scale:.4f}, {h*scale:.4f})')
    frames = ','.join('{"texture":SubResource("%s_%d"),"duration":1.0}'%(name,i) for i in range(4))
    animations.append('{"name":&"%s","speed":8,"loop":true,"frames":[%s]}'%(name,frames))
out.append('[resource]\nanimations = ['+',\n'.join(animations)+']')
(root/'assets/animations/germ_poses.tres').write_text('\n\n'.join(out)+'\n',encoding='utf-8')
print('Generated four laughing green frames and four breathing red frames, aligned at their feet.')
