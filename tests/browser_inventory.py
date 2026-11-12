"""Isolated inventory UI regression. Requires Playwright, Pillow, Chromium and tesseract.
Run against a local web export on port 8768, or pass its URL as the first argument.
Fixtures only affect the fresh test browser context.
"""
import ast,json,shutil,subprocess,sys
from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image, ImageChops
source=ast.parse(Path(__file__).with_name('browser_smoke.py').read_text())
readjs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='read_js' for t in n.targets))
writejs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='write_js' for t in n.targets))
writejs=writejs.replace("['bow','bow','bow','bow']", "['bow','crossbow','wand','sword','hammer','chakram','vest','boots','hood','pants','ring','bracelet','charm',...Array(27).fill('bow')]").replace('rarity:0,plus:0,level:1','rarity:j%5,plus:0,level:1').replace('weapon:0','weapon:100')
base=sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:8768/'
base=base.rstrip('/')+'/'
def ocr(path): return subprocess.check_output(['tesseract',str(path),'stdout'],stderr=subprocess.DEVNULL,text=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True)
 page=c.new_page(); errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto(base);page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000);page.wait_for_timeout(1800)
 print('save exists',bool(page.evaluate(readjs)),flush=True)
 page.route('**/__fixture.html',lambda r:r.fulfill(body='<html></html>',content_type='text/html'))
 page.goto(base+'__fixture.html');page.evaluate(writejs)
 page.goto(base);page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000);page.wait_for_timeout(600)
 scale=390/480
 def tap(x,y):page.touchscreen.tap(x*scale,y*scale);page.wait_for_timeout(350)
 tap(144,982)
 page.screenshot(path='/tmp/inventory-mobile-before.png')
 print('before: screenshot captured',flush=True)
 cdp=c.new_cdp_session(page)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':180*scale,'y':790*scale,'id':0}]})
 for y in range(770,550,-20):
  cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':180*scale,'y':y*scale,'id':0}]});page.wait_for_timeout(40)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(600)
 page.screenshot(path='/tmp/inventory-mobile-after.png')
 print('after: screenshot captured',flush=True)
 before=Image.open('/tmp/inventory-mobile-before.png');after=Image.open('/tmp/inventory-mobile-after.png')
 assert ImageChops.difference(before.crop((15,430,370,740)),after.crop((15,430,370,740))).getbbox(),'Swipe did not scroll'
 assert 'parts available' not in ocr('/tmp/inventory-mobile-after.png'),'Swipe selected an item'
 tap(73,575)
 page.screenshot(path='/tmp/inventory-mobile-preview.png')
 print('preview: screenshot captured',flush=True)
 assert 'parts available' in ocr('/tmp/inventory-mobile-preview.png')
 tap(450,80)
 page.screenshot(path='/tmp/inventory-mobile-dismissed.png')
 assert 'parts available' not in ocr('/tmp/inventory-mobile-dismissed.png')
 print('errors',errors,flush=True);assert not errors
 c.close()
 c=b.new_context(viewport={'width':480,'height':800});page=c.new_page()
 page.goto(base);page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000)
 page.mouse.click(144,750);page.wait_for_timeout(500)
 page.mouse.move(73,510);page.wait_for_timeout(500);page.screenshot(path='/tmp/inventory-desktop-hover.png')
 print('hover: screenshot captured',flush=True)
 assert 'parts available' in ocr('/tmp/inventory-desktop-hover.png')
 page.mouse.move(470,70);page.wait_for_timeout(500);page.screenshot(path='/tmp/inventory-desktop-dismissed.png')
 assert 'parts available' not in ocr('/tmp/inventory-desktop-dismissed.png')
 for index in [0,3,4]:
  page.mouse.click(48+96*index,750);page.wait_for_timeout(300);page.screenshot(path=f'/tmp/inventory-menu-{index}.png')
 b.close();print('PASS mobile swipe, tap preview, outside dismissal, desktop hover/dismissal',flush=True)
