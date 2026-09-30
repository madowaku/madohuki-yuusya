async page => {
  // Playwright CLI run-code. All game actions use real mouse/touch input;
  // window.windowHero.state is read-only telemetry.
  const initialViewport = page.viewportSize();
  const mode = initialViewport && initialViewport.width <= 400 ? 'touch' : 'mouse';
  const width = mode === 'touch' ? 360 : 720;
  const height = mode === 'touch' ? 800 : 1280;
  await page.setViewportSize({width,height});

  const errors = [];
  let step = 'initialize';
  const onError = error => errors.push(error.message);
  const onConsole = message => {
    if (message.type() === 'error' || message.type() === 'warning') errors.push(message.text());
  };
  page.on('pageerror',onError);
  page.on('console',onConsole);

  const scale = Math.min(width / 720,height / 1280);
  const point = (x,y) => ({
    x:(width - 720 * scale) / 2 + x * scale,
    y:(height - 1280 * scale) / 2 + y * scale,
  });
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:mode === 'touch',maxTouchPoints:1});
  const touch = (type,x,y) => cdp.send('Input.dispatchTouchEvent',{
    type,
    touchPoints:type === 'touchEnd' ? [] : [{...point(x,y),id:0,radiusX:6,radiusY:6,force:1}],
  });
  const click = async (x,y) => {
    if (mode === 'touch') {
      await touch('touchStart',x,y);
      await touch('touchEnd');
    } else {
      const position = point(x,y);
      await page.mouse.click(position.x,position.y);
    }
  };
  const move = async (x,y) => {
    if (mode === 'touch') await touch('touchMove',x,y);
    else {
      const position = point(x,y);
      await page.mouse.move(position.x,position.y);
    }
  };
  const snapshot = () => page.evaluate(() => window.windowHero.state);
  const wait = async (predicate,arg,label = step) => {
    try {
      await page.waitForFunction(predicate,arg,{timeout:30000});
    } catch (error) {
      throw new Error(`${label}: ${error.message}; state=${JSON.stringify(await snapshot())}`);
    }
  };
  const clickButton = async name => {
    step = `button ${name}`;
    await wait(button => !!window.windowHero.state.buttons?.[button],name,step);
    const bounds = (await snapshot()).buttons[name];
    await click(bounds[0] + bounds[2] / 2,bounds[1] + bounds[3] / 2);
  };
  const shot = label => page.screenshot({path:`output/playwright/ux-v02-${mode}-${label}.png`});
  const center = rect => [rect[0] + rect[2] / 2,rect[1] + rect[3] / 2];
  const windowCenter = async index => center((await snapshot()).window_hits[index]);
  const tapWindow = async index => {
    step = `tap window ${index}`;
    await click(...await windowCenter(index));
  };
  const waitWindowReady = async index => {
    const state = await snapshot();
    const [cx] = center(state.window_hits[index]);
    await wait(({index,cx}) => {
      const current = window.windowHero.state;
      return !current.busy && !current.climbing && current.floor === current.window_floors[index]
        && Math.abs(current.hero[0] - cx) < 108;
    },{index,cx},`approach window ${index}`);
  };
  const polish = async index => {
    step = `approach window ${index}`;
    if ((await snapshot()).progress[index] === 1) return;
    await tapWindow(index);
    await waitWindowReady(index);

    step = `wipe window ${index}`;
    const area = (await snapshot()).windows[index];
    const [x,y,w,h] = area;
    let last = {x:x + 3,y:y + 5};
    if (mode === 'touch') await touch('touchStart',last.x,last.y);
    else {
      const position = point(last.x,last.y);
      await page.mouse.move(position.x,position.y);
      await page.mouse.down();
    }
    for (let row = 0; row < 4; row++) {
      const target = {x:row % 2 === 0 ? x + w - 3 : x + 3,y:y + 5 + row * (h - 10) / 3};
      for (let part = 1; part <= 4; part++) {
        await move(last.x + (target.x - last.x) * part / 4,last.y + (target.y - last.y) * part / 4);
        await page.waitForTimeout(12);
      }
      last = target;
    }
    if (mode === 'touch') await touch('touchEnd');
    else await page.mouse.up();
    await wait(index => window.windowHero.state.progress[index] === 1 || window.windowHero.state.phase === 'clear',index,`polish window ${index}`);
  };
  const startPlacementMode = async state => {
    const hit = state.ladder >= 0 ? state.ladder_hit : state.carried_ladder_hit;
    if (!hit || hit[2] <= 0 || hit[3] <= 0) throw new Error(`Missing ladder control hit area: ${JSON.stringify(state)}`);
    await click(...center(hit));
    await wait(() => window.windowHero.state.placement_mode,undefined,'enter ladder placement mode');
  };
  const chooseGhost = async (index,expectHorizontal = false,label = null) => {
    const state = await snapshot();
    if (!state.candidates.includes(index)) throw new Error(`Expected legal ghost ${index}: ${JSON.stringify(state)}`);
    if (!!state.horizontal_anchors[index] !== expectHorizontal) throw new Error(`Ghost ${index} has the wrong orientation`);
    const ghost = state.ghost_hits.find(item => item.index === index);
    if (!ghost) throw new Error(`Missing ghost hit region ${index}: ${JSON.stringify(state.ghost_hits)}`);
    if (label) await shot(label);
    const beforeMoves = state.moves;
    // Select the center of the visible shaft/bridge so placement uses the full ghost body.
    await click((ghost.base[0] + ghost.top[0]) / 2,(ghost.base[1] + ghost.top[1]) / 2);
    await wait(({index,beforeMoves}) => {
      const current = window.windowHero.state;
      return current.ladder === index && current.moves === beforeMoves + 1 && !current.busy;
    },{index,beforeMoves},`place ladder at ghost ${index}`);
  };
  const place = async (index,expectHorizontal = false,label = null) => {
    const before = await snapshot();
    if (!before.placement_mode) await startPlacementMode(before);
    await chooseGhost(index,expectHorizontal,label);
  };

  step = 'wait for title';
  await wait(() => window.windowHero?.state?.buttons && window.windowHero.state.phase === 'title',undefined,step);
  const initial = await snapshot();
  await shot('title');
  const desiredLanguage = mode === 'mouse' ? 'en' : 'ja';
  if (initial.language !== desiredLanguage) {
    await clickButton('Language');
    await wait(language => window.windowHero.state.language === language,desiredLanguage,'change language');
  }
  await clickButton('Start');
  await wait(() => window.windowHero.state.tutorial === true && window.windowHero.state.tutorial_step === 1,undefined,'start T1');

  // T1: one vertical ghost teaches ladder selection and automatic climbing.
  step = 'T1 board';
  await shot('T1');
  await clickButton('Pause');
  await wait(() => window.windowHero.state.paused,undefined,'open menu');
  await shot('menu');
  const pausedTime = (await snapshot()).elapsed;
  await page.waitForTimeout(350);
  if ((await snapshot()).elapsed !== pausedTime) throw new Error('Menu failed to freeze the tutorial clock');
  await clickButton('Resume');
  await wait(() => !window.windowHero.state.paused,undefined,'resume tutorial');
  const t1Start = await snapshot();
  await click(...center(t1Start.window_hits[0]));
  await wait(() => {
    const state = window.windowHero.state;
    return state.unreachable_window === 0 && state.unreachable_points.length > 1;
  },undefined,'show unreachable response');
  const unreachable = await snapshot();
  if (!unreachable.unreachable_gap || unreachable.unreachable_gap.length < 2) throw new Error(`Unreachable tap did not identify a missing ladder route: ${JSON.stringify(unreachable)}`);
  if (unreachable.hero[0] !== t1Start.hero[0] || unreachable.ladder !== -1) throw new Error('Unreachable tap moved the hero or placed a ladder');
  await shot('unreachable');

  await clickButton('Help');
  await wait(() => window.windowHero.state.help_visible,undefined,'show available actions');
  const help = await snapshot();
  if (!help.candidates.includes(0) || help.reachable_windows.length !== 0) throw new Error(`Help should show a legal ladder ghost without a route solution: ${JSON.stringify(help)}`);
  if (Object.keys(help).some(key => /solution|optimal/i.test(key))) throw new Error('Help telemetry exposed a solution field');
  await shot('help');
  await clickButton('Help');
  await wait(() => !window.windowHero.state.help_visible,undefined,'dismiss available actions');

  await place(0,false,'ghosts-T1');
  let state = await snapshot();
  const ladderPoint = center(state.ladder_hit);
  await click(...ladderPoint);
  await wait(() => window.windowHero.state.placement_mode,undefined,'select installed ladder');
  state = await snapshot();
  if (state.ladder !== 0) throw new Error('Selecting the installed ladder removed it');
  await click(...center(state.ladder_hit));
  await wait(() => !window.windowHero.state.placement_mode && window.windowHero.state.ladder === 0,undefined,'cancel ladder placement mode');
  await polish(0);
  await wait(() => window.windowHero.state.tutorial === true && window.windowHero.state.tutorial_step === 2,undefined,'advance to T2');

  // T2: the only ghost is horizontal and connects two regions on one floor.
  step = 'T2 board';
  await shot('T2');
  state = await snapshot();
  if (state.candidates?.length && state.candidates.length !== 1) throw new Error(`T2 should have one legal destination: ${JSON.stringify(state.candidates)}`);
  await click(...center(state.window_hits[0]));
  await wait(() => window.windowHero.state.unreachable_window === 0,undefined,'show T2 gap feedback');
  state = await snapshot();
  if (!state.unreachable_gap || state.unreachable_gap.length < 2) throw new Error('T2 unreachable target did not pulse its missing bridge');
  await startPlacementMode(state);
  state = await snapshot();
  if (state.candidates.length !== 1 || state.horizontal_anchors[state.candidates[0]] !== true) throw new Error(`T2 must offer only a horizontal bridge: ${JSON.stringify(state)}`);
  await chooseGhost(0,true,'ghosts');
  await polish(0);
  await wait(() => window.windowHero.state.tutorial === true && window.windowHero.state.tutorial_step === 3,undefined,'advance to T3');

  // T3: polish the first upper pane, then directly move that same ladder into the bridge.
  step = 'T3 board';
  await shot('T3');
  state = await snapshot();
  await startPlacementMode(state);
  state = await snapshot();
  if (state.candidates.length !== 1 || state.horizontal_anchors[state.candidates[0]]) throw new Error(`T3 should initially offer one vertical destination: ${JSON.stringify(state)}`);
  await chooseGhost(0,false,'ghosts-T3-vertical');
  await polish(0);
  state = await snapshot();
  if (state.ladder !== 0 || state.candidates.length !== 0) throw new Error('T3 should keep the installed vertical ladder until a new destination is selected');
  await startPlacementMode(state);
  state = await snapshot();
  if (state.candidates.length !== 1 || state.candidates[0] !== 1 || state.horizontal_anchors[1] !== true) throw new Error(`Polishing window 0 must unlock only the horizontal destination: ${JSON.stringify(state)}`);
  await chooseGhost(1,true,'ghosts-T3');
  state = await snapshot();
  if (state.moves !== 2 || state.ladder !== 1 || state.region !== 1) throw new Error(`T3 must reposition one ladder in two placements: ${JSON.stringify(state)}`);
  await polish(1);
  await wait(() => window.windowHero.state.tutorial !== true && window.windowHero.state.phase === 'playing',undefined,'enter the twelve-window tower');

  // Tower route: four selected destinations, all transport handled by the game.
  step = 'twelve-window tower';
  await polish(0);
  await polish(1);
  await polish(2);
  await place(0,false);
  await clickButton('Undo');
  await wait(() => window.windowHero.state.ladder === -1,undefined,'undo first tower placement');
  state = await snapshot();
  if (state.progress.slice(0,3).some(value => value !== 1)) throw new Error('Tower Undo removed already polished glass');
  await shot('tower-undo');

  await place(0,false);
  await polish(3);
  await polish(4);
  await place(4,true);
  await polish(5);
  await place(2,false);
  await polish(6);
  await polish(7);
  await tapWindow(7);
  await wait(() => window.windowHero.state.inside && !window.windowHero.state.busy,undefined,'enter the open entry window');
  await tapWindow(8);
  await wait(() => window.windowHero.state.shutter_open && !window.windowHero.state.busy,undefined,'open the inner shutter');
  await shot('inside');
  await clickButton('Undo');
  await wait(() => !window.windowHero.state.shutter_open && window.windowHero.state.inside,undefined,'undo shutter opening');
  await tapWindow(8);
  await wait(() => window.windowHero.state.shutter_open && !window.windowHero.state.busy,undefined,'reopen the inner shutter');
  await tapWindow(8);
  await wait(() => !window.windowHero.state.inside && window.windowHero.state.region === 4 && !window.windowHero.state.busy,undefined,'exit through the shutter');
  await polish(8);
  await wait(() => window.windowHero.state.gallery_open,undefined,'activate the permanent gallery');
  await place(7,false);
  await polish(9);
  await polish(10);
  await polish(11);
  await wait(() => window.windowHero.state.phase === 'clear',undefined,'finish the twelve-window tower');
  await page.waitForTimeout(1500);
  await shot('result');

  const final = await snapshot();
  if (final.cleaned !== 12 || final.moves !== 4 || !final.shutter_open || !final.gallery_open) {
    throw new Error(`Tower route did not finish at four placements: ${JSON.stringify(final)}`);
  }
  if (await page.evaluate(() => typeof window.windowHeroCommand) !== 'undefined') {
    throw new Error('Release build exposed a browser mutation hook');
  }
  if (errors.length) throw new Error(errors.join('\n'));

  page.off('pageerror',onError);
  page.off('console',onConsole);
  await cdp.detach();
  return {mode,tutorialSteps:[1,2,3],cleaned:final.cleaned,moves:final.moves,bridges:final.bridge_crossings,errors};
}
