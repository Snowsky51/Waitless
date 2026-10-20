(() => {
  'use strict';
  const copy = {
    fr: ['Tester WaitLess en 2 minutes', 'Une démonstration gratuite, sans inscription ni paiement. Les tickets restent sur cet appareil.', 'Choisis un établissement et prends un ticket.', 'Ouvre « Entreprises », puis appelle le suivant et termine le service.', 'Reviens dans « Mes tickets » pour vérifier son statut.', 'Commencer le test', 'Partager sur WhatsApp', 'Ajouter à mon écran d’accueil', 'Sur Android : ouvre ce lien dans Chrome, puis le menu ⋮ et « Ajouter à l’écran d’accueil » ou « Installer l’application ». Sur iPhone : ouvre-le dans Safari, puis Partager et « Sur l’écran d’accueil ». Une connexion Internet reste nécessaire.', 'Teste gratuitement WaitLess, ma démonstration de gestion de files d’attente. Sans compte ni paiement. Essaie un ticket, puis le tableau de bord entreprise, et dis-moi ce qui est clair ou ce qui bloque !'],
    en: ['Try WaitLess in 2 minutes', 'A free demo, with no account or payment. Tickets stay on this device.', 'Choose a venue and take a ticket.', 'Open “Businesses”, call the next customer and complete the service.', 'Return to “My tickets” to check the status.', 'Start the test', 'Share on WhatsApp', 'Add to my home screen', 'Android: open this link in Chrome, then use the ⋮ menu and “Add to Home screen” or “Install app”. iPhone: open it in Safari, then Share and “Add to Home Screen”. An Internet connection is still required.', 'Try WaitLess, my free queue-management demo. No account or payment. Take a ticket, try the business dashboard, and tell me what works or what is confusing!'],
    es: ['Prueba WaitLess en 2 minutos', 'Demostración gratuita, sin registro ni pago. Los tickets se guardan en este dispositivo.', 'Elige un establecimiento y toma un ticket.', 'Abre « Empresas », llama al siguiente y completa el servicio.', 'Vuelve a « Mis tickets » para comprobar su estado.', 'Empezar la prueba', 'Compartir en WhatsApp', 'Añadir a mi pantalla de inicio', 'Android: abre el enlace en Chrome, menú ⋮ y « Añadir a pantalla de inicio » o « Instalar aplicación ». iPhone: Safari, Compartir y « Añadir a pantalla de inicio ». Se necesita conexión a Internet.', 'Prueba WaitLess, mi demostración gratuita para gestionar colas. Sin cuenta ni pago. Prueba un ticket y el panel de empresa, ¡y dime qué mejorarías!'],
    pt: ['Teste o WaitLess em 2 minutos', 'Demonstração gratuita, sem cadastro nem pagamento. As senhas ficam neste dispositivo.', 'Escolha um estabelecimento e retire uma senha.', 'Abra « Empresas », chame o próximo e conclua o atendimento.', 'Volte a « Minhas senhas » para conferir o status.', 'Começar o teste', 'Compartilhar no WhatsApp', 'Adicionar à tela inicial', 'Android: abra no Chrome, menu ⋮ e « Adicionar à tela inicial » ou « Instalar aplicativo ». iPhone: Safari, Compartilhar e « Adicionar à Tela de Início ». É necessária uma conexão à Internet.', 'Teste o WaitLess, minha demonstração gratuita de gestão de filas. Sem conta nem pagamento. Experimente uma senha e o painel da empresa e conte o que podemos melhorar!'],
    de: ['WaitLess in 2 Minuten testen', 'Kostenlose Demo ohne Konto oder Zahlung. Tickets bleiben auf diesem Gerät.', 'Wähle einen Betrieb und ziehe ein Ticket.', 'Öffne „Unternehmen“, rufe den nächsten Kunden auf und beende den Service.', 'Prüfe den Status unter „Meine Tickets“.', 'Test starten', 'Auf WhatsApp teilen', 'Zum Startbildschirm hinzufügen', 'Android: Link in Chrome öffnen, Menü ⋮ und „Zum Startbildschirm hinzufügen“ oder „App installieren“. iPhone: Safari, Teilen und „Zum Home-Bildschirm“. Eine Internetverbindung bleibt erforderlich.', 'Teste WaitLess, meine kostenlose Warteschlangen-Demo. Ohne Konto oder Zahlung. Probiere ein Ticket und die Unternehmensansicht aus und gib mir dein Feedback!'],
    it: ['Prova WaitLess in 2 minuti', 'Demo gratuita, senza account né pagamenti. I ticket restano su questo dispositivo.', 'Scegli un locale e prendi un ticket.', 'Apri « Aziende », chiama il prossimo e completa il servizio.', 'Torna a « I miei ticket » per controllare lo stato.', 'Inizia il test', 'Condividi su WhatsApp', 'Aggiungi alla schermata Home', 'Android: apri il link in Chrome, menu ⋮ e « Aggiungi a schermata Home » o « Installa app ». iPhone: Safari, Condividi e « Aggiungi alla schermata Home ». Serve una connessione Internet.', 'Prova WaitLess, la mia demo gratuita per gestire le code. Senza account né pagamenti. Prova un ticket e il pannello aziendale e dimmi cosa miglioreresti!']
  };
  const main = document.querySelector('main');
  const language = document.getElementById('language');
  if (!main || !language) return;
  const section = document.createElement('section');
  section.className = 'card';
  section.setAttribute('aria-labelledby', 'test-guide-title');
  section.style.marginBottom = '22px';
  section.innerHTML = '<h2 id="test-guide-title" style="margin-top:0;font-size:22px"></h2><p class="sub" id="test-guide-intro"></p><ol class="sub" style="line-height:1.8;padding-left:22px"><li></li><li></li><li></li></ol><div style="display:flex;gap:10px;flex-wrap:wrap"><button type="button" class="btn primary" data-go="explore" id="test-guide-start"></button><a class="btn outline" id="test-guide-new-demo" href="demo.html" style="text-decoration:none"></a><a class="btn mint" id="test-guide-share" target="_blank" rel="noopener noreferrer" style="text-decoration:none"></a></div><details style="margin-top:18px"><summary id="test-guide-install" style="cursor:pointer;font-weight:700"></summary><p class="sub" id="test-guide-install-help"></p></details>';
  main.insertBefore(section, main.querySelector('.tabs'));
  function update() {
    const text = copy[language.value] || copy.en;
    const demoLink = section.querySelector('#test-guide-new-demo');
    if (demoLink) demoLink.textContent = ({fr:'Essayer les nouvelles fonctions',en:'Try the new features',es:'Probar las nuevas funciones',pt:'Testar os novos recursos',de:'Neue Funktionen testen',it:'Prova le nuove funzioni'})[language.value] || 'Try the new features';
    section.querySelector('#test-guide-title').textContent = text[0];
    section.querySelector('#test-guide-intro').textContent = text[1];
    section.querySelectorAll('li').forEach((item, i) => { item.textContent = text[i + 2]; });
    section.querySelector('#test-guide-start').textContent = text[5];
    const share = section.querySelector('#test-guide-share');
    share.textContent = text[6];
    // Only a public URL is shared; never include local tickets or account data.
    share.href = 'https://wa.me/?text=' + encodeURIComponent(text[9] + '\nhttps://voluble-pie-7e8eda.netlify.app/');
    section.querySelector('#test-guide-install').textContent = text[7];
    section.querySelector('#test-guide-install-help').textContent = text[8];
  }
  language.addEventListener('change', update);
  update();
})();
