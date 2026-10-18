# Brudcast Flutter example

A small app built the way a customer's app would be, with each SDK call where a real app puts it:
identify at sign-in, reset at sign-out, a screen view as each route appears, events as the user
shops, and message buttons that open the app's own screens. It uses the packages in this
repository, so changes to them show up on the next run. Its activity is Flutter's default
`FlutterActivity`.

## Run it

1. Copy `config/local.json.example` to `config/local.json` (ignored by git) and set the publishable
   key of an in-app application in the dashboard:

   ```json
   {
     "BRUDCAST_PUBLISHABLE_KEY": "bpk_...",
     "BRUDCAST_ENVIRONMENT": "local",
     "SAMPLE_BACKEND_URL": "http://10.0.2.2:4000"
   }
   ```

2. Run it with the configuration:

   ```sh
   flutter run --dart-define-from-file=config/local.json
   ```

`BRUDCAST_ENVIRONMENT` picks `production`, `staging`, `uat`, `development` or `local`. `local` talks
to `brudcast-in-app-delivery-service` on port `BRUDCAST_LOCAL_PORT` (8191) of the development
machine: `10.0.2.2` from the Android emulator, `localhost` from the iOS simulator. The app allows
cleartext HTTP to both. `config/staging.json.example` is a starting point for staging.

Until the native SDKs 0.2.0 are released, build as the repository README's "Against unreleased
native SDKs" describes.

## Sign in like a real app

With `SAMPLE_BACKEND_URL` set, sign-in goes through your backend: it computes the user hash with the
identity secret, the app passes it to `Brudcast.identify`, and **Send me a welcome** on Home has the
backend send the user an in-app message through the Brudcast API. The identity secret and the API
key stay on the backend. Without it, sign-in takes a pasted user hash instead.

The backend needs `POST /login` (`{ "userId", "email" }` in, `{ "externalId", "userHash", "email" }`
out) and `POST /welcome` (`{ "externalId" }`).
[brudcast-sample-backend](https://github.com/brudcast/brudcast-sample-backend) implements both.

## The app

```
Sign in ──▶ Home ┬ Shop ──▶ Product ──▶ Checkout
                 ├ Inbox ──▶ Message
                 └ Account ──▶ Sign out ──▶ Sign in
```

| Where        | What the SDK does                                                                                     |
| ------------ | ----------------------------------------------------------------------------------------------------- |
| Sign in      | `Brudcast.identify` with the hash from the backend                                                    |
| Every screen | `Brudcast.screen` from a `NavigatorObserver`: `SignIn`, `Home`, `Shop`, `Product`, `Checkout`, ...    |
| Home         | The inbox bell with its `unreadCount` badge, the native inbox, and **Send me a welcome**              |
| Product      | Tracks `product_viewed` with `product` and `price`                                                    |
| Checkout     | Tracks `checkout_started` on arrival and `order_completed` on **Place order**                         |
| Inbox        | `InboxController` with paging, pull to refresh and swipe to delete; `BrudcastInboxMessage` for detail |
| Account      | Notification permission, pausing and syncing messages, the action log, any event or screen, sign-out  |

Set a button's action to `brudcast-sample://checkout` or `brudcast-sample://shop` and tapping it
opens that screen: the action handler routes the example's own links and records every action in
the log on Account, with `unverified` on taps the SDK cannot prove it created.

## Push

Push needs your Firebase project. Add Android (`com.brudcast.flutter.example`) and iOS apps to it,
put `google-services.json` in `android/app` and `GoogleService-Info.plist` in `ios/Runner` (both
ignored by git), add the Push Notifications capability to the Runner target, and set
`"FIREBASE_ENABLED": true` in the configuration. `lib/push_setup.dart` shows the whole
`firebase_messaging` wiring.
