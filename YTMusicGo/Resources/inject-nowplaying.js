// Envia ao app a faixa atual (título, artista, capa e se está tocando) para o widget da tela inicial,
// e expõe window.__ytmToggle() para o botão de tocar/pausar do widget.
(() => {
  if (window.__ytmNowPlaying) return; // guard: não rodar duas vezes
  window.__ytmNowPlaying = true;

  const CONFIG = {
    playPause: 'ytmusic-player-bar #play-pause-button',
    // Plano B quando a mediaSession ainda não tem dados.
    title: 'ytmusic-player-bar .title',
    byline: 'ytmusic-player-bar .byline',
    thumb: 'ytmusic-player-bar .thumbnail img, ytmusic-player-bar img.image',
    pollMs: 1000,
  };

  const $ = (s) => document.querySelector(s);

  const read = () => {
    const v = $('video');
    const md = navigator.mediaSession && navigator.mediaSession.metadata;
    const art = md && md.artwork && md.artwork.length ? md.artwork[md.artwork.length - 1].src : null;
    const img = $(CONFIG.thumb);
    return {
      title: (md && md.title) || ($(CONFIG.title) || {}).textContent?.trim() || '',
      artist: (md && md.artist) || ($(CONFIG.byline) || {}).textContent?.split('•')[0].trim() || '',
      artwork: art || (img && img.src) || null,
      playing: !!v && !v.paused && !v.ended,
    };
  };

  let last = '';
  const send = () => {
    const h = window.webkit && window.webkit.messageHandlers.ytmNowPlaying;
    if (!h) return;
    const np = read();
    if (!np.title) return;
    const key = JSON.stringify(np);
    if (key === last) return;
    last = key;
    h.postMessage(np);
  };

  window.__ytmToggle = () => {
    const b = $(CONFIG.playPause);
    if (b) b.click();
    else {
      const v = $('video');
      if (v) v.paused ? v.play() : v.pause();
    }
    setTimeout(send, 300);
  };

  // Eventos de mídia não borbulham; captura no document pega qualquer <video>.
  for (const e of ['play', 'pause', 'ended', 'loadedmetadata']) document.addEventListener(e, () => setTimeout(send, 200), true);
  setInterval(send, CONFIG.pollMs);
})();
