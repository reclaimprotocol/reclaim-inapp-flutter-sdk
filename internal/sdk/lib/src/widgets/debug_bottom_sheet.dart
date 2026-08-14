import 'package:collection/collection.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../controller.dart';
import '../l10n/provider.dart';
import '../logging/logging.dart';
import '../repository/feature_flags.dart';
import '../services/source/source.dart';
import '../ui/dev/dev.dart';
import '../utils/widget.dart';
import 'feature_flags.dart';
import 'reclaim_theme_provider.dart';

class DebugBottomSheet extends StatelessWidget {
  final VoidCallback onRefreshPage;
  final VoidCallback copySessionId;
  final String sessionId;

  const DebugBottomSheet({
    super.key,
    required this.onRefreshPage,
    required this.copySessionId,
    required this.sessionId,
  });

  static void show({
    required BuildContext context,
    required VoidCallback refreshPage,
    required VoidCallback copySessionId,
    required String sessionId,
  }) {
    final controller = VerificationController.readOf(context);
    final themeProviderWidget = context.findAncestorWidgetOfExactType<ReclaimThemeProvider>();
    final l10nProvider = ReclaimLocalizationProvider.find(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) {
        final child = ReclaimThemeProvider(
          applicationId: themeProviderWidget!.applicationId,
          locale: controller.options.locale,
          isApplicationLevel: false,
          builder: (context) {
            return DebugBottomSheet(onRefreshPage: refreshPage, copySessionId: copySessionId, sessionId: sessionId);
          },
        );
        return controller.wrap(child: l10nProvider != null ? l10nProvider.wrap(child: child) : child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final featureFlagsProviderFuture = FeatureFlagsProvider.readAfterSessionStartedOf(context);

    final theme = Theme.of(context);
    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        foregroundBuilder: (context, states, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Flexible(child: child!)],
          );
        },
      ).merge(theme.elevatedButtonTheme.style),
    );
    return Padding(
      padding: const EdgeInsets.all(16.0) + const EdgeInsets.only(bottom: 16),
      child: ElevatedButtonTheme(
        data: elevatedButtonTheme,
        child: FutureBuilder(
          future: featureFlagsProviderFuture,
          builder: (context, asyncSnapshot) {
            final featureFlagsProvider = asyncSnapshot.data;
            if (featureFlagsProvider == null) {
              return const CupertinoActivityIndicator();
            }
            return ListTileTheme.merge(
              minVerticalPadding: 0,
              horizontalTitleGap: 10,
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          context.l10n.settings,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      ListTile(
                        onTap: onRefreshPage,
                        leading: const Icon(Icons.refresh),
                        title: Text(context.l10n.refreshPage),
                        tileColor: Colors.blue,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                      ),
                      ListTile(
                        onTap: copySessionId,
                        leading: const Icon(Icons.content_copy),
                        title: Text(context.l10n.copySessionId),
                        tileColor: Colors.purple,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                      ),
                      StreamBuilder(
                        stream: featureFlagsProvider.stream(FeatureFlag.canSaveWebStorageDev),
                        builder: (context, snapshot) {
                          final value = snapshot.data == true;
                          void onToggle() async {
                            try {
                              await featureFlagsProvider.set(FeatureFlag.canSaveWebStorageDev, !value);
                            } catch (e, s) {
                              logging.severe('Failed to set feature flag', e, s);
                            }
                          }

                          return ListTile(
                            onTap: onToggle,
                            leading: Icon(value ? Icons.cookie_outlined : Icons.cookie),
                            title: Text(context.l10n.saveWebsiteData),
                            trailing: Switch(
                              value: value,
                              onChanged: (_) {
                                onToggle();
                              },
                            ),
                            tileColor: value ? Colors.green : Colors.red,
                            textColor: Colors.white,
                            iconColor: Colors.white,
                          );
                        },
                      ),
                      const ChangeLocaleTile(),
                      // NOTE: Feature not impl
                      // StreamBuilder(
                      //   stream: featureFlagsProvider.stream(FeatureFlag.isSingleClaimRequest),
                      //   builder: (context, snapshot) {
                      //     final value = snapshot.data == true;
                      //     return ElevatedButton.icon(
                      //       onPressed: () {
                      //         featureFlagsProvider.set(FeatureFlag.isSingleClaimRequest, !value);
                      //       },
                      //       icon: Icon(value ? Icons.toggle_on : Icons.toggle_off),
                      //       label: Text("Single Claim Request: ${value ? 'ON' : 'OFF'}"),
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: value ? Colors.green : Colors.red,
                      //         foregroundColor: Colors.white,
                      //         iconColor: Colors.white,
                      //       ),
                      //     );
                      //   },
                      // ),
                      ChangeLogLevelTile(
                        setIsWebInspectable: (value) {
                          featureFlagsProvider.set(FeatureFlag.isWebInspectable, value);
                        },
                        simplified: true,
                      ),
                      GestureDetector(
                        onLongPress: () {
                          Dev.open(context);
                        },
                        child: _ConsumerIdentifierLabel(sessionId: sessionId),
                      ),
                      const SizedBox(height: 40),
                    ].map((e) {
                      return Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 0), child: e);
                    }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChangeLogLevelTile extends StatefulWidget {
  final ValueChanged<bool>? setIsWebInspectable;
  final bool simplified;

  const ChangeLogLevelTile({super.key, this.setIsWebInspectable, this.simplified = false});

  @override
  State<ChangeLogLevelTile> createState() => _ChangeLogLevelTileState();
}

class _ChangeLogLevelTileState extends State<ChangeLogLevelTile> {
  final _levelChangeButtonKey = GlobalKey();

  void openDropdown() {
    final dropdownInkWell = findChildWidgetByType<InkWell>(_levelChangeButtonKey.currentContext!);
    assert(dropdownInkWell != null);

    dropdownInkWell?.onTap?.call();
  }

  void onButtonTap() {
    if (widget.simplified) {
      onSimplifiedAction();
    } else {
      openDropdown();
    }
  }

  void onSimplifiedAction() {
    final currentLevel = logging.level;
    final wasTroubleshootingModeOn = currentLevel <= Level.CONFIG;
    final canSetTroubleshootingModeOn = !wasTroubleshootingModeOn;
    if (canSetTroubleshootingModeOn) {
      logging.level = Level.ALL;
    } else {
      logging.level = Level.INFO;
    }
    widget.setIsWebInspectable?.call(canSetTroubleshootingModeOn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaWidth = MediaQuery.sizeOf(context).width;

    return DropdownButtonHideUnderline(
      child: ListTile(
        onTap: onButtonTap,
        tileColor: Colors.teal,
        iconColor: theme.colorScheme.onPrimary,
        textColor: theme.colorScheme.onPrimary,
        leading: const Icon(Icons.bug_report_rounded),
        title: widget.simplified ? Text(context.l10n.troubleshootingMode) : const Text("Log Level"),
        trailing: StreamBuilder<Level?>(
          stream: logging.onLevelChanged,
          initialData: logging.level,
          builder: (context, snapshot) {
            final currentLevel = snapshot.data;
            final levelOptions = [...Level.LEVELS].where((e) => e != Level.FINER && e != Level.FINEST).toList();
            if (currentLevel != null && !Level.LEVELS.contains(currentLevel)) {
              // if custom level is added, add it to the dropdown options
              levelOptions.add(currentLevel);
            }
            final textStyle = TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold);
            if (widget.simplified) {
              return Switch(
                value: currentLevel != null && currentLevel <= Level.CONFIG,
                onChanged: (_) {
                  onButtonTap();
                },
              );
            }
            return DropdownButton(
              key: _levelChangeButtonKey,
              value: currentLevel,
              onChanged: (value) {
                if (value == null) return;
                logging.level = value;
                widget.setIsWebInspectable?.call(value <= Level.CONFIG);
              },
              menuWidth: mediaWidth * 0.8,
              dropdownColor: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              iconEnabledColor: theme.colorScheme.onPrimary,
              style: textStyle,
              items: levelOptions.map((level) {
                return DropdownMenuItem(value: level, child: Text(level.name));
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class ChangeLocaleTile extends StatefulWidget {
  const ChangeLocaleTile({super.key});

  @override
  State<ChangeLocaleTile> createState() => _ChangeLocaleTileState();
}

class _ChangeLocaleTileState extends State<ChangeLocaleTile> {
  final _changeButtonKey = GlobalKey();

  void openDropdown() {
    final dropdownInkWell = findChildWidgetByType<InkWell>(_changeButtonKey.currentContext!);
    assert(dropdownInkWell != null);

    dropdownInkWell?.onTap?.call();
  }

  void onButtonTap() {
    openDropdown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final current = Localizations.maybeLocaleOf(context);

    String? getLocaleNameBy(Locale? locale) {
      if (locale == null) return null;
      return ReclaimLocalizationProvider.translateByLocale(locale, (it) => it.localeName);
    }

    final options = ReclaimLocalizationProvider.supportedLocales.map((e) {
      return MapEntry(getLocaleNameBy(e), e);
    });

    final textStyle = TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold);

    return DropdownButtonHideUnderline(
      child: ListTile(
        onTap: onButtonTap,
        tileColor: Colors.blueGrey,
        iconColor: theme.colorScheme.onPrimary,
        textColor: theme.colorScheme.onPrimary,
        leading: const Icon(Icons.translate_rounded),
        title: Text(ReclaimLocalizationProvider.maybeTranslate(context, (it) => it.changeLanguage) ?? 'none'),
        trailing: DropdownButton(
          key: _changeButtonKey,
          value: getLocaleNameBy(current),
          onChanged: (selectedValue) {
            if (selectedValue == null) return;
            final provider = ReclaimLocalizationProvider.find(context);
            final option = options.firstWhereOrNull((it) => it.key == selectedValue);
            if (option == null) return;

            provider?.update(option.value);
          },
          menuWidth: mediaWidth * 0.8,
          dropdownColor: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          iconEnabledColor: theme.colorScheme.onPrimary,
          style: textStyle,
          items: options.map((entry) {
            final name = entry.key;
            return DropdownMenuItem(
              value: name,
              child: Text(
                ReclaimLocalizationProvider.translateByLocale(entry.value, (it) => it.languageName).toString(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ConsumerIdentifierLabel extends StatelessWidget {
  final String sessionId;

  const _ConsumerIdentifierLabel({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getSdkConsumerIdentifier(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        final consumerIdentifier = snapshot.data!;
        return Text('$consumerIdentifier | $sessionId', textAlign: TextAlign.center, style: textTheme.labelSmall);
      },
    );
  }
}
