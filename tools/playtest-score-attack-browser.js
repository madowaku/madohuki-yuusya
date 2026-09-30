async page => {
  const mode = page.viewportSize()?.width <= 400 ? 'touch' : 'mouse';
  const width = mode === 'touch' ? 360 : 720;
  const height = mode === 'touch' ? 800 : 1280;
  await page.setViewportSize({width,height});
  const scale = Math.min(width / 720,height / 1280);
  const errors = [];
  const onError = e => errors.push(e.message);
  const onConsole = m => { if (['error','warning'].includes(m.type())) errors.push(m.text()); };
  page.on('pageerror',onError); page.on('console',onConsole);
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:mode === 'touch',maxTouchPoints:1});
  const screen = (x,y) => ({x:(width-720*scale)/2+x*scale,y:(height-1280*scale)/2+y*scale});
  const touch = (type,x,y) => cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{...screen(x,y),id:0,radiusX:5,radiusY:5,force:1}]});
  const snapshot = () => page.evaluate(() => window.windowHero.state);
  const wait = async (predicate,arg,label) => {
    try { await page.waitForFunction(predicate,arg,{timeout:20000}); }
    catch(e) {throw new Error(`${label}: ${e.message}; state=${JSON.stringify(await snapshot())}`);}
  };
  const click = async (x,y) => {
    if(mode==='touch'){await touch('touchStart',x,y);await touch('touchEnd');}
    else {const p=screen(x,y);await page.mouse.click(p.x,p.y);}
  };
  const button = async name => {
    await wait(name=>!!window.windowHero.state.buttons?.[name],name,name);
    const r=(await snapshot()).buttons[name];await click(r[0]+r[2]/2,r[1]+r[3]/2);
  };
  const drag = async (points,delay=16) => {
    const first=points[0];
    if(mode==='touch') await touch('touchStart',...first);
    else {const p=screen(...first);await page.mouse.move(p.x,p.y);await page.mouse.down();}
    for(const p of points.slice(1)){
      if(mode==='touch') await touch('touchMove',...p);else{const q=screen(...p);await page.mouse.move(q.x,q.y);}
      await page.waitForTimeout(delay);
    }
    if(mode==='touch') await touch('touchEnd'); else await page.mouse.up();
  };
  const shot = name => page.screenshot({path:`output/playwright/score-attack-${mode}-${name}.png`});
  const settle = async () => {
    await wait(()=>{const s=window.windowHero.state;return !s.busy&&!s.climbing},undefined,'settle movement');
    await page.waitForTimeout(260);
  };
  const flick = async (direction,targetRegion) => {
    const s=await snapshot();
    const y=s.hero[1]-s.camera_y-25;
    const dx=direction==='right'?210:direction==='left'?-210:0;
    const dy=direction==='up'?-145:direction==='down'?145:0;
    await drag([[355,y],[355+dx*.35,y+dy*.35],[355+dx*.7,y+dy*.7],[355+dx,y+dy]],20);
    if(targetRegion!==undefined) await wait(region=>{const s=window.windowHero.state;return s.region===region&&!s.busy},targetRegion,`flick ${direction} to ${targetRegion}`);
    await settle();
  };
  const polish = async index => {
    let s=await snapshot();
    const r=s.windows[index];const cy=r[1]+r[3]/2-s.camera_y;
    await click(r[0]+r[2]/2,cy);await settle();s=await snapshot();
    const camera=s.camera_y;let last=[r[0]+3,r[1]+5-camera];
    const points=[last];const rows=Math.max(4,Math.ceil(r[3]/40));
    for(let row=0;row<rows;row++){
      const end=[row%2===0?r[0]+r[2]-3:r[0]+3,r[1]+5+row*(r[3]-10)/(rows-1)-camera];
      for(let part=1;part<=4;part++)points.push([last[0]+(end[0]-last[0])*part/4,last[1]+(end[1]-last[1])*part/4]);
      last=end;
    }
    await drag(points,12);
    await wait(index=>window.windowHero.state.progress[index]===1,index,`polish ${index}`);
    await wait(()=>window.windowHero.state.cleaning_remaining===0,undefined,'finish risky cleaning pause');
  };
  const run = async detours => {
    await button('Start');
    await wait(()=>window.windowHero.state.score_attack&&window.windowHero.state.phase==='playing',undefined,'fixed ladder start');
    let s=await snapshot();
    if(s.fixed_ladders.length!==18 || s.moves!==0 || s.placement_mode || s.buttons.Undo || s.buttons.Help)throw new Error('Unexpected ladder setup controls');
    if(s.window_hits.some(r=>r[2]*scale<44||r[3]*scale<44))throw new Error('Small window touch target');
    await shot(detours?'detour-start':'rush-start');
    if(detours)await polish(0);
    // Horizontal following, climb, descent and climb again are all physical gestures.
    const initialX=(await snapshot()).hero[0];await flick('left');
    if((await snapshot()).hero[0]>=initialX-20)throw new Error('Horizontal flick did not move hero');
    await flick('up',1);await flick('down',0);await flick('up',1);
    if(detours)await polish(1);
    await flick('up',3);if(detours)await polish(3);
    await flick('right',4);if(detours)await polish(4);
    await flick('up',6);if(detours)await polish(6);
    await flick('up',8);if(detours)await polish(8);
    await button('Pause');await wait(()=>window.windowHero.state.paused,undefined,'pause');
    const seconds=(await snapshot()).seconds;await page.waitForTimeout(350);
    if((await snapshot()).seconds!==seconds)throw new Error('Paused time changed');
    await button('Resume');
    await flick('left',7);if(detours)await polish(7);
    await flick('up',9);if(detours){await polish(9);await flick('right',10);await polish(10);await flick('left',9);}
    await flick('up',11);if(detours){await polish(11);await flick('up',13);await polish(13);await flick('down',11);}
    await flick('right',12);if(detours)await polish(12);
    await flick('up',14);if(detours)await polish(14);
    await flick('up',15);await shot(detours?'detour-summit':'rush-summit');
    if((await snapshot()).window_points!==0&&!detours)throw new Error('Climbing awarded window points');
    if(detours)await polish(15);
    await flick('up');
    await wait(()=>window.windowHero.state.ending&&window.windowHero.state.final_ready,undefined,'legendary ending');
    await page.waitForTimeout(700);
    const stats=(await snapshot()).ending_stats;
    if(!stats.won || stats.cleaned!==(detours?14:0))throw new Error(`Wrong result ${JSON.stringify(stats)}`);
    if(Math.abs(stats.score-Math.max(0,Math.round(10000+stats.window_points+stats.all_clean_bonus-stats.seconds*50-stats.damage*150)))>1)throw new Error('Score formula mismatch');
    await shot(detours?'detour-ending':'rush-ending');
    return stats;
  };
  await wait(()=>window.windowHero?.state?.phase==='title',undefined,'title');
  const language=mode==='mouse'?'en':'ja';if((await snapshot()).language!==language)await button('Language');
  await shot('title');
  await button('Instructions');await shot('instructions');await button('Back');
  await button('Records');await shot('best');await button('Back');
  await button('Credits');await button('Back');
  const rush=await run(false);
  await button('Credits');await wait(()=>window.windowHero.state.credits_open,undefined,'credits');await button('Back');
  await button('Replay');await wait(()=>window.windowHero.state.score_attack&&window.windowHero.state.phase==='playing'&&window.windowHero.state.cleaned===0,undefined,'immediate retry');
  await button('Pause');
  await button('Title');
  const detour=await run(true);
  if(detour.score<=rush.score)throw new Error('Meaningful detours lost to a boss-only rush');
  if(await page.evaluate(()=>typeof window.windowHeroCommand)!=='undefined')throw new Error('Release mutation hook exposed');
  await button('Title');
  if(errors.length)throw new Error(errors.join('\n'));
  page.off('pageerror',onError);page.off('console',onConsole);await cdp.detach();
  return {mode,rush,detour,gestures:['left','right','up','down'],errors};
}
