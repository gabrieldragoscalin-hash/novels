"""Check lab entry/return, interchangeable profiles, pose controls, and three layouts."""
import shutil,json,os
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 results=[]
 for name,width,height in [('phone',390,844),('short',390,640),('desktop',1280,900)]:
  context=browser.new_context(viewport={'width':width,'height':height},has_touch=True,is_mobile=name!='desktop',device_scale_factor=2 if name=='phone' else 1)
  page=context.new_page();errors=[]
  page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None);page.on('pageerror',lambda e:errors.append(str(e)))
  base='http://127.0.0.1:8765/'
  page.goto(base if name=='phone' else base+'?animation_lab=1',wait_until='networkidle');page.wait_for_timeout(2200)
  box=page.locator('canvas').bounding_box();scale=min(box['width']/480,box['height']/800);offset=(box['width']/scale-480)/2;h=box['height']/scale
  def tap(x,y):page.touchscreen.tap(box['x']+(offset+x)*scale,box['y']+y*scale);page.wait_for_timeout(120)
  def snap(tag):page.screenshot(path=f'/tmp/animation-lab-{name}-{tag}.png')
  if name=='phone':
   tap(434,h-56);tap(240,498);page.wait_for_timeout(1000)
  snap('entry')
  tap(390,552) # Pause to inspect reproducible poses.
  for i,key in enumerate(['sun','moon','hammer']):
   tap(90+i*150,121)
   for col,facing in enumerate(['front','back','right','left']):
    tap(70+col*113,167);tap(20+440*0.38,629);snap(key+'-'+facing)
  tap(70+2*113,167);tap(20+440*0.54,629);snap('hammer-impact')
  tap(90,681);snap('game-size');tap(230,681)
  tap(240,552);tap(390,552)
  for i in range(3):page.wait_for_timeout(150);snap('walking-'+str(i))
  tap(390,681);snap('contact-markers');tap(390,681)
  tap(422,30);page.wait_for_timeout(900);snap('returned-hub')
  assert page.evaluate("new URLSearchParams(location.search).get('animation_lab')") is None,'Deep-link flag must be cleared when returning to hub'
  assert not errors,errors
  results.append({'viewport':name,'result':'PASS','errors':errors});print(name,'PASS',flush=True)
  context.close()
 browser.close();print(json.dumps(results))
