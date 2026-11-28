const play='https://play.google.com/store/apps/details?id=com.destnlyapp';
const features={
 post:{label:'A conversation worth joining',html:`<div class="stage-profile"><span class="stage-avatar">ア</span><div>Anime Fan Club<small>community post</small></div></div><h3>Which series deserves a second season?</h3><p>Some endings stay with you. Tell us the one you still think about.</p><div class="stage-action"><span>♡ join the discussion</span><span>comment ↗</span></div>`},
 poll:{label:'Everyone gets a say',html:`<div class="stage-profile"><span class="stage-avatar">b.</span><div>Books & Beyond<small>community poll</small></div></div><h3>What should we read next?</h3><div class="stage-option"><span>A good mystery</span><span>○</span></div><div class="stage-option"><span>Something heartwarming</span><span>○</span></div><div class="stage-option"><span>A classic</span><span>○</span></div><div class="stage-action"><span>your vote, your community</span><span>↗</span></div>`},
 ice:{label:'A new question every day',html:`<div class="stage-profile"><span class="stage-avatar">✳</span><div>Today's icebreaker<small>fresh daily prompt</small></div></div><h3>What’s a tiny thing that instantly makes your day better?</h3><p>There are no wrong answers. Sometimes the smallest details make the best conversations.</p><div class="stage-action"><span>answer anonymously</span><span>↗</span></div>`},
 chat:{label:'A conversation can go anywhere',html:`<div class="stage-profile"><span class="stage-avatar">♫</span><div>Music Masti<small>illustrative conversation</small></div></div><h3>That song was such a good recommendation.</h3><div class="stage-chat">Wait, you like that artist too?</div><div class="stage-chat reply">Been listening all week!</div><div class="stage-action"><span>shared interests, real conversations</span><span>♡</span></div>`}
};
const tabs=[...document.querySelectorAll('.feature-tab')],panel=document.getElementById('featurePanel'),stage=document.getElementById('stageContent');
function showFeature(key){const feature=features[key];if(!feature)return;stage.innerHTML='<div class="stage-content">'+feature.html+'</div>';const active=tabs.find(t=>t.dataset.feature===key);tabs.forEach(t=>{t.classList.toggle('active',t===active);t.setAttribute('aria-selected',String(t===active));t.tabIndex=t===active?0:-1});panel.setAttribute('aria-labelledby',active.id);document.getElementById('stageNumber').textContent=String(tabs.indexOf(active)+1).padStart(2,'0')+' — 04'}
tabs.forEach((t,i)=>{t.addEventListener('click',()=>showFeature(t.dataset.feature));t.addEventListener('keydown',e=>{if(!['ArrowDown','ArrowUp','Home','End'].includes(e.key))return;e.preventDefault();let j=e.key==='Home'?0:e.key==='End'?tabs.length-1:(i+(e.key==='ArrowDown'?1:-1)+tabs.length)%tabs.length;showFeature(tabs[j].dataset.feature);tabs[j].focus()})});if(stage)showFeature('post');
const toggle=document.getElementById('menuToggle'),nav=document.getElementById('nav');toggle?.addEventListener('click',()=>{const open=nav.classList.toggle('open');toggle.setAttribute('aria-expanded',String(open));toggle.setAttribute('aria-label',open?'Close navigation':'Open navigation')});nav?.querySelectorAll('a').forEach(a=>a.addEventListener('click',()=>{nav.classList.remove('open');toggle.setAttribute('aria-expanded','false')}));
const observer=window.IntersectionObserver?new IntersectionObserver(entries=>{entries.forEach(e=>{if(e.isIntersecting){e.target.classList.add('visible');observer.unobserve(e.target)}})},{threshold:.1}):null;document.querySelectorAll('.reveal').forEach(el=>observer?observer.observe(el):el.classList.add('visible'));
const y=document.getElementById('year');if(y)y.textContent=new Date().getFullYear();

// Scroll-driven product story. Only one IntersectionObserver + one passive scroll listener.
const journey=document.querySelector('.journey');
const scenes=[...document.querySelectorAll('.journey-scene')];
const stepEls=[...document.querySelectorAll('.journey-steps>div')];
const journeyScreen=document.getElementById('journeyScreen');
const journeyMarkup=[
`<figure class="ref-shot journey-shot"><img src="assets/screen-communities.webp" alt="Destnly communities reference visual based on the approved mobile design"></figure>`,
`<figure class="ref-shot journey-shot"><img src="assets/screen-circle-feed.webp" alt="Anime Fan Club circle screen from Destnly"></figure>`,
`<figure class="ref-shot journey-shot"><img src="assets/screen-circle-media.webp" alt="Destnly mood board screen"></figure>`,
`<figure class="ref-shot journey-shot"><img src="assets/screen-onboarding.webp" alt="Meaningful matches reference visual"></figure>`
];
let activeJourney=-1,journeyPending=false;
function renderJourney(){journeyPending=false;if(!journey||!scenes.length)return;const rect=journey.getBoundingClientRect();const span=Math.max(1,journey.offsetHeight-window.innerHeight);const progress=Math.min(0.9999,Math.max(0,-rect.top/span));const next=Math.min(3,Math.floor(progress*4));if(next!==activeJourney){activeJourney=next;scenes.forEach((el,i)=>el.classList.toggle('active',i===next));journeyScreen.innerHTML=journeyMarkup[next];journey?.querySelector(".journey-phone")?.classList.toggle("tall-screen",next===0);journey?.querySelector(".journey-phone")?.classList.toggle("circle-screen",next===1);document.getElementById('journeyCount').textContent=String(next+1).padStart(2,'0')+' / 04'}document.getElementById('journeyProgress').style.width=((next+1)*25)+'%'}
function scheduleJourney(){if(journeyPending)return;journeyPending=true;requestAnimationFrame(renderJourney)}
if(journey){window.addEventListener('scroll',scheduleJourney,{passive:true});window.addEventListener('resize',scheduleJourney,{passive:true});renderJourney()}

// Product-led scroll narrative. IntersectionObserver avoids expensive continuous DOM updates.
const datingTemplates=[
`<figure class="ref-shot dating-shot"><img src="assets/screen-vibe.webp" alt="Show Your Vibe approved design reference"></figure>`,
`<figure class="ref-shot dating-shot"><img src="assets/screen-discover.webp" alt="Discover People approved design reference"></figure>`,
`<figure class="ref-shot dating-shot"><img src="assets/screen-buzz.webp" alt="Send a Buzz approved design reference"></figure>`,
`<figure class="ref-shot dating-shot"><img src="assets/screen-chat.webp" alt="Conversations reference visual"></figure>`
];
const datingDynamic=document.getElementById('datingDynamic');
const chapters=[...document.querySelectorAll('.dating-chapter')];
function setDating(i){if(datingDynamic&&datingDynamic.dataset.active!==String(i)){datingDynamic.innerHTML=datingTemplates[i];datingDynamic.dataset.active=String(i)}}
if(chapters.length){setDating(0);if('IntersectionObserver'in window){const io=new IntersectionObserver(es=>{const visible=es.filter(e=>e.isIntersecting).sort((a,b)=>b.intersectionRatio-a.intersectionRatio);if(visible.length)setDating(Number(visible[0].target.dataset.dating))},{rootMargin:'-22% 0px -22% 0px',threshold:[0,.2,.5,.8]});chapters.forEach(el=>io.observe(el))}}
const film=document.querySelector('.film-media');
if(film&&matchMedia('(min-width: 761px) and (prefers-reduced-motion: no-preference)').matches){let ticking=false;addEventListener('scroll',()=>{if(ticking)return;ticking=true;requestAnimationFrame(()=>{const r=film.parentElement.getBoundingClientRect();if(r.bottom>0&&r.top<innerHeight){const v=Math.max(-35,Math.min(35,(innerHeight/2-(r.top+r.height/2))*.07));film.style.transform=`scale(1.08) translate3d(0,${v}px,0)`}ticking=false})},{passive:true})}


// Atelier motion layer. One RAF loop for progress and pointer; no scroll-linked React rerenders.
(()=>{
  const reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;
  const coarse=matchMedia('(pointer: coarse)').matches;
  const progress=document.getElementById('siteProgress');
  const hero=document.querySelector('.hero');
  const tilt=document.querySelector('[data-tilt]');
  const halo=document.getElementById('cursorHalo');
  let px=-1000,py=-1000,tx=-1000,ty=-1000,frame=0,scrollDirty=true,pointerDirty=false;
  function tick(){frame=0;
    if(scrollDirty){scrollDirty=false;const max=Math.max(1,document.documentElement.scrollHeight-innerHeight);if(progress)progress.style.transform=`scaleX(${Math.max(0,Math.min(1,scrollY/max))})`;}
    if(pointerDirty&&!reduce&&!coarse){pointerDirty=false;tx+=(px-tx)*.15;ty+=(py-ty)*.15;if(halo)halo.style.transform=`translate3d(${tx-195}px,${ty-195}px,0)`;if(Math.abs(px-tx)+Math.abs(py-ty)>1){pointerDirty=true;request()}}
  }
  function request(){if(!frame)frame=requestAnimationFrame(tick)}
  addEventListener('scroll',()=>{scrollDirty=true;request()},{passive:true});addEventListener('resize',()=>{scrollDirty=true;request()},{passive:true});request();
  if(!reduce&&!coarse){addEventListener('pointermove',e=>{px=e.clientX;py=e.clientY;pointerDirty=true;request()},{passive:true});
    if(tilt&&hero){hero.addEventListener('pointermove',e=>{const r=tilt.getBoundingClientRect(),x=(e.clientX-r.left)/r.width-.5,y=(e.clientY-r.top)/r.height-.5;if(x<-.5||x>.5||y<-.5||y>.5)return;tilt.style.transform=`perspective(1200px) rotateY(${x*5}deg) rotateX(${-y*5}deg) translate3d(0,0,0)`},{passive:true});hero.addEventListener('pointerleave',()=>{tilt.style.transform=''})}
  }
})();

// Optional analytics bridge: emits useful events when a host analytics provider is present.
function destnlyTrack(event,details={}){
  if(typeof window.gtag==='function')window.gtag('event',event,details);
  else if(Array.isArray(window.dataLayer))window.dataLayer.push({event,...details});
  document.dispatchEvent(new CustomEvent('destnly:analytics',{detail:{event,...details}}));
}
const milestoneSection=document.querySelector('[data-milestone-section]');
if(milestoneSection&&'IntersectionObserver'in window){
  const milestoneObserver=new IntersectionObserver(entries=>{if(entries.some(entry=>entry.isIntersecting)){destnlyTrack('milestone_section_view',{milestone:'50k_downloads'});milestoneObserver.disconnect()}},{threshold:.35});
  milestoneObserver.observe(milestoneSection);
}
document.querySelector('[data-milestone-story]')?.addEventListener('click',()=>destnlyTrack('milestone_story_click',{milestone:'50k_downloads'}));
if(document.body.dataset.storyPage){destnlyTrack('story_view',{story:document.body.dataset.storyPage});}
document.querySelector('[data-story-download]')?.addEventListener('click',()=>destnlyTrack('story_download_click',{story:document.body.dataset.storyPage||'unknown'}));
const shareStory=document.querySelector('[data-share-story]');
shareStory?.addEventListener('click',async()=>{
  const status=document.querySelector('.story-share-status');
  const shareData={title:shareStory.dataset.shareTitle||document.title,url:location.href};
  try{
    if(navigator.share){await navigator.share(shareData);if(status)status.textContent='Shared.';}
    else if(navigator.clipboard){await navigator.clipboard.writeText(location.href);if(status)status.textContent='Link copied.';}
    else{throw new Error('Sharing is unavailable');}
    destnlyTrack('story_share',{story:document.body.dataset.storyPage||'unknown',method:navigator.share?'native':'clipboard'});
  }catch(error){if(error?.name!=='AbortError'&&status)status.textContent='Copy the link from your browser to share.';}
});
