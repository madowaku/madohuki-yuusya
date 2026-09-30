async page => {
  // Actions are real pointer input. The game exposes only read-only release telemetry.
  const mode = page.viewportSize()?.width <= 400 ? 'touch' : 'mouse';
  const width = mode === 'touch' ? 360 : 720;
  const height = mode === 'touch' ? 800 : 1280;
  await page.setViewportSize({width,height});
  const errors = [];
  const onError = error => errors.push(error.message);
  const onConsole = message => {
    if (['error','warning'].includes(message.type())) errors.push(message.text());
  };
  page.on('pageerror',onError);
  page.on('console',onConsole);
  let step = 'title';
  const scale = Math.min(width / 720,height / 1280);
  const point = (x,y) => ({x:(width - 720 * scale) / 2 + x * scale,y:(height - 1280 * scale) / 2 + y * scale});
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:mode === 'touch',maxTouchPoints:1});
  const touch = (type,x,y) => cdp.send('Input.dispatchTouchEvent',{
    type,touchPoints:type === 'touchEnd' ? [] : [{...point(x,y),id:0,radiusX:6,radiusY:6,force:1}],
  });
  const click = async (x,y) => {
    if (mode === 'touch') { await touch('touchStart',x,y); await touch('touchEnd'); }
    else { const p = point(x,y); await page.mouse.click(p.x,p.y); }
  };
  const move = async (x,y) => {
    if (mode === 'touch') await touch('touchMove',x,y);
    else { const p = point(x,y); await page.mouse.move(p.x,p.y); }
  };
  const snapshot = () => page.evaluate(() => window.windowHero.state);
  const wait = async (predicate,arg,label = step) => {
    try { await page.waitForFunction(predicate,arg,{timeout:30000}); }
    catch (error) { throw new Error(`${label}: ${error.message}; state=${JSON.stringify(await snapshot())}`); }
  };
  const center = rect => [rect[0] + rect[2] / 2,rect[1] + rect[3] / 2];
  const clickButton = async name => {
    step = `button ${name}`;
    await wait(name => !!window.windowHero.state.buttons?.[name],name);
    await click(...center((await snapshot()).buttons[name]));
  };
  const shot = name => page.screenshot({path:`output/playwright/final-v1-${mode}-${name}.png`});
  const tapWindow = async index => {
    step = `tap window ${index}`;
    await click(...center((await snapshot()).window_hits[index]));
  };
  const polish = async index => {
    const before = await snapshot();
    if (before.progress[index] === 1) return;
    await tapWindow(index);
    const [cx] = center(before.window_hits[index]);
    await wait(({index,cx}) => {
      const s = window.windowHero.state;
      return !s.busy && !s.climbing && s.floor === s.window_floors[index] && Math.abs(s.hero[0] - cx) < 108;
    },{index,cx},`approach window ${index}`);
    step = `polish ${index}`;
    const [x,y,w,h] = (await snapshot()).windows[index];
    let last = {x:x + 3,y:y + 5};
    if (mode === 'touch') await touch('touchStart',last.x,last.y);
    else { const p = point(last.x,last.y); await page.mouse.move(p.x,p.y); await page.mouse.down(); }
    const rows = Math.max(4,Math.ceil(h / 40));
    for (let row = 0; row < rows; row++) {
      const target = {x:row % 2 === 0 ? x + w - 3 : x + 3,y:y + 5 + row * (h - 10) / (rows - 1)};
      for (let part = 1; part <= 4; part++) {
        await move(last.x + (target.x - last.x) * part / 4,last.y + (target.y - last.y) * part / 4);
        await page.waitForTimeout(12);
      }
      last = target;
    }
    if (mode === 'touch') await touch('touchEnd'); else await page.mouse.up();
    await wait(index => window.windowHero.state.progress[index] === 1,index,`clean window ${index}`);
  };
  const place = async (index,horizontal = false,label = '') => {
    step = `place ladder ${index}`;
    let s = await snapshot();
    if (!s.placement_mode) {
      await click(...center(s.ladder >= 0 ? s.ladder_hit : s.carried_ladder_hit));
      await wait(() => window.windowHero.state.placement_mode,undefined,'select actual ladder');
      s = await snapshot();
    }
    if (!s.candidates.includes(index) || !!s.horizontal_anchors[index] !== horizontal) throw new Error(`Missing ${horizontal ? 'bridge' : 'vertical'} ghost ${index}: ${JSON.stringify(s)}`);
    const ghost = s.ghost_hits.find(item => item.index === index);
    if (!ghost || ghost.rect[2] * scale < 44 || ghost.rect[3] * scale < 44) throw new Error('Ghost hit area below 44 CSS px');
    if (label) await shot(label);
    await click((ghost.base[0] + ghost.top[0]) / 2,(ghost.base[1] + ghost.top[1]) / 2);
    await wait(({index,moves}) => {
      const s = window.windowHero.state;
      return s.ladder === index && s.moves === moves + 1 && !s.busy;
    },{index,moves:s.moves},`finish smart reposition ${index}`);
  };
  const stage = async id => {
    step = `stage ${id}`;
    await wait(id => window.windowHero.state.stage_id === id && window.windowHero.state.phase === 'playing',id);
    await shot(id);
    const s = await snapshot();
    if (Object.keys(s).some(key => /solution|optimal/i.test(key))) throw new Error('Release telemetry exposed a solution');
    if (s.window_hits.some(rect => rect[2] * scale < 44 || rect[3] * scale < 44)) throw new Error('Window tap target below 44 CSS px');
    return s;
  };
  const finishBoard = async (id,placements) => {
    await wait(() => window.windowHero.state.phase === 'clear',undefined,`clear ${id}`);
    const s = await snapshot();
    if (s.moves !== placements || s.cleaned !== s.window_count) throw new Error(`${id} did not clear at ${placements} placements: ${JSON.stringify(s)}`);
    if (s.buttons?.Retry) throw new Error('A per-floor result panel interrupted the campaign');
    await wait(() => window.windowHero.state.flow_phase === 'ascent',undefined,`ascent from ${id}`);
    if (id === 'tower') {
      await clickButton('Pause');
      await wait(() => window.windowHero.state.paused,undefined,'pause ascent');
      const paused = (await snapshot()).ascent_elapsed;
      await page.waitForTimeout(300);
      if ((await snapshot()).ascent_elapsed !== paused) throw new Error('Paused ascent kept advancing');
      await clickButton('Resume');
      await wait(() => !window.windowHero.state.paused,undefined,'resume ascent');
    }
    await shot(`ascent-${id}`);
    return s;
  };

  await wait(() => window.windowHero?.state?.phase === 'title',undefined,'load title');
  const desired = mode === 'mouse' ? 'en' : 'ja';
  if ((await snapshot()).language !== desired) {
    await clickButton('Language');
    await wait(language => window.windowHero.state.language === language,desired,'language');
  }
  await shot('title');
  await clickButton('Start');
  await stage('tutorial_1');
  if ((await snapshot()).ladder !== 0) throw new Error('First ladder was not already installed');
  await polish(0);
  await finishBoard('tutorial_1',0);
  if (page.url().includes('qa=ascent')) {
    if (errors.length) throw new Error(errors.join('\n'));
    page.off('pageerror',onError); page.off('console',onConsole); await cdp.detach();
    return {mode,checked:['tutorial_1','single-ladder-ascent'],errors};
  }
  await stage('tutorial_2');
  await tapWindow(0);
  await wait(() => window.windowHero.state.unreachable_gap.length === 2,undefined,'missing bridge route feedback');
  await place(0,true,'tutorial-horizontal-ghost');
  await polish(0);
  await finishBoard('tutorial_2',1);
  await stage('tutorial_3');
  await place(0);
  await polish(0);
  await place(1,true);
  await polish(1);
  await finishBoard('tutorial_3',2);

  const ids = (await snapshot()).stage_ids;
  if (ids.includes('switchback')) {
    await stage('switchback');
    await polish(0);
    await place(0,false,'switchback-route-choice');
    await polish(1);
    await place(1,true);
    await polish(2);
    await place(2);
    await polish(3);
    await finishBoard('switchback',3);
  }
  if (ids.includes('gallery_return')) {
    await stage('gallery_return');
    await polish(0); await place(0); await polish(1); await place(1,true); await polish(2);
    await wait(() => window.windowHero.state.gallery_open,undefined,'open permanent return route');
    await place(2); await polish(3); await place(3,false,'gallery-return-reposition');
    await polish(4); await place(4); await polish(5);
    await finishBoard('gallery_return',5);
  }

  await stage('tower');
  await polish(0); await polish(1); await polish(2); await place(0);
  await clickButton('Undo');
  await wait(() => window.windowHero.state.ladder === -1,undefined,'Undo tower placement');
  if ((await snapshot()).progress.slice(0,3).some(value => value !== 1)) throw new Error('Undo removed clean glass');
  await place(0); await polish(3); await polish(4); await place(4,true); await polish(5);
  await place(2); await polish(6); await polish(7); await tapWindow(7);
  await wait(() => window.windowHero.state.inside && !window.windowHero.state.busy,undefined,'enter tower room');
  await tapWindow(8);
  await wait(() => window.windowHero.state.shutter_open && !window.windowHero.state.busy,undefined,'inner shutter');
  await shot('tower-cutaway');
  await clickButton('Undo');
  await wait(() => !window.windowHero.state.shutter_open && window.windowHero.state.inside,undefined,'Undo shutter');
  await tapWindow(8);
  await wait(() => window.windowHero.state.shutter_open && !window.windowHero.state.busy,undefined,'reopen shutter');
  await tapWindow(8);
  await wait(() => !window.windowHero.state.inside && window.windowHero.state.region === 4 && !window.windowHero.state.busy,undefined,'exit room');
  await polish(8); await place(7); await polish(9); await polish(10); await polish(11);
  await finishBoard('tower',4);

  if (ids.includes('heart_window')) {
    await stage('heart_window');
    await tapWindow(5);
    if ((await snapshot()).progress[5] !== 0) throw new Error('Heart cleaned before its prerequisites');
    await polish(0); await place(0); await polish(1); await place(1,true); await polish(2);
    await place(2); await polish(3); await tapWindow(3);
    await wait(() => window.windowHero.state.inside && !window.windowHero.state.busy,undefined,'Heart room');
    await tapWindow(4);
    await wait(() => window.windowHero.state.shutter_open && !window.windowHero.state.busy,undefined,'Heart shutter');
    await shot('heart-cutaway');
    await tapWindow(4);
    await wait(() => !window.windowHero.state.inside && !window.windowHero.state.busy,undefined,'Heart exit');
    await polish(4); await place(3,false,'heart-reposition');
    await clickButton('Undo');
    await wait(() => window.windowHero.state.ladder === 2,undefined,'Undo Heart ladder');
    await place(3); await tapWindow(5);
    await wait(() => window.windowHero.state.region === 5 && !window.windowHero.state.busy,undefined,'approach Heart');
    await shot('heart-before');
    await polish(5);
    await finishBoard('heart_window',4);
  }

  await wait(() => window.windowHero.state.ending === true,undefined,'Ending');
  await page.waitForTimeout(1200);
  await shot('ending-king');
  await wait(() => window.windowHero.state.final_ready,undefined,'legendary ladder');
  await shot('ending-final');
  const final = await snapshot();
  if (final.ending_stats.completed_stages !== ids.length || final.ending_stats.tower_placements !== 4) throw new Error(`Incomplete campaign records: ${JSON.stringify(final)}`);
  if (await page.evaluate(() => typeof window.windowHeroCommand) !== 'undefined') throw new Error('Release exposed mutation commands');
  await clickButton('Credits');
  await wait(() => window.windowHero.state.credits_open,undefined,'Ending credits');
  await shot('ending-credits');
  await clickButton('Back');
  await clickButton('Title');
  await wait(() => window.windowHero.state.phase === 'title' && !window.windowHero.state.campaign_active,undefined,'Ending return to title');
  if (errors.length) throw new Error(errors.join('\n'));
  page.off('pageerror',onError); page.off('console',onConsole); await cdp.detach();
  return {mode,stages:ids,completed:final.ending_stats.completed_stages,windows:final.ending_stats.total_windows,placements:final.ending_stats.total_placements,towerPlacements:4,errors};
}
