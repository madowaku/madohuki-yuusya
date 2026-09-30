async page => {
  // Playwright CLI run-code. Only pointer/keyboard input; telemetry is read-only.
  const {width,height}=page.viewportSize(), mode=width===360?'touch':'mouse';
  const errors=[], durations=[];
  const onError=e=>errors.push(e.message);
  const onConsole=m=>{if(['error','warning'].includes(m.type()))errors.push(m.text());};
  page.on('pageerror',onError);page.on('console',onConsole);
  const s=()=>page.evaluate(()=>window.windowHero.state);
  const wait=async(fn,arg)=>{
    try{await page.waitForFunction(fn,arg,{timeout:16000});}
    catch(e){throw new Error(e.message+'; state='+JSON.stringify(await s()));}
  };
  await wait(()=>window.windowHero?.state.buttons);
  const scale=Math.min(width/720,height/1280);
  const p=(x,y)=>({x:(width-720*scale)/2+x*scale,y:(height-1280*scale)/2+y*scale});
  const cdp=await page.context().newCDPSession(page);
  await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:mode==='touch',maxTouchPoints:1});
  const touch=(type,x,y)=>cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{...p(x,y),id:0,radiusX:6,radiusY:6,force:1}]});
  const click=async(x,y)=>{if(mode==='touch'){await touch('touchStart',x,y);await touch('touchEnd');}else{const v=p(x,y);await page.mouse.click(v.x,v.y);}};
  const move=async(x,y)=>{if(mode==='touch')await touch('touchMove',x,y);else{const v=p(x,y);await page.mouse.move(v.x,v.y);}};
  const button=async name=>{
    await wait(n=>!!window.windowHero.state.buttons[n],name);
    const r=(await s()).buttons[name];await click(r[0]+r[2]/2,r[1]+r[3]/2);
  };
  const shot=label=>page.screenshot({path:`output/playwright/visual-ux-${mode}-${label}.png`});
  const initial=await s();
  if(initial.phase!=='title')throw new Error('Start this verification at title');
  await shot('title');
  if(initial.language!==(mode==='touch'?'ja':'en'))await button('Language');
  await button('Start');await wait(()=>window.windowHero.state.phase==='playing');
  // Reading settings still pauses time; the board stays minimal.
  await button('Pause');await wait(()=>window.windowHero.state.paused);
  await shot('menu');const pausedTime=(await s()).elapsed;
  await page.waitForTimeout(350);
  if((await s()).elapsed!==pausedTime)throw new Error('Menu failed to freeze clock');
  await button('Resume');await wait(()=>!window.windowHero.state.paused);
  await shot('start');
  // Closed shutter responds visually without any explanatory panel.
  const rattleWindow=(await s()).windows[8];
  await click(rattleWindow[0]+rattleWindow[2]/2,rattleWindow[1]+rattleWindow[3]/2);
  if((await s()).shutter_open)throw new Error('Outside opened shutter');
  const clean=async i=>{
    let state=await s();const [x,y,w,h]=state.windows[i], cx=x+w/2;
    await click(cx,y+h/2);
    await wait(({i,cx})=>{const v=window.windowHero.state;return !v.busy&&!v.inside&&v.floor===v.window_floors[i]&&Math.abs(v.hero[0]-cx)<110;},{i,cx});
    const started=Date.now();let last={x:x+3,y:y+5};
    if(mode==='touch')await touch('touchStart',last.x,last.y);else{const v=p(last.x,last.y);await page.mouse.move(v.x,v.y);await page.mouse.down();}
    for(let row=0;row<4;row++){
      const target={x:row%2===0?x+w-3:x+3,y:y+5+row*(h-10)/3};
      for(let k=1;k<=3;k++){await move(last.x+(target.x-last.x)*k/3,last.y+(target.y-last.y)*k/3);await page.waitForTimeout(12);}
      last=target;
    }
    if(mode==='touch')await touch('touchEnd');else await page.mouse.up();
    await wait(i=>window.windowHero.state.progress[i]===1,i);
    durations.push({i,seconds:(Date.now()-started)/1000});
  };
  const place=async i=>{
    const before=await s();await click(before.hero[0],before.hero[1]+20);
    await wait(()=>window.windowHero.state.placement_mode);
    const candidate=await s();
    if(!candidate.candidates.includes(i))throw new Error('Expected legal destination '+i+': '+JSON.stringify(candidate));
    // Every visible hook has a disjoint 44px target, including incoming/outgoing hooks.
    const hits=[...candidate.window_hits,...candidate.candidates.map(a=>candidate.hook_hits[a])];
    const overlap=(a,b)=>a[0]<b[0]+b[2]&&b[0]<a[0]+a[2]&&a[1]<b[1]+b[3]&&b[1]<a[1]+a[3];
    for(let a=0;a<hits.length;a++)for(let b=a+1;b<hits.length;b++)if(overlap(hits[a],hits[b]))throw new Error('Overlap in active targets');
    await shot(`candidates-${i}`);
    await click(...candidate.anchor_points[i]);
    await wait(i=>{const v=window.windowHero.state;return v.ladder===i&&!v.busy;},i);
    if((await s()).moves!==before.moves+1)throw new Error('Smart move must count one placement');
  };
  const cross=async()=>{
    const before=await s();await click(...before.anchor_points[before.ladder]);
    await wait(b=>{const v=window.windowHero.state;return !v.busy&&v.region!==b.region;},before);
  };
  const windowTap=async i=>{const [x,y,w,h]=(await s()).windows[i];await click(x+w/2,y+h/2);};
  await clean(0);await clean(1);await clean(2);
  await place(0);
  // Real HUD Undo keeps polished glass, then the same destination can be tried again.
  await button('Undo');await wait(()=>window.windowHero.state.ladder===-1);
  if((await s()).progress.slice(0,3).some(v=>v!==1))throw new Error('Undo lost polishing');
  await place(0);await cross();await clean(3);await clean(4);
  await place(4);await shot('horizontal-bridge');await cross();await clean(5);
  await place(2);await cross();await clean(6);await clean(7);
  await windowTap(7);await wait(()=>window.windowHero.state.inside&&!window.windowHero.state.busy);
  if((await s()).ladder!==2)throw new Error('Entering removed ladder without asking');
  await shot('inside-latch');
  await windowTap(8);await wait(()=>window.windowHero.state.shutter_open&&!window.windowHero.state.busy);
  await shot('shutter-open');
  await button('Undo');await wait(()=>!window.windowHero.state.shutter_open);
  await windowTap(8);await wait(()=>window.windowHero.state.shutter_open&&!window.windowHero.state.busy);
  await windowTap(8);await wait(()=>window.windowHero.state.region===4&&!window.windowHero.state.busy);
  await clean(8);await wait(()=>window.windowHero.state.gallery_open);await shot('permanent-route');
  await place(7);await cross();await clean(9);await clean(10);await clean(11);
  await wait(()=>window.windowHero.state.phase==='clear');
  await shot('lit-tower');await page.waitForTimeout(1350);await shot('result');
  const final=await s();
  if(final.cleaned!==12||final.moves!==4||!final.shutter_open||!final.gallery_open)throw new Error('Incorrect finish '+JSON.stringify(final));
  if(await page.evaluate(()=>typeof window.windowHeroCommand)!=='undefined')throw new Error('Release exposes mutation debug hook');
  if(errors.length)throw new Error(errors.join('\n'));
  page.off('pageerror',onError);page.off('console',onConsole);await cdp.detach();
  return {mode,cleaned:final.cleaned,moves:final.moves,bridges:final.bridge_crossings,durations,errors};
}
