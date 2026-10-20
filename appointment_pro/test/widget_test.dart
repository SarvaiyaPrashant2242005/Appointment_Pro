import 'package:appointment_pro/app/app.dart';
import 'package:appointment_pro/app/theme/theme_provider.dart';
import 'package:appointment_pro/core/services/network_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNetworkService extends NetworkService {
  @override
  Future<bool> hasInternetConnection({
    Duration timeout = const Duration(seconds: 4),
  }) async => true;
}

void main() {
  testWidgets('AppointmentProApp smoke test launches successfully', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          networkServiceProvider.overrideWithValue(MockNetworkService()),
        ],
        child: const AppointmentProApp(),
      ),
    );

    // Allow splash timer to complete and settle
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentProApp), findsOneWidget);
  });
}
