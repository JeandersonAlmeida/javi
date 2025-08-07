// PWA Installation for Onboarding
document.addEventListener('DOMContentLoaded', function () {
    let deferredPrompt;

    // Listen for the beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (e) => {
        e.preventDefault();
        deferredPrompt = e;

        // Notify LiveView that PWA is installable
        if (window.liveSocket) {
            window.liveSocket.execJS(document, "pwa_installable", { installable: "true" });
        }
    });

    // Listen for the appinstalled event
    window.addEventListener('appinstalled', (evt) => {
        console.log('App was installed');

        // Notify LiveView that PWA was installed
        if (window.liveSocket) {
            window.liveSocket.execJS(document, "pwa_installed", {});
        }
    });

    // Handle install button click in onboarding
    document.addEventListener('click', function (e) {
        if (e.target.closest('#pwa-install-btn-onboarding')) {
            if (deferredPrompt) {
                deferredPrompt.prompt();
                deferredPrompt.userChoice.then((choiceResult) => {
                    if (choiceResult.outcome === 'accepted') {
                        console.log('User accepted the install prompt');
                    } else {
                        console.log('User dismissed the install prompt');
                    }
                    deferredPrompt = null;
                });
            }
        }
    });

    // Check if app is already installed
    if (window.matchMedia('(display-mode: standalone)').matches ||
        window.navigator.standalone === true) {
        if (window.liveSocket) {
            window.liveSocket.execJS(document, "pwa_installed", {});
        }
    }
}); 