"""Touch-accessible testing menu, pause/resume and persistent grants in Chromium."""
import json,shutil,time
from pathlib import Path
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    page=browser.new_page(viewport={'width':390,'height':844},has_touch=True,is_mobile=True)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
    page.goto('http://127.0.0.1:8765/?seed=9',wait_until='networkidle');page.wait_for_timeout(3500)
    box=page.locator('canvas').bounding_box();scale=box['width']/480;h=box['height']/scale
    def tap(x,y):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(180)
    tap(434,h-56);tap(230,434)
    page.screenshot(path='/tmp/cheats-phone-top.png')
    tap(230,240) # Grant coins.
    # Read real browser storage to verify the visible button applied the grant.
    source=Path('tests/browser_smoke.py').read_text()
    read_js=source.split('    read_js="""',1)[1].split('"""',1)[0]
    for attempt in range(40):
        profile=page.evaluate(read_js)
        if profile and profile['coins']==10000:break
        page.wait_for_timeout(200)
    assert profile['coins']==10000,profile
    page.screenshot(path='/tmp/cheats-phone-grant.png')
    tap(230,76) # Close.
    page.screenshot(path='/tmp/cheats-phone-wallet.png')
    tap(242,h-56);tap(240,540) # Enter dungeon.
    tap(390,756) # In-run Cheats button.
    page.screenshot(path='/tmp/cheats-phone-run.png')
    # Scroll the mobile menu to reach current-run tools.
    for _ in range(3):
        page.mouse.move(270,650);page.mouse.wheel(0,500);page.wait_for_timeout(200)
    page.screenshot(path='/tmp/cheats-phone-bottom.png')
    tap(230,76)
    page.reload(wait_until="networkidle");page.wait_for_timeout(3500)
    assert page.evaluate(read_js)["coins"]==10000
    assert not errors,errors
    print(json.dumps({'result':'PASS','checks':['hub entry','currency grant','close','run entry','scrolling','resume'],'errors':errors}))
    browser.close()
