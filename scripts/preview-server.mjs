// 에셋 미리보기 서버 (의존성 없음): 저장소 폴더를 웹으로 보여 주고, 파일이 바뀌면 열린 페이지를 자동 새로고침
// 실행: node scripts/preview-server.mjs [port=3208]
// 외부 공개: dev-proxy-3108 컨테이너가 http://home.ribs.kr:3108 → host:3208 중계 (scripts/preview-proxy.sh)
// - .glb/.gltf → 3D 뷰어(model-viewer), .png + 같은 이름 .json(Aseprite) → 애니메이션 재생, 이미지 → 픽셀 그대로 확대, .md/.txt/.json/.py → 원문
import { createServer } from 'node:http';
import { readdir, readFile, stat } from 'node:fs/promises';
import { watch } from 'node:fs';
import { extname, join, normalize, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const PORT = Number(process.argv[2] || process.env.PORT || 3208);
const DIRS = [ 'scratch', 'blender', 'aseprite', 'export', 'research' ]; // scratch = 커밋 안 하는 임시 미리보기
const SKIP = /(^|[\\/])(\.git|node_modules|tmp)([\\/]|$)|\.blend\d$|~$/;
const MIME = {
  '.html': 'text/html; charset=utf-8', '.json': 'application/json; charset=utf-8', '.md': 'text/plain; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8', '.py': 'text/plain; charset=utf-8', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp', '.svg': 'image/svg+xml',
  '.glb': 'model/gltf-binary', '.gltf': 'model/gltf+json', '.bin': 'application/octet-stream', '.mp4': 'video/mp4', '.webm': 'video/webm',
};

async function walk(dir) {
  const out = [];
  let ents = [];
  try { ents = await readdir(join(ROOT, dir), { withFileTypes: true }); } catch { return out; }
  for (const e of ents) {
    const rel = `${dir}/${e.name}`;
    if (SKIP.test(rel) || e.name.startsWith('.')) continue;
    if (e.isDirectory()) out.push(...await walk(rel));
    else {
      const s = await stat(join(ROOT, rel));
      out.push({ path: rel, size: s.size, mtime: s.mtimeMs });
    }
  }
  return out;
}

// 실시간 새로고침 (Server-Sent Events)
const clients = new Set();
let timer;
watch(ROOT, { recursive: true }, (_, f) => {
  if (!f || SKIP.test(f) || !DIRS.some(d => f.startsWith(d + sep) || f.startsWith(d + '/'))) return;
  clearTimeout(timer);
  timer = setTimeout(() => { for (const c of clients) c.write(`data: ${f.replaceAll('\\', '/')}\n\n`); }, 300);
});

createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x');
  const p = decodeURIComponent(url.pathname);
  if (p === '/events') {
    res.writeHead(200, { 'content-type': 'text/event-stream', 'cache-control': 'no-store', connection: 'keep-alive' });
    res.write(': hi\n\n');
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }
  if (p === '/api/files') {
    const files = (await Promise.all(DIRS.map(walk))).flat();
    res.writeHead(200, { 'content-type': MIME['.json'], 'cache-control': 'no-store' });
    return res.end(JSON.stringify(files));
  }
  if (p === '/') {
    res.writeHead(200, { 'content-type': MIME['.html'], 'cache-control': 'no-store' });
    return res.end(PAGE);
  }
  // 정적 파일: 허용 폴더 안만
  const file = normalize(join(ROOT, p));
  const rel = relative(ROOT, file).replaceAll('\\', '/');
  if (rel.startsWith('..') || SKIP.test(rel) || !DIRS.some(d => rel.startsWith(d + '/'))) {
    res.writeHead(404); return res.end('not found');
  }
  try {
    const buf = await readFile(file);
    res.writeHead(200, { 'content-type': MIME[extname(file).toLowerCase()] || 'application/octet-stream', 'cache-control': 'no-store' });
    res.end(buf);
  } catch { res.writeHead(404); res.end('not found'); }
}).listen(PORT, '127.0.0.1', () => console.log(`preview http://127.0.0.1:${PORT}  (external http://home.ribs.kr:3108)`));

const PAGE = `<!doctype html><html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ribs-assets 미리보기</title>
<script type="module" src="https://cdn.jsdelivr.net/npm/@google/model-viewer@3.4.0/dist/model-viewer.min.js"></script>
<style>
:root{--bg:#16181d;--card:#20232b;--fg:#e6e6e6;--mut:#8a8f9c;--acc:#6cb6ff;color-scheme:dark}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:14px/1.5 system-ui,sans-serif}
header{position:sticky;top:0;z-index:2;background:var(--bg);padding:10px 16px;border-bottom:1px solid #2c303a;display:flex;gap:8px;align-items:center;flex-wrap:wrap}
header b{margin-right:auto}select,input,button{background:var(--card);color:var(--fg);border:1px solid #3a3f4b;border-radius:6px;padding:5px 8px;font:inherit}
main{padding:16px;display:grid;gap:16px;grid-template-columns:repeat(auto-fill,minmax(min(100%,340px),1fr))}
.card{background:var(--card);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}
.card.new{outline:2px solid var(--acc)}
.view{height:300px;display:flex;align-items:center;justify-content:center;background:repeating-conic-gradient(#2a2d35 0 25%,#23262d 0 50%) 0 0/16px 16px}
.view img,.view canvas{max-width:100%;max-height:100%;image-rendering:pixelated}
model-viewer{width:100%;height:100%;background:#2a2d35}
pre{margin:0;padding:10px;height:300px;overflow:auto;white-space:pre-wrap;font-size:12px;background:#1b1d23}
.meta{padding:8px 10px;display:flex;gap:6px;align-items:center;flex-wrap:wrap;font-size:12px;color:var(--mut)}
.meta a{color:var(--fg);text-decoration:none;font-weight:600;word-break:break-all;margin-right:auto}
.empty{color:var(--mut);padding:40px 16px}
</style></head><body>
<header><b>ribs-assets</b>
<select id="dir"><option value="">전체</option><option>scratch</option><option>blender</option><option>aseprite</option><option>export</option><option>research</option></select>
<input id="q" placeholder="검색" size="10"><label><input type="checkbox" id="big"> 크게</label><span id="st" style="color:var(--mut)">●</span></header>
<main id="m"></main>
<script>
const $=s=>document.querySelector(s), m=$('#m');
const kb=n=>n>1e6?(n/1e6).toFixed(1)+'MB':(n/1e3).toFixed(0)+'KB';
const ext=p=>p.slice(p.lastIndexOf('.')+1).toLowerCase();
const SHOW=['html','glb','gltf','png','jpg','jpeg','gif','webp','svg','md','txt','py','mp4','webm'];
let files=[], changed='';
// 작은 도트 이미지는 정수배로 키워 카드에 맞춤 (픽셀 그대로)
window.fit=img=>{const b=img.parentElement,w=img.naturalWidth,h=img.naturalHeight;const s=Math.floor(Math.min((b.clientWidth-8)/w,(b.clientHeight-8)/h));if(s>1)img.style.width=w*s+'px'};
const players=[];
function anim(cv,src,meta,sel,scale){
  const img=new Image();img.src=src;const fr=meta.frames,tags=meta.meta.frameTags||[];
  for(const t of tags)sel.add(new Option(t.name+' ('+(t.to-t.from+1)+')',t.from+'-'+t.to));
  if(!tags.length)sel.hidden=true;
  const ctx=cv.getContext('2d');let i=0,acc=0,last=0;
  const W=fr[0].sourceSize.w,H=fr[0].sourceSize.h;
  const p={run(t){if(!img.complete)return;const [a,b]=sel.value?sel.value.split('-').map(Number):[0,fr.length-1];
    if(i<a||i>b)i=a;acc+=t-last;last=t;if(acc>=(fr[i].duration||100)){acc=0;i=i>=b?a:i+1}
    const s=scale();cv.width=W*s;cv.height=H*s;ctx.imageSmoothingEnabled=false;const f=fr[i];
    ctx.drawImage(img,f.frame.x,f.frame.y,f.frame.w,f.frame.h,f.spriteSourceSize.x*s,f.spriteSourceSize.y*s,f.frame.w*s,f.frame.h*s)}};
  players.push(p);
}
(function loop(t){for(const p of players)p.run(t);requestAnimationFrame(loop)})(0);
async function render(){
  files=await (await fetch('/api/files')).json();
  const d=$('#dir').value,q=$('#q').value.toLowerCase(),paths=new Set(files.map(f=>f.path));
  const list=files.filter(f=>SHOW.includes(ext(f.path))&&(!d||f.path.startsWith(d+'/'))&&f.path.toLowerCase().includes(q))
    .filter(f=>!(ext(f.path)==='json'))
    .sort((a,b)=>b.mtime-a.mtime);
  players.length=0;m.innerHTML=list.length?'':'<div class="empty">아직 에셋이 없습니다. scratch/ 나 blender/·aseprite/ 에 파일을 넣으면 바로 나타납니다.</div>';
  const big=$('#big').checked;
  for(const f of list){
    const e=ext(f.path),url='/'+f.path.split('/').map(encodeURIComponent).join('/')+'?t='+f.mtime;
    const c=document.createElement('div');c.className='card'+(f.path===changed?' new':'');
    let v;
    if(e==='glb'||e==='gltf'){v=document.createElement('div');v.className='view';v.innerHTML='<model-viewer src="'+url+'" camera-controls auto-rotate shadow-intensity="1" exposure="1"></model-viewer>'}
    else if(e==='html'){v=document.createElement('div');v.className='view';v.innerHTML='<iframe src="'+url+'" style="width:100%;height:100%;border:0;background:#16181d"></iframe>'}
    else if(['md','txt','py'].includes(e)){v=document.createElement('pre');fetch(url).then(r=>r.text()).then(t=>v.textContent=t)}
    else if(e==='mp4'||e==='webm'){v=document.createElement('div');v.className='view';v.innerHTML='<video src="'+url+'" controls loop muted autoplay style="max-width:100%;max-height:100%"></video>'}
    else{v=document.createElement('div');v.className='view';
      const js=f.path.replace(/\\.[^.]+$/,'.json'),aj=f.path.replace(/\\.[^.]+$/,'.anim.json');
      if(e==='png'&&paths.has(aj)){const cv=document.createElement('canvas'),sel=document.createElement('select');v.append(cv);
        // 계약 형식(.anim.json): clip마다 프레임을 Aseprite 형식으로 바꿔 같은 재생기로
        fetch('/'+aj+'?t='+Date.now()).then(r=>r.json()).then(a=>{const frames=[],tags=[];const [W,H]=a.frameSize;
          for(const [name,clip] of Object.entries(a.clips)){const from=frames.length;
            for(const fr of clip.frames)frames.push({frame:{x:fr.sx,y:fr.sy,w:fr.sWidth,h:fr.sHeight},spriteSourceSize:{x:0,y:0},sourceSize:{w:W,h:H},duration:fr.durationMs});
            tags.push({name:name+(clip.loop?'':' ·1회'),from,to:frames.length-1})}
          const box=v;anim(cv,url,{frames,meta:{frameTags:tags}},sel,()=>Math.max(1,Math.floor(Math.min((box.clientWidth-8)/W,(box.clientHeight-8)/H))))}).catch(()=>{});
        c._sel=sel}
      else if(e==='png'&&paths.has(js)){const cv=document.createElement('canvas'),sel=document.createElement('select');v.append(cv);
        fetch('/'+js+'?t='+Date.now()).then(r=>r.json()).then(meta=>{if(!meta.frames||!Array.isArray(meta.frames)){v.innerHTML='<img src="'+url+'" onload="fit(this)">';return}
          const box=v;anim(cv,url,meta,sel,()=>{const W=meta.frames[0].sourceSize.w,H=meta.frames[0].sourceSize.h;return Math.max(1,Math.floor(Math.min((box.clientWidth-8)/W,(box.clientHeight-8)/H)))})}).catch(()=>{});
        c._sel=sel}
      else v.innerHTML='<img src="'+url+'" onload="fit(this)">'}
    if(big)v.style.height='70vh';
    c.append(v);const mt=document.createElement('div');mt.className='meta';
    mt.innerHTML='<a href="'+url+'" target="_blank"></a><span>'+kb(f.size)+' · '+new Date(f.mtime).toLocaleString('ko-KR',{month:'numeric',day:'numeric',hour:'2-digit',minute:'2-digit'})+'</span>';
    mt.querySelector('a').textContent=f.path;if(c._sel)mt.prepend(c._sel);c.append(mt);m.append(c);
  }
  if(big)m.style.gridTemplateColumns='1fr';else m.style.gridTemplateColumns='';
}
for(const id of ['dir','q','big'])$('#'+id).addEventListener('input',render);
const es=new EventSource('/events');es.onopen=()=>$('#st').style.color='#5fd35f';es.onerror=()=>$('#st').style.color='#e05555';
es.onmessage=e=>{changed=e.data;render()};
render();
</script></body></html>`;
