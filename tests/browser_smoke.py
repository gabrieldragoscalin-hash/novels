"""Optional browser checks. Requires playwright, Pillow, and an installed Chromium.
Serve build/web first; pass its URL as the first argument.
"""
import sys, shutil, tempfile
from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image
import io,json

def player_center(page):
 im=Image.open(io.BytesIO(page.screenshot())).convert('RGB')
 pts=[]
 for y in range(100,min(600,im.height)):
  for x in range(im.width):
   r,g,b=im.getpixel((x,y))
   if abs(r-57)<4 and abs(g-188)<4 and abs(b-167)<4:pts.append((x,y))
 assert pts,'Player sprite must be visible'
 return [sum(p[i] for p in pts)/len(pts) for i in (0,1)]

with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium') or shutil.which('google-chrome'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 context=browser.new_context(viewport={'width':390,'height':844},device_scale_factor=1,has_touch=True,is_mobile=True)
 page=context.new_page()
 errors=[]
 page.on('pageerror',lambda e: errors.append(str(e)))
 page.on('console',lambda msg: errors.append(msg.text) if msg.type=='error' else None)
 page.goto(sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:8765',wait_until='networkidle')
 page.wait_for_timeout(6000)
 page.screenshot(path=str(Path(tempfile.gettempdir())/'dungeon-start.png'))
 canvas=page.locator('canvas')
 box=canvas.bounding_box()
 print('canvas',box,flush=True)
 # Portrait canvas expands height; its logical width remains 480.
 scale=box['width']/480
 def pos(x,y):return (box['x']+x*scale,box['y']+y*scale)
 page.touchscreen.tap(*pos(240,420))
 page.wait_for_timeout(400)
 page.screenshot(path=str(Path(tempfile.gettempdir())/'dungeon-room.png'))
 before=player_center(page)
 page.keyboard.down('w');page.wait_for_timeout(400);page.keyboard.up('w')
 page.wait_for_timeout(100)
 after=player_center(page)
 assert after[1]<before[1]-20,('Keyboard movement failed',before,after)
 # CDP sends a real touch drag with an identifiable touch point.
 cdp=context.new_cdp_session(page)
 x,y=pos(220,380)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':x,'y':y,'id':0}]})
 cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':x+35*scale,'y':y,'id':0}]})
 page.wait_for_timeout(400)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
 page.wait_for_timeout(100)
 touch=player_center(page)
 assert touch[0]>after[0]+15,('Touch movement failed',after,touch)
 page.wait_for_timeout(350)
 stopped=player_center(page)
 assert abs(stopped[0]-touch[0])<2,'Release must stop movement'
 # A real touch on Reset must still work, without starting the joystick.
 page.touchscreen.tap(*pos(240,755))
 page.wait_for_timeout(150)
 reset=player_center(page)
 assert abs(reset[0]-before[0])<2 and abs(reset[1]-before[1])<2,('Reset button failed',reset,before)
 # Walk through the east door and return; verify the minimap's current-room tile.
 page.keyboard.down('w');page.wait_for_timeout(780);page.keyboard.up('w')
 x,y=pos(80,680)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':x,'y':y,'id':0}]})
 cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':x+35*scale,'y':y,'id':0}]})
 page.wait_for_timeout(1800)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
 page.wait_for_timeout(400)
 def map_color(x,y):
  image=Image.open(io.BytesIO(page.screenshot())).convert('RGB')
  px,py=pos(365+x*16,30+y*16)
  return image.getpixel((int(px),int(py)))
 assert map_color(1,0)==(223,189,120),('East doorway must enter B1',map_color(1,0))
 # Wait for automatic attacks to clear B1; enemy health bars stay visible during hit flashes.
 def enemy_bars():
  image=Image.open(io.BytesIO(page.screenshot())).convert('RGB')
  crop=image.crop((0,100,image.width,490))
  return sum(count for count,(r,g,b) in crop.getcolors(crop.width*crop.height) if abs(r-237)<3 and abs(g-131)<3 and abs(b-146)<3)
 page.screenshot(path=str(Path(tempfile.gettempdir())/'dungeon-enemies.png'))
 for attempt in range(40):
  if enemy_bars()==0: break
  page.wait_for_timeout(200)
 assert enemy_bars()==0,'Automatic attacks must clear enemies in B1'
 # XP from the two enemies should trigger the first reward choice.
 def choice_visible():
  image=Image.open(io.BytesIO(page.screenshot())).convert('RGB')
  px,py=pos(50,240)
  return image.getpixel((int(px),int(py)))==(19,30,48)
 for attempt in range(25):
  if choice_visible(): break
  page.wait_for_timeout(200)
 assert choice_visible(),'Collected enemy XP must show a level-up choice'
 page.screenshot(path=str(Path(tempfile.gettempdir())/'dungeon-level-up.png'))
 page.keyboard.down('a');page.wait_for_timeout(300);page.keyboard.up('a')
 assert map_color(1,0)==(223,189,120),'Room travel must pause during reward choice'
 page.touchscreen.tap(*pos(240,500))
 page.wait_for_timeout(200)
 assert not choice_visible(),'Touching the coin card must dismiss the reward choice'

 page.screenshot(path=str(Path(tempfile.gettempdir())/'dungeon-combat.png'))

 page.keyboard.down('a');page.wait_for_timeout(1800);page.keyboard.up('a')
 page.wait_for_timeout(400)
 assert map_color(0,0)==(223,189,120),'West doorway must return to A1'
 page.screenshot(path=str(Path(tempfile.gettempdir())/'dungeon-tested.png'))
 assert not errors,errors
 print(json.dumps({'keyboard_before':before,'keyboard_after':after,'touch_after':touch,'release_after':stopped,'browser_errors':errors,'result':'PASS'}),flush=True)
 browser.close()
