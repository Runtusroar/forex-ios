# Forex Factory MVP for iPhone

A native personal iPhone app for the independent Forex Factory MVP backend. It presents the
economic calendar and news with English as the primary text and optional Simplified Chinese below.

## MVP scope

- iOS 17+, Swift 6, and SwiftUI
- Calendar, News, and Settings tabs
- all eight Forex Factory news feeds: Latest, Hot, Fundamental, Technical, Industry,
  Entertainment, Educational, and Latest Comments
- English-first cards and story segments with optional Simplified Chinese directly underneath
- impact filtering, opaque-cursor pagination, article comments, and authenticated cached media
- foreground refresh approximately every 30 seconds
- pull-to-refresh
- last-successful JSON cache
- backend URL in UserDefaults and API key in Keychain
- no account system, pairing, or App Store distribution

The free Apple development account supports direct installation from Xcode, but it is not a
reliable production APNs deployment path. This MVP refreshes while active; production-quality
background remote notifications can be added after enrolling in the paid Apple Developer Program.

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

Run the unit tests with:

```bash
xcodebuild test \
  -project ForexFactoryMVP.xcodeproj \
  -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO
```

For a real iPhone, open the generated project in Xcode, select your free Apple development team,
choose the paired device, and run. The default backend is `https://api.juezhou.cc`; enter its
`APP_API_KEY` once in Settings. The key is stored in the iPhone Keychain. The Kimi API key remains
only on the backend.

See [API contract](docs/api-contract.md) for the network boundary and
[implementation plan](docs/implementation-plan.md) for the test-first implementation record.
