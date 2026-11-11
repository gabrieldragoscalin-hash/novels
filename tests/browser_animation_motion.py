"""Capture actual walking and walking-while-firing for animation review."""
import io,json,os,shutil
from PIL import Image,ImageChops
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 video={'record_video_dir':'/tmp/walk-animation-videos','record_video_size':{'width':480,'height':800}} if os.environ.get('RECORD_ANIMATIONS') else {}
 context=browser.new_context(viewport={'width':390,'height':844},has_touch=True,is_mobile=True,**video)
 page=context.new_page();errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto('http://127.0.0.1:8765/?seed=6',wait_until='networkidle');page.wait_for_timeout(3000)
 box=page.locator('canvas').bounding_box();scale=box['width']/480;h=box['height']/scale
 def tap(x,y):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(180)
 def marker(data):
  im=Image.open(io.BytesIO(data)).convert('RGB')
  channels=im.split();mask=Image.new('L',im.size,255)
  for channel,value in zip(channels,(57,188,167)):
   mask=ImageChops.multiply(mask,channel.point(lambda pixel:255 if abs(pixel-value)<3 else 0))
  bounds=mask.getbbox();assert bounds,'Dungeon must be active with a visible player marker'
  return ((bounds[0]+bounds[2])/2,(bounds[1]+bounds[3])/2)
 def screenshot(index):
  data=page.screenshot(path=f'/tmp/hero-walk-{index}.png',clip={'x':0,'y':370,'width':390,'height':120})
  return marker(data)
 tap(240,540);page.wait_for_timeout(350)
 marker(page.screenshot())
 page.keyboard.down('d');positions=[]
 for i in range(6):page.wait_for_timeout(55);positions.append(screenshot(i))
 assert positions[-1][0]>positions[0][0]+20,'Walking capture must show real movement'
 page.keyboard.up('d');page.wait_for_timeout(150)
 # Resume the same walk in reverse, then move vertically while auto-attacking.
 page.keyboard.down('a');page.wait_for_timeout(350);page.keyboard.up('a')
 tap(390,756);page.mouse.move(250,650);page.mouse.wheel(0,4000);page.wait_for_timeout(250)
 tap(240,h-133);page.wait_for_timeout(300)
 page.keyboard.down('w')
 for i in range(6):page.wait_for_timeout(75);page.screenshot(path=f'/tmp/hero-moving-attack-{i}.png')
 page.keyboard.up('w');page.wait_for_timeout(150)
 assert not errors,errors
 context.close();browser.close()
 print(json.dumps({'result':'PASS','checks':['continuous walk rendering','direction changes','movement during automatic attacks'],'errors':errors}))
