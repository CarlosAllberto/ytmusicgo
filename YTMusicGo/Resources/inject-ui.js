// Ajustes de interface do YouTube Music: esconde elementos, carrossel de artistas inscritos,
// botões do cabeçalho do artista e página inicial ao reabrir o popover.
// Se o YouTube mudar o DOM, ajuste só o objeto CONFIG abaixo.
(() => {
  if (window.__ytmUi) return; // guard: não rodar duas vezes
  window.__ytmUi = true;

  const CONFIG = {
    // Sempre escondidos.
    hide: [
      '#guide-button', // menu hambúrguer
      'tp-yt-app-drawer#guide', // gaveta lateral que o botão abre
      'ytmusic-menu-service-item-download-renderer', // "Baixar" nos três pontinhos
      'tp-yt-paper-toast', // toasts, ex.: "Iniciando a rádio"
    ],
    // Escondidos só na página inicial (rota "/").
    homeHide: ['ytmusic-chip-cloud-renderer'], // chips Podcasts, Para treinar etc.
    hideMenuText: /^\s*(Baixar|Download)\s*$/i, // item de menu que não usa o renderer acima
    // Prateleira da página inicial é de vídeos se tiver miniatura 16:9 ou título assim.
    videoRatio: 'RECTANGLE_16_9',
    videoTitle: /v[ií]deo/i,
    hideShelfTitle: /^\s*Continuar ouvindo\s*$/i, // prateleira que também é removida da página inicial
    section: 'ytmusic-section-list-renderer',
    shelf: 'ytmusic-carousel-shelf-renderer',
    artistHeader: 'ytmusic-immersive-header-renderer',
    searchHide: [
      'ytmusic-tabbed-search-results-renderer ytmusic-tabs', // abas YT MUSIC e BIBLIOTECA
      'ytmusic-tabbed-search-results-renderer ytmusic-chip-cloud-renderer', // filtros Artistas, Músicas etc.
    ],
    searchCard: 'ytmusic-card-shelf-renderer', // resultado principal da busca
    cardRow: 'ytmusic-responsive-list-item-renderer',
    firstTrack: 'ytmusic-shelf-renderer ytmusic-responsive-list-item-renderer',
    player: 'ytmusic-app-layout',
    subsBrowseId: 'FEmusic_library_corpus_artists',
    subsTitle: 'Artistas inscritos',
    firstShelfTitle: /^\s*Escolha a dedo\s*$/i,
    topSongsTitle: /^\s*Top m[úu]sicas\s*$/i, // na página do artista, vem antes de Álbuns
    cardSize: 88, // largura dos cartões dos carrosseis, em px
    subsMaxAgeMs: 60000,
  };

  const css = `
    ${CONFIG.hide.join(',')} { display: none !important; }
    html[ytm-home] ${CONFIG.homeHide.join(`, html[ytm-home] `)} { display: none !important; }
    ${CONFIG.searchHide.join(',')} { display: none !important; }
    [ytm-hidden] { display: none !important; }
    /* A barra de navegação passa 2px da largura e gerava scroll lateral; carrosseis já rolam por setas. */
    html, body { overflow-x: clip !important; }
    ::-webkit-scrollbar:horizontal { display: none !important; height: 0 !important; }
    /* Esconde a logo quando a busca está aberta (aparecia um pedaço atrás do campo). */
    html[ytm-searching] ytmusic-nav-bar ytmusic-logo { visibility: hidden !important; }
    * { -webkit-user-select: none !important; user-select: none !important; }
    input, textarea { -webkit-user-select: text !important; user-select: text !important; }

    /* Escolha a dedo (início) e Top músicas (artista) sempre antes das outras prateleiras. */
    ${CONFIG.section} > #contents:has(> [ytm-first]) { display: flex; flex-direction: column; }
    [ytm-first] { order: -1; }

    /* Menos espaço entre prateleiras: 16 (margem) + 24 (carrossel) + 16 (cabeçalho) virou 8 + 16. */
    ${CONFIG.shelf} { margin-bottom: 0 !important; }
    ${CONFIG.shelf} ytmusic-carousel { margin-bottom: 8px !important; }

    /* Cartões menores: cerca de 4 por tela. */
    ${CONFIG.shelf} ytmusic-two-row-item-renderer { width: ${CONFIG.cardSize}px !important; }

    #ytm-subs { padding: 16px 0 8px; }
    #ytm-subs .head { display: flex; align-items: center; justify-content: space-between; margin: 0 8px 16px; }
    #ytm-subs h2 { margin: 0; font: 700 24px/28.8px "YouTube Sans", Roboto, Arial, sans-serif; color: #fff; }
    #ytm-subs .row { display: flex; gap: 12px; padding: 0 16px; overflow-x: auto; scrollbar-width: none; scroll-snap-type: x proximity; scroll-padding: 0 16px; }
    #ytm-subs .row::-webkit-scrollbar { display: none; }
    #ytm-subs .nav { display: flex; gap: 8px; }
    #ytm-subs .nav button { width: 34px; height: 34px; padding: 0; border-radius: 50%; border: 1px solid rgba(255,255,255,.3);
      background: transparent; color: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; }
    #ytm-subs .nav button::before { content: ""; width: 24px; height: 24px; background: currentColor;
      -webkit-mask: var(--ytm-chevron) center / contain no-repeat; mask: var(--ytm-chevron) center / contain no-repeat; }
    #ytm-subs .nav .prev::before { transform: scaleX(-1); }
    #ytm-subs .nav button:disabled { opacity: .3; cursor: default; }
    #ytm-subs .card { flex: none; width: ${CONFIG.cardSize}px; scroll-snap-align: start; text-align: center; color: #fff; text-decoration: none; cursor: pointer; }
    #ytm-subs img { width: ${CONFIG.cardSize}px; height: ${CONFIG.cardSize}px; border-radius: 50%; object-fit: cover; display: block; background: #222; }
    #ytm-subs .t { margin-top: 8px; font: 500 12px/14.4px Roboto, Arial, sans-serif; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    #ytm-subs .s { font: 400 12px/14.4px Roboto, Arial, sans-serif; color: rgba(255,255,255,.7); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

    ${CONFIG.artistHeader} .buttons { display: flex !important; flex-direction: row !important; flex-wrap: nowrap; justify-content: flex-start !important; align-items: center; gap: 8px; width: 100% !important; max-width: none !important; box-sizing: border-box; }
    ${CONFIG.artistHeader} .buttons .play-buttons { display: contents !important; }
    ${CONFIG.artistHeader} .buttons .ytm-start { order: 0; }
    ${CONFIG.artistHeader} .buttons .play-button { order: 1; }
    ${CONFIG.artistHeader} .buttons .radio-button { order: 2; }
    ${CONFIG.artistHeader} .buttons .subscribe { order: 3; margin: 0 0 0 auto !important; }
    ${CONFIG.artistHeader} .buttons .play-buttons > :not(.play-button):not(.radio-button) { order: 4; }
    ${CONFIG.artistHeader} .buttons .play-button, ${CONFIG.artistHeader} .buttons .radio-button { margin: 0 !important; }
    ${CONFIG.searchCard} #actions { gap: 8px !important; }
    ${CONFIG.searchCard} #actions > yt-button-renderer { flex: 1 1 0; min-width: 0; }
    ${CONFIG.searchCard} #actions .ytm-start { order: -1; flex: none; }
    ${CONFIG.searchCard} #actions yt-button-renderer button { width: 100%; background: transparent !important; color: #fff !important;
      border: 1px solid rgba(255,255,255,.3) !important; }
    .ytm-start { height: 36px; padding: 0 16px; border: 0; border-radius: 18px; background: #fff; color: #030303;
      font: 500 14px Roboto, Arial, sans-serif; cursor: pointer; flex: none; }
    ${CONFIG.artistHeader} .play-button button, ${CONFIG.artistHeader} .radio-button button {
      background: transparent !important; color: #fff !important; border: 1px solid rgba(255,255,255,.3) !important; }
    ${CONFIG.artistHeader} .subscribe button { width: 40px; min-width: 0; height: 36px; padding: 0 !important; border-radius: 18px;
      display: flex; align-items: center; justify-content: center; }
    /* Vermelho do YouTube na inscrição ainda não feita (o site usa um tom mais rosado, #f57). */
    ${CONFIG.artistHeader} .subscribe:not([is-subscribed]) button { color: #f00 !important; border-color: #f00 !important; }
    ${CONFIG.artistHeader} .subscribe .ytSpecButtonShapeNextButtonTextContent { display: none !important; }
    ${CONFIG.artistHeader} .subscribe button::before { content: ""; width: 22px; height: 22px; background: currentColor;
      -webkit-mask: var(--ytm-heart) center / contain no-repeat; mask: var(--ytm-heart) center / contain no-repeat; }
    ${CONFIG.artistHeader} .subscribe[is-subscribed] button::before { -webkit-mask-image: var(--ytm-check); mask-image: var(--ytm-check); }
    :root {
      --ytm-chevron: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path d='M9.4 6 8 7.4l4.6 4.6L8 16.6 9.4 18l6-6z'/></svg>");
      --ytm-heart: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path d='M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z'/></svg>");
      --ytm-check: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path d='M9 16.17 4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z'/></svg>");
    }
  `;

  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const isHome = () => location.pathname === '/';

  // Navega dentro do app (sem recarregar a página, senão a música para).
  const navigate = (endpoint) => {
    const app = $('ytmusic-app');
    if (app) app.dispatchEvent(new CustomEvent('yt-navigate', { detail: { endpoint }, bubbles: true, composed: true }));
  };
  const goHome = () => navigate({ browseEndpoint: { browseId: 'FEmusic_home' } });

  // Chama a API interna do site com a sessão logada (mesmo cabeçalho SAPISIDHASH que o app usa).
  const browse = async (browseId) => {
    const sap = (document.cookie.match(/SAPISID=([^;]+)/) || [])[1];
    if (!sap) return null;
    const ts = Math.floor(Date.now() / 1000);
    const digest = await crypto.subtle.digest('SHA-1', new TextEncoder().encode(`${ts} ${sap} ${location.origin}`));
    const hash = Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, '0')).join('');
    const r = await fetch('/youtubei/v1/browse?prettyPrint=false', {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `SAPISIDHASH ${ts}_${hash}`,
        'X-Origin': location.origin,
        'X-Goog-AuthUser': '0',
      },
      body: JSON.stringify({ context: window.ytcfg.get('INNERTUBE_CONTEXT'), browseId }),
    });
    return r.ok ? r.json() : null;
  };

  // Percorre o JSON e junta os itens de lista (artistas) da biblioteca.
  const collect = (node, out = []) => {
    if (node && typeof node === 'object') {
      const li = node.musicResponsiveListItemRenderer;
      if (li) {
        const col = (i) => ((li.flexColumns || [])[i] || {}).musicResponsiveListItemFlexColumnRenderer;
        const runs = (i) => (col(i) && col(i).text && col(i).text.runs) || [];
        const id = li.navigationEndpoint && li.navigationEndpoint.browseEndpoint && li.navigationEndpoint.browseEndpoint.browseId;
        const thumbs = (li.thumbnail && li.thumbnail.musicThumbnailRenderer && li.thumbnail.musicThumbnailRenderer.thumbnail.thumbnails) || [];
        const img = thumbs.length ? thumbs[thumbs.length - 1].url.replace(/=w\d+-h\d+/, '=w320-h320') : '';
        if (id) out.push({ id, img, title: runs(0).map((r) => r.text).join(''), sub: runs(1).map((r) => r.text).join('') });
      } else {
        for (const k in node) collect(node[k], out);
      }
    }
    return out;
  };

  let subs = null; // { at, items }
  let loading = false;
  const loadSubs = async () => {
    if (loading || (subs && Date.now() - subs.at < CONFIG.subsMaxAgeMs)) return;
    loading = true;
    try {
      const json = await browse(CONFIG.subsBrowseId);
      if (json) subs = { at: Date.now(), items: collect(json) };
    } catch (e) {}
    loading = false;
    schedule();
  };

  const renderSubs = (el) => {
    const items = subs ? subs.items : [];
    el.hidden = items.length === 0;
    const key = items.map((i) => i.id).join();
    if (el.dataset.key === key) return;
    el.dataset.key = key;
    el.textContent = '';
    const h = document.createElement('h2');
    h.textContent = CONFIG.subsTitle;
    const row = document.createElement('div');
    row.className = 'row';
    const mk = (cls, dir) => {
      const b = document.createElement('button');
      b.className = cls;
      b.setAttribute('aria-label', dir < 0 ? 'Anterior' : 'Próximo');
      b.addEventListener('click', () => row.scrollBy({ left: dir * row.clientWidth * 0.8, behavior: 'smooth' }));
      return b;
    };
    const prev = mk('prev', -1);
    const next = mk('next', 1);
    const nav = document.createElement('div');
    nav.className = 'nav';
    nav.append(prev, next);
    const head = document.createElement('div');
    head.className = 'head';
    head.append(h, nav);
    // Setas apagam nas pontas, como nas outras prateleiras.
    const sync = () => {
      prev.disabled = row.scrollLeft <= 1;
      next.disabled = row.scrollLeft + row.clientWidth >= row.scrollWidth - 1;
    };
    row.addEventListener('scroll', sync);
    for (const it of items) {
      const a = document.createElement('a');
      a.className = 'card';
      a.href = `/channel/${it.id}`;
      a.addEventListener('click', (e) => {
        e.preventDefault();
        navigate({
          browseEndpoint: {
            browseId: it.id,
            browseEndpointContextSupportedConfigs: { browseEndpointContextMusicConfig: { pageType: 'MUSIC_PAGE_TYPE_ARTIST' } },
          },
        });
      });
      const img = document.createElement('img');
      img.src = it.img;
      img.alt = '';
      const t = document.createElement('div');
      t.className = 't';
      t.textContent = it.title;
      const s = document.createElement('div');
      s.className = 's';
      s.textContent = it.sub;
      a.append(img, t, s);
      row.append(a);
    }
    el.append(head, row);
    setTimeout(sync, 100);
  };

  const homeSection = () => $$(CONFIG.section).find((e) => e.offsetParent !== null);

  // Busca aberta: na rota /search ou com o campo em foco.
  const updateSearching = () => {
    const box = $('ytmusic-search-box');
    const on = location.pathname.startsWith('/search') || (box && box.contains(document.activeElement));
    document.documentElement.toggleAttribute('ytm-searching', !!on);
  };

  let wasHome = false;
  const updateHome = () => {
    const home = isHome();
    // Voltou para o início (ex.: depois de inscrever ou cancelar): recarrega a lista de inscritos.
    if (home && !wasHome && subs) subs.at = 0;
    wasHome = home;
    document.documentElement.toggleAttribute('ytm-home', home);
    const own = $('#ytm-subs');
    if (!home) {
      // O site reaproveita o mesmo container para outras páginas.
      if (own) own.hidden = true;
      // E as prateleiras escondidas na início não podem vazar para outras páginas (elementos reaproveitados).
      $$(`${CONFIG.shelf}[ytm-hidden]`).forEach((sh) => sh.removeAttribute('ytm-hidden'));
      return;
    }
    loadSubs();

    const section = homeSection();
    if (section) {
      let el = $('#ytm-subs');
      if (!el) {
        el = document.createElement('div');
        el.id = 'ytm-subs';
        el.hidden = true;
      }
      if (el.nextElementSibling !== section) section.parentElement.insertBefore(el, section);
      renderSubs(el);
    }

    // Prateleiras de vídeos poluem a página inicial.
    for (const sh of $$(CONFIG.shelf)) {
      const title = ($('.title', sh) || {}).textContent || '';
      const hide = $(`ytmusic-two-row-item-renderer[aspect-ratio$="${CONFIG.videoRatio}"]`, sh) || CONFIG.videoTitle.test(title) || CONFIG.hideShelfTitle.test(title);
      sh.toggleAttribute('ytm-hidden', !!hide);
    }
  };

  // Artista: Iniciar primeiro, Aleatório e Mix secundários, inscrição só com ícone (CSS acima).
  const updateArtist = () => {
    const header = $(CONFIG.artistHeader);
    const bar = header && $('.buttons', header);
    if (!bar || $('.ytm-start', bar)) return;
    const b = document.createElement('button');
    b.className = 'ytm-start';
    b.textContent = 'Iniciar';
    b.addEventListener('click', () => {
      // Toca a primeira música da lista, na ordem original (sem aleatório).
      const row = $(CONFIG.firstTrack);
      const play = row && $('ytmusic-play-button-renderer', row);
      if (play) play.click();
    });
    bar.prepend(b);
  };

  // O site reaproveita os elementos das prateleiras entre páginas, então a marca é recalculada sempre.
  const updateFirst = () => {
    for (const sh of $$(`ytmusic-shelf-renderer, ${CONFIG.shelf}`)) {
      const title = ($('.title, h2', sh) || {}).textContent || '';
      sh.toggleAttribute('ytm-first', CONFIG.firstShelfTitle.test(title) || CONFIG.topSongsTitle.test(title));
    }
  };

  // Busca: Iniciar antes de Aleatório e Mix no resultado principal.
  const updateSearch = () => {
    for (const card of $$(CONFIG.searchCard)) {
      const bar = $('#actions', card);
      if (!bar || $('.ytm-start', bar) || $$('yt-button-renderer', bar).length < 2) continue;
      const b = document.createElement('button');
      b.className = 'ytm-start';
      b.textContent = 'Iniciar';
      b.addEventListener('click', () => {
        const play = $(`${CONFIG.cardRow} ytmusic-play-button-renderer`, card);
        if (play) play.click();
      });
      bar.prepend(b);
    }
  };

  const updateMenus = () => {
    for (const it of $$('ytmusic-menu-service-item-renderer, ytmusic-toggle-menu-service-item-renderer, ytmusic-menu-navigation-item-renderer')) {
      if (CONFIG.hideMenuText.test(it.textContent)) it.setAttribute('ytm-hidden', '');
    }
  };

  let queued = false;
  const run = () => {
    queued = false;
    try {
      updateHome();
      updateSearching();
      updateArtist();
      updateSearch();
      updateFirst();
      updateMenus();
    } catch (e) {
      // nunca quebrar a página
    }
  };
  const schedule = () => {
    if (queued) return;
    queued = true;
    setTimeout(run, 50);
  };

  // Abre a página do player: ela é a rota /watch, não dá para abrir por propriedade ou botão.
  // O site reinicia a faixa ao navegar, então devolvemos a posição anterior.
  const openPlayer = (video) => {
    const mp = $('#movie_player');
    const d = mp && mp.getVideoData && mp.getVideoData();
    if (!d || !d.video_id || location.pathname.startsWith('/watch')) return;
    const t = video.currentTime;
    const wasPaused = video.paused;
    navigate({ watchEndpoint: { videoId: d.video_id, playlistId: d.list || undefined } });
    let tries = 0;
    const timer = setInterval(() => {
      const v = $('video');
      if (v && v.currentTime + 2 < t) {
        v.currentTime = t;
        if (wasPaused) (mp.pauseVideo ? mp.pauseVideo() : v.pause()); // a navegação religa; pausar pelo player mantém o botão em sincronia
        clearInterval(timer);
      } else if (++tries > 20) {
        clearInterval(timer);
      }
    }, 200);
  };

  // O app chama isto ao abrir o popover: com faixa carregada (tocando ou pausada) = mostra o player; sem faixa = início.
  window.__ytmOnOpen = () => {
    try {
      if (subs) subs.at = 0; // reabrir o popover também atualiza os inscritos
      const v = $('video');
      if (v && v.currentSrc) openPlayer(v);
      else if (!isHome()) goHome();
    } catch (e) {}
  };

  try {
    const style = document.createElement('style');
    style.textContent = css;
    document.documentElement.append(style);
    new MutationObserver(schedule).observe(document, { childList: true, subtree: true });
    window.addEventListener('popstate', schedule);
    document.addEventListener('focusin', schedule);
    document.addEventListener('focusout', schedule);
    schedule();
  } catch (e) {}
})();
