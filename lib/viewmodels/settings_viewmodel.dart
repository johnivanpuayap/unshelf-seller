import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/models/settings_model.dart';

part 'settings_viewmodel.g.dart';

/// Immutable state for the Settings screen. Wraps a mutable `SettingsModel`
/// purely for state-emission purposes — toggling notifications or changing
/// language replaces the inner model entirely (mirrors the original
/// ChangeNotifier).
class SettingsState {
  final SettingsModel settings;

  const SettingsState({required this.settings});

  factory SettingsState.initial() => SettingsState(
        settings: SettingsModel(
          notificationsEnabled: true,
          language: 'English',
        ),
      );

  SettingsState copyWith({SettingsModel? settings}) {
    return SettingsState(settings: settings ?? this.settings);
  }
}

/// Settings ViewModel — backs the Settings screen.
@Riverpod(keepAlive: true)
class SettingsViewModel extends _$SettingsViewModel {
  @override
  SettingsState build() => SettingsState.initial();

  void toggleNotifications(bool value) {
    state = state.copyWith(
      settings: SettingsModel(
        notificationsEnabled: value,
        language: state.settings.language,
      ),
    );
  }

  void changeLanguage(String newLanguage) {
    state = state.copyWith(
      settings: SettingsModel(
        notificationsEnabled: state.settings.notificationsEnabled,
        language: newLanguage,
      ),
    );
  }
}
