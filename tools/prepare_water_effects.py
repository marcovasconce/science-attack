"""Create atlas metadata for the generated six-frame water effects; PNGs stay untouched."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
regions={
 "beam":[(col*887,row*296,887,295 if row==2 else 296) for row in range(3) for col in range(2)],
 "splash":[(190,135,230,340),(568,130,470,350),(1070,135,680,345),
           (60,550,520,265),(610,590,540,225),(1180,610,550,215)]
}
for kind,rects in regions.items():
 out=['[gd_resource type="SpriteFrames" format=3]',
      f'[ext_resource type="Texture2D" path="res://assets/animations/soap_water_{kind}.png" id="sheet"]']
 for i,rect in enumerate(rects):
  out.append(f'[sub_resource type="AtlasTexture" id="frame_{i}"]\natlas = ExtResource("sheet")\nregion = Rect2({", ".join(map(str,rect))})')
 frames=','.join('{"texture":SubResource("frame_%d"),"duration":1.0}'%i for i in range(6))
 out.append('[resource]\nanimations = [{"name":&"effect","speed":12,"loop":%s,"frames":[%s]}]'%('true' if kind=='beam' else 'false',frames))
 (root/f'assets/animations/soap_water_{kind}.tres').write_text('\n\n'.join(out)+'\n',encoding='utf-8')
 print(kind,len(rects),"frames")

