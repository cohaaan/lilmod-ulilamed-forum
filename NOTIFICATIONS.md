# Notifications — Push & In-App

> **Scope:** [`MVPPLAN.md`](MVPPLAN.md) defines *what* ships in MVP (reply, quote, mention).  
> **This document** is the implementation canon for *how* notifications work — in-app center, FCM push, badges, and deep links.

Firebase Cloud Messaging is the **delivery transport only**. Django/Postgres remains the **source of truth**. We do not use Firestore or any Firebase database.

---

## End-to-end flow

```text
Member replies
    ↓
Django saves the reply
    ↓
Django creates an in-app Notification row
    ↓
Celery sends the notification through FCM
    ↓
FCM delivers through:
    ├── APNs on iPhone
    └── Google Play services on Android
    ↓
User taps notification
    ↓
Flutter opens the exact thread and post
```

**Correctness rule:** A temporary Firebase failure must **never** cause the reply itself to fail. Save the post and notification first; push after the database transaction commits.

---

## MVP notification types

| Type | Trigger |
|------|---------|
| `reply` | Someone replied in a thread you started |
| `quote` | Someone quoted your post |
| `mention` | Someone `@mentioned` you |

Dedupe: if one post is simultaneously a reply + quote + mention to the same recipient, create **one** notification (priority: mention > quote > reply). Never notify a user about their own action.

---

## Infrastructure

Push delivery adds two services beyond Django + Postgres:

| Service | Role |
|---------|------|
| **Redis** | Celery message broker |
| **Celery worker** | Async FCM send (`send_push_notification` task) |

Add both to `docker-compose` alongside the web and database containers.

---

## 1. Firebase project setup

In [Firebase Console](https://console.firebase.google.com/):

1. Create the **Lilmod Ulilamed** project.
2. Add the Android app using its package name (`com.lilmodulilamed.lilmod_ulilamed`).
3. Add the iOS app using its bundle ID.
4. Add Firebase configuration to Flutter (`google-services.json`, `GoogleService-Info.plist`, FlutterFire config).
5. Enable **Cloud Messaging**.

Install Flutter packages:

```bash
flutter pub add firebase_core
flutter pub add firebase_messaging
```

### iOS (APNs)

In Xcode, enable **Push Notifications**, **Background Fetch**, and **Remote Notifications**.

Create an Apple APNs `.p8` authentication key in Apple Developer → Certificates, Identifiers & Profiles → Keys. Upload it to Firebase (Project Settings → Cloud Messaging) with your Apple Team ID and Key ID.

References: [FCM Flutter get started](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)

### Android 13+

The app must request the `POST_NOTIFICATIONS` runtime permission before notifications can be shown. See [Android notification permission](https://developer.android.com/develop/ui/compose/notifications/notification-permission).

---

## 2. Firebase Admin SDK credentials (required)

The Celery task authenticates to FCM using the **Firebase Admin SDK**. Initializing with only a project ID is not enough — the server needs a **service account private key**.

### Generate the key

1. Firebase Console → **Project Settings** → **Service accounts**.
2. Click **Generate new private key** → download the JSON file.
3. Store it as a secret on the Django server — **never commit it to git**.

### Mount on the server

Set Application Default Credentials via environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-service-account.json
export FIREBASE_PROJECT_ID=your-firebase-project-id
```

In Django settings:

```python
FIREBASE_PROJECT_ID = env("FIREBASE_PROJECT_ID")
GOOGLE_APPLICATION_CREDENTIALS = env("GOOGLE_APPLICATION_CREDENTIALS")
```

Initialize once at startup (e.g. `backend/config/firebase.py`):

```python
import os

import firebase_admin
from django.conf import settings

if not firebase_admin._apps:
    cred_path = settings.GOOGLE_APPLICATION_CREDENTIALS
    if cred_path and os.path.isfile(cred_path):
        firebase_admin.initialize_app(
            firebase_admin.credentials.Certificate(cred_path),
            options={"projectId": settings.FIREBASE_PROJECT_ID},
        )
```

Install:

```bash
pip install firebase-admin
```

Reference: [Send a message using Firebase Admin SDK](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk)

---

## 3. Ask the member for permission

Do **not** show the operating-system permission prompt immediately when the app opens.

Show an explanation first:

> Get notified when someone replies, quotes, or mentions you.

Then request permission:

```dart
final settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

final allowed =
    settings.authorizationStatus == AuthorizationStatus.authorized ||
    settings.authorizationStatus == AuthorizationStatus.provisional;
```

Notification permission is required on iOS, web, and Android 13 or newer.

**The in-app notification center still works without push permission.** The bell, unread count, and notification list load from Django regardless of whether the user granted OS push access.

Reference: [Receive messages in Flutter apps](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)

---

## 4. Device tokens

FCM assigns each app installation a registration token. One member can have several:

```text
Isaac
├── iPhone token
├── iPad token
└── Android token
```

### Django model

```python
class DeviceToken(models.Model):
    class Platform(models.TextChoices):
        IOS = "ios", "iOS"
        ANDROID = "android", "Android"
        WEB = "web", "Web"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    token = models.TextField(unique=True)
    platform = models.CharField(max_length=20, choices=Platform.choices)
    is_active = models.BooleanField(default=True)
    permission_status = models.CharField(max_length=30)
    app_version = models.CharField(max_length=30, blank=True)
    last_registered_at = models.DateTimeField(auto_now=True)
    last_successful_push_at = models.DateTimeField(null=True, blank=True)
    failure_count = models.PositiveIntegerField(default=0)
```

**Security:** Raw FCM tokens must never be returned through ordinary member APIs.

### Register token (Flutter)

```dart
final token = await FirebaseMessaging.instance.getToken();

if (token != null) {
  await api.post(
    '/api/v1/me/devices/',
    data: {
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'permission_status': allowed ? 'authorized' : 'denied',
      'app_version': appVersion,
    },
  );
}
```

Watch for token refresh:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
  await api.post(
    '/api/v1/me/devices/',
    data: {
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'permission_status': 'authorized',
    },
  );
});
```

On logout, call `DELETE /api/v1/me/devices/` (or deactivate the current token) so pushes stop for that installation.

Prune stale tokens when FCM returns `UNREGISTERED` or `InvalidRegistration` errors (see §6).

---

## 5. Create the in-app notification first

Suppose Avi replies to Isaac's thread.

```python
from django.db import transaction

@transaction.atomic
def create_reply(*, thread, author, body):
    post = Post.objects.create(
        thread=thread,
        author=author,
        body_markdown=body,
    )

    if thread.author_id != author.id:
        notification = Notification.objects.create(
            recipient=thread.author,
            actor=author,
            type=Notification.Type.REPLY,
            thread=thread,
            post=post,
            title="New reply",
            body_preview=f'{author.display_name} replied to "{thread.title}".',
            route=f"/threads/{thread.id}?post={post.id}",
        )

        transaction.on_commit(
            lambda nid=str(notification.id): send_push_notification.delay(nid)
        )

    return post
```

Order:

1. Save the post.
2. Save the notification.
3. Commit the transaction.
4. Enqueue the Celery push task.

Apply the same pattern for quote and mention notifications in the notification service layer.

---

## 6. Send the push from Celery

```python
from celery import shared_task
from django.utils import timezone
from firebase_admin import messaging

@shared_task(
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_kwargs={"max_retries": 3},
)
def send_push_notification(notification_id: str) -> None:
    notification = (
        Notification.objects
        .select_related("recipient", "actor", "thread", "post")
        .get(id=notification_id)
    )

    tokens = list(
        notification.recipient.device_tokens
        .filter(is_active=True)
        .values_list("token", flat=True)
    )

    if not tokens:
        return

    unread_count = Notification.objects.filter(
        recipient=notification.recipient,
        is_read=False,
    ).count()

    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(
            title=notification.title,
            body=notification.body_preview,
        ),
        data={
            "notification_id": str(notification.id),
            "type": notification.type,
            "route": notification.route,
            "thread_id": str(notification.thread_id),
            "post_id": str(notification.post_id or ""),
        },
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="forum_activity",
                sound="default",
                notification_count=unread_count,
            ),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound="default",
                    badge=unread_count,
                ),
            ),
        ),
    )

    response = messaging.send_each_for_multicast(message)

    for token, result in zip(tokens, response.responses):
        if result.success:
            DeviceToken.objects.filter(token=token).update(
                last_successful_push_at=timezone.now(),
                failure_count=0,
            )
        else:
            handle_fcm_error(token, result.exception)


def handle_fcm_error(token: str, exc: Exception) -> None:
    """Increment failure_count; deactivate tokens FCM reports as invalid."""
    from firebase_admin import exceptions

    device = DeviceToken.objects.filter(token=token).first()
    if not device:
        return

    error_code = getattr(exc, "code", None)
    if error_code in ("UNREGISTERED", "INVALID_ARGUMENT"):
        device.is_active = False
        device.save(update_fields=["is_active"])
        return

    DeviceToken.objects.filter(pk=device.pk).update(
        failure_count=device.failure_count + 1,
    )
```

Use `send_each_for_multicast` (current API; older `send_multicast` is deprecated). Multicast supports up to **500 tokens** per call.

The data payload carries identifiers and the route — not the full post body.

Reference: [firebase_admin.messaging module](https://firebase.google.com/docs/reference/admin/python/firebase_admin.messaging)

---

## 7. App-icon badge

Django calculates:

```text
unread_count = unread Notification rows for this member
```

Send that count with every push.

### iPhone

```python
messaging.Aps(badge=unread_count)
```

APNs paints the exact red numeric badge on the app icon. When the member reads everything, send `badge=0` and have Flutter clear the local badge immediately.

### Android

```python
notification_count=unread_count
```

Android launchers that support numeric badging may show a count. Standard Android guarantees a notification dot on supported launchers, but an exact red number is **launcher/OEM-dependent** (Pixel typically shows a dot; Samsung and others may show a number).

**Product requirement:**

> Exact red numeric badge on iOS. Notification dot or numeric badge on Android according to launcher support — do not promise an iPhone-style count on every Android device.

---

## 8. Receive notifications in Flutter

Three app states must all be handled.

### App is open (foreground)

FCM does not auto-display a system notification while the app is in the foreground. Show your own in-app banner and refresh the bell count:

```dart
FirebaseMessaging.onMessage.listen((message) {
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(notificationListProvider);

  showInAppNotificationBanner(
    title: message.notification?.title,
    body: message.notification?.body,
    route: message.data['route'],
  );
});
```

### App in background

```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  openNotificationRoute(message.data);
});
```

### App was completely closed (terminated)

```dart
final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

if (initialMessage != null) {
  openNotificationRoute(initialMessage.data);
}
```

Register the background handler at startup:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const ProviderScope(child: LilmodApp()));
}
```

The background handler must be a top-level function with `@pragma('vm:entry-point')` for release builds.

---

## 9. In-app notification API

Flutter loads the permanent notification center from Django (works with or without push permission):

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/v1/me/notifications/` | Paginated list (`?filter=unread\|all&type=reply\|quote\|mention`) |
| GET | `/api/v1/me/notifications/unread-count/` | Lightweight badge poll (every 30–60s) |
| POST | `/api/v1/me/notifications/{id}/read/` | Mark single notification read |
| POST | `/api/v1/me/notifications/mark-all-read/` | Mark all read |
| POST | `/api/v1/me/devices/` | Register or refresh FCM device token |
| DELETE | `/api/v1/me/devices/` | Deactivate token on logout |

### Opening a notification

1. Mark it read (`POST .../{id}/read/`).
2. Refresh unread count.
3. Update the app-icon badge (iOS).
4. Navigate to `/threads/123?post=456`.
5. Scroll to post `456`.

---

## Build checklist

- [ ] Firebase project (Android + iOS apps registered)
- [ ] APNs `.p8` key uploaded to Firebase
- [ ] Service account JSON on Django server (`GOOGLE_APPLICATION_CREDENTIALS`)
- [ ] `firebase_core` + `firebase_messaging` in Flutter
- [ ] Permission priming screen before OS prompt
- [ ] `DeviceToken` model + `/me/devices/` API
- [ ] `Notification` model + notification service layer (dedupe, self-suppress)
- [ ] Celery + Redis in docker-compose
- [ ] Firebase Admin SDK + `send_push_notification` task
- [ ] Notification bell + in-app notification screen
- [ ] Foreground in-app banner
- [ ] Deep-link routing (`onMessageOpenedApp` + `getInitialMessage`)
- [ ] App-icon badge sync (iOS exact; Android best-effort)
- [ ] Physical iPhone and Android device testing

---

## References

1. [Get started with FCM in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
2. [Android POST_NOTIFICATIONS permission](https://developer.android.com/develop/ui/compose/notifications/notification-permission)
3. [Receive messages in Flutter apps](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
4. [Send a message using Firebase Admin SDK](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk)
5. [firebase_admin.messaging module](https://firebase.google.com/docs/reference/admin/python/firebase_admin.messaging)
