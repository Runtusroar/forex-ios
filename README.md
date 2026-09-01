# Forex Factory MVP for iPhone

A native personal iPhone app for the independent Forex Factory MVP backend. It presents the
economic calendar and news with English as the primary text and optional Simplified Chinese below.

## MVP scope

- iOS 17+, Swift 6, and SwiftUI
- Calendar, News, and Settings tabs
- foreground refresh approximately every 30 seconds
- pull-to-refresh
- last-successful JSON cache
- backend URL in UserDefaults and API key in Keychain
- no APNs, background fetch, account system, pairing, or App Store distribution

## Generate and build

Install XcodeGen, then run:

```bash
xcodegen generate
xcodebuild build-for-testing \
  -project ForexFactoryMVP.xcodeproj \
  -scheme ForexFactoryMVP \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

For a real iPhone, open the generated project in Xcode, select your free Apple development team,
choose the paired device, and run. Enter the public HTTPS backend URL and `APP_API_KEY` in Settings.
The Kimi API key remains only on the backend.

See [API contract](docs/api-contract.md) for the network boundary and
[implementation plan](docs/implementation-plan.md) for the remaining test-first work.
