import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vikunja_app/core/di/locale_provider.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/notification_provider.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/theming/theme_mode.dart';
import 'package:vikunja_app/core/utils/constants.dart';
import 'package:vikunja_app/core/utils/language_autonyms.dart';
import 'package:vikunja_app/core/utils/user_extensions.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/settings_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/login/login_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends ConsumerState<SettingsPage> {
  static const _intervalMinutes = [0, 15, 30, 45, 60, 90, 120, 180, 240, 300, 360];
  bool _isDragging = false;
  double _dragValue = 0;

  String _formatInterval(int minutes, AppLocalizations l10n) {
    if (minutes == 0) return '0 — ${l10n.none}';
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} h';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    final l10n = AppLocalizations.of(context);
    final overrideLocale = ref.watch(localeOverrideProvider).asData?.value;
    final resolvedLocale = Localizations.localeOf(context);
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final bool isSystemSelected = overrideLocale == null;
    final bool isFallback =
        isSystemSelected &&
        platformLocale.languageCode != resolvedLocale.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: settings.when(
        data: (settings) {
          // Slider-Position aus gespeichertem Wert ableiten
          final sliderIndex = _isDragging
              ? _dragValue.round()
              : (_intervalMinutes.indexOf(settings.refreshInterval).clamp(
                  0,
                  _intervalMinutes.length - 1,
                ));

          return ListView(
            children: [
              _buildUserHeader(ref, settings.user, settings.projects, context),
              Divider(),
              ListTile(
                title: Text(l10n.theme),
                trailing: DropdownButton<FlutterThemeMode>(
                  items: [
                    DropdownMenuItem(
                      value: FlutterThemeMode.system,
                      child: Text(l10n.system),
                    ),
                    DropdownMenuItem(
                      value: FlutterThemeMode.light,
                      child: Text(l10n.light),
                    ),
                    DropdownMenuItem(
                      value: FlutterThemeMode.dark,
                      child: Text(l10n.dark),
                    ),
                  ],
                  value: settings.themeMode,
                  onChanged: (FlutterThemeMode? value) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(value ?? FlutterThemeMode.system);
                  },
                ),
              ),
              ListTile(
                title: Text(l10n.language),
                subtitle: isFallback
                    ? Text(
                        'System language (${platformLocale.languageCode}${platformLocale.countryCode != null ? '-${platformLocale.countryCode}' : ''}) not supported. Using ${languageAutonym(resolvedLocale)}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      )
                    : null,
                trailing: DropdownButton<Locale?>(
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.systemLanguage),
                    ),
                    ...AppLocalizations.supportedLocales.map(
                      (loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(languageAutonym(loc)),
                      ),
                    ),
                  ],
                  value: overrideLocale,
                  onChanged: (Locale? value) {
                    ref.read(localeOverrideProvider.notifier).setLocale(value);
                  },
                ),
              ),
              SwitchListTile(
                title: Text(l10n.dynamicColors),
                value: settings.dynamicColors,
                onChanged: (bool? value) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setDynamicColors(value ?? false);
                },
              ),
              Divider(),
              CheckboxListTile(
                title: Text(l10n.ignoreCertificates),
                value: settings.ignoreCertificates,
                onChanged: (value) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setIgnoreCertificates(value ?? false);
                },
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.backgroundRefreshInterval} ${_formatInterval(_intervalMinutes[sliderIndex], l10n)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Slider(
                      value: sliderIndex.toDouble(),
                      min: 0,
                      max: (_intervalMinutes.length - 1).toDouble(),
                      divisions: _intervalMinutes.length - 1,
                      label: _formatInterval(
                        _intervalMinutes[sliderIndex],
                        l10n,
                      ),
                      onChanged: (v) => setState(() {
                        _isDragging = true;
                        _dragValue = v;
                      }),
                      onChangeEnd: (v) {
                        final idx = v.round();
                        setState(() {
                          _isDragging = false;
                          _dragValue = idx.toDouble();
                        });
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setRefreshInterval(_intervalMinutes[idx]);
                      },
                    ),
                    Text(
                      l10n.noLimitHelper,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Divider(),
              TextButton(
                onPressed: () async {
                  var notifGranted = await Permission.notification.isGranted;
                  if (notifGranted) {
                    ref.read(notificationProvider)?.sendTestNotification();
                  } else {
                    var status = await Permission.notification.request();
                    if (status.isGranted) {
                      ref.read(notificationProvider)?.sendTestNotification();
                    } else if (status.isPermanentlyDenied && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.noNotificationPermission)),
                      );
                    }
                  }
                },
                child: Text(l10n.sendTestNotification),
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Column(
                  children: [
                    FutureBuilder<String?>(
                      future: ref.read(settingsRepositoryProvider).getServer(),
                      builder: (context, snapshot) {
                        final serverUrl = snapshot.data;
                        if (serverUrl == null || serverUrl.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            serverUrl,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.35),
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      'v$appVersion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.5),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(
                          'https://github.com/go-vikunja/app',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Text(
                        'Fork von go-vikunja/app v0.1.8',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.3),
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      'MIT License',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.2),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(settingsRepositoryProvider).saveServer(null);
                  ref.read(settingsRepositoryProvider).saveUserToken(null);
                  ref.read(settingsRepositoryProvider).saveRefreshToken(null);

                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (buildContext) => LoginPage()),
                  );
                },
                child: Text(l10n.logout),
              ),
            ],
          );
        },
        error: (err, _) => VikunjaErrorWidget(
          error: err,
          onRetry: () => ref.invalidate(settingsControllerProvider),
        ),
        loading: () => const LoadingWidget(),
      ),
    );
  }

  Widget _buildUserHeader(
    WidgetRef ref,
    User user,
    List<Project> projects,
    BuildContext context,
  ) {
    return Column(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            user.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          accountEmail: Text(
            user.username,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          currentAccountPicture: FutureBuilder(
            future: ref.read(clientProviderProvider).getHeaders(),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.hasData && asyncSnapshot.data != null) {
                return CircleAvatar(
                  backgroundImage: user.username != ""
                      ? NetworkImage(
                          user.avatarUrl(
                            ref.read(clientProviderProvider).apiBase,
                          ),
                          headers: asyncSnapshot.data,
                        )
                      : null,
                );
              } else {
                return CircleAvatar();
              }
            },
          ),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/graphics/hypnotize.png"),
              repeat: ImageRepeat.repeat,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.secondaryContainer,
                BlendMode.multiply,
              ),
            ),
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context).defaultProject),
          trailing: DropdownButton<int>(
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text(AppLocalizations.of(context).none),
              ),
              ...projects.map(
                (e) => DropdownMenuItem(value: e.id, child: Text(e.title)),
              ),
            ],
            value:
                projects.firstWhereOrNull(
                      (element) =>
                          element.id == user.settings?.defaultProjectId,
                    ) !=
                    null
                ? user.settings?.defaultProjectId
                : 0,
            onChanged: (int? value) {
              if (value != null && user.settings != null) {
                ref
                    .read(settingsControllerProvider.notifier)
                    .setDefaultProject(value);
              }
            },
          ),
        ),
      ],
    );
  }
}
