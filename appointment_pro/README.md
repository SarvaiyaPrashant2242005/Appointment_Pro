# AppointmentPro --- Flutter Project Guide

Feature-first Flutter architecture using Riverpod. Build screens with
dummy data first; connect APIs later.

## Folder structure

``` text
lib/
├── main.dart                         # App entry point; initializes ProviderScope
├── app/
│   ├── app.dart                      # Root app, theme, router configuration
│   ├── router/
│   │   └── app_router.dart           # Route paths and screen mapping
│   └── theme/
│       ├── app_theme.dart            # Light/dark ThemeData and component themes
│       ├── app_colors.dart           # Brand and semantic colors
│       ├── app_text_styles.dart      # Shared typography
│       └── app_dimensions.dart       # Spacing, sizes, and corner radii
├── core/
│   ├── constants/                    # App-wide constants and asset paths
│   ├── errors/                       # Common exceptions and error mapping
│   ├── utils/
│   │   ├── validators.dart           # Reusable input validation
│   │   ├── date_time_utils.dart      # Date/time formatting helpers
│   │   └── app_toast.dart             # Success, error, warning, info toasts
│   └── widgets/
│       ├── app_button.dart           # Primary/outlined buttons and loading state
│       ├── app_text_field.dart       # Styled form input and validation
│       ├── app_card.dart             # Shared card design
│       ├── app_loader.dart           # Standard loading indicator
│       ├── app_empty_view.dart       # Empty state with optional action
│       └── app_error_view.dart       # Error state with retry action
├── shared/
│   ├── models/                       # Models genuinely shared by features
│   └── widgets/                      # Widgets reused across features
└── features/
    ├── splash/
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

## Structure inside a feature

``` text
bookings/
├── data/
│   ├── models/          # Data models and JSON mapping
│   ├── datasources/     # Dummy data now; API datasource later
│   └── repositories/    # Data access implementation
├── domain/
│   └── entities/        # Core business objects, when useful
└── presentation/
    ├── screens/         # Full pages
    ├── widgets/         # Widgets specific to this feature
    └── providers/       # Riverpod state and actions
```

## What goes where?

-   **`app/router/`**: Keep route paths and screen mappings in
    `app_router.dart`. Use GoRouter. Add authentication redirects after
    authentication is implemented.
-   **`app/theme/`**: `app_colors.dart` holds brand colors;
    `app_text_styles.dart` holds typography; `app_dimensions.dart` holds
    spacing and sizes; `app_theme.dart` configures `ThemeData`. Avoid
    hardcoded styling in screens.
-   **`core/widgets/`**: Generic reusable UI components.
    Feature-specific widgets stay inside their feature.
-   **`core/utils/`**: Reusable helpers. `app_toast.dart` provides
    `AppToast.success(context, message)`, `error`, `warning`, and
    `info`.
-   **`features/<feature>/presentation/`**: Screens display state;
    Riverpod providers manage UI state and actions.
-   **`features/<feature>/data/`**: Use local dummy datasources for the
    prototype; add API datasources when backend endpoints are ready.
-   **`main.dart`**: Keep startup small; initialize Flutter and wrap
    `AppointmentProApp` in `ProviderScope`.
-   **`pubspec.yaml`**: Declare dependencies, assets, and fonts. Never
    store production secrets in the app.

## Dependencies

``` bash
flutter pub add flutter_riverpod
flutter pub add go_router
flutter pub add toastification
```

Add other packages only when required. Run `flutter pub get` and
`flutter analyze` after changes.

## Rules

-   Data flow: **Screen → Riverpod Provider → Repository → Dummy
    datasource now / API datasource later**.
-   Never make HTTP requests directly from screens or widgets.
-   Use theme values and reusable widgets consistently.
-   Use `AppToast` for short success/error/warning/info feedback.
-   Keep dummy data outside screen widgets so it can be replaced later.
-   Keep API configuration separate from UI code.
-   Create only folders and files needed for the current feature.
