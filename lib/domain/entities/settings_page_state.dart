import 'package:vikunja_app/core/theming/theme_mode.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/user.dart';

class SettingsPageState {
  User user;
  List<Project> projects;

  bool ignoreCertificates;

  int refreshInterval;
  int snoozeDuration;

  FlutterThemeMode themeMode;
  bool dynamicColors;

  SettingsPageState(
    this.user,
    this.projects,
    this.ignoreCertificates,
    this.refreshInterval,
    this.snoozeDuration,
    this.themeMode,
    this.dynamicColors,
  );
}
