# AppointmentPro --- Flutter Folder Structure

Feature-first Flutter architecture using Riverpod. Build the UI with
dummy data first; connect APIs later.

``` text
lib/
├── main.dart                    # App entry point and ProviderScope
├── app/
│   ├── app.dart                 # Root MaterialApp
│   ├── router/app_router.dart   # App routes and navigation
│   └── theme/
│       ├── app_theme.dart       # Global ThemeData
│       ├── app_colors.dart      # Brand colors
│       └── app_text_styles.dart # Typography
├── core/
│   ├── constants/               # App-wide constants
│   ├── utils/                   # Validators, date/time helpers
│   ├── errors/                  # Common error handling
│   └── widgets/                 # Reusable buttons, fields, loaders
├── shared/
│   ├── models/                  # Models shared by features
│   └── widgets/                 # Cross-feature widgets
└── features/
    ├── auth/
    ├── business_setup/
    ├── dashboard/
    ├── services/
    ├── availability/
    ├── staff/
    ├── customers/
    ├── bookings/
    ├── calendar/
    ├── notifications/
    ├── payments/
    ├── reports/
    └── settings/
```

## Structure inside each feature

``` text
bookings/
├── data/
│   ├── models/          # Data models / JSON mapping
│   ├── datasources/     # Dummy data now; API calls later
│   └── repositories/    # Data access implementation
├── domain/
│   └── entities/        # Core business objects (when needed)
└── presentation/
    ├── screens/         # Full pages
    ├── widgets/         # Widgets specific to bookings
    └── providers/       # Riverpod state and actions
```

## Key rules

-   `main.dart`: initialize Flutter and `ProviderScope`; keep it small.
-   `app/`: app setup, routing, and theme.
-   `core/`: generic utilities and reusable UI components.
-   `features/`: keep each module's screens, state, and data together.
-   `data/datasources/`: use local dummy data first; add API datasources
    later.
-   `presentation/providers/`: call repositories; do not put HTTP
    requests in screens.
-   `pubspec.yaml`: dependencies and asset declarations.
-   `assets/`: icons, images, illustrations, and fonts.

**Data flow:** Screen → Riverpod Provider → Repository → Dummy Data now
/ API later.

Create folders as you need them; avoid adding unnecessary empty files.
