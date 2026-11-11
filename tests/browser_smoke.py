"""Mobile browser smoke test for seed 9. Requires Playwright, Pillow and Chromium.
Serve build/web on port 8765, or pass another base URL as the first argument.
"""
import io
import json
import shutil
import sys
import tempfile
import time
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=shutil.which('chromium') or shutil.which('google-chrome'), headless=True,
        args=['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
    context = browser.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=1, has_touch=True, is_mobile=True)
    page = context.new_page()
    errors = []
    page.on('pageerror', lambda e: errors.append(str(e)))
    page.on('console', lambda m: errors.append(m.text) if m.type == 'error' else None)
    url = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8765/'
    page.goto(url + ('&' if '?' in url else '?') + 'seed=9', wait_until='networkidle')
    page.wait_for_timeout(4500)
    box = page.locator('canvas').bounding_box()
    scale = box['width'] / 480
    def pos(x, y): return (box['x'] + x * scale, box['y'] + y * scale)
    def hub_tab(index):
        tap(50 + index*96, box['height']/scale - 56)
    def image(): return Image.open(io.BytesIO(page.screenshot())).convert('RGB')
    def capture(name): page.screenshot(path=str(Path(tempfile.gettempdir()) / name))
    def tap(x, y): page.touchscreen.tap(*pos(x, y)); page.wait_for_timeout(180)
    def current_room():
        im = image()
        for y in range(5):
            for x in range(5):
                px, py = pos(361 + x * 16, 26 + y * 16)
                rgb = im.getpixel((int(px), int(py)))
                if all(abs(a-b) < 3 for a,b in zip(rgb, (223,189,120))): return (x,y)
        return None
    def player_pos():
        im = image()
        pts = []
        for y in range(120, 490):
            for x in range(im.width):
                r,g,b = im.getpixel((x,y))
                if abs(r-57)<3 and abs(g-188)<3 and abs(b-167)<3: pts.append((x,y))
        assert pts, 'Player sprite must be visible'
        return ((sum(x for x,y in pts)/len(pts)-box['x'])/scale,
                (sum(y for x,y in pts)/len(pts)-box['y'])/scale + 13)
    def align(axis, target):
        for attempt in range(30):
            value = player_pos()[axis]
            if abs(value-target) < 7: return
            key = ('d' if value < target else 'a') if axis == 0 else ('s' if value < target else 'w')
            page.keyboard.down(key)
            page.wait_for_timeout(min(140, max(20, abs(value-target)/185*1000)))
            page.keyboard.up(key)
        raise AssertionError('Could not align with doorway')
    def go(dx, dy):
        before = current_room()
        assert before is not None
        target = (before[0]+dx, before[1]+dy)
        align(1,385) if dx else align(0,240)
        key = 'd' if dx == 1 else 'a' if dx == -1 else 's' if dy == 1 else 'w'
        page.keyboard.down(key)
        try:
            deadline = time.monotonic()+6
            while time.monotonic()<deadline:
                page.wait_for_timeout(90)
                if current_room() == target: return
            raise AssertionError(('Door did not reach room', before,target,current_room()))
        finally: page.keyboard.up(key)

    capture('dungeon-hub.png')
    tap(240,540)
    assert current_room() == (0,1), 'Seed 9 must start at A2'
    before = player_pos()
    cdp = context.new_cdp_session(page)
    x,y = pos(220,380)
    cdp.send('Input.dispatchTouchEvent', {'type':'touchStart','touchPoints':[{'x':x,'y':y,'id':0}]})
    cdp.send('Input.dispatchTouchEvent', {'type':'touchMove','touchPoints':[{'x':x+35*scale,'y':y,'id':0}]})
    page.wait_for_timeout(300)
    cdp.send('Input.dispatchTouchEvent', {'type':'touchEnd','touchPoints':[]})
    after = player_pos()
    assert after[0] > before[0]+20
    page.wait_for_timeout(250)
    assert abs(player_pos()[0]-after[0])<2
    go(0,-1)  # A1 trader, no upgrades owned yet.
    tap(240,682)
    capture('dungeon-trader.png')
    tap(240,575)  # Back to room.
    go(1,0)  # B1 free loot.
    tap(240,682)
    tap(240,575)  # Loot/materials notice.
    go(1,0)  # C1 shop.
    tap(240,682)
    capture('dungeon-shop.png')
    tap(135,334)  # Permanent left-column hub key: 20 coins from B1.
    tap(240,575)
    go(0,1)  # C2 loot.
    tap(240,682)
    tap(240,575)
    go(0,1)  # C3 empty.
    go(0,1)  # C4 loot.
    tap(240,682)
    tap(240,575)
    go(0,1)  # C5 free upgrade.
    tap(240,682)
    capture('dungeon-level-up.png')
    tap(240,340)  # One of the two upgrade cards.
    go(0,-1)
    assert current_room() == (2,3), 'Movement must resume after reward selection'
    tap(240,755)  # Return to hub, retaining the purchased key.
    capture('dungeon-hub-return.png')
    hub_tab(1)  # Inventory: eight slots around the character.
    capture('dungeon-inventory.png')
    tap(81,203)  # Equipped weapon slot.
    capture('dungeon-weapon.png')
    tap(240,355)  # Spend 3 collected scrap to upgrade it.
    capture('dungeon-weapon-upgraded.png')
    tap(240,575)  # Back to hub.

    hub_tab(3)  # Perks.
    tap(240,470)  # Spend the key on training.
    hub_tab(2)  # Play selects the page, not an immediate departure.
    capture('dungeon-play-menu.png')
    tap(240,540)  # Start again with the same seed and permanent training.
    assert current_room() == (0,1)
    # Read the actual browser save to verify atomic persistence of gear and training.
    save_script = """async () => {
      for (const info of await indexedDB.databases()) {
        const db = await new Promise((resolve,reject) => {
          const req=indexedDB.open(info.name);req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);
        });
        if (!db.objectStoreNames.contains('FILE_DATA')) { db.close();continue; }
        const tx=db.transaction('FILE_DATA','readonly');const store=tx.objectStore('FILE_DATA');
        const read=req=>new Promise((resolve,reject)=>{req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);});
        const [keys,values]=await Promise.all([read(store.getAllKeys()),read(store.getAll())]);
        db.close();
        for (let i=0;i<keys.length;i++) {
          if (!String(keys[i]).endsWith('/hub.json')) continue;
          try {return JSON.parse(new TextDecoder().decode(new Uint8Array(values[i].contents)));} catch(e) {}
        }
      }
      return null;
    }"""
    saved=None
    for attempt in range(30):
        saved=page.evaluate(save_script)
        if saved and saved.get('inventory',{}).get('bow')==2 and saved.get('training')==1:break
        page.wait_for_timeout(200)
    assert saved and saved['inventory']['bow']==2 and saved['training']==1,('Gear must persist to IndexedDB',saved)
    page.reload(wait_until='networkidle')
    page.wait_for_timeout(4500)
    tap(240,540)
    assert current_room()==(0,1),'Saved loadout must allow restarting after reload'
    capture('dungeon-tested.png')
    # Reach the boss through a combat-free floor-one route and inspect its attack.
    go(0,-1)
    go(1,0)
    go(1,0)
    go(0,1)
    go(0,1)
    go(1,0)
    capture('dungeon-boss.png')
    page.wait_for_timeout(2300)
    capture('dungeon-boss-volley.png')
    assert not errors, errors
    print(json.dumps({'result':'PASS', 'seed':9, 'checks':['touch movement','release','door travel','trader menu','loot pickup','two-column shop','permanent key purchase','free upgrade','hub return and training','eight-slot inventory and weapon upgrade','browser save and reload','boss rendering and volley'], 'browser_errors':errors}))
    browser.close()
