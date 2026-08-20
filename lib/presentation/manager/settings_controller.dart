import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/di/theme_provider.dart';
import 'package:vikunja_app/core/theming/theme_mode.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/settings_page_state.dart';
import 'package:workmanager/workmanager.dart';

part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<SettingsPageState> build() async {
    return getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => getAll());
  }

  Future<SettingsPageState> getAll() async {
    var ignoreCertificates = await ref
        .read(settingsRepositoryProvider)
        .getIgnoreCertificates();
    var refreshInterval = await ref
        .read(settingsRepositoryProvider)
        .getRefreshInterval();
    var themeMode = await ref.read(settingsRepositoryProvider).getThemeMode();
    var dynamicColor = await ref
        .read(settingsRepositoryProvider)
        .getDynamicColors();

    var snoozeDuration = await ref
        .read(settingsRepositoryProvider)
        .getSnoozeDuration();

    final user = ref.read(currentUserProvider)!;
    final projectsResponse = await ref.read(projectRepositoryProvider).getAll();

    var projects = projectsResponse.isSuccessful
        ? projectsResponse.toSuccess().body
        : <Project>[];

    return SettingsPageState(
      user,
      projects,
      ignoreCertificates,
      refreshInterval,
      snoozeDuration,
      themeMode,
      dynamicColor,
    );
  }

  Future<void> setThemeMode(FlutterThemeMode mode) async {
    ref.read(settingsRepositoryProvider).setThemeMode(mode);
    var themeModel = ref.read(themeProvider).value?.copyWith(themeMode: mode);
    if (themeModel != null) {
      ref.read(themeProvider.notifier).set(themeModel);
    }
    state = AsyncData(await getAll());
  }

  Future<void> setDynamicColors(bool dynamicColors) async {
    ref.read(settingsRepositoryProvider).setDynamicColors(dynamicColors);
    var themeModel = ref
        .read(themeProvider)
        .value
        ?.copyWith(dynamicColors: dynamicColors);
    if (themeModel != null) {
      ref.read(themeProvider.notifier).set(themeModel);
    }
    state = AsyncData(await getAll());
  }

  Future<void> setIgnoreCertificates(bool value) async {
    ref.read(settingsRepositoryProvider).setIgnoreCertificates(value);

    ref.read(clientProviderProvider).setIgnoreCerts(value);

    state = AsyncData(await getAll());
  }

  Future<void> setRefreshInterval(int minutes) async {
    ref.read(settingsRepositoryProvider).setRefreshInterval(minutes);
    state = AsyncData(await getAll());

    updateWorkManagerDuration();
  }

  Future<void> setSnoozeDuration(int minutes) async {
    ref.read(settingsRepositoryProvider).setSnoozeDuration(minutes);
    state = AsyncData(await getAll());
  }

  void updateWorkManagerDuration() async {
    if (kIsWeb) {
      return;
    }

    var settings = await getAll();
    Workmanager().cancelAll().then((value) {
      var duration = Duration(minutes: settings.refreshInterval);
      if (duration.inMinutes > 0) {
        Workmanager().registerPeriodicTask(
          "update-tasks",
          "update-tasks",
          frequency: duration,
          constraints: Constraints(networkType: NetworkType.connected),
          initialDelay: Duration(seconds: 15),
        );
      }
    });
  }

  void setDefaultProject(int value) {
    final user = ref.read(currentUserProvider);
    user!.settings!.defaultProjectId = value;
    ref.read(userRepositoryProvider).setCurrentUserSettings(user.settings!);

    ref.read(currentUserProvider.notifier).set(user);

    refresh();
  }
}
