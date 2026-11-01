/* Craft-owned UI: only IDs and requested batch counts leave this page. Lua/server own all mutations. */
(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const fallback = 'workbench.svg';
  const array = value => Array.isArray(value) ? value : [];
  let state = null, selected = null, quantity = 1, elapsed = 0, busy = false, query = '';
  let lastNotice = '', noticeSuccess = false;
  const expanded = new Map();
  function t(key, ...args) {
    let index = 0;
    const text = state && state.messages[key] || key;
    return text.replace(/%%|%[ds]/g, token => token === '%%' ? '%' : String(args[index++]));
  }
  function node(tag, className, text) {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (text !== undefined) element.textContent = text;
    return element;
  }
  function image(source, alt) {
    const img = node('img');
    img.alt = alt || '';
    img.src = source || fallback;
    img.addEventListener('error', () => { if (!img.dataset.fallback) { img.dataset.fallback = 'true'; img.src = fallback; } });
    return img;
  }
  function heroImage(id, source, alt) {
    const img = $(id);
    img.alt = alt;
    if (!img.dataset.bound) {
      img.dataset.bound = 'true';
      img.addEventListener('error', () => { if (!img.dataset.fallback) { img.dataset.fallback = 'true'; img.src = fallback; } });
    }
    if (img.dataset.source !== source) {
      img.dataset.source = source || fallback;
      delete img.dataset.fallback;
      img.src = source || fallback;
    }
  }
  function duration(seconds) {
    seconds = Math.max(0, Math.ceil(seconds));
    return [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60].map(v => String(v).padStart(2, '0')).join(':');
  }
  function recipe() { return state && state.catalog.recipes.find(row => row.Id === selected); }
  function assessment(row = recipe(), batches = quantity) {
    return row && (state.assessments[row.Id] || [])[batches - 1];
  }
  function maximum(row = recipe()) { return row && row.Weapon ? 1 : Math.max(1, row && row.MaxBatch !== undefined ? row.MaxBatch : state.catalog.maxBatch); }
  function setQuantity(value) {
    quantity = Math.max(1, Math.min(maximum(), Math.floor(Number(value) || 1)));
    renderDetail();
  }
  async function post(action, extra = {}) {
    if (!state) return;
    const nonce = state.nonce;
    try {
      const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'h4nr-craft';
      const response = await fetch(`https://${resource}/${action}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ nonce, ...extra }),
      });
      const result = await response.json();
      if (state && state.nonce === nonce && !result.ok) showNotice(t(result.code || 'unavailable'), false);
    } catch {
      if (state && state.nonce === nonce) showNotice(t('unavailable'), false);
    }
  }
  function showNotice(message, success) {
    lastNotice = message; noticeSuccess = success;
    $('notice').textContent = message;
    $('notice').classList.toggle('success', success);
  }
  function renderBrowser() {
    const groups = new Map();
    const search = query.trim().toLocaleLowerCase();
    const recipes = state.catalog.recipes.filter(row => `${row.Label} ${row.Item} ${row.Category}`.toLocaleLowerCase().includes(search));
    for (const row of recipes) {
      if (!groups.has(row.Category)) groups.set(row.Category, []);
      groups.get(row.Category).push(row);
    }
    const list = $('recipe-list'); list.replaceChildren();
    $('recipe-count').textContent = `${recipes.length} / ${state.catalog.recipes.length}`;
    if (!recipes.length) list.append(node('p', 'empty', t('noMatches')));
    for (const [category, rows] of groups) {
      const group = node('details', 'category');
      group.open = search !== '' || expanded.get(category) !== false;
      const summary = node('summary', '', category);
      summary.append(node('small', '', rows.length)); group.append(summary);
      group.addEventListener('toggle', () => { if (!query.trim()) expanded.set(category, group.open); });
      for (const row of rows) {
        const button = node('button', `recipe-button${row.Id === selected ? ' selected' : ''}`);
        button.type = 'button'; button.dataset.recipe = row.Id;
        button.setAttribute('aria-pressed', String(row.Id === selected));
        button.append(image(row.Image, ''));
        const copy = node('span', 'recipe-copy'); copy.append(node('span', '', row.Label));
        const check = assessment(row, 1);
        const reason = check && check.reasons[0];
        const hint = node('small', reason ? 'locked' : '', reason ? (reason === 'low_level' ? t('lockedShort', row.Level) : t(reason)) : t('readyShort'));
        copy.append(hint); button.append(copy);
        button.addEventListener('click', () => { selected = row.Id; quantity = 1; renderBrowser(); renderDetail(); });
        group.append(button);
      }
      list.append(group);
    }
    $('book').hidden = !state.hasBooks || state.portable;
    $('book').textContent = t('book'); $('book').disabled = busy;
  }
  function requirement(text, ok) {
    return node('p', `requirement ${ok ? 'ok' : 'missing'}`, `${ok ? '✓' : '!'} ${text}`);
  }
  function renderDetail() {
    const row = recipe(), check = assessment();
    if (!row || !check) {
      $('craft').disabled = true; $('craft').textContent = t('craft');
      $('recipe-name').textContent = t('noMatches'); heroImage('item-image', fallback, '');
      for (const id of ['recipe-description','required-level','recipe-category','eligibility','output-summary','duration','xp-reward']) $(id).textContent = '';
      for (const id of ['materials','tools','requirements','inventory-list']) $(id).replaceChildren();
      for (const id of ['minus','plus','amount']) $(id).disabled = true;
      return;
    }
    $('recipe-name').textContent = row.Label;
    heroImage('item-image', row.Image, row.Label);
    $('recipe-description').textContent = row.Description || t('descriptionFallback');
    $('required-level').textContent = t('levelRequirement', row.Level);
    $('recipe-category').textContent = row.Category;
    $('amount').max = maximum(); $('amount').value = quantity;
    $('minus').disabled = busy || quantity <= 1; $('plus').disabled = busy || quantity >= maximum(); $('amount').disabled = busy;
    $('duration').textContent = `◷ ${duration(check.seconds)}`;
    $('xp-reward').textContent = `+${check.xp} XP`;
    $('output-summary').textContent = t('batchOutput', quantity, check.output, row.Label);
    $('material-count').textContent = check.materials.length;
    const materials = $('materials'), inventory = $('inventory-list'); materials.replaceChildren(); inventory.replaceChildren();
    $('inventory-count').textContent = check.materials.length;
    for (const material of check.materials) {
      const source = (state.catalog.inventory[material.item] || {}).image;
      const card = node('div', `ingredient${material.enough ? '' : ' missing'}`);
      card.append(image(source, ''), node('span', '', material.label), node('strong', '', `×${material.needed}`)); materials.append(card);
      const stock = node('div', 'stock-row'); stock.append(image(source, ''));
      const copy = node('div', 'stock-copy', material.label); copy.append(node('small', '', t('requiredCount', material.needed)));
      stock.append(copy, node('span', `stock-count${material.enough ? '' : ' missing'}`, material.owned)); inventory.append(stock);
    }
    const tools = $('tools'); tools.replaceChildren();
    if (!check.tools.length) tools.append(node('p', 'empty', t('noTools')));
    for (const tool of check.tools) {
      const card = node('div', `tool-row${tool.enough ? '' : ' missing'}`);
      card.append(node('span', '', t('toolCondition', tool.label, tool.condition, tool.wear)));
      const track = node('div', 'condition-track'), fill = node('i'); fill.style.width = `${Math.max(0, Math.min(100, tool.condition))}%`; track.append(fill); card.append(track);
      card.append(node('small', '', t('conditionAfter', Math.max(0, tool.condition - tool.wear)))); tools.append(card);
    }
    const requirements = $('requirements'); requirements.replaceChildren();
    requirements.append(requirement(t('levelRequirement', row.Level), state.catalog.level >= row.Level));
    if (row.Book) {
      const book = state.catalog.inventory[row.Book] || {};
      requirements.append(requirement(t('bookRequirement', book.label || row.Book), book.count > 0));
    }
    for (const job of array(row.Jobs)) {
      requirements.append(requirement(t('jobRequirement', Array.isArray(job) ? job[0] : job, Array.isArray(job) ? job[1] : 0), row.JobAllowed !== false));
    }
    if (!row.Portable) requirements.append(requirement(t('fixedBench'), !state.portable));
    $('eligibility').textContent = check.canCraft ? t('readyCraft') : check.reasons.map(code => `! ${t(code)}`).join('\n');
    $('eligibility').classList.toggle('blocked', !check.canCraft);
    $('craft').textContent = busy ? t('processing') : t('craft'); $('craft').disabled = busy || !check.canCraft;
  }
  function renderQueue() {
    const list = $('queue'); list.replaceChildren();
    $('queue-count').textContent = `${state.catalog.queueCount} / ${state.catalog.maxQueue}`;
    if (!state.catalog.queue.length) list.append(node('p', 'empty', t('empty')));
    for (const order of state.catalog.queue) {
      const remaining = Math.max(0, order.remaining - elapsed);
      const preparing = order.state === 'preparing', ready = !preparing && remaining === 0;
      const card = node('article', `queue-card${preparing ? ' preparing' : ready ? ' ready' : ''}`); card.dataset.order = order.id;
      const title = node('div', 'queue-title', order.label); title.append(node('span', '', `×${order.amount}`)); card.append(title);
      card.append(node('p', 'queue-status', preparing ? t('preparingStatus') : ready ? t('readyCollect') : t('workingStatus', duration(remaining))));
      const progress = node('div', 'queue-progress'), fill = node('i');
      fill.style.width = `${preparing ? 0 : Math.max(0, Math.min(100, 100 * (1 - remaining / Math.max(1, order.duration))))}%`;
      progress.setAttribute('role', 'progressbar'); progress.setAttribute('aria-label', t('progress'));
      progress.setAttribute('aria-valuemin', '0'); progress.setAttribute('aria-valuemax', '100'); progress.setAttribute('aria-valuenow', fill.style.width.replace('%', ''));
      progress.append(fill); card.append(progress);
      const blocked = state.portable && !order.portable;
      const button = node('button', 'queue-action', preparing ? t('resume') : t('collect')); button.type = 'button';
      button.disabled = busy || blocked || (!preparing && !ready);
      button.addEventListener('click', () => post(preparing ? 'resume' : 'collect', { id: order.id })); card.append(button);
      if (blocked) card.append(node('p', 'queue-status', t('workshop_required')));
      list.append(card);
    }
    $('pending-box').hidden = !state.pending;
    $('pending-message').textContent = t('pendingRequest'); $('retry').textContent = t('resume'); $('retry').disabled = busy;
  }
  function render() {
    $('station-name').textContent = state.station.label;
    $('station-mode').textContent = t(state.portable ? 'fieldBench' : 'fixedBench');
    $('level-label').textContent = t('level', state.catalog.level, state.catalog.xp);
    const full = state.catalog.level >= state.catalog.maxLevel;
    const within = state.catalog.xp % state.catalog.xpStep;
    $('xp-fill').style.width = `${full ? 100 : 100 * within / state.catalog.xpStep}%`;
    $('xp-label').textContent = full ? t('maxLevel') : `${within} / ${state.catalog.xpStep} XP`;
    for (const [id,key] of [['recipes-label','recipes'],['output-label','output'],['materials-label','materials'],['tools-label','tools'],['inventory-label','owned'],['queue-label','queue'],['amount-label','amount']]) $(id).textContent = t(key);
    $('search').placeholder = t('search'); $('search').setAttribute('aria-label', t('search'));
    $('refresh').setAttribute('aria-label', t('refresh')); $('close').setAttribute('aria-label', t('close'));
    $('minus').setAttribute('aria-label', t('fewer')); $('plus').setAttribute('aria-label', t('more'));
    $('busy').hidden = !busy; $('refresh').disabled = busy;
    showNotice(lastNotice, noticeSuccess);
    renderBrowser(); renderDetail(); renderQueue();
  }
  window.addEventListener('message', event => {
    const message = event.data;
    if (!message || typeof message !== 'object') return;
    if (message.action === 'close') { $('app').hidden = true; state = null; return; }
    if (message.action === 'busy') {
      busy = message.value === true;
      if (state) { $('busy').hidden = !busy; $('refresh').disabled = busy; $('book').disabled = busy; renderDetail(); renderQueue(); }
      return;
    }
    if (message.action === 'notice') { showNotice(String(message.message || ''), message.success === true); return; }
    if (message.action === 'queueTick' && state) { elapsed = Math.max(0, Number(message.elapsed) || 0); renderQueue(); return; }
    if (message.action !== 'workbench' || !message.catalog || !message.messages) return;
    message.catalog.recipes = array(message.catalog.recipes);
    message.catalog.queue = array(message.catalog.queue);
    for (const values of Object.values(message.assessments || {})) {
      for (const check of array(values)) {
        check.materials = array(check.materials); check.tools = array(check.tools); check.reasons = array(check.reasons);
      }
    }
    const changed = !state || state.nonce !== message.nonce;
    state = message; elapsed = 0;
    if (changed) { selected = null; quantity = 1; query = ''; $('search').value = ''; expanded.clear(); lastNotice = ''; }
    if (!recipe()) { selected = state.catalog.recipes[0] && state.catalog.recipes[0].Id; quantity = 1; }
    quantity = Math.max(1, Math.min(maximum(), quantity));
    $('app').hidden = false; document.documentElement.lang = message.language || 'ro'; render();
    if (changed) $('search').focus();
  });
  $('search').addEventListener('input', event => { query = event.target.value; if (state) renderBrowser(); });
  $('amount').addEventListener('input', event => { if (state) setQuantity(event.target.value); });
  $('amount').addEventListener('change', event => { if (state) setQuantity(event.target.value); });
  $('minus').addEventListener('click', () => setQuantity(quantity - 1)); $('plus').addEventListener('click', () => setQuantity(quantity + 1));
  $('craft').addEventListener('click', () => { if (!busy && assessment() && assessment().canCraft) post('craft', { recipe: selected, amount: quantity }); });
  for (const action of ['close','refresh','book','retry']) $(action).addEventListener('click', () => post(action));
  function focusable() { return [...$('app').querySelectorAll('button:not(:disabled), input:not(:disabled), summary')].filter(element => element.getClientRects().length > 0); }
  document.addEventListener('keydown', event => {
    if (!state) return;
    if (event.key === 'Escape') { event.preventDefault(); post('close'); }
    if (event.key === 'Tab') {
      const controls = focusable(); if (!controls.length) return;
      const index = controls.indexOf(document.activeElement);
      if (event.shiftKey && index <= 0) { event.preventDefault(); controls[controls.length - 1].focus(); }
      else if (!event.shiftKey && (index < 0 || index === controls.length - 1)) { event.preventDefault(); controls[0].focus(); }
    }
  });
  let previousButtons = [];
  function gamepad() {
    if (state && navigator.getGamepads) {
      const pad = [...navigator.getGamepads()].find(Boolean);
      if (pad) {
        const down = index => pad.buttons[index] && pad.buttons[index].pressed;
        const edge = index => down(index) && !previousButtons[index];
        if (edge(1)) post('close');
        if (edge(12) || edge(13)) {
          const controls = focusable(), index = controls.indexOf(document.activeElement);
          if (controls.length) controls[(index + (edge(12) ? -1 : 1) + controls.length) % controls.length].focus();
        }
        if (edge(0) && document.activeElement) document.activeElement.click();
        previousButtons = pad.buttons.map(button => button.pressed);
      } else previousButtons = [];
    } else previousButtons = [];
    requestAnimationFrame(gamepad);
  }
  requestAnimationFrame(gamepad);
})();
