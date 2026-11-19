"""Write the editable route scene using the project's existing cartoon textures."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
assets = [29,30,32,35,36,37,39,40,53,55,56,57,65,67,73,74,75,82,85,86,87,88,89,90,92,99,100,104,108,109,111,112]
lines = ['[gd_scene format=3]', '[ext_resource type="Script" path="res://scripts/tabletop_route.gd" id="route"]', '[ext_resource type="Script" path="res://scripts/tabletop_route_art.gd" id="art"]', '[ext_resource type="Script" path="res://scripts/elevator_pad.gd" id="pad"]', '[ext_resource type="PackedScene" path="res://scenes/environment/powered_gate.tscn" id="gate"]', '[ext_resource type="FontFile" path="res://assets/fonts/PressStart2P-Regular.ttf" id="font"]']
for n in assets:
    lines.append(f'[ext_resource type="Texture2D" path="res://assets/third_party/cartoon/industrial/PNG/Default size/platformIndustrial_{n:03}.png" id="t{n}"]')
lines += ['[ext_resource type="Script" path="res://scripts/medical_supply_box.gd" id="medical"]', '[ext_resource type="Texture2D" path="res://assets/ui/healing_flask.svg" id="flask"]', '[ext_resource type="Script" path="res://scripts/tabletop_machine_progress.gd" id="progress"]']

lines += ['[ext_resource type="PackedScene" path="res://scenes/environment/cooperative_elevator.tscn" id="exit_cabin"]', '[ext_resource type="Script" path="res://scripts/tabletop_exit_elevator.gd" id="exit_lift"]']

def node(name, kind='Node2D', parent='.', **props):
    lines.append(f'\n[node name="{name}" type="{kind}" parent="{parent}"]')
    lines.extend(f'{key} = {value}' for key, value in props.items())

def sprite(name, n, x, y, scale=1.0, parent='.', **props):
    node(name,'Sprite2D',parent,position=f'Vector2({x},{y})',texture=f'ExtResource("t{n}")',scale=f'Vector2({scale},{scale})',**props)

def label(name, text, x, y, parent='.', size=8):
    node(name,'Label',parent,offset_left=x,offset_top=y,theme_override_fonts__font='ExtResource("font")',theme_override_font_sizes__font_size=size,text='"'+text+'"',mouse_filter=2)

lines += ['[sub_resource type="RectangleShape2D" id="medical_shape"]','size = Vector2(36,20)']
lines += ['\n[node name="Route" type="Node2D"]','script = ExtResource("route")','texture_filter = 1']
node('Art',script='ExtResource("art")',z_index=-3)
node('MachineProgress',script='ExtResource("progress")',position='Vector2(5480,90)',z_index=8)
node('PickupNotice','Label',visible='false',z_index=30,offset_right=130,horizontal_alignment=1,theme_override_font_sizes__font_size=13,theme_override_colors__font_outline_color='Color(0.02,0.06,0.1,1)',theme_override_constants__outline_size=4,mouse_filter=2)
for name,x in [('PowerGate',2430),('DrainGate',3110),('PassageGate',4470),('ExitGate',6370)]:
    lines += [f'\n[node name="{name}" parent="." instance=ExtResource("gate")]',f'position = Vector2({x},260)']

node('PumpDecor',z_index=-2)
sprite('Inlet',100,2700,140,0.9,'PumpDecor')
sprite('Outlet',100,3062,140,0.9,'PumpDecor')
for i,x in enumerate([2700,3062]):
    sprite(f'StandTop{i}',36,x,181.4,0.9,'PumpDecor',region_enabled='true',region_rect='Rect2(0,0,70,22)')
    sprite(f'StandLeg{i}',85,x,214.05,0.65,'PumpDecor')
    sprite(f'StandFoot{i}',36,x,246.7,0.9,'PumpDecor',region_enabled='true',region_rect='Rect2(0,0,70,22)')
for i,x in enumerate([2724,3040]):
    sprite(f'Socket{i}',85,x,140,0.4,'PumpDecor',rotation=1.5707963,region_enabled='true',region_rect='Rect2(10,0,50,70)')
node('ValveWheels',z_index=-2)
for i,x in enumerate([2780,2880,2980]):
    sprite(f'Wheel{i}',67,x,250,0.5,'ValveWheels',modulate='Color(1.2,1.05,0.6,1)')
sprite('Spill',108,3230,265,1.0,z_index=-3)
# Explicit floor perspective on the spill tile, never on upright props.
idx = next(i for i,l in enumerate(lines) if '[node name="Spill"' in l)
for j in range(idx+1,len(lines)):
    if lines[j].startswith('scale = '): lines[j]='scale = Vector2(3.25,1.7)'

node('VentMachinery',z_index=-2)
for i,x in enumerate([3540,3740,3970]):
    sprite(f'Vent{i}',99,x,316,0.45,'VentMachinery',rotation=1.5707963)
    sprite(f'Pipe{i}',85,x,215,0.48,'VentMachinery')
sprite('Fan',67,3650,118,0.8,'VentMachinery')
sprite('FanHousing',29,3650,118,1.05,'VentMachinery',show_behind_parent='true')

for i,(x,y) in enumerate([(3390,293),(4650,293)]):
    sprite(f'Battery{i}',90 if i==0 else 104,x,y,0.45)
for i,(x,y) in enumerate([(3430,216),(4930,299)]):
    node(f'Supply{i}','StaticBody2D',position=f'Vector2({x},{y})',script='ExtResource("medical")',supply_index=i,collision_layer=8,collision_mask=0)
    idx = next(j for j in range(len(lines)-1,-1,-1) if lines[j].lstrip().startswith('[node name='))
    lines[idx] = lines[idx][:-1]+' groups=["medical_supplies"]]'
    node('Collision','CollisionShape2D',f'Supply{i}',shape='SubResource("medical_shape")')
    sprite('Box',57,0,-10,0.65,f'Supply{i}',modulate='Color(0.85,1,0.9,1)')
    node('Contents','Sprite2D',f'Supply{i}',visible='false',position='Vector2(0,-14)',texture='ExtResource("flask")',scale='Vector2(1,1)')
    label('Cross','+',-8,-15,f'Supply{i}',16)

node('StorageDecor',z_index=-2)
for i in range(3):
    sprite(f'Shelf{i}',[87,88,89][i],4650+i*84,217,1.2,'StorageDecor')
sprite('GlassJar',99,4650,167,1.15,'StorageDecor')
sprite('SmallJar',100,4750,185,0.65,'StorageDecor')
sprite('StoredBox',57,4820,188,0.75,'StorageDecor')

node('Sterilizer',z_index=-2)
sprite('Console',32,5400,215,0.9,'Sterilizer')
sprite('ConsoleStand',85,5400,253.5,0.2,'Sterilizer')
sprite('ConsoleFoot',36,5400,267.1,0.6,'Sterilizer',region_enabled='true',region_rect='Rect2(0,0,70,22)')
sprite('Lamp',40,5400,157,0.5,'Sterilizer')
for i in range(4): sprite(f'Foot{i}',[35,36,36,37][i],5480+i*70,246.5,1.0,'Sterilizer')
for i,x in enumerate([5490,5680]): sprite(f'Leg{i}',85,x,247.5,0.4,'Sterilizer')
node('Green',parent='Sterilizer')
node('Blue',parent='Sterilizer')
for i,x in enumerate([5525,5650]):
    sprite(f'Tank{i}',104,x,159,1.5,'Sterilizer/Green')
    sprite(f'Tank{i}',100,x,159,1.5,'Sterilizer/Blue')
sprite('Sample',100,5600,290,0.42)

node('CleaningFans',z_index=-2)
for i,x in enumerate([5900,6010,6120]):
    sprite(f'Case{i}',29,x,211,0.95,'CleaningFans')
    sprite(f'Fan{i}',67,x,211,0.7,'CleaningFans')
for i,(x,y) in enumerate([(2580,222),(4160,220),(6590,242)]):
    node(f'Record{i}',position=f'Vector2({x},{y})',z_index=-2)
    node('EnergyFlask','Sprite2D',f'Record{i}',texture='ExtResource("flask")',scale='Vector2(1.2,1.2)',modulate='Color(0.6,0.75,2.5,1)')

lines += ['\n[node name="ExitElevator" parent="." instance=ExtResource("exit_cabin")]','position = Vector2(6900,316)','script = ExtResource("exit_lift")','next_scene_path = "res://scenes/gameplay/lower_lab_stage.tscn"','travels_down = true']

node('Inventory','CanvasLayer',layer=9)
node('Hint','Label','Inventory',offset_left=258,offset_top=126,offset_right=460,offset_bottom=152,theme_override_font_sizes__font_size=14,theme_override_colors__font_outline_color='Color(0.02,0.06,0.1,1)',theme_override_constants__outline_size=4,mouse_filter=2)
node('Label','Label','Inventory',offset_left=14,offset_top=120,theme_override_fonts__font='ExtResource("font")',theme_override_font_sizes__font_size=7,theme_override_colors__font_outline_color='Color(0.02,0.06,0.1,1)',theme_override_constants__outline_size=3,mouse_filter=2)
text='\n'.join(lines).replace('theme_override_fonts__','theme_override_fonts/').replace('theme_override_font_sizes__','theme_override_font_sizes/').replace('theme_override_colors__','theme_override_colors/').replace('theme_override_constants__','theme_override_constants/')+'\n'
(ROOT/'scenes/environment/tabletop_route.tscn').write_text(text,encoding='utf-8')
print('Authored tabletop_route.tscn with persistent scenery, gates, controls and supplies.')

