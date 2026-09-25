import { verses } from './verses.js';
import { dateKey, reviewResult, dueIds, normalizeState } from './progress.js';
const $ = id => document.getElementById(id);
const key = 'chalisa-practice-v1';
let storageOK = true;
let state;
try { state = normalizeState(JSON.parse(localStorage.getItem(key))); } catch { state = normalizeState(null); storageOK = false; }
let mode = 'read', checked = false, revealed = new Set(), token = 0, playing = false, pendingResolve = null, repeatTimer = null, reviewSession = false;
const audio = $('audio');
function notice(text) { $('notice').textContent = text; }
function save() {
  try { localStorage.setItem(key, JSON.stringify(state)); } catch {
    storageOK = false;
    document.querySelector('.save-label').textContent = 'Progress not saved';
    document.querySelector('.save-label').classList.add('error');
    notice('Your browser cannot save progress right now. Practice still works for this visit.');
  }
}
function summary() {
  const recalled = Object.values(state.records).filter(r => r.recalled).length;
  $('learnedCount').innerHTML = `${recalled}<span>/43</span>`;
  $('sidePercent').textContent = Math.round(recalled/43*100) + '%';
  $('sideProgress').style.width = recalled/43*100 + '%';
  const due = dueIds(state.records);
  $('dueCount').textContent = due.length;
  $('mobileReview').textContent = due.length ? `Review (${due.length})` : 'Review';
  const record = state.records[state.current];
  $('sessionLabel').textContent = reviewSession ? `${due.length} passage${due.length === 1 ? '' : 's'} due for review` : (state.current < 2 ? 'Start with the opening prayer' : 'A little practice goes a long way');
  $('reviewInfo').textContent = record?.due ? (record.due <= dateKey() ? 'Ready to review today' : `Review on ${new Date(record.due+'T12:00:00').toLocaleDateString('en',{month:'short',day:'numeric'})}`) : 'Read → listen → say it back';
}
function renderLines() {
  $('verseLines').replaceChildren();
  verses[state.current].lines.forEach((line, lineIndex) => {
    const row = document.createElement('div'); row.className = 'verse-line'; row.dataset.line = lineIndex;
    const number = document.createElement('span'); number.className = 'line-number'; number.textContent = '0'+(lineIndex+1);
    const text = document.createElement('div'); text.className = 'line-text';
    line.split(' ').forEach((word, wordIndex) => {
      const id = `${lineIndex}-${wordIndex}`;
      const hide = !checked && !revealed.has(id) && (mode === 'recall' || (mode === 'hints' && wordIndex % 2 === 1));
      const item = document.createElement(hide ? 'button' : 'span');
      item.className = 'word' + (hide ? ' masked' : '');
      item.textContent = hide ? (mode === 'hints' ? word.charAt(0) + '···' : '···') : word;
      if (hide) {
        item.setAttribute('aria-label', `Reveal word ${wordIndex+1} of line ${lineIndex+1}`);
        item.addEventListener('click', () => {
          revealed.add(id); renderLines();
          // A hint is permitted; self-assessment remains explicitly up to the learner.
        });
      }
      text.append(item, document.createTextNode(' '));
    });
    const listen = document.createElement('button'); listen.className = 'line-listen'; listen.textContent = '▶'; listen.setAttribute('aria-label', `Listen to line ${lineIndex+1}`);
    listen.addEventListener('click', () => startAudio([lineIndex]));
    row.append(number, text, listen); $('verseLines').append(row);
  });
}
function render() {
  $('verseTitle').textContent = verses[state.current].title;
  $('versePosition').textContent = String(state.current+1).padStart(2,'0')+' / 43';
  document.querySelectorAll('[data-mode]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.mode === mode)));
  $('modeHelp').textContent = mode === 'read' ? 'Listen, then say each line out loud.' : mode === 'hints' ? 'Fill the gaps out loud. Tap a hidden word if you need it.' : checked ? 'Compare with what you said. Be honest with yourself.' : 'Say both lines from memory, then check the answer.';
  $('assessmentText').textContent = mode === 'read' ? 'Ready to try with fewer words?' : mode === 'hints' ? 'Can you say it without looking?' : checked ? 'How did you do without the text?' : 'Take your time. Say it out loud.';
  $('advance').textContent = mode === 'read' ? 'Try with hints →' : mode === 'hints' ? 'Try from memory →' : 'Check the answer';
  $('advance').hidden = checked;
  $('advance').style.display = checked ? 'none' : '';
  $('gradeControls').hidden = !checked;
  $('previous').disabled = state.current === 0;
  $('next').disabled = state.current === verses.length-1;
  renderLines(); summary();
}
function stopAudio() {
  token++; clearTimeout(repeatTimer); audio.pause(); audio.onended = null; audio.onerror = null;
  if (pendingResolve) { pendingResolve(false); pendingResolve = null; }
  playing = false; $('playIcon').textContent = '▶'; $('playLabel').textContent = 'Listen'; $('playVerse').setAttribute('aria-label','Listen to this verse');
  $('audioStatus').textContent = 'Hear the whole verse';
  document.querySelectorAll('.verse-line').forEach(row => row.classList.remove('playing'));
}
function playClip(index, run) {
  return new Promise(resolve => {
    if (run !== token) { resolve(false); return; }
    pendingResolve = resolve;
    const finish = ok => { if (pendingResolve === resolve) pendingResolve = null; resolve(ok); };
    audio.src = `audio/${String(state.current).padStart(2,'0')}-${index}.mp3`;
    audio.playbackRate = Number($('speed').value);
    audio.onended = () => finish(true);
    audio.onerror = () => { if (run === token) notice('Audio could not load. Check your connection and tap Listen again.'); finish(false); };
    audio.play().catch(() => { if (run === token) notice('Audio did not start. Tap Listen again and check your sound settings.'); finish(false); });
  });
}
async function startAudio(lines = [0,1]) {
  stopAudio(); notice('');
  const run = token, cycles = $('repeat').checked ? 3 : 1;
  playing = true; $('playIcon').textContent = '■'; $('playLabel').textContent = 'Stop'; $('playVerse').setAttribute('aria-label','Stop pronunciation audio');
  for (let cycle = 0; cycle < cycles; cycle++) {
    for (const index of lines) {
      if (run !== token) return;
      $('audioStatus').textContent = `Line ${index+1} of 2${cycles > 1 ? ' · repeat '+(cycle+1)+'/3' : ''}`;
      document.querySelectorAll('.verse-line').forEach(row => row.classList.toggle('playing',Number(row.dataset.line) === index));
      if (!(await playClip(index, run))) { if (run === token) stopAudio(); return; }
      if (run !== token) return;
      await new Promise(resolve => { pendingResolve = resolve; repeatTimer = setTimeout(() => { pendingResolve=null; resolve(); }, 900); });
    }
  }
  if (run === token) stopAudio();
}
function selectVerse(index, requestedMode = 'read') {
  stopAudio(); state.current = index; mode = requestedMode; checked = false; revealed.clear(); save(); notice(''); render();
}
function setMode(next) { stopAudio(); mode = next; checked = false; revealed.clear(); render(); }
function openLibrary() {
  stopAudio(); $('verseLibrary').replaceChildren();
  verses.forEach(verse => {
    const button = document.createElement('button'); button.className = 'library-item'+(verse.id === state.current ? ' selected' : '');
    const r = state.records[verse.id];
    const num = document.createElement('span'); num.className='lib-number'; num.textContent=String(verse.id+1).padStart(2,'0');
    const copy=document.createElement('span');copy.className='lib-copy';
    const title=document.createElement('strong');title.textContent=verse.title;
    const line=document.createElement('span');line.textContent=verse.lines[0];copy.append(title,line);
    const status=document.createElement('span');status.className='lib-state';status.textContent=r?.recalled?'✓':r?.practised?'◐':'○';status.setAttribute('aria-label',r?.recalled?'Recalled':r?.practised?'Practising':'New');
    button.append(num,copy,status);button.addEventListener('click',()=>{reviewSession=false;selectVerse(verse.id);$('libraryDialog').close();});$('verseLibrary').append(button);
  });
  $('libraryDialog').showModal();
}
function grade(success) {
  if (!checked) return;
  const previous = state.current;
  state.records[previous] = reviewResult(state.records[previous], success); save();
  if (success) {
    const due = dueIds(state.records).filter(id => id !== previous);
    if (reviewSession && due.length) selectVerse(due[0], 'recall');
    else if (!reviewSession && previous < verses.length-1) selectVerse(previous+1);
    else { setMode('read'); summary(); }
    notice(reviewSession && !due.length ? 'Today’s review is done. Your next review is scheduled.' : `${verses[previous].title} saved. Come back on ${new Date(state.records[previous].due+'T12:00:00').toLocaleDateString('en',{month:'short',day:'numeric'})}.`);
  } else { setMode('read'); summary(); notice('No rush. Listen again, then try recalling it once more.'); }
}
$('playVerse').addEventListener('click',()=>playing?stopAudio():startAudio());
$('speed').value=state.speed;
$('speed').addEventListener('change',()=>{state.speed=Number($('speed').value);audio.playbackRate=state.speed;save();});
$('repeat').addEventListener('change',stopAudio);
document.querySelectorAll('[data-mode]').forEach(button=>button.addEventListener('click',()=>setMode(button.dataset.mode)));
$('advance').addEventListener('click',()=>{if(mode==='read')setMode('hints');else if(mode==='hints')setMode('recall');else{stopAudio();checked=true;render();}});
$('remembered').addEventListener('click',()=>grade(true));$('again').addEventListener('click',()=>grade(false));
$('previous').addEventListener('click',()=>{if(state.current>0)selectVerse(state.current-1);});
$('next').addEventListener('click',()=>{if(state.current<42)selectVerse(state.current+1);});
['libraryNav','mobileLibrary','chooseVerse'].forEach(id=>$(id).addEventListener('click',openLibrary));
$('practiceNav').addEventListener('click',()=>{reviewSession=false;selectVerse(state.current);});
function startReview() {
  const ids=dueIds(state.records);
  if(!ids.length){notice('Nothing is due yet. Recall a verse to schedule your first review.');return;}
  reviewSession=true;selectVerse(ids[0],'recall');
}
$('reviewNav').addEventListener('click',startReview);
$('mobileReview').addEventListener('click',startReview);
$('aboutButton').addEventListener('click',()=>{stopAudio();$('aboutDialog').showModal();});
document.querySelectorAll('[data-close]').forEach(button=>button.addEventListener('click',()=>$(button.dataset.close).close()));
$('resetProgress').addEventListener('click',()=>{if(confirm('Reset all practice progress on this device? This cannot be undone.')){state=normalizeState(null);reviewSession=false;$('speed').value='1';selectVerse(0);$('aboutDialog').close();notice('Progress reset. Start fresh with the opening prayer.');}});
window.addEventListener('pagehide',stopAudio);
document.addEventListener('visibilitychange',()=>{if(document.hidden)stopAudio();});
$('dateLabel').textContent = new Date().toLocaleDateString('en',{weekday:'long',month:'long',day:'numeric'});
render();
if(!storageOK) notice('Saved progress could not be loaded. Your practice starts fresh.');
