async (page) => {
  const mode = page.viewportSize().width === 360 ? 'touch' : 'mouse';
  const width = mode === 'touch' ? 360 : 720;
  const height = mode === 'touch' ? 800 : 1280;
  await page.setViewportSize({width, height});
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', msg => { if (msg.type() === 'error' || msg.type() === 'warning') errors.push(msg.text()); });
  await page.reload();
  await page.waitForFunction(() => window.windowHero?.ready && window.windowHero.state.phase === 'title');
  const scale = Math.min(width / 720, height / 1280);
  const offset = {x: (width - 720 * scale) / 2, y: (height - 1280 * scale) / 2};
  const point = (x,y) => ({x:offset.x+x*scale, y:offset.y+y*scale});
  const inputSession = await page.context().newCDPSession(page);
  await inputSession.send('Emulation.setTouchEmulationEnabled', {enabled:mode==='touch', maxTouchPoints:1});
  const cdp = mode === 'touch' ? inputSession : null;
  const touch = async (type,x,y) => cdp.send('Input.dispatchTouchEvent', {type, touchPoints:type==='touchEnd'?[]:[{...point(x,y),id:0,radiusX:6,radiusY:6,force:1}]});
  const click = async (x,y) => {
    if(cdp){await touch('touchStart',x,y);await touch('touchEnd');}
    else {const p=point(x,y); await page.mouse.click(p.x,p.y);}
  };
  const snapshot = () => page.evaluate(() => window.windowHero.state);
  const wait = async (key, value) => page.waitForFunction(({key,value}) => window.windowHero.state[key] === value, {key,value}, {timeout:12000});
  const move = async (x,y) => { if(cdp) await touch('touchMove',x,y); else {const p=point(x,y);await page.mouse.move(p.x,p.y);} };
  const rects = [[182,876],[412,876],[182,611],[412,611],[294,346]];
  const durations = [];
  const clean = async index => {
    const [x,y]=rects[index];
    await click(x+66,y+79);
    await page.waitForFunction(cx=>Math.abs(window.windowHero.state.hero[0]-cx)<185,x+66);
    const started=Date.now();
    let last={x:x+4,y:y+8};
    if(cdp) await touch('touchStart',last.x,last.y);
    else {const p=point(last.x,last.y);await page.mouse.move(p.x,p.y);await page.mouse.down();}
    for(let row=0;row<5;row++){
      const target={x:row%2===0?x+128:x+4,y:y+8+row*36};
      for(let step=1;step<=7;step++){
        await move(last.x+(target.x-last.x)*step/7,last.y+(target.y-last.y)*step/7);
        await page.waitForTimeout(35);
      }
      last=target;
    }
    if(cdp) await touch('touchEnd'); else await page.mouse.up();
    await page.waitForFunction(i=>window.windowHero.state.progress[i]===1,index,{timeout:4000});
    durations.push({window:index,seconds:(Date.now()-started)/1000});
  };
  await page.screenshot({path:`output/playwright/title-${mode}.png`});
  await click(360,1120);
  await wait('phase','playing');
  await clean(0);
  await page.screenshot({path:`output/playwright/first-reveal-${mode}.png`});
  await clean(1);
  await click(606,1054);
  await wait('ladder',1);
  await click(380,1210);
  await wait('floor',1);
  await click(615,1210);
  await wait('ladder',-1);
  await clean(3);
  await page.screenshot({path:`output/playwright/resident-${mode}.png`});
  await clean(2);
  await click(224,789);
  await wait('ladder',2);
  await click(380,1210);
  await wait('floor',2);
  await clean(4);
  await wait('phase','clear');
  await page.screenshot({path:`output/playwright/castle-clean-${mode}.png`});
  await page.waitForTimeout(1900);
  await page.screenshot({path:`output/playwright/clear-${mode}.png`});
  const state=await snapshot();
  if(errors.length) throw new Error(errors.join('\n'));
  if(state.moves!==2 || state.cleaned!==5 || state.elapsed>=180) throw new Error(JSON.stringify(state));
  return {mode,width,height,state,durations,errors};
}
