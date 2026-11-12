// ===== NAV scroll =====
const nav = document.getElementById('main-nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 50);
  const sections = ['accueil','programme','speakers','partenaires','infos','faq'];
  let current = '';
  sections.forEach(id => {
    const el = document.getElementById(id);
    if (el && window.scrollY >= el.offsetTop - 120) current = id;
  });
  document.querySelectorAll('.site-nav__links a').forEach(a => {
    a.classList.toggle('active', a.getAttribute('href') === '#'+current);
  });
}, { passive: true });

// ===== Mobile burger =====
document.getElementById('burger-btn').addEventListener('click', function() {
  const links = document.getElementById('nav-links');
  const open = links.classList.toggle('open');
  this.setAttribute('aria-expanded', open);
});

// ===== Schedule tabs =====
function switchTab(id) {
  document.querySelectorAll('.tab').forEach(t => {
    t.classList.toggle('active', t.id === 'tab-'+id);
    t.setAttribute('aria-selected', t.id === 'tab-'+id);
  });
  document.querySelectorAll('.tab-panel').forEach(p => {
    p.classList.toggle('active', p.id === 'panel-'+id);
  });
}

// ===== FAQ accordion =====
function toggleFaq(btn) {
  const answer = btn.nextElementSibling;
  const expanded = btn.getAttribute('aria-expanded') === 'true';
  document.querySelectorAll('.faq-q').forEach(b => {
    b.setAttribute('aria-expanded', 'false');
    b.nextElementSibling.classList.remove('open');
  });
  if (!expanded) {
    btn.setAttribute('aria-expanded', 'true');
    answer.classList.add('open');
  }
}

// ===== Scroll reveal =====
const observer = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('visible'); observer.unobserve(e.target); }
  });
}, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });

document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
