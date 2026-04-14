import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relapse_flutter/providers/settings_providers.dart';
import 'package:relapse_flutter/services/settings_service.dart';

AppSettings _settingsWithFlag(bool enabled) {
  return AppSettings(
    reminderCooldownMinutes: 30,
    notificationSoundEnabled: true,
    dailyReportHour: 20,
    dailyReportMinute: 0,
    themeMode: 'system',
    useOptimizedLatestLocationQuery: enabled,
  );
}

void main() {
  group('latestLocationOptimizedQueryProvider', () {
    test('uses true fallback when appSettingsProvider has no value yet', () {
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith((ref) => const Stream<AppSettings>.empty()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(latestLocationOptimizedQueryProvider), isTrue);
    });

    test('uses false when settings stream emits disabled flag', () async {
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => Stream<AppSettings>.value(_settingsWithFlag(false)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);

      expect(container.read(latestLocationOptimizedQueryProvider), isFalse);
    });

    test('uses true when settings stream emits enabled flag', () async {
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => Stream<AppSettings>.value(_settingsWithFlag(true)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);

      expect(container.read(latestLocationOptimizedQueryProvider), isTrue);
    });
  });
}
