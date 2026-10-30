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
      'ytmusic-player-page .fullscreen-button', // tela cheia sobre a capa
      'ytmusic-player .ytp-fullscreen-button',
      'ytmusic-player [aria-label*="tela inteira" i]',
      'ytmusic-player [title*="tela inteira" i]',
      'ytmusic-responsive-list-item-renderer ytmusic-like-button-renderer', // curtir e descurtir ao passar o dedo/mouse nas músicas
      'ytmusic-responsive-list-item-renderer ytmusic-menu-renderer', // três pontinhos das músicas
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
      'ytmusic-card-shelf-renderer #actions', // Aleatório e Mix no resultado principal
    ],
    cardRow: 'ytmusic-responsive-list-item-renderer',
    card: 'ytmusic-two-row-item-renderer',
    cardLinks: ['.title a', '.secondary-flex-columns a', '.fixed-columns a', '.subtitle a'], // título, artista e álbum dentro dos cards
    cardControls: 'a, button, input, yt-icon-button, ytmusic-play-button-renderer, ytmusic-menu-renderer, tp-yt-paper-checkbox', // o site já trata o toque nestes
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
    /* Voltar no topo das páginas de artista e de busca. */
    .ytm-back { position: fixed; top: 10px; left: 16px; z-index: 5000; width: 44px; height: 44px; padding: 0; border: 0; border-radius: 50%; background: rgba(255,255,255,.15); color: #fff; cursor: pointer; flex: none;
      display: flex; align-items: center; justify-content: center; }
    .ytm-back[hidden], html:not([ytm-search-page]):has(ytmusic-search-box[opened]) .ytm-back { display: none; }
    /* O botão fica fora do cabeçalho, por cima dele; a busca abre espaço à esquerda. */
    /* Com o campo vazio e sem foco o site recolhe a busca a um ícone, que fica no lugar original. */
    html[ytm-search-page] ytmusic-nav-bar ytmusic-search-box:has(input:focus, input:not(:placeholder-shown)) { transform: translateX(52px); width: calc(100vw - 84px) !important; max-width: none !important; }
    html[ytm-search-page]:has(ytmusic-search-box input:focus, ytmusic-search-box input:not(:placeholder-shown)) ytmusic-nav-bar .right-content { display: none !important; }
    .ytm-back::before { content: ""; width: 30px; height: 30px; background: currentColor; transform: scaleX(-1);
      -webkit-mask: var(--ytm-chevron) center / contain no-repeat; mask: var(--ytm-chevron) center / contain no-repeat; }
    /* Artista: cabeçalho só com o voltar. */
    html[ytm-artist] ytmusic-nav-bar ytmusic-logo, html[ytm-artist] ytmusic-nav-bar ytmusic-search-box,
    html[ytm-artist] ytmusic-nav-bar .center-content, html[ytm-artist] ytmusic-nav-bar .right-content { display: none !important; }
    /* Biblioteca em 3 colunas. */
    html[ytm-library] ytmusic-grid-renderer #items { display: grid !important; grid-template-columns: repeat(3, minmax(0, 1fr)) !important; gap: 16px 12px !important; }
    html[ytm-library] ytmusic-grid-renderer ${CONFIG.card} { width: auto !important; min-width: 0 !important; margin: 0 !important; }
    /* Sem ícone e escurecimento na miniatura da música, exceto na faixa atual (indicador de tocando). */
    ${[CONFIG.cardRow, CONFIG.card].map((c) => `${c}:not([play-button-state="playing"]):not([play-button-state="paused"]):not([play-button-state="loading"]) ytmusic-item-thumbnail-overlay-renderer`).join(',')} { display: none !important; }
    /* Círculo de hover e toque dos botões do site. */
    yt-interaction { display: none !important; }
    /* Links internos dos cards: o toque passa para o card e não há efeito de hover. */
    ${CONFIG.cardLinks.flatMap((l) => [`${CONFIG.cardRow} ${l}`, `${CONFIG.card} ${l}`]).join(',')} {
      pointer-events: none !important; text-decoration: none !important; color: inherit !important; }
    /* No iOS, sem cursor pointer o toque em elemento comum não gera click. */
    ${CONFIG.cardRow}, ${CONFIG.card} { cursor: pointer; }
    /* Voltar faixa na barra de baixo (ver updatePrev). */
    ytmusic-player-bar .ytm-prev { width: 40px !important; height: 40px !important; min-width: 40px; padding: 0; border: 0; background: transparent;
      color: #fff; cursor: pointer; flex: none; position: static !important; opacity: 1 !important; visibility: visible !important;
      display: flex !important; align-items: center; justify-content: center; }
    .ytm-prev::before { content: ""; width: 32px; height: 32px; background: currentColor;
      -webkit-mask: var(--ytm-prev) center / contain no-repeat; mask: var(--ytm-prev) center / contain no-repeat; }
    /* Início: cabeçalho sempre preto (o site só escurece o fundo depois de rolar). */
    html[ytm-home] ${CONFIG.player} #nav-bar-background { opacity: 1 !important; background: #000 !important; }
    html[ytm-home] ytmusic-nav-bar { background: #000 !important; }
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
      --ytm-prev: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path d='M6 6h2v12H6zm3.5 6 8.5 6V6z'/></svg>");
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

  // Toca a faixa pelo endpoint do botão de play do site. Clique sintético não dispara o tap do Polymer
  // quando a página recebeu toque real (ele ignora "mouse" por um tempo), então só serve de reserva.
  const playRow = (play) => {
    if (!play) return;
    const ep = play.data && play.data.playNavigationEndpoint;
    if (ep) navigate(ep);
    else play.dispatchEvent(new MouseEvent('click', { bubbles: false }));
  };

  // Card inteiro clicável: no celular é difícil acertar só o título.
  const openCard = (e) => {
    const card = e.target.closest(`${CONFIG.cardRow}, ${CONFIG.card}`);
    if (!card || e.target.closest(CONFIG.cardControls)) return;
    const ep = card.data && card.data.navigationEndpoint;
    const link = $('a[href]', card);
    if (ep) navigate(ep);
    else if (card.matches(CONFIG.cardRow)) playRow($('ytmusic-play-button-renderer', card));
    else if (link) link.click();
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
    document.documentElement.toggleAttribute('ytm-library', location.pathname.startsWith('/library'));
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
      playRow(row && $('ytmusic-play-button-renderer', row));
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

  // Na barra de baixo o site esconde .left-controls-buttons; o play que aparece é outro elemento.
  const updatePrev = () => {
    const bar = $('ytmusic-player-bar:not(#top-player-bar)');
    const play = bar && $$('.play-pause-button', bar).find((e) => e.offsetWidth > 0);
    if (!play || (play.previousElementSibling && play.previousElementSibling.matches('.ytm-prev'))) return;
    let b = $('.ytm-prev', bar);
    if (!b) {
      b = document.createElement('button');
      b.className = 'ytm-prev';
      b.setAttribute('aria-label', 'Anterior');
      b.addEventListener('click', () => {
        const mp = $('#movie_player');
        if (mp && mp.previousVideo) mp.previousVideo();
      });
    }
    play.before(b);
  };

  // Rota e estado do player: a tab bar nativa destaca a aba atual e some com o player aberto.
  const tabsKey = () => `${location.pathname}|${!!$('ytmusic-player-bar[player-page-open]')}`;
  let lastTabs = '';
  const updateTabs = () => {
    const key = tabsKey();
    const h = window.webkit && window.webkit.messageHandlers.ytmTabs;
    if (!h || key === lastTabs) return;
    lastTabs = key;
    const [path, open] = key.split('|');
    h.postMessage({ path, playerOpen: open === 'true' });
  };
  window.__ytmTab = (browseId) => navigate({ browseEndpoint: { browseId } });

  const updateBack = () => {
    let b = $('.ytm-back');
    if (!b) {
      b = document.createElement('button');
      b.className = 'ytm-back';
      b.setAttribute('aria-label', 'Voltar');
      b.addEventListener('click', () => history.back());
      document.body.append(b);
    }
    // A rota do artista pode ser /channel/ ou /browse/, então vale também o cabeçalho visível.
    const header = $(CONFIG.artistHeader);
    const artistHeader = header && header.offsetParent !== null && $('.subscribe', header);
    // Com o player aberto a rota é /watch, mas o cabeçalho do artista segue visível por baixo.
    const artist = location.pathname.startsWith('/channel/') || (!!artistHeader && !location.pathname.startsWith('/watch'));
    const search = location.pathname.startsWith('/search');
    b.hidden = !artist && !search;
    document.documentElement.toggleAttribute('ytm-artist', artist);
    document.documentElement.toggleAttribute('ytm-search-page', search);
  };

  // No toque o hover fica preso no último item tocado: tira as regras :hover do CSS do site.
  // shortcut: folhas de outra origem não podem ser lidas e ficam de fora, tratar caso a caso se algum hover restar.
  const hoverDone = new WeakMap(); // folha -> nº de regras já limpas; o site adiciona regras com o tempo
  const stripHover = (group) => {
    for (let i = group.cssRules.length - 1; i >= 0; i--) {
      const rule = group.cssRules[i];
      if (rule.cssRules && rule.cssRules.length) stripHover(rule);
      if (!rule.selectorText || !rule.selectorText.includes(':hover')) continue;
      const keep = rule.selectorText.split(',').filter((sel) => !sel.includes(':hover'));
      if (keep.length) rule.selectorText = keep.join(',');
      else group.deleteRule(i);
    }
  };
  const removeHover = () => {
    for (const sheet of document.styleSheets) {
      try {
        if (hoverDone.get(sheet) === sheet.cssRules.length) continue;
        stripHover(sheet);
        hoverDone.set(sheet, sheet.cssRules.length);
      } catch (e) {} // folha de outra origem
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
      updateFirst();
      updateMenus();
      updatePrev();
      updateTabs();
      updateBack();
      removeHover();
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
      // Logo após o `emptied` a fonte ainda está vazia (readyState 0) e o seek seria descartado.
      if (v && v.readyState >= 1 && v.currentTime + 2 < t) {
        v.currentTime = t;
        if (wasPaused) (mp.pauseVideo ? mp.pauseVideo() : v.pause()); // a navegação religa; pausar pelo player mantém o botão em sincronia
      }
      // Só para quando a posição foi confirmada (ou no limite de tentativas).
      if ((v && v.readyState >= 1 && v.currentTime + 2 >= t) || ++tries > 20) clearInterval(timer);
    }, 200);
  };

  // O app chama isto ao abrir o popover: com faixa carregada (tocando ou pausada) = mostra o player; sem faixa = início.
  window.__ytmOnOpen = () => {
    try {
      run(); // antes de tudo: o atributo ytm-home pode estar desatualizado
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
    document.addEventListener('click', openCard, true);
    document.addEventListener('visibilitychange', schedule);
    // O site troca de página reaproveitando elementos (só atributos mudam), então o observer não vê a rota mudar.
    let lastPath = tabsKey();
    setInterval(() => {
      if (tabsKey() !== lastPath) {
        lastPath = tabsKey();
        schedule();
      }
    }, 300);
    document.addEventListener('focusin', schedule);
    document.addEventListener('focusout', schedule);
    schedule();
  } catch (e) {}
})();
