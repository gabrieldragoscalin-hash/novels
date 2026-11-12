"""Actual home-screen interactions and screenshot review at three viewport shapes."""
import json,shutil,subprocess,os
from playwright.sync_api import sync_playwright
from PIL import Image

def read(path):
    return ''.join(subprocess.run(['tesseract',path,'stdout','--psm','11'],capture_output=True,text=True,check=True,timeout=20,env={**os.environ,'OMP_THREAD_LIMIT':'1'}).stdout.lower().split())

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    results=[]
    for name,width,height in [('phone',390,844),('short',390,640),('desktop',1280,900)]:
        if os.environ.get('HOME_VIEWPORTS') and name not in os.environ['HOME_VIEWPORTS'].split(','):continue
        context=browser.new_context(viewport={'width':width,'height':height},has_touch=True,is_mobile=name!='desktop')
        page=context.new_page();errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
        page.goto('http://127.0.0.1:8765/',wait_until='networkidle');page.wait_for_timeout(3000)
        box=page.locator('canvas').bounding_box();scale=min(box['width']/480,box['height']/800);h=box['height']/scale;offset=(box['width']/scale-480)/2
        def tap(x,y):page.touchscreen.tap(box['x']+(offset+x)*scale,box['y']+y*scale);page.wait_for_timeout(200)
        def capture(suffix):
            path=f'/tmp/home-{name}-{suffix}.png';page.screenshot(path=path);return path
        def dismiss():tap(8,h/2)
        top=max(16,(h-610)/2)
        capture('main')
        tap(280,42);path=capture('battlepass');assert 'hellindevelopment' in read(path),read(path)
        dismiss()
        tap(48,42);capture('profile');tap(98,130);path=capture('settings');assert 'insertcode' in read(path),read(path)
        # Change music volume, then use the actual text field and redeem action.
        tap(245,top+196);tap(160,top+445);page.keyboard.type('SLEEPWELL');capture('code-entry');tap(385,top+445);capture('code-result')
        dismiss()
        tap(48,42);tap(98,184);path=capture('bag');assert 'yourbagisempty' in read(path),read(path)
        dismiss()
        tap(48,42);tap(98,238);path=capture('details');assert 'bestfloor' in read(path),read(path)
        tap(240,top+558);capture('licenses');dismiss()
        for index,key in enumerate(['tasks','login','privileges','event']):
            tap(80,227+65+index*59+27);capture(key);dismiss()
        tap(434,h-56);path=capture('misc');assert 'cheatmenu' in read(path),read(path)
        tap(242,h-56);tap(290,h-94-67);page.wait_for_timeout(350);path=capture('dungeon')
        assert 'returntohub' in read(path).replace(' ',''),read(path)
        im=Image.open(path).convert('RGB');px=int(box['x']+240*scale);py=int(box['y']+530*scale)
        assert sum(all(abs(a-b)<3 for a,b in zip(im.getpixel((x,y)),(57,188,167))) for y in range(py-15,py+16) for x in range(px-24,px+25))>6,'Dungeon player marker must appear'
        assert not errors,errors
        results.append({'viewport':name,'result':'PASS','errors':errors});print(name,'PASS',flush=True)
        context.close()
    browser.close();print(json.dumps(results))
