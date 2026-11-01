import { createServer } from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const { chromium } = await import(process.env.CRAFT_PLAYWRIGHT_MODULE || 'playwright');
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const resource=path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const root=path.resolve(resource, '../..');
const fixture=JSON.parse(await readFile(process.argv[2] || '/tmp/h4nr-craft-workbench-view.json','utf8'));
const browser=await chromium.launch({headless:true,executablePath:process.env.CRAFT_BROWSER_EXECUTABLE || undefined,args:['--no-sandbox','--disable-dev-shm-usage'],env:process.env});
const server=createServer(async (request,response)=>{
 const file=request.url==='/'?'index.html':request.url.slice(1);
 if(!['index.html','style.css','app.js','workbench.svg'].includes(file)){response.writeHead(404);response.end();return;}
 try {response.setHeader('Content-Type',({'html':'text/html','css':'text/css','js':'text/javascript','svg':'image/svg+xml'})[file.split('.').pop()]);response.end(await readFile(path.join(resource,'web',file)));}
 catch {response.writeHead(404);response.end();}
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const address=`http://127.0.0.1:${server.address().port}`;
const page=await browser.newPage({viewport:{width:1440,height:900}});
const errors=[],actions=[];let checks=0;
page.on('pageerror',e=>errors.push(e.message));
await page.addInitScript(()=>{window.GetParentResourceName=()=> 'h4nr-craft';});
await page.route(/^https:\/\/cfx-nui-/,async route=>{
 const url=new URL(route.request().url());
 const bases={'cfx-nui-feather-inventory':root+'/[feather]/feather-inventory','cfx-nui-feather-theme':root+'/[feather]/feather-theme'};
 const base=bases[url.hostname] || resource;
 try {await route.fulfill({body:await readFile(base+url.pathname),contentType:({'.js':'text/javascript','.css':'text/css','.woff2':'font/woff2','.svg':'image/svg+xml'})[path.extname(url.pathname)] || 'image/png'});}
 catch(error) {console.log('Preview asset unavailable:',base+url.pathname,error.code);await route.fulfill({status:404,body:''});}
});
await page.route('https://h4nr-craft/*',async route=>{actions.push({action:new URL(route.request().url()).pathname.slice(1),body:route.request().postDataJSON()});await route.fulfill({contentType:'application/json',body:'{"ok":true}'});});
const send=message=>page.evaluate(message=>window.dispatchEvent(new MessageEvent('message',{data:message})),message);
function check(value,label){assert(value,label);checks++;}
try {
 await page.goto(address);
 check(await page.locator('#app').isHidden(),'NUI stays hidden at resource startup');
 check(await page.evaluate(()=>getComputedStyle(document.body).backgroundColor==='rgba(0, 0, 0, 0)'&&getComputedStyle(document.documentElement).colorScheme!=='dark'),'Page canvas stays transparent around the NUI');
 await send(fixture);
 check(await page.locator('#app').isVisible(),'Workbench opens from actual Lua payload');
 await page.evaluate(()=>document.fonts.ready);
 check(await page.locator('#app').evaluate(el=>getComputedStyle(el).fontFamily.startsWith('Barlow')),'Craft uses the shared Inventory body font');
 check(await page.locator('h1').evaluate(el=>getComputedStyle(el).fontFamily.includes('Chakra Petch')),'Craft uses the shared Menu/Inventory display font');
 check(await page.evaluate(()=>[...document.fonts].some(f=>f.family==='Barlow'&&f.status==='loaded')&&[...document.fonts].some(f=>f.family==='Chakra Petch'&&f.status==='loaded')),'Shared bundled fonts actually load, including Romanian text');
 check(await page.locator('#craft').evaluate(el=>getComputedStyle(el).backgroundColor==='rgb(61, 139, 255)'),'Initial accent follows shared Neon Vice blue');
 await send({type:'feather-theme:state',state:{palette:{accent:'#ff3d9a',accent2:'#29d3ff',background:'#121321',text:'#f9faff',muted:'#aabbd1',warning:'#ffd23d'}}});
 await page.waitForFunction(()=>getComputedStyle(document.querySelector('#craft')).backgroundColor==='rgb(255, 61, 154)');
 check(await page.locator('#craft').evaluate(el=>getComputedStyle(el).backgroundColor==='rgb(255, 61, 154)'&&getComputedStyle(el).color==='rgb(255, 255, 255)'),'Live player accent recolors Craft with readable button text');
 check(await page.locator('.recipe-button.selected').evaluate(el=>getComputedStyle(el).backgroundColor==='rgba(255, 61, 154, 0.14)'),'Selected recipe tint follows the live accent');
 check(await page.locator('#xp-fill').evaluate(el=>getComputedStyle(el).backgroundColor==='rgb(255, 61, 154)'),'Progress follows the live accent');
 check(await page.locator('#app').evaluate(el=>getComputedStyle(el).backgroundImage.includes('rgb(18, 19, 33)')&&getComputedStyle(el).color==='rgb(249, 250, 255)'),'Workbench surface and text follow the server palette');
 check(await page.locator('.stock-count').first().evaluate(el=>getComputedStyle(el).color==='rgb(41, 211, 255)'),'Secondary palette follows live theme state');
 await send({type:'feather-theme:state',state:{palette:{accent:'#ffd23d'}}});
 check(await page.locator('#craft').evaluate(el=>getComputedStyle(el).color==='rgb(6, 16, 31)'),'Light accents switch primary button text for contrast');
 await send({type:'feather-theme:state',state:{palette:{}}});
 check(await page.locator('#search').evaluate(el=>document.activeElement===el),'Opening moves focus into search');
 await page.locator('.queue-action').filter({hasText:fixture.messages.collect}).first().focus();
 await page.keyboard.press('Tab');
 check(await page.locator('#refresh').evaluate(el=>document.activeElement===el),'Tab wraps within the visible workbench controls');

 check(await page.locator('.workspace').evaluate(el=>getComputedStyle(el).gridTemplateColumns.split(' ').length===3),'Desktop has three columns');
 check(await page.locator('#craft').isEnabled(),'Eligible recipe is actionable');
 await page.locator('#amount').fill('3');
 check((await page.locator('#output-summary').innerText()).includes('3 rețete → 3'),'Quantity updates output total');
 check((await page.locator('#duration').innerText()).includes('00:00:30'),'Quantity updates total duration');
 check((await page.locator('.ingredient strong').first().innerText()).includes('3'),'Quantity updates material requirement');
 const limited=structuredClone(fixture);limited.catalog.recipes[0].MaxBatch=2;
 await send(limited);
 check(await page.locator('#amount').inputValue()==='2','Quantity clamps to the catalog item batch limit');
 check(await page.locator('#plus').isDisabled(),'Cannot increase past an item batch limit');
 await send(fixture);await page.locator('#amount').fill('3');

 await page.locator('#search').fill('grătar');
 check(await page.locator('.recipe-button').count()===1,'Search filters recipes as typed');
 await page.locator('.recipe-button').click();
 check(await page.locator('#recipe-name').innerText()==='Carne la grătar','Selecting recipe updates detail panel');
 check(await page.locator('#amount').inputValue()==='1','New recipe resets quantity');
 await page.locator('#search').fill('');
 await page.locator('.recipe-button').first().click();
 await page.locator('#amount').fill('3');
 await page.locator('#craft').click();await page.waitForTimeout(50);
 check(actions.at(-1).action==='craft'&&actions.at(-1).body.amount===3&&actions.at(-1).body.nonce===fixture.nonce,'Craft submits recipe/quantity scoped to current NUI');
 const before=await page.locator('#amount').inputValue();await send(fixture);
 check(await page.locator('#amount').inputValue()===before,'Catalog refresh preserves selected quantity');
 check(await page.locator('.queue-card.ready').count()===1,'Ready queue uses ready state');
 check(await page.locator('.queue-card:not(.ready) .queue-action').isDisabled(),'Working order cannot be collected');
 await send({action:'queueTick',elapsed:20});
 check(await page.locator('.queue-card.ready').count()===2,'Local countdown turns completed orders collectible');
 await page.locator('.queue-action').first().click();await page.waitForTimeout(50);
 check(actions.at(-1).action==='collect'&&actions.at(-1).body.id==='preview-ready','Collect submits queue identity');
 const missing=structuredClone(fixture);
 missing.assessments[missing.catalog.recipes[0].Id][2].canCraft=false;
 missing.assessments[missing.catalog.recipes[0].Id][2].reasons=['missing_materials'];
 await send(missing);
 check(await page.locator('#craft').isDisabled(),'Missing requirements disable Craft');
 check((await page.locator('#eligibility').innerText()).includes(fixture.messages.missing_materials),'Blocking reason is visible');
 await send(fixture);
 await page.waitForFunction(()=>[...document.images].every(img=>img.complete&&img.naturalWidth>0));
 check(await page.locator('#item-image').evaluate(img=>img.naturalWidth>0),'Item hero image loads or falls back');
 await page.screenshot({omitBackground:true,path:process.env.CRAFT_SCREENSHOT_OUT || '/tmp/h4nr-craft-workbench.png'});
 await page.setViewportSize({width:1280,height:720});
 check(await page.locator('#app').evaluate(el=>el.scrollWidth<=el.clientWidth),'No horizontal overflow at 720p');
 await page.setViewportSize({width:650,height:900});
 check(await page.locator('.workspace').evaluate(el=>getComputedStyle(el).flexDirection==='column'),'Narrow viewport stacks panels');
 check(await page.locator('#app').evaluate(el=>el.scrollWidth<=el.clientWidth),'No horizontal overflow on narrow viewport');
 await page.setViewportSize({width:1440,height:900});
 await page.keyboard.press('Escape');await page.waitForTimeout(50);
 check(actions.at(-1).action==='close','Escape requests scoped close');
 const empty=structuredClone(fixture);empty.catalog.recipes={};empty.catalog.queue={};empty.assessments={};
 await send(empty);
 check(await page.locator('#app').isVisible()&&await page.locator('#craft').isDisabled(),'Empty Lua tables leave a visible closable empty workbench');
 await send({action:'close'});
 check(await page.locator('#app').isHidden(),'Close removes the NUI');
 check(errors.length===0,'No browser runtime errors: '+errors.join('; '));
 console.log(`Browser: ${checks} checks passed; screenshot /tmp/h4nr-craft-workbench.png`);
} finally {await browser.close();server.close();}
