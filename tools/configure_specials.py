"""Apply input/UI scene wiring without changing any raster asset."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
path = root/'project.godot'
text = path.read_text(encoding='utf-8')
block = re.search(r'p0_heal=\{.*?\n\}',text,re.S).group()
if 'p0_special=' not in text:
    first = re.sub(r'"physical_keycode":\d+','"physical_keycode":81',block.replace('p0_heal=','p0_special='))
    second = first.replace('p0_special=','p1_special=').replace('"physical_keycode":81','"physical_keycode":73')
    text = text.replace('[input]','[input]\n\n'+first+'\n'+second,1)
text = re.sub(r'p0_heal=\{.*?\n\}',lambda m:re.sub(r'"physical_keycode":\d+','"physical_keycode":82',m.group()),text,flags=re.S)
path.write_text(text,encoding='utf-8')
path = root/'scenes/gameplay/micro_arena.tscn'
text = path.read_text(encoding='utf-8')
if 'id="training_dummy"' not in text:
    text = text.replace('[sub_resource', '[ext_resource type="PackedScene" path="res://scenes/actors/training_dummy.tscn" id="training_dummy"]\n\n[sub_resource',1)
    text += '\n[node name="TrainingDummy" parent="Actors" instance=ExtResource("training_dummy")]\nposition = Vector2(2100,266)\n'
    text = re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m.group(1))+1),text,count=1)
text = text.replace('Curar    Q               O','Curar    R               O\nEspecial Q               I')
text = text.replace('Curar    H               O','Curar    R               O')
# Escaped newlines avoid Windows CRLF being interpreted as extra label lines.
help_start = text.index('[node name="Keys"')
help_match = re.search(r'text = "([^"]*)"', text[help_start:])
start, end = (help_start+offset for offset in help_match.span(1))
text = text[:start]+help_match.group(1).replace('\n',r'\n')+text[end:]
path.write_text(text,encoding='utf-8')
print('Special keys: Q/I; healing R/O; training dummy at (2100,266).')
