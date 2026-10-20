"""Build a standalone local demo without hosted links, accounts or remote resources."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / 'outputs' / 'WaitLess_Test_Prive.html'
html = (ROOT / 'index.html').read_text()
html = html.replace('<title>WaitLess — Global Edition</title>', '<title>WaitLess — Test privé</title>')
html = re.sub(r'<link\b[^>]*>', '', html)
html = html.replace('GLOBAL • PROTOTYPE', 'TEST PRIVÉ • DÉMO LOCALE')
html = re.sub(r'<a\b[^>]*href="online.html"[^>]*>.*?</a>', '', html)
html = re.sub(r'<button\b[^>]*data-go="reports"[^>]*>.*?</button>', '', html)
html = re.sub(r'<section class="screen" id="reports">.*?</section>', '', html, flags=re.S)
html = html.replace('<main>', '<main><div class="notice"><b>Test privé sur cet appareil.</b> Ce fichier fonctionne sans Internet, sans compte et sans paiement. Il ne partage aucune file avec d’autres téléphones. Pour conserver tes essais, utilise « Entreprises → Exporter les données ». Si le navigateur refuse le stockage local, les essais restent disponibles seulement jusqu’à la fermeture de la page.</div>', 1)
html = html.replace("const KEY='waitless_global_demo_v1';", "const KEY='waitless_private_demo_v1';")
html = html.replace("'waitless_global_lang'", "'waitless_private_lang'")
# Local-file viewers may deny persistent storage. Fall back to memory without stopping the demo.
html = html.replace('localStorage.', 'localStore.')
storage = '''<script>
const localStore = (() => {
  const memory = new Map();
  return {
    getItem(key) { try { return window.localStorage.getItem(key); } catch { return memory.get(key) ?? null; } },
    setItem(key, value) { memory.set(key, String(value)); try { window.localStorage.setItem(key, value); } catch {} }
  };
})();
</script>'''
html = html.replace('<script>', storage + '\n<script>', 1)
guide = (ROOT / 'test-guide.js').read_text()
guide = guide.replace('<a class="btn mint" id="test-guide-share" target="_blank" rel="noopener noreferrer" style="text-decoration:none"></a>', '')
guide = guide.replace('<details style="margin-top:18px"><summary id="test-guide-install" style="cursor:pointer;font-weight:700"></summary><p class="sub" id="test-guide-install-help"></p></details>', '')
guide = re.sub(r'<a class="btn outline" id="test-guide-new-demo".*?</a>', '', guide)
guide = re.sub(r'    const share = .*?    section.querySelector\(\'#test-guide-install-help\'\).textContent = text\[8\];\n', '', guide, flags=re.S)
html = html.replace('<script src="test-guide.js" defer></script>', '<script>\n' + guide + '\n</script>')
csp = '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'; script-src \'unsafe-inline\'; style-src \'unsafe-inline\'; img-src data: blob:; connect-src \'none\'; frame-src \'none\'; base-uri \'none\'; form-action \'none\'">'
html = html.replace('<meta charset="utf-8">', '<meta charset="utf-8">\n' + csp)
assert not re.search(r'<(?:iframe|script|link)\b[^>]*(?:src|href)=', html)
assert not re.search(r'<a\b[^>]*href="https?://', html)
OUT.parent.mkdir(exist_ok=True)
OUT.write_text(html)
print(OUT)
