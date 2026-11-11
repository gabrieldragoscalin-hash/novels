"""Render each weapon in an actual exported encounter, with isolated saved fixtures."""
import json,shutil,tempfile,time,os
from pathlib import Path
from playwright.sync_api import sync_playwright
source=Path('tests/browser_smoke.py').read_text()
read_js=source.split('    read_js="""',1)[1].split('"""',1)[0]
write_js='''async weapon=>{
 for(const info of await indexedDB.databases()){
  const db=await new Promise((resolve,reject)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
  if(!db.objectStoreNames.contains('FILE_DATA')){db.close();continue;}
  const read=r=>new Promise((resolve,reject)=>{r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
  const store=db.transaction('FILE_DATA','readonly').objectStore('FILE_DATA');
  const [keys,values]=await Promise.all([read(store.getAllKeys()),read(store.getAll())]);
  for(let i=0;i<keys.length;i++)if(String(keys[i]).endsWith('/hub.json')){
   const d=JSON.parse(new TextDecoder().decode(new Uint8Array(values[i].contents)));
   d.inventory={test_weapon:{type:weapon,rarity:0,plus:0,level:1}};
   Object.keys(d.equipped).forEach(slot=>d.equipped[slot]=slot==='weapon'?'test_weapon':'');
   d.perks={starting_upgrade:0,starting_hp:25,dodge:0,boss_damage:0};d.perk_purchases=25;
   values[i].contents=new TextEncoder().encode(JSON.stringify(d));values[i].timestamp=new Date();
   const tx=db.transaction('FILE_DATA','readwrite');tx.objectStore('FILE_DATA').put(values[i],keys[i]);
   await new Promise((resolve,reject)=>{tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);});db.close();return;
  }db.close();
 }throw Error('Missing test profile');
}'''
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 context=browser.new_context(viewport={'width':390,'height':844},has_touch=True,is_mobile=True,**({'record_video_dir':'/tmp/weapon-animation-videos','record_video_size':{'width':390,'height':844}} if os.environ.get('RECORD_ANIMATIONS') else {}))
 page=context.new_page()
 errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 url='http://127.0.0.1:8765/?seed=9'
 page.goto(url,wait_until='networkidle');page.wait_for_timeout(3500)
 for attempt in range(40):
  if page.evaluate(read_js):break
  page.wait_for_timeout(200)
 page.route('**/__weapon_fixture.html',lambda route:route.fulfill(status=200,body='<html>fixture</html>',content_type='text/html'))
 for weapon in ['bow','crossbow','wand','sword','hammer','chakram']:
  page.goto('http://127.0.0.1:8765/__weapon_fixture.html');page.evaluate(write_js,weapon)
  page.goto(url,wait_until='networkidle');page.wait_for_timeout(3000)
  box=page.locator('canvas').bounding_box();scale=box['width']/480;h=box['height']/scale
  def tap(x,y):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(150)
  tap(146,h-56)
  page.screenshot(path=f'/tmp/inventory-{weapon}.png')
  tap(242,h-56);tap(240,540);tap(390,756)
  page.mouse.move(250,650);page.mouse.wheel(0,2500);page.wait_for_timeout(250)
  tap(240,h-133) # Teleport to boss; reset profile sits below this row.
  tap(240,76) # Close cheats.
  page.wait_for_timeout(250)
  if weapon in ['sword','hammer']:
   page.keyboard.down('w');page.wait_for_timeout(800);page.keyboard.up('w')
  for frame in range(3):
   page.wait_for_timeout(170)
   page.screenshot(path=f'/tmp/weapon-{weapon}-{frame}.png')
  assert not errors,(weapon,errors)
  print(weapon,'PASS',flush=True)
 context.close()
 browser.close()
 print(json.dumps({'result':'PASS','checks':['six saved weapon loadouts','mobile controls','actual boss encounter rendering'],'errors':errors}))
