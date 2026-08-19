(function () {
  var shots = Array.from(document.querySelectorAll('#galleryGrid .gallery-thumb'));

  var lightbox = document.getElementById('lightbox');
  var lightboxImg = document.getElementById('lightboxImg');
  var lightboxCaption = document.getElementById('lightboxCaption');
  var closeBtn = document.getElementById('lightboxClose');
  var prevBtn = document.getElementById('lightboxPrev');
  var nextBtn = document.getElementById('lightboxNext');
  var current = 0;

  function open(index) {
    current = index;
    var shot = shots[current];
    lightboxImg.src = shot.src;
    lightboxImg.alt = shot.alt;
    lightboxCaption.textContent = shot.alt;
    lightbox.classList.add('open');
    lightbox.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
  }

  function close() {
    lightbox.classList.remove('open');
    lightbox.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
  }

  function step(delta) {
    current = (current + delta + shots.length) % shots.length;
    open(current);
  }

  document.querySelectorAll('[data-shot]').forEach(function (el) {
    el.addEventListener('click', function () {
      var index = parseInt(el.getAttribute('data-shot'), 10);
      open(index);
    });
  });

  closeBtn.addEventListener('click', close);
  prevBtn.addEventListener('click', function () { step(-1); });
  nextBtn.addEventListener('click', function () { step(1); });

  lightbox.addEventListener('click', function (e) {
    if (e.target === lightbox) close();
  });

  document.addEventListener('keydown', function (e) {
    if (!lightbox.classList.contains('open')) return;
    if (e.key === 'Escape') close();
    if (e.key === 'ArrowLeft') step(-1);
    if (e.key === 'ArrowRight') step(1);
  });

  var navToggle = document.getElementById('navToggle');
  var siteNav = document.querySelector('.site-nav');
  navToggle.addEventListener('click', function () {
    var isOpen = siteNav.classList.toggle('nav-open');
    navToggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
  });
})();
