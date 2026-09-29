async (page) => {
  // Playwright CLI run-code: execute once per wall. Uses only real input + read-only telemetry.
  const {width, height}=page.viewportSize();
  const mode=width===360?'touch':'mouse';
  const errors=[];
  let step='initialize';
  const onError=e=>errors.push(e.message);
  const onConsole=m=>{if(['error','warning'].includes(m.type()))errors.push(m.text());};
  page.on('pageerror',onError);page.on('console',onConsole);
  await page.waitForFunction(()=>window.windowHero?.state.buttons);
  const scale=Math.min(width/720,height/1280);
  const p=(x,y)=>({x:(width-720*scale)/2+x*scale,y:(height-1280*scale)/2+y*scale});
  const cdp=await page.context().newCDPSession(page);
  await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:mode==='touch',maxTouchPoints:1});
  const touch=(type,x,y)=>cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{...p(x,y),id:0,radiusX:6,radiusY:6,force:1}]});
  const click=async(x,y)=>{if(mode==='touch'){await touch('touchStart',x,y);await touch('touchEnd');}else{const v=p(x,y);await page.mouse.click(v.x,v.y);}};
  const snapshot=()=>page.evaluate(()=>window.windowHero.state);
  const wait=async(fn,arg)=>{
    try{return await page.waitForFunction(fn,arg,{timeout:15000});}
    catch(error){throw new Error(`${step}: ${error.message}; state=${JSON.stringify(await snapshot())}`);}
  };
  const button=async name=>{
    step=`button ${name}`;
    await wait(n=>!!window.windowHero.state.buttons[n],name);
    const r=(await snapshot()).buttons[name];await click(r[0]+r[2]/2,r[1]+r[3]/2);
  };
  const shot=label=>page.screenshot({path:`output/playwright/run-${mode}-${label}.png`});
  let initial=await snapshot();
  if(initial.phase==='title'){
    await shot('title');
    if(initial.language!==(mode==='mouse'?'en':'ja'))await button('Language');
    await button('Start');await wait(()=>window.windowHero.state.phase==='playing');
  }else if(initial.phase==='clear'&&!initial.journey.complete){
    const gift=initial.journey.wall===1?(mode==='touch'?'Reach':'Recall'):'Soap';
    await button('Gift'+gift);
    await wait(w=>window.windowHero.state.journey.wall===w+1,initial.journey.wall);
  }else throw new Error('Expected title or gift screen: '+JSON.stringify(initial));
  const start=await snapshot(), wall=start.journey.wall;
  await button('Plan');await wait(()=>window.windowHero.state.paused);
  await shot(`wall-${wall}-rules`);
  const pausedTime=(await snapshot()).elapsed;
  await page.waitForTimeout(300);
  if((await snapshot()).elapsed!==pausedTime)throw new Error('Rule map did not pause');
  await button('Resume');await wait(()=>!window.windowHero.state.paused);
  const move=async(x,y)=>{if(mode==='touch')await touch('touchMove',x,y);else{const v=p(x,y);await page.mouse.move(v.x,v.y);}};
  const durations=[];
  const clean=async i=>{
    step=`approach window ${i}`;
    let s=await snapshot();if(s.progress[i]===1)return;
    const [x,y,w,h]=s.windows[i], cx=x+w/2;
    await click(cx,y+h/2);
    await wait(({i,cx})=>{const s=window.windowHero.state;const f=s.window_floors[i];const sameSide=(s.hero[0]<=320&&cx<=320)||(s.hero[0]>=400&&cx>=400);const floorHasGap=s.has_gap&&s.floor===1&&!s.gallery_open;const connected=f!==s.floor||!floorHasGap||sameSide;const reach=f===s.floor||(s.gifts.includes('reach')&&!s.reach_spent&&f===s.floor+1);return connected&&reach&&Math.abs(s.hero[0]-cx)<(f>s.floor?96:185);},{i,cx});
    step=`wipe window ${i}`;const started=Date.now();let last={x:x+4,y:y+8};
    if(mode==='touch')await touch('touchStart',last.x,last.y);else{const v=p(last.x,last.y);await page.mouse.move(v.x,v.y);await page.mouse.down();}
    for(let row=0;row<5;row++){
      const target={x:row%2===0?x+w-4:x+4,y:y+8+row*36};
      for(let k=1;k<=6;k++){await move(last.x+(target.x-last.x)*k/6,last.y+(target.y-last.y)*k/6);await page.waitForTimeout(30);}
      last=target;
    }
    if(mode==='touch')await touch('touchEnd');else await page.mouse.up();
    step=`finish window ${i}`;await wait(i=>window.windowHero.state.progress[i]===1,i);
    durations.push({i,seconds:(Date.now()-started)/1000});
  };
  const retrieve=async()=>{if((await snapshot()).ladder>=0){await button('Retrieve');await wait(()=>window.windowHero.state.ladder===-1);}};
  const place=async anchor=>{
    step=`retrieve before placing anchor ${anchor}`;
    await retrieve();const s=await snapshot();await click(...s.anchor_points[anchor]);
    step=`confirm placement at anchor ${anchor}`;
    await wait(a=>window.windowHero.state.ladder===a,anchor);
    if(s.horizontal_anchors[anchor])await shot(`wall-${wall}-bridge-${anchor}`);
  };
  const cross=async()=>{
    const before=await snapshot();step=`cross from floor ${before.floor} using anchor ${before.ladder}`;await button('Action');
    await wait(b=>{const s=window.windowHero.state;return !s.climbing&&(b.horizontal_anchors[b.ladder]?(s.hero[0]<360)!==(b.hero[0]<360):s.floor!==b.floor);},before);
  };
  await shot(`wall-${wall}-start`);
  await clean(0);
  if(wall===1){
    await clean(1);await place(1);await cross();await clean(3);await clean(2);await place(2);await cross();await clean(4);
  }else if(wall===3){
    await place(0);await cross();await clean(2);
    const reach=start.gifts.includes('reach');
    if(reach){
      await place(4);await cross();await clean(4);
      await retrieve();await clean(3);
      await place(1);await cross();await clean(1);await cross();await retrieve();
      await place(3);await cross();await place(7);await cross();await clean(5);
    }else{
      await place(2);await cross();await place(5);await cross();await clean(4);
      await cross();await place(2);await cross();await clean(3);
      await place(1);await cross();await clean(1);await cross();await retrieve();
      await place(3);await cross();await place(7);await cross();await clean(5);
    }
  }else{
    await place(0);await cross();await clean(2);
    const reach=start.gifts.includes('reach');
    if(reach){
      await clean(4);await cross();await clean(1);await cross();await place(4);await cross();await clean(3);
    }else{
      await place(4);await cross();await clean(3);await place(3);await cross();await clean(4);await cross();
      await place(1);await cross();await clean(1);
    }
  }
  await wait(()=>window.windowHero.state.phase==='clear');
  await page.waitForTimeout(1900);await shot(`wall-${wall}-result`);
  const result=await snapshot();
  if(result.cleaned!==result.window_count||result.moves!==result.placement_goal)throw new Error('Route missed target: '+JSON.stringify(result));
  if(errors.length)throw new Error(errors.join('\n'));
  page.off('pageerror',onError);page.off('console',onConsole);await cdp.detach();
  return {mode,wall,seed:result.journey.seed,moves:result.moves,bridges:result.bridge_moves,complete:result.journey.complete,gifts:result.gifts,durations,errors};
}
