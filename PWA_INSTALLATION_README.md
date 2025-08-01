# PWA Installation in Onboarding

This document describes the PWA (Progressive Web App) installation feature integrated into the onboarding process.

## Overview

The PWA installation feature has been added as **Step 6** of the onboarding process, allowing users to install the Javi app directly on their device during their first experience with the application.

## Features

### 1. **Automatic Detection**
- Detects if the app is installable on the user's device
- Shows appropriate UI based on installation availability
- Handles different browser capabilities gracefully

### 2. **Interactive Installation**
- One-click installation button when available
- Real-time feedback on installation status
- Success confirmation after installation

### 3. **Fallback Handling**
- Graceful degradation for unsupported browsers
- Clear messaging about compatibility requirements
- Option to skip installation and continue

## Implementation Details

### Files Modified

#### 1. **Onboarding Live View** (`lib/javi_web/live/onboarding/onboarding_live.ex`)
```elixir
# Added PWA-related assigns
|> assign(:pwa_installable, false)
|> assign(:pwa_installed, false)

# Added PWA event handlers
def handle_event("pwa_installable", %{"installable" => installable}, socket)
def handle_event("pwa_installed", _params, socket)
def handle_event("skip_pwa_install", _params, socket)
```

#### 2. **Onboarding Template** (`lib/javi_web/live/onboarding/onboarding_live.html.heex`)
- Added PWA installation UI for step 6
- Integrated JavaScript for PWA detection and installation
- Added skip option for users who don't want to install

#### 3. **PWA Controller** (`lib/javi_web/controllers/pwa_controller.ex`)
- Handles serving PWA static files
- Proper content-type headers for manifest and scripts

#### 4. **Router Updates** (`lib/javi_web/router.ex`)
- Added routes for PWA files
- Proper routing for manifest, service worker, and PWA script

### JavaScript Integration

The onboarding template includes JavaScript that:

1. **Listens for `beforeinstallprompt`** - Detects when the app is installable
2. **Handles `appinstalled`** - Confirms successful installation
3. **Manages install button** - Triggers the native install prompt
4. **Communicates with LiveView** - Updates the UI state in real-time

```javascript
// PWA Installation for Onboarding
document.addEventListener('DOMContentLoaded', function() {
  let deferredPrompt;
  
  // Listen for the beforeinstallprompt event
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    
    // Notify LiveView that PWA is installable
    if (window.liveSocket) {
      window.liveSocket.execJS(document, "pwa_installable", {installable: "true"});
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
});
```

## User Experience

### Step 6: App Installation

When users reach step 6 of onboarding, they see:

1. **Installation Benefits**
   - Offline access to their data
   - Faster loading times
   - Native app experience
   - Push notifications

2. **Installation Options**
   - **Install Button** (when available) - One-click installation
   - **Skip Option** - Continue without installing
   - **Success Message** - Confirmation after installation

3. **Fallback States**
   - **Not Available** - Clear messaging for unsupported browsers
   - **Already Installed** - Detection of existing installation

## Browser Compatibility

### Fully Supported
- Chrome (Desktop & Mobile)
- Edge (Desktop & Mobile)
- Firefox (Desktop & Mobile)
- Safari (iOS 11.3+)

### Partially Supported
- Samsung Internet
- UC Browser

### Not Supported
- Internet Explorer
- Older browsers without service worker support

## Installation Criteria

For the install prompt to appear, the app must meet these criteria:

1. **HTTPS Required** - Must be served over secure connection
2. **Valid Manifest** - Web app manifest must be properly configured
3. **Service Worker** - Must have a registered service worker
4. **User Engagement** - User must have interacted with the site
5. **Not Already Installed** - App must not already be installed

## Testing

### Manual Testing

1. **Start the server**: `mix phx.server`
2. **Navigate to onboarding**: Visit `/onboarding`
3. **Go to step 6**: Click through to the PWA installation step
4. **Test installation**: Click the install button if available
5. **Test skip functionality**: Use the skip button to continue

### Automated Testing

Run the PWA controller tests:
```bash
mix test test/javi_web/controllers/pwa_controller_test.exs
```

### Browser Dev Tools Testing

1. **Open Dev Tools** (F12)
2. **Go to Application tab**
3. **Check Manifest**: Verify manifest loads correctly
4. **Check Service Worker**: Verify SW is registered
5. **Test Install Prompt**: Use "Install" button in dev tools

## Configuration

### Customizing Installation Text

Edit the onboarding template to change:
- Installation benefits text
- Button labels
- Success/error messages

### Customizing Installation Behavior

Modify the JavaScript in the onboarding template to:
- Change installation trigger conditions
- Customize success/error handling
- Add additional installation steps

## Troubleshooting

### Common Issues

1. **Install button not showing**
   - Check if browser supports PWA
   - Verify HTTPS is enabled
   - Ensure manifest is valid
   - Check service worker registration

2. **Installation fails**
   - Check browser console for errors
   - Verify manifest file is accessible
   - Ensure all required icons exist

3. **Skip button not working**
   - Check LiveView connection
   - Verify event handler is registered
   - Check browser console for errors

### Debug Commands

```javascript
// Check if PWA is installable
navigator.serviceWorker.getRegistrations()

// Check manifest
fetch('/manifest.json').then(r => r.json()).then(console.log)

// Check if app is already installed
window.matchMedia('(display-mode: standalone)').matches
```

## Future Enhancements

1. **Analytics Integration** - Track installation rates
2. **A/B Testing** - Test different installation prompts
3. **Custom Installation Flow** - Multi-step installation process
4. **Installation Incentives** - Rewards for installing the app
5. **Cross-Platform Support** - Better iOS Safari support

## Security Considerations

1. **HTTPS Required** - PWA features only work over HTTPS
2. **Manifest Validation** - Browser validates manifest before installation
3. **Service Worker Scope** - SW only controls its scope
4. **User Consent** - Installation requires explicit user action

## Performance Impact

1. **Minimal Overhead** - PWA detection is lightweight
2. **Conditional Loading** - PWA scripts only load when needed
3. **Cached Resources** - Service worker improves performance
4. **Progressive Enhancement** - Works without PWA support

## Resources

- [MDN PWA Installation](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Installable_PWAs)
- [Web App Manifest](https://w3c.github.io/manifest/)
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [Before Install Prompt](https://developer.mozilla.org/en-US/docs/Web/API/BeforeInstallPromptEvent) 