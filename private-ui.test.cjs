const assert=require('node:assert/strict');const fs=require('node:fs'),path=require('node:path');const {JSDOM,VirtualConsole}=require('jsdom');
const html=fs.readFileSync(path.resolve(__dirname,'../outputs/WaitLess_Files_Test_Prive.html'),'utf8');
async function uiTest(){
 const errors=[];const vc=new VirtualConsole();vc.on('jsdomError',e=>errors.push(e));
 const dom=new JSDOM(html,{url:'https://preview.invalid/online.html',runScripts:'dangerously',virtualConsole:vc,beforeParse(w){w.confirm=()=>true;w.fetch=()=>{throw Error('Unexpected network request')};w.HTMLDialogElement.prototype.showModal=function(){this.setAttribute('open','')};w.HTMLDialogElement.prototype.close=function(){this.removeAttribute('open');this.dispatchEvent(new w.Event('close'));};}});
 const w=dom.window,d=w.document;
 async function until(fn,label){for(let i=0;i<100;i++){if(fn())return;await new Promise(r=>setTimeout(r,10));}throw Error('Timeout: '+label+'; '+d.getElementById('message').textContent);}
 const click=async selector=>{await until(()=>d.querySelector(selector)&&!d.querySelector(selector).disabled,'enabled '+selector);const el=d.querySelector(selector);assert.ok(el,selector);assert.ok(!el.disabled,'Button enabled: '+selector);el.click();};
 await until(()=>d.getElementById('syncStatus').textContent==='Données synchronisées','initial sync');
 await click('[data-action="join"]');await until(()=>d.querySelector('.ticket-number')?.textContent==='WL-1','first ticket');
 await click('[data-demo-role="other"]');await until(()=>d.getElementById('accountEmail').textContent.includes('Client 2')&&d.getElementById('syncStatus').textContent==='Données synchronisées','second client');
 await click('[data-view="explore"]');await click('[data-action="join"]');await until(()=>d.querySelector('.ticket-number')?.textContent==='WL-2','second ticket');
 assert.equal(d.querySelector('#ticketList .metric strong').textContent,'1');
 assert.equal(d.querySelectorAll('#ticketList .card').length,1,'Customer does not see another customer ticket');
 await click('[data-demo-role="owner"]');await until(()=>d.querySelector('[data-action="toggle"]')&&!d.querySelector('[data-action="toggle"]').disabled,'owner');
 await click('[data-action="toggle"]');await until(()=>d.querySelector('[data-action="toggle"]').dataset.open==='true'&&!d.querySelector('[data-action="toggle"]').disabled,'closed');
 await click('[data-view="explore"]');assert.ok(d.querySelector('[data-action="join"]').disabled,'Closed file rejects new ticket in UI');
 await click('[data-view="business"]');await click('[data-action="call"]');await until(()=>d.querySelector('[data-action="complete"]')?.dataset.ticket,'call');
 assert.ok(d.querySelector('[data-action="call"]').disabled,'One service at a time');
 await click('[data-qr]');assert.ok(d.querySelector('#qrImage svg'),'Locally generated QR');assert.equal(new URL(d.getElementById('qrLink').value).hostname,'example.invalid');assert.ok(d.getElementById('qrHelp').textContent.includes('ne connecte pas'));assert.ok(d.getElementById('copyVenueLink').disabled,'Private demo cannot share an inactive live link');
 await click('#closeQr');await click('[data-demo-role="client"]');await until(()=>d.querySelector('.called-banner')?.textContent.includes('votre tour'),'your-turn screen');await click('[data-demo-role="owner"]');await click('[data-action="complete"]');await until(()=>!d.querySelector('[data-action="complete"]').dataset.ticket,'complete');
 await click('[data-demo-role="client"]');await until(()=>d.querySelector('#ticketList .badge')?.textContent==='Terminé','customer completed status');
 await click('[data-demo-role="other"]');await until(()=>d.querySelector('#ticketList .metric strong')?.textContent==='0','remaining position');
 await click('[data-action="cancel"]');await until(()=>d.querySelector('#ticketList .badge')?.textContent==='Annulé','cancel');
 const lang=d.getElementById('language');lang.value='en';lang.dispatchEvent(new w.Event('change',{bubbles:true}));assert.equal(d.documentElement.lang,'en');assert.ok(d.getElementById('privateTitle').textContent.includes('LOCAL DEMO'));
 assert.equal(errors.length,0,errors.map(x=>x.message).join('\n'));
 assert.equal(d.querySelectorAll('script[src],iframe,link[href]').length,0,'Standalone file has no remote assets');
 dom.window.close();console.log('PASS UI: customer isolation, positions, closed queue, call/complete, QR preview, cancel, EN/FR and no external assets.');
}
uiTest().catch(e=>{console.error(e);process.exitCode=1});
