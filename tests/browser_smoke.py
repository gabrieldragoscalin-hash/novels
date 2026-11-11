"""Mobile gameplay + economy integration. Fixtures exist only in this isolated browser profile.
Serve the Web export locally on port 8765. Requires Playwright, Pillow, Chromium.
"""
import io,json,shutil,sys,tempfile,time
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=shutil.which('chromium') or shutil.which('google-chrome'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    ctx=browser.new_context(viewport={'width':390,'height':844},device_scale_factor=1,has_touch=True,is_mobile=True)
    page=ctx.new_page();errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
    base=sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:8765/'
    url=base+('&' if '?' in base else '?')+'seed=9'
    page.goto(url,wait_until='networkidle');page.wait_for_timeout(4000)
    box=page.locator('canvas').bounding_box();scale=box['width']/480;logical_height=box['height']/scale
    def pos(x,y):return(box['x']+x*scale,box['y']+y*scale)
    def tap(x,y):page.touchscreen.tap(*pos(x,y));page.wait_for_timeout(180)
    def tab(index):tap(50+96*index,logical_height-56)
    def capture(name):page.screenshot(path=str(Path(tempfile.gettempdir())/name))
    def image():return Image.open(io.BytesIO(page.screenshot())).convert('RGB')
    def current_room():
        im=image()
        for y in range(5):
            for x in range(5):
                px,py=pos(361+x*16,26+y*16)
                if all(abs(a-b)<3 for a,b in zip(im.getpixel((int(px),int(py))),(223,189,120))):return(x,y)
        return None
    def player_pos():
        im=image();points=[]
        for y in range(120,490):
            for x in range(im.width):
                r,g,b=im.getpixel((x,y))
                if abs(r-57)<3 and abs(g-188)<3 and abs(b-167)<3:points.append((x,y))
        assert points,'Player must be visible'
        return(sum(x for x,y in points)/len(points)/scale,sum(y for x,y in points)/len(points)/scale+13)
    def align(axis,target):
        for attempt in range(30):
            value=player_pos()[axis]
            if abs(value-target)<7:return
            key=('d' if value<target else 'a') if axis==0 else ('s' if value<target else 'w')
            page.keyboard.down(key);page.wait_for_timeout(min(140,max(20,abs(value-target)/185*1000)));page.keyboard.up(key)
        raise AssertionError('Cannot align doorway')
    def go(dx,dy):
        old=current_room();assert old is not None
        target=(old[0]+dx,old[1]+dy)
        align(1,385) if dx else align(0,240)
        key='d' if dx==1 else 'a' if dx==-1 else 's' if dy==1 else 'w'
        page.keyboard.down(key)
        try:
            deadline=time.monotonic()+6
            while time.monotonic()<deadline:
                page.wait_for_timeout(90)
                if current_room()==target:return
            raise AssertionError(('Door failed',old,target,current_room()))
        finally:page.keyboard.up(key)
    read_js="""async()=>{
      for(const info of await indexedDB.databases()){
        const db=await new Promise((res,rej)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error);});
        if(!db.objectStoreNames.contains('FILE_DATA')){db.close();continue;}
        const store=db.transaction('FILE_DATA','readonly').objectStore('FILE_DATA');
        const read=r=>new Promise((res,rej)=>{r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error);});
        const [keys,values]=await Promise.all([read(store.getAllKeys()),read(store.getAll())]);db.close();
        for(let i=0;i<keys.length;i++)if(String(keys[i]).endsWith('/hub.json'))return JSON.parse(new TextDecoder().decode(new Uint8Array(values[i].contents)));
      }return null;
    }"""
    def saved_when(predicate):
        saved=None
        for attempt in range(40):
            saved=page.evaluate(read_js)
            if saved and predicate(saved):return saved
            page.wait_for_timeout(200)
        raise AssertionError(('Saved profile did not reach expected state',saved))

    tap(240,540);assert current_room()==(0,1)
    cdp=ctx.new_cdp_session(page);before=player_pos();x,y=pos(220,380)
    cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':x,'y':y,'id':0}]})
    cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':x+35*scale,'y':y,'id':0}]})
    page.wait_for_timeout(300);cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
    after=player_pos();assert after[0]>before[0]+20
    page.wait_for_timeout(250);assert abs(player_pos()[0]-after[0])<2
    go(0,-1);go(1,0);tap(240,682);tap(240,575) # B1 chest.
    go(1,0);go(0,1);tap(240,682);tap(240,575) # C2 chest.
    go(0,1);go(0,1);tap(240,682);tap(240,575) # C4 chest.
    tap(240,755)
    natural=saved_when(lambda d:d.get('coins',0)>=60 and len(d.get('inventory',{}))>=4)
    assert 'materials' not in {k:v for k,v in natural.items() if k!='legacy_data'}
    # Put a controlled duplicate/coin/key fixture into a separate page of this fresh test origin.
    page.route('**/__economy_fixture.html',lambda route:route.fulfill(status=200,body='<html><body>test fixture</body></html>',content_type='text/html'))
    page.goto(base.rstrip('/')+'/__economy_fixture.html')
    write_js="""async()=>{
      for(const info of await indexedDB.databases()){
        const db=await new Promise((res,rej)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error);});
        if(!db.objectStoreNames.contains('FILE_DATA')){db.close();continue;}
        const read=r=>new Promise((res,rej)=>{r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error);});
        let store=db.transaction('FILE_DATA','readonly').objectStore('FILE_DATA');
        const [keys,values]=await Promise.all([read(store.getAllKeys()),read(store.getAll())]);
        for(let i=0;i<keys.length;i++)if(String(keys[i]).endsWith('/hub.json')){
          const d=JSON.parse(new TextDecoder().decode(new Uint8Array(values[i].contents)));
          d.coins=2000;d.gems=1000;d.keys={copper:1,silver:1,gold:1};d.parts={armor:0,accessory:0,weapon:0};
          d.inventory={};['bow','bow','crossbow','wand'].forEach((type,j)=>d.inventory['fixture_'+j]={type,rarity:0,plus:0,level:1});
          Object.keys(d.equipped).forEach(slot=>d.equipped[slot]=slot==='weapon'?'fixture_0':'');
          d.pity={copper:0,silver:0,gold:34};d.perks={starting_upgrade:0,starting_hp:0,dodge:0,boss_damage:0};d.perk_purchases=0;
          values[i].contents=new TextEncoder().encode(JSON.stringify(d));values[i].timestamp=new Date();
          const tx=db.transaction('FILE_DATA','readwrite');tx.objectStore('FILE_DATA').put(values[i],keys[i]);
          await new Promise((res,rej)=>{tx.oncomplete=res;tx.onerror=()=>rej(tx.error);});db.close();return;
        }db.close();
      }throw Error('No game profile to seed');
    }"""
    page.evaluate(write_js);page.goto(url,wait_until='networkidle');page.wait_for_timeout(4000)
    tab(1);tap(378,121);capture('economy-synthesis-empty.png')
    for x in [73,179,285,391]:tap(x,660)
    capture('economy-synthesis-ready.png');tap(240,472)
    merged=saved_when(lambda d:len(d['inventory'])==1 and d['inventory']['fixture_0']['rarity']==1)
    assert merged['equipped']['weapon']=='fixture_0'
    capture('economy-synthesis-result.png')
    tab(0);capture('economy-shop.png');tap(126,344)
    saved_when(lambda d:d['parts']['weapon']==5 and d['coins']==1950)
    tap(131,656) # Copper key purchase.
    capture('economy-chest-result.png');tap(240,575)
    saved_when(lambda d:d['keys']['copper']==0 and len(d['inventory'])==2)
    tab(1);tap(378,121) # Back from Synthesis to the equipment view.
    tap(81,203);tap(240,355);tap(240,575)
    saved_when(lambda d:d['inventory']['fixture_0']['level']==2 and d['parts']['weapon']==0)
    tab(3);tap(240,587)
    saved_when(lambda d:d['perks']['starting_upgrade']==1 and d['perk_purchases']==1)
    for i in range(4):tap(240,587)
    perks=saved_when(lambda d:d['perk_purchases']==5)
    assert all(v>=1 for v in perks['perks'].values()) and sum(perks['perks'].values())==5
    capture('economy-perks.png')
    tab(4);capture('economy-reserved-tasks.png')
    assert perks['gems']==1000,'Reserved tasks cannot grant gems'
    tab(2);tap(240,540);capture('economy-starting-upgrade.png');tap(240,340)
    assert current_room()==(0,1)
    page.reload(wait_until='networkidle');page.wait_for_timeout(4000)
    reloaded=page.evaluate(read_js)
    assert reloaded['inventory']['fixture_0']['rarity']==1 and reloaded['inventory']['fixture_0']['level']==2
    assert reloaded['perk_purchases']==5 and reloaded['keys']['copper']==0
    assert not errors,errors
    print(json.dumps({'result':'PASS','checks':['touch movement','dungeon item/coin pickups','individual duplicates','four-copy synthesis','daily parts purchase','copper chest key payment','parts item-level upgrade','fixed first perk and unlock-before-level','reserved gems/tasks','starting upgrade','browser persistence/reload'],'errors':errors}))
    browser.close()
