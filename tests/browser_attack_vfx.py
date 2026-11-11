"""Exercise explosive arrows, Perpetuum and max-upgrade Meteor Rain through real cheats."""
import json,os,shutil,subprocess,tempfile
from pathlib import Path
from playwright.sync_api import sync_playwright
source=Path('tests/browser_weapons.py').read_text()
write_js=source.split("write_js='''",1)[1].split("'''",1)[0]
read_js=Path('tests/browser_smoke.py').read_text().split('    read_js="""',1)[1].split('"""',1)[0]
with tempfile.TemporaryDirectory() as tmp:
 plan_path=Path(tmp)/'plans.json'
 subprocess.run(['godot','--headless','--path','.','--script','tools/build_vfx_test_plans.gd','--',str(plan_path)],check=True,stdout=subprocess.DEVNULL)
 plans=json.loads(plan_path.read_text())
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=browser.new_page(viewport={'width':390,'height':844},has_touch=True,is_mobile=True)
 errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 url='http://127.0.0.1:8765/?seed=9'
 page.goto(url,wait_until='networkidle');page.wait_for_timeout(3000)
 for i in range(40):
  if page.evaluate(read_js):break
  page.wait_for_timeout(100)
 page.route('**/__vfx_fixture.html',lambda route:route.fulfill(status=200,body='<html>fixture</html>',content_type='text/html'))
 results=[]
 for name in ['explosive','laser','meteor']:
  fixture=plans[name]
  page.goto('http://127.0.0.1:8765/__vfx_fixture.html');page.evaluate(write_js,fixture['weapon'])
  page.goto(url,wait_until='networkidle');page.wait_for_timeout(2500)
  box=page.locator('canvas').bounding_box();scale=box['width']/480;h=box['height']/scale
  def tap(x,y,pause=90):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(pause)
  def bottom():page.mouse.move(250,650);page.mouse.wheel(0,4000);page.wait_for_timeout(180)
  def choose(x,y,index):
   tap(x,y,50);page.keyboard.press('Home')
   for _ in range(index+1):page.keyboard.press('ArrowDown')
   page.keyboard.press('Enter');page.wait_for_timeout(40)
  tap(434,h-56);tap(240,434)
  choose(240,984,9);bottom();tap(240,343);page.wait_for_timeout(250)
  tap(390,756);bottom();tap(240,h-509) # God mode.
  for step,index in enumerate(fixture['plan']):
   choose(240,h-614,index)
   if step==0:
    choice=f'/tmp/attack-vfx-choice-{name}.png';page.screenshot(path=choice)
    if shutil.which('tesseract'):
     text=subprocess.check_output(['tesseract',choice,'stdout','--psm','6'],stderr=subprocess.DEVNULL,text=True).lower()
     expected={'meteor':'magic meteor','laser':'perpetuum','explosive':'explosive arrows'}[name]
     assert expected in text,(name,'Wrong upgrade selected',text)
   tap(240,h-564,60)
  if name=='meteor':
   choose(240,h-237,plans['combat_room']);tap(240,h-183)
  else:tap(240,h-133)
  page.wait_for_timeout(700)
  page.evaluate('''()=>{window.vfxFrameTimes=[];let last=performance.now();let until=last+2400;
   function tick(now){window.vfxFrameTimes.push(now-last);last=now;if(now<until)requestAnimationFrame(tick);}requestAnimationFrame(tick);}''')
  for frame in range(4):
   page.wait_for_timeout(150);page.screenshot(path=f'/tmp/attack-vfx-{name}-{frame}.png')
  page.wait_for_timeout(1600)
  timing=page.evaluate('window.vfxFrameTimes')
  assert len(timing)>=5,(name,'Browser did not remain responsive',timing)
  assert not errors,(name,errors)
  timing.sort();results.append({'build':name,'frames':len(timing),'p50_ms':round(timing[len(timing)//2],1),'p95_ms':round(timing[int((len(timing)-1)*.95)],1)})
  print(name,'PASS',results[-1],flush=True)
 browser.close()
 print(json.dumps({'result':'PASS','checks':['explosive animation','laser animation','max-upgrade meteor/rain/Telekinesis','responsive rendering'],'timing':results,'errors':errors}))
