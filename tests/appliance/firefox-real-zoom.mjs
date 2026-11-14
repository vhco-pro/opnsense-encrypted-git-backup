import { firefox } from '@playwright/test';
import assert from 'node:assert/strict';
import net from 'node:net';
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

const root = process.argv[2];
const url = new URL(process.env.FIXTURE_APPLIANCE_URL);
assert.equal(url.hostname, '127.0.0.1');
const port = 29345;
const profile = await fs.mkdtemp(path.join(os.tmpdir(), 'encryptedgit-firefox-'));
const prefs = { 'marionette.port':port, 'network.captive-portal-service.enabled':false, 'network.connectivity-service.enabled':false };
await fs.writeFile(path.join(profile,'user.js'), Object.entries(prefs).map(([k,v])=>`user_pref(${JSON.stringify(k)}, ${JSON.stringify(v)});`).join('\n'));
execFileSync('certutil',['-N','--empty-password','-d','sql:'+profile]);
execFileSync('certutil',['-A','-d','sql:'+profile,'-n','Disposable loopback appliance','-t','P,,','-i',root+'/r45-fixture-cert.pem']);
const browser = spawn(firefox.executablePath(),['--headless','--no-remote','--profile',profile,'--marionette','--remote-allow-system-access'], {stdio:'ignore',env:{...process.env,MOZ_REMOTE_ALLOW_SYSTEM_ACCESS:'1',MOZ_HEADLESS_WIDTH:'800',MOZ_HEADLESS_HEIGHT:'900'}});
let socket;
try {
 for (let n=0;n<80;n++) {
  try {
   socket = await new Promise((resolve,reject)=>net.createConnection(port,'127.0.0.1').once('connect',function(){resolve(this)}).once('error',reject));
   break;
  } catch { await new Promise(resolve=>setTimeout(resolve,250)); }
 }
 assert.ok(socket,'Firefox Marionette listener');
 let buffer=Buffer.alloc(0), id=0;
 const pending=new Map();
 socket.on('data',chunk=>{
  buffer=Buffer.concat([buffer,chunk]);
  while (true) {
   const colon=buffer.indexOf(58);
   if (colon<0) break;
   const len=Number(buffer.subarray(0,colon));
   if (buffer.length<colon+1+len) break;
   const reply=JSON.parse(buffer.subarray(colon+1,colon+1+len));
   buffer=buffer.subarray(colon+1+len);
   if (!Array.isArray(reply)) continue;
   const callback=pending.get(reply[1]);
   pending.delete(reply[1]);
   callback(reply[2],reply[3]);
  }
 });
 const call=(name,params={})=>new Promise((resolve,reject)=>{
  const seq=++id;
  const request=JSON.stringify([0,seq,name,params]);
  pending.set(seq,(error,result)=>error?reject(new Error(JSON.stringify(error))):resolve(result));
  socket.write(Buffer.byteLength(request)+':'+request);
 });
 const script=async (source,args=[]) => (await call('WebDriver:ExecuteScript',{script:source,args})).value;
 await call('WebDriver:NewSession',{capabilities:{alwaysMatch:{acceptInsecureCerts:true}},acceptInsecureCerts:true});
 await call('WebDriver:Navigate',{url:url.href});
 await script(`document.querySelector('[name=usernamefld]').value='fixture-reader';
 document.querySelector('[name=passwordfld]').value=arguments[0];
 document.querySelector('button[type=submit],input[type=submit]').click();`,[process.env.FIXTURE_READER_PASSWORD]);
 await new Promise(resolve=>setTimeout(resolve,2000));
 await call('WebDriver:Navigate',{url:new URL('/ui/encrypted_git_backup',url).href});
 const measure=()=>script(`return {width:innerWidth,dpr:devicePixelRatio,scroll:document.documentElement.scrollWidth,commit:document.querySelector('#backup-commit')?.getBoundingClientRect().right,text:document.querySelector('#backup-commit')?.textContent};`);
 let before;
 for (let n=0;n<40;n++){
  before=await measure();
  if (/^[a-f0-9]{40}$/.test(before.text)) break;
  await new Promise(resolve=>setTimeout(resolve,250));
 }
 assert.match(before.text,/^[a-f0-9]{40}$/);
 await call('Marionette:SetContext',{value:'chrome'});
 const zoom=await script('window.ZoomManager.zoom = 2; return window.ZoomManager.zoom;');
 await call('Marionette:SetContext',{value:'content'});
 const after=await measure();
 delete before.text;
 delete after.text;
 console.log(JSON.stringify({zoom,before,after}));
 assert.equal(zoom,2);
 assert.equal(after.dpr/before.dpr,2);
 assert.ok(Math.abs(after.width*2-before.width)<=2);
 assert.ok(after.scroll<=after.width && after.commit<=after.width);
 const shot=await call('WebDriver:TakeScreenshot',{full:false});
 await fs.writeFile(root+'/firefox-real-zoom.png',Buffer.from(shot.value,'base64'));
 await call('WebDriver:DeleteSession');
} finally {
 socket?.destroy();
 browser.kill();
 if(browser.exitCode===null && browser.signalCode===null) await new Promise(resolve=>browser.once('exit',resolve));
 await fs.rm(profile,{recursive:true,force:true});
}
