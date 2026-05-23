// Firebase Messaging Service Worker
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker.
// Since FCM config is project-specific, we provide standard structure.
// Users can populate their standard firebase configuration keys if they deploy to web.
firebase.initializeApp({
  messagingSenderId: "103953800507" // Standard placeholder, compatible with default setups.
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification ? payload.notification.title : 'Alfloest Chat';
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : 'You have a new message.',
    icon: '/favicon.png',
    badge: '/favicon.png',
    data: payload.data || {}
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click to focus or open chat
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  
  const chatId = event.notification.data ? (event.notification.data.chatId || event.notification.data.chat_id) : null;
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // If a window is already open, focus it
      for (let i = 0; i < clientList.length; i++) {
        let client = clientList[i];
        if (client.url.indexOf('/') !== -1 && 'focus' in client) {
          if (chatId) {
            client.postMessage({
              type: 'NAVIGATE_CHAT',
              chatId: chatId
            });
          }
          return client.focus();
        }
      }
      // If no window is open, open a new one
      if (clients.openWindow) {
        let url = '/';
        if (chatId) {
          url = '/?chatId=' + chatId;
        }
        return clients.openWindow(url);
      }
    })
  );
});
