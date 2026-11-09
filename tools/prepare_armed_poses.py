"""Describe generated armed pose regions and anchors without editing any PNG."""
from pathlib import Path
from PIL import Image
import numpy as np

root=Path(__file__).resolve().parents[1]
cuts=[0,310,568,800,1024]
for name, original in [("max","Owlet_Monster"),("amanda","Pink_Monster")]:
    data=np.array(Image.open(root/f"assets/animations/{name}_armed_walk.png").convert("RGBA"))
    original_pixels=np.array(Image.open(root/f"assets/avatars/{original}/{original}_Idle_4.png").convert("RGBA"))[:,:32]
    oy,ox=np.where(original_pixels[:,:,3]>204)
    target_height=int(oy.max()-oy.min()+1)
    regions=[]
    for row in range(4):
        # The last Max muzzle crosses x=1152. Split in the empty gutter instead,
        # so frame 14 keeps its muzzle and frame 15 cannot inherit a loose pixel.
        columns=[0,384,768,1200,1536] if row==3 else [0,384,768,1152,1536]
        for col in range(4):
            x0,x1=columns[col],columns[col+1]
            y0,y1=cuts[row],cuts[row+1]
            mask=data[y0:y1,x0:x1,3]>204
            yy,xx=np.where(mask)
            left,right,top,bottom=int(xx.min()),int(xx.max()),int(yy.min()),int(yy.max())
            # The highest third contains only the head, so its center anchors the body,
            # independently of the weapon extending behind or in front of the player.
            hy,hx=np.where(mask[top:top+max(1,(bottom-top)//3)])
            head_center=(int(hx.min())+int(hx.max()))/2
            head_width=int(hx.max()-hx.min()+1)
            b0=max(0,round(head_center-head_width*.65))
            b1=min(mask.shape[1],round(head_center+head_width*.65))
            fy,fx=np.where(mask[:,b0:b1])
            feet=int(fy.max())+1
            regions.append({"region":(x0+left,y0+top,right-left+1,bottom-top+1),
                            "anchor":(head_center-left,feet-top),
                            "body_height":feet-top})
    # One consistent scale per weapon preserves the authored walk cycle.
    scales=[target_height/regions[0]["body_height"],target_height/regions[8]["body_height"]]
    out=['[gd_resource type="SpriteFrames" format=3]',
         f'[ext_resource type="Texture2D" path="res://assets/animations/{name}_armed_walk.png" id="sheet"]']
    for i,info in enumerate(regions):
        scale=scales[i//8]
        x,y,w,h=info["region"]
        ax,ay=info["anchor"]
        out.append(f'[sub_resource type="AtlasTexture" id="frame_{i}"]\natlas = ExtResource("sheet")\nregion = Rect2({x}, {y}, {w}, {h})\nmetadata/draw_size = Vector2({w*scale:.4f}, {h*scale:.4f})\nmetadata/foot_anchor = Vector2({ax*scale:.4f}, {ay*scale:.4f})')
    entries=[]
    for weapon,offset in [("brush",0),("bubbles",8)]:
        for state,indices,fps in [("idle",[0,0,0,1,1,1,0,0],5),("run",list(range(2,8)),10)]:
            textures=','.join('{"texture":SubResource("frame_%d"),"duration":1.0}'%(offset+i) for i in indices)
            entries.append('{"name":&"%s_%s","speed":%d,"loop":true,"frames":[%s]}'%(weapon,state,fps,textures))
    out.append('[resource]\nanimations = ['+',\n'.join(entries)+']')
    (root/f"assets/animations/{name}_armed_poses.tres").write_text('\n\n'.join(out)+'\n',encoding='utf-8')
    print(name,"original height",target_height,"scales",scales,"frames",len(regions))

