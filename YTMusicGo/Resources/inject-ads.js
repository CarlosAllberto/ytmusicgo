// Remove anúncios do YouTube Music: pula o anúncio em reprodução e esconde promoções.
// Se o YouTube mudar o DOM, ajuste só o objeto CONFIG abaixo.
(() => {
  if (window.__ytmAds) return; // guard: não rodar duas vezes
  window.__ytmAds = true;

  const CONFIG = {
    // Qualquer um destes presente no documento = anúncio tocando.
    adPlaying: [
      '#movie_player.ad-showing',
      '#movie_player.ad-interrupting',
      '.ad-showing',
      '.ad-interrupting',
      '.ytp-ad-player-overlay',
      '.ytp-ad-player-overlay-layout',
      'ytmusic-player-bar[is-advertisement]',
    ],
    skipButtons: ['.ytp-ad-skip-button', '.ytp-skip-ad-button', '.ytp-ad-skip-button-modern'],
    // Elementos de promoção removidos do DOM.
    promo: [
      'ytmusic-mealbar-promo-renderer',
      'ytmusic-statement-banner-renderer',
      'ytmusic-upsell-dialog-renderer',
      'ytmusic-premium-upsell-renderer',
    ],
    adRate: 16,
  };

  const adSel = CONFIG.adPlaying.join(',');
  const skipSel = CONFIG.skipButtons.join(',');
  const promoSel = CONFIG.promo.join(',');
  let saved = null; // estado do vídeo antes do anúncio
  let queued = false;

  const check = () => {
    queued = false;
    try {
      const video = document.querySelector('video');
      const adNow = !!document.querySelector(adSel);

      if (adNow && video) {
        if (!saved) saved = { muted: video.muted, rate: video.playbackRate };
        video.muted = true;
        video.playbackRate = CONFIG.adRate;
        if (isFinite(video.duration) && video.duration > 0) video.currentTime = video.duration;
        document.querySelectorAll(skipSel).forEach((b) => b.click());
      } else if (!adNow && saved && video) {
        video.muted = saved.muted;
        video.playbackRate = saved.rate;
        saved = null;
      }

      document.querySelectorAll(promoSel).forEach((el) => el.remove());
    } catch (e) {
      // nunca quebrar a página
    }
  };

  // Agrupa rajadas de mutações em uma checagem a cada 50 ms (rAF pausa com a janela oculta).
  const schedule = () => {
    if (queued) return;
    queued = true;
    setTimeout(check, 50);
  };

  try {
    new MutationObserver(schedule).observe(document, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class', 'is-advertisement'],
    });
  } catch (e) {}
})();
