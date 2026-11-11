"""Focused hub layout checks at phone, short-phone and desktop sizes.
Requires the same served Web export and dependencies as browser_smoke.py.
"""
import json
import shutil
import sys
import tempfile
from pathlib import Path
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=shutil.which('chromium') or shutil.which('google-chrome'),headless=True,
        args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    results=[]
    for name,width,height in [('phone',390,844),('short-phone',390,640),('desktop',1280,900)]:
        ctx=browser.new_context(viewport={'width':width,'height':height},has_touch=True,is_mobile=name!='desktop',device_scale_factor=1)
        page=ctx.new_page();errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
        page.goto(sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:8765/',wait_until='networkidle')
        page.wait_for_timeout(4000)
        box=page.locator('canvas').bounding_box()
        scale=min(box['width']/480,box['height']/800)
        logical_height=box['height']/scale
        offset=(box['width']/scale-480)/2
        def tap(x,y):page.touchscreen.tap(box['x']+(offset+x)*scale,box['y']+y*scale);page.wait_for_timeout(150)
        def capture(suffix):page.screenshot(path=str(Path(tempfile.gettempdir())/f'hub-{name}-{suffix}.png'))
        capture('play')
        for index,title in enumerate(['shop','inventory','play','perks','miscellaneous']):
            tap(50+index*96,logical_height-56)
            capture(title)
        tap(146,logical_height-56)
        inventory_scale=max(0.9,min(1,0.9+(logical_height-800)*0.001))
        tap(81,160+(351-160)*inventory_scale)  # Empty Headgear slot filters inventory without equipping anything.
        capture('headgear-empty')
        tap(400,160+(570-160)*inventory_scale)  # Show all stored equipment.
        tap(81,203)  # Equipped weapon slot opens details.
        capture('weapon-details')
        tap(240,575) # Close modal back to inventory.
        tap(242,logical_height-56)
        assert not errors,errors
        results.append({'viewport':name,'result':'PASS','errors':errors})
        ctx.close()
    print(json.dumps(results))
    browser.close()
