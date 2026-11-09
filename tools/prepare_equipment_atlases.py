"""Read alpha bounds and author Godot atlas regions/anchors. Never modifies PNG pixels."""
from pathlib import Path
from PIL import Image
import numpy as np
import json,re
project=Path(__file__).resolve().parents[1]

def runs(values):
    indices=np.flatnonzero(values)
    groups=np.split(indices,np.where(np.diff(indices)>1)[0]+1)
    return [(int(g[0]),int(g[-1])+1) for g in groups if len(g)>5]

def regions(name,columns,rows):
    image=np.asarray(Image.open(project/'assets/animations'/f'{name}.png').convert('RGBA'))
    mask=image[:,:,3]>128
    bands=runs(mask.sum(axis=1)>3)
    assert len(bands)==rows,(name,'rows',bands)
    result=[]
    for y0,y1 in bands:
        spans=runs(mask[y0:y1].sum(axis=0)>3)
        assert len(spans)==columns,(name,'columns',spans)
        for x0,x1 in spans:
            rect=(max(0,x0-2),max(0,y0-2),min(image.shape[1],x1+2),min(image.shape[0],y1+2))
            left,top,right,bottom=rect
            local=mask[top:bottom,left:right]
            # Feet remain on the near/left character side even when a brush sweeps low.
            body_side=local[:,:int(local.shape[1]*0.64)]
            ys=np.flatnonzero(body_side.sum(axis=1)>2)
            foot_y=int(ys[-1])+1
            foot_band=local[max(0,foot_y-7):foot_y]
            cols=np.flatnonzero(foot_band.sum(axis=0)>1)
            if name.endswith('brush') and len(cols) and cols[-1] > local.shape[1]*0.85:
                cols=cols[cols<local.shape[1]*0.68]
            foot_x=float((cols[0]+cols[-1])/2)
            # The first idle pose's body is on the left, excluding the tall brush head.
            core=local[:,max(0,int(foot_x)-int(local.shape[1]*0.16)):min(local.shape[1],int(foot_x)+int(local.shape[1]*0.12))]
            body_ys=np.flatnonzero(core.sum(axis=1)>2)
            body_height=foot_y-int(body_ys[0])
            result.append({'region':[left,top,right-left,bottom-top],'foot':[foot_x,foot_y],'body_height':body_height})
    return result

build=regions('assembly_empty',6,2)
for avatar,slug,row in [('Owlet','max',0),('Pink','amanda',1)]:
    path=project/'assets/avatars'/f'{avatar}_Monster.tres'
    text=path.read_text(encoding='utf-8')
    if 'metadata/detailed_layout' in text:
        print(f'{avatar}: atlas resources already prepared')
        continue
    ext=re.search(r'\[ext_resource[^\n]+path="res://assets/animations/'+avatar+r'_build_6.png" id="([^"]+)"\]',text)
    assert ext
    build_id=ext[1]
    text=text.replace(f'assets/animations/{avatar}_build_6.png','assets/animations/assembly_empty.png')
    layouts={}
    authored=build[row*6:(row+1)*6]
    build_scale=46.0/authored[0]['body_height']
    layouts['build']=[]
    blocks=re.split(r'(?=^\[)',text,flags=re.M)
    index=0
    for i,block in enumerate(blocks):
        if block.startswith('[sub_resource') and f'atlas = ExtResource("{build_id}")' in block:
            data=authored[index]
            region=data['region']
            blocks[i]=re.sub(r'region = Rect2\([^\n]+\)', 'region = Rect2('+', '.join(map(str,region))+')',block)
            layouts['build'].append({'scale':build_scale,'x':(region[2]/2-data['foot'][0])*build_scale,'y':(region[3]/2-data['foot'][1])*build_scale})
            index+=1
    assert index==6
    text=''.join(blocks)
    ext_lines=''
    sub_lines=''
    animations=[]
    for weapon in ['brush','bubbles']:
        data=regions(f'{slug}_{weapon}',4,3)
        scale=50.0/data[0]['body_height']
        ext_lines+=f'[ext_resource type="Texture2D" path="res://assets/animations/{slug}_{weapon}.png" id="{weapon}_sheet"]\n'
        for row_index,state in enumerate(['idle','run','attack']):
            name=weapon+'_'+state
            layouts[name]=[]
            frames=[]
            for frame in range(4):
                item=data[row_index*4+frame]
                region=item['region']
                ident=f'{name}_{frame}'
                sub_lines+=f'[sub_resource type="AtlasTexture" id="{ident}"]\natlas = ExtResource("{weapon}_sheet")\nregion = Rect2('+', '.join(map(str,region))+')\nfilter_clip = true\n\n'
                layouts[name].append({'scale':scale,'x':(region[2]/2-item['foot'][0])*scale,'y':(region[3]/2-item['foot'][1])*scale})
                frames.append('{"duration": 1.0, "texture": SubResource("'+ident+'")}')
            animations.append('{"frames": ['+', '.join(frames)+'], "loop": '+('false' if state=='attack' else 'true')+', "name": &"'+name+'", "speed": '+str(8 if state=='idle' else 12)+'.0}')
    text=text.replace('[sub_resource',ext_lines+'\n[sub_resource',1)
    text=text.replace('[resource]',sub_lines+'[resource]',1)
    end=text.rfind(']')
    text=text[:end]+',\n'+',\n'.join(animations)+text[end:]
    text+='\nmetadata/detailed_layout = '+json.dumps(layouts,ensure_ascii=False)+'\n'
    path.write_text(text,encoding='utf-8')
    print(avatar,'build scale',round(build_scale,3),'weapon body heights',[data[0]['body_height']],'animations',list(layouts))
