// Publish only runtime assets; do not expose SQL migrations, tests, or development files.
const fs=require('node:fs'),path=require('node:path');
const destination=path.join(__dirname,'dist');
fs.rmSync(destination,{recursive:true,force:true});fs.mkdirSync(destination,{recursive:true});
for(const file of ['index.html','online.html','reports.html','shared-queues.js','test-guide.js','manifest.webmanifest','icon-192.png','icon-512.png','qrcode.js','demo.html']){
 const target=path.join(destination,file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(__dirname,file),target);
}
console.log('WaitLess public assets prepared in dist/');
