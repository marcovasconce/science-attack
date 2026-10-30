from PIL import Image
from pathlib import Path
im=Image.open('assets/animations/build_sheet_source.png').convert('RGBA')
cw,ch=im.width//6,im.height//2
for row,name in enumerate(['Owlet','Pink']):
 cells=[im.crop((col*cw,row*ch,(col+1)*cw,(row+1)*ch)) for col in range(6)]
 for cell in cells:
  cell.putalpha(cell.getchannel('A').point(lambda value:value if value>160 else 0))
 bounds=[cell.getbbox() for cell in cells]
 ratio=25/max(b[3]-b[1] for b in bounds)
 sheet=Image.new('RGBA',(192,32))
 for i,(cell,b) in enumerate(zip(cells,bounds)):
  cut=cell.crop(b)
  cut=cut.resize((max(1,round(cut.width*ratio)),max(1,round(cut.height*ratio))),Image.Resampling.NEAREST)
  sheet.alpha_composite(cut,(i*32+16-cut.width//2,30-cut.height))
 sheet.save(f'assets/animations/{name}_build_6.png')
print('Build sprite sheets normalized to six 32x32 frames each.')
