// Mantém a ordem original de playlists e álbuns: sem shuffle, sem autoplay de sugestões.
// Se o YouTube mudar o DOM, ajuste só o objeto CONFIG abaixo.
(() => {
  if (window.__ytmOrderInit) return; // guard: não rodar duas vezes
  window.__ytmOrderInit = true;
  window.__ytmOrder = window.__ytmOrder || { enabled: true };

  const CONFIG = {
    playerBar: 'ytmusic-player-bar',
    shuffle: 'ytmusic-player-bar .shuffle',
    queue: 'ytmusic-player-queue',
    queueItem: 'ytmusic-player-queue-item',
    selectedAttr: 'selected',
    windowMs: 5000, // tempo para a faixa seguinte começar depois do 'ended'
  };

  let lastList = null; // playlist/álbum já tratada
  let snapshot = 0; // tamanho da fila quando a playlist começou
  let pending = null; // { expected, stop, at } definido no 'ended'

  const items = () => Array.from(document.querySelectorAll(`${CONFIG.queue} ${CONFIG.queueItem}`));
  const currentIndex = () => items().findIndex((i) => i.hasAttribute(CONFIG.selectedAttr));

  const shuffleOn = () => {
    const b = document.querySelector(CONFIG.shuffle);
    if (!b) return false;
    return b.getAttribute('aria-pressed') === 'true' || b.hasAttribute('active') || b.classList.contains('active');
  };

  // Nova playlist ou álbum: desliga o shuffle uma vez e guarda o tamanho original da fila.
  const onPlaying = () => {
    const o = window.__ytmOrder;
    if (!o.enabled) return;

    const list = new URL(location.href).searchParams.get('list');
    if (list && list !== lastList) {
      lastList = list;
      if (shuffleOn()) document.querySelector(CONFIG.shuffle).click();
      setTimeout(() => { snapshot = items().length; }, 1500);
    }

    if (!pending) return;
    const p = pending;
    pending = null;
    if (Date.now() - p.at > CONFIG.windowMs) return;

    const video = document.querySelector('video');
    if (p.stop) {
      // Acabou a playlist: pausa em vez de seguir para faixas sugeridas.
      if (video) video.pause();
      return;
    }
    // Faixa errada tocando (shuffle ou sugestão): clica no item esperado da fila.
    const list2 = items();
    if (currentIndex() !== p.expected && list2[p.expected]) list2[p.expected].click();
  };

  const onEnded = () => {
    const o = window.__ytmOrder;
    if (!o.enabled || !lastList) return;
    const idx = currentIndex();
    if (idx < 0) return;
    const expected = idx + 1;
    pending = { expected, stop: snapshot > 0 && expected >= snapshot, at: Date.now() };
  };

  try {
    // Eventos de mídia não borbulham; captura no document pega qualquer <video>.
    document.addEventListener('playing', (e) => { if (e.target.tagName === 'VIDEO') onPlaying(); }, true);
    document.addEventListener('ended', (e) => { if (e.target.tagName === 'VIDEO') onEnded(); }, true);
  } catch (e) {}
})();
