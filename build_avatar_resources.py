from pathlib import Path
import shutil
from PIL import Image
root=Path.cwd(); src=Path(r'C:\Users\Marco\Downloads\ABDM\AVATAR')
for folder in ['1 Pink_Monster','2 Owlet_Monster','3 Dude_Monster']:
 d=root/'assets/avatars'/folder.split(' ',1)[1]; d.mkdir(exist_ok=True)
 for f in (src/folder).glob('*.png'): shutil.copy2(f,d/f.name)
shutil.copy2(src/'license.txt',root/'assets/avatars/license.txt')
def frames(prefix,folder):
 anims={'idle':('Idle',4,8,True),'run':('Run',6,12,True),'attack':('Attack1',4,14,False),'heavy':('Attack2',6,14,False),'jump':('Jump',8,14,False),'hurt':('Hurt',4,12,False),'death':('Death',8,10,False),'push':('Push',6,10,True)}
 if prefix!='Dude_Monster': anims['build']=('Build',6,10,True)
 out=['[gd_resource type="SpriteFrames" load_steps=100 format=3]']; subs=[]; entries=[]
 for i,(name,(file,n,fps,loop)) in enumerate(anims.items()):
  path=f'assets/animations/{"Owlet" if prefix=="Owlet_Monster" else "Pink"}_build_6.png' if file=='Build' else f'assets/avatars/{folder}/{prefix}_{file}_{n}.png'
  w,h=Image.open(root/path).size
  out.append(f'[ext_resource type="Texture2D" path="res://{path}" id="{i}"]')
  ids=[]
  for j in range(n):
   id=f'{name}_{j}'; ids.append(id)
   subs.append(f'[sub_resource type="AtlasTexture" id="{id}"]\natlas = ExtResource("{i}")\nregion = Rect2({j*w//n}, 0, {w//n}, {h})')
  entries.append('{"name": &"'+name+'", "speed": '+str(fps)+', "loop": '+str(loop).lower()+', "frames": ['+','.join('{"texture": SubResource("'+id+'"), "duration": 1.0}' for id in ids)+']}')
 out+=subs+['[resource]\nanimations = ['+',\n'.join(entries)+']']
 (root/f'assets/avatars/{folder}.tres').write_text('\n\n'.join(out),encoding='utf8')
frames('Owlet_Monster','Owlet_Monster'); frames('Pink_Monster','Pink_Monster')

frames('Dude_Monster','Dude_Monster')
