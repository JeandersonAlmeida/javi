# Progressive Web App (PWA) Setup

This document describes the PWA configuration for the Javi application.

## Overview

The Javi application has been configured as a Progressive Web App (PWA) with the following features:

- **Web App Manifest**: Defines app metadata, icons, and behavior
- **Service Worker**: Provides offline functionality and caching
- **Install Prompt**: Allows users to install the app on their device
- **Push Notifications**: Support for push notifications (when implemented)
- **Responsive Design**: Optimized for all device sizes

## Files Structure

```
priv/static/
├── manifest.json          # Web app manifest
├── sw.js                  # Service worker
├── pwa.js                 # PWA management script
└── images/
    ├── icon-72x72.png     # App icons (various sizes)
    ├── icon-96x96.png
    ├── icon-128x128.png
    ├── icon-144x144.png
    ├── icon-152x152.png
    ├── icon-167x167.png
    ├── icon-180x180.png
    ├── icon-192x192.png
    ├── icon-384x384.png
    └── icon-512x512.png

lib/javi_web/
├── pwa.ex                 # PWA configuration module
└── components/
    └── pwa_install_component.ex  # PWA install component
```

## Features

### 1. Web App Manifest (`manifest.json`)

- **App Name**: "Javi - Your Entertainment Companion"
- **Display Mode**: Standalone (runs like a native app)
- **Theme Color**: Purple gradient (#8b5cf6)
- **Background Color**: Dark slate (#0f172a)
- **Orientation**: Portrait primary
- **Icons**: Multiple sizes for different devices
- **Shortcuts**: Quick access to Dashboard, Search, and Lists
- **Screenshots**: App previews for app stores

### 2. Service Worker (`sw.js`)

- **Caching Strategy**: Cache-first for static assets
- **Offline Support**: Serves cached content when offline
- **Background Sync**: Framework for offline actions
- **Push Notifications**: Support for push notifications
- **Update Management**: Automatic cache updates

### 3. PWA Management (`pwa.js`)

- **Install Prompt**: Shows install button when app is installable
- **Update Notifications**: Notifies users of app updates
- **Service Worker Registration**: Handles SW lifecycle
- **Standalone Detection**: Detects if app is running in standalone mode

### 4. PWA Configuration Module (`pwa.ex`)

- **Centralized Configuration**: All PWA settings in one place
- **Meta Tags**: Generates proper meta tags for different platforms
- **Link Tags**: Generates proper link tags for icons and manifest
- **Manifest Generation**: Programmatic manifest generation

## Installation

### For Users

1. **Visit the app** in a supported browser (Chrome, Edge, Firefox, Safari)
2. **Look for the install prompt** (usually in the address bar or as a floating button)
3. **Click "Install"** to add the app to your device
4. **Launch the app** from your device's app launcher

### For Developers

1. **Clone the repository**
2. **Install dependencies**: `mix deps.get`
3. **Start the server**: `mix phx.server`
4. **Visit the app** at `http://localhost:4000`
5. **Test PWA features** using browser dev tools

## Testing PWA Features

### Browser Dev Tools

1. **Open Dev Tools** (F12)
2. **Go to Application tab**
3. **Check Manifest**: Verify manifest is loaded correctly
4. **Check Service Worker**: Verify SW is registered and active
5. **Test Offline**: Use "Offline" checkbox to test offline functionality

### Lighthouse Audit

1. **Open Dev Tools** (F12)
2. **Go to Lighthouse tab**
3. **Run PWA audit** to check PWA compliance
4. **Review results** and fix any issues

## Configuration

### Customizing the Manifest

Edit `priv/static/manifest.json` to customize:

- App name and description
- Colors and theme
- Icons and screenshots
- Shortcuts and categories

### Customizing the Service Worker

Edit `priv/static/sw.js` to customize:

- Caching strategy
- Offline behavior
- Push notification handling
- Background sync logic

### Customizing PWA Management

Edit `priv/static/pwa.js` to customize:

- Install prompt behavior
- Update notifications
- Service worker registration
- Standalone detection

## Browser Support

### Fully Supported
- Chrome (Desktop & Mobile)
- Edge (Desktop & Mobile)
- Firefox (Desktop & Mobile)
- Safari (iOS & macOS)

### Partially Supported
- Samsung Internet
- UC Browser

### Not Supported
- Internet Explorer
- Older browsers without service worker support

## Performance Benefits

1. **Faster Loading**: Cached assets load instantly
2. **Offline Access**: App works without internet connection
3. **Reduced Data Usage**: Assets are cached locally
4. **Native-like Experience**: Runs like a native app
5. **Automatic Updates**: Updates are handled seamlessly

## Security Considerations

1. **HTTPS Required**: PWA features only work over HTTPS
2. **Service Worker Scope**: SW only controls its scope
3. **Manifest Validation**: Browser validates manifest before installation
4. **Permission Handling**: Notifications require user permission

## Troubleshooting

### Common Issues

1. **Install prompt not showing**
   - Ensure app meets installability criteria
   - Check that service worker is registered
   - Verify manifest is valid

2. **Offline functionality not working**
   - Check service worker registration
   - Verify cache is populated
   - Check browser console for errors

3. **Icons not displaying**
   - Verify icon files exist
   - Check icon paths in manifest
   - Ensure icons are proper PNG format

### Debug Commands

```bash
# Check if service worker is registered
navigator.serviceWorker.getRegistrations()

# Check cache contents
caches.keys().then(keys => console.log(keys))

# Check manifest
fetch('/manifest.json').then(r => r.json()).then(console.log)
```

## Future Enhancements

1. **Push Notifications**: Implement server-side push notifications
2. **Background Sync**: Add offline action queuing
3. **App Updates**: Implement update notifications
4. **Analytics**: Track PWA usage and performance
5. **Advanced Caching**: Implement more sophisticated caching strategies

## Resources

- [MDN PWA Documentation](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
- [Web App Manifest Specification](https://w3c.github.io/manifest/)
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [PWA Builder](https://www.pwabuilder.com/)
- [Lighthouse PWA Audit](https://developers.google.com/web/tools/lighthouse) 