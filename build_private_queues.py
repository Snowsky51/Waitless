"""Standalone role-based preview; no deployment, real account or external requests."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parent
html=(ROOT/'online.html').read_text()
html=html.replace('WaitLess — Files partagées','WaitLess — Test privé des files')
html=re.sub(r'<p><a href="index.html".*?</a></p>','',html)
html=html.replace('<p class="muted" data-t="refreshHelp">','<p hidden class="muted" data-t="refreshHelp">')
html=html.replace('<button id="logout" class="secondary"','<button hidden id="logout" class="secondary"')
html=re.sub(r'<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.118.0"></script>','',html)
html=html.replace('<script src="qrcode.js"></script>','<script>\n'+(ROOT/'qrcode.js').read_text()+'\n</script>\n<script>\n'+(ROOT/'private-queues-adapter.js').read_text()+'\n</script>')
html=html.replace('<script src="shared-queues.js"></script>','<script>\n'+(ROOT/'shared-queues.js').read_text()+'\n</script>')
# Block requests even if the file is opened while connected to the Internet.
csp="<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; connect-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none'\">"
html=html.replace('<meta charset="utf-8">','<meta charset="utf-8">'+csp)
assert not re.search(r'<script\b[^>]*src=',html)
assert not re.search(r'<(?:iframe|link)\b',html)
out=ROOT.parent/'outputs'/'WaitLess_Files_Test_Prive.html';out.parent.mkdir(exist_ok=True);out.write_text(html);print(out)
