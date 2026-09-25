export function dateKey(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
}
export function reviewResult(previous = {}, success, now = new Date()) {
  const today = dateKey(now);
  const oldStage = Number.isInteger(previous.stage) ? Math.max(0, Math.min(4, previous.stage)) : 0;
  const stage = success ? Math.min(4, oldStage + (previous.lastSuccess === today ? 0 : 1)) : 0;
  const days = success ? [1,1,3,7,14][stage] : 0;
  const next = new Date(now);
  next.setDate(next.getDate() + days);
  return { stage, due: dateKey(next), lastSuccess: success ? today : previous.lastSuccess || null, recalled: success || previous.recalled === true, practised: true };
}
export function dueIds(records, today = dateKey()) {
  return Object.entries(records).filter(([,r]) => r && typeof r.due === 'string' && r.due <= today).map(([id]) => Number(id)).sort((a,b) => a-b);
}
export function normalizeState(raw, count = 43) {
  const state = { current: 0, records: {}, speed: 1 };
  if (!raw || typeof raw !== 'object') return state;
  if (Number.isInteger(raw.current) && raw.current >= 0 && raw.current < count) state.current = raw.current;
  if ([0.75,1,1.15].includes(raw.speed)) state.speed = raw.speed;
  if (raw.records && typeof raw.records === 'object') {
    for (const [id, r] of Object.entries(raw.records)) {
      if (!/^\d+$/.test(id) || Number(id) >= count || !r || typeof r !== 'object') continue;
      state.records[id] = {
        stage: Number.isInteger(r.stage) ? Math.max(0,Math.min(4,r.stage)) : 0,
        due: typeof r.due === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(r.due) ? r.due : dateKey(),
        lastSuccess: typeof r.lastSuccess === 'string' ? r.lastSuccess : null,
        recalled: r.recalled === true, practised: r.practised === true
      };
    }
  }
  return state;
}
