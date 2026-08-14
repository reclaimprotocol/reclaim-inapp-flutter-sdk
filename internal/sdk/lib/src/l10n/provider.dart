import 'package:material_ui/material_ui.dart';

import '../utils/observable_notifier.dart';
import 'generated/app_localizations.dart';
import 'remote/remote_l10n.dart';

export 'generated/app_localizations.dart';

typedef MaybeTranslationCallback = String? Function(ReclaimAppLocalizations it);

extension ReclaimLocalizationX on BuildContext {
  ReclaimAppLocalizations get l10n {
    return ReclaimLocalizationProvider.of(this);
  }

  String translate(MaybeTranslationCallback cb) {
    return ReclaimLocalizationProvider.translate(this, cb);
  }
}

class ReclaimLocalizationProvider extends ObservableNotifier<Locale?> {
  ReclaimLocalizationProvider({Locale? locale}) : super(locale);

  static List<Locale> get supportedLocales => ReclaimAppLocalizations.supportedLocales;

  // Not [ReclaimAppLocalizations.localizationsDelegates]: gen-l10n emits the delegates from
  // package:flutter_localizations, which localize the legacy package:flutter/material.dart types.
  // Since material/cupertino moved into their own packages, our widgets look up material_ui's
  // MaterialLocalizations and cupertino_ui's CupertinoLocalizations instead, and those delegates
  // never satisfy the lookup. GlobalMaterialLocalizations.delegates below is material_ui's, and
  // already bundles the matching cupertino and widgets delegates.
  static const List<LocalizationsDelegate<dynamic>> _localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    ReclaimAppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ];

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegate => _localizationsDelegates;

  static ReclaimAppLocalizations of(BuildContext context) {
    final l10n = maybeOf(context);
    assert(l10n != null, 'Ensure ReclaimThemeProvider is available as an ancestor in the context of this widget');
    return l10n!;
  }

  static ReclaimAppLocalizations? maybeOf(BuildContext context) {
    final remotel10n = Localizations.of<RemoteLocalizations>(context, RemoteLocalizations);
    final appl10n = ReclaimAppLocalizations.of(context);
    // Prefer remote translation over in-app
    return remotel10n ?? appl10n;
  }

  static ReclaimLocalizationProvider? find(BuildContext context) {
    final _ProviderScope? scope = context.getInheritedWidgetOfExactType<_ProviderScope>();

    return scope?.notifier;
  }

  static String? translateByLocale(Locale locale, MaybeTranslationCallback cb) {
    final l10n = lookupReclaimAppLocalizations(locale);
    final text = cb(l10n);
    if (text != null) return text;
    return null;
  }

  static String? maybeTranslate(BuildContext context, MaybeTranslationCallback cb) {
    final remotel10n = Localizations.of<RemoteLocalizations>(context, RemoteLocalizations);
    final appl10n = ReclaimAppLocalizations.of(context);
    // Prefer remote translation over in-app
    if (remotel10n != null) {
      final text = cb(remotel10n);
      if (text != null) return text;
    }
    if (appl10n != null) {
      final text = cb(appl10n);
      if (text != null) return text;
    }
    final locale = Localizations.maybeLocaleOf(context);
    if (locale != null) {
      final text = cb(lookupReclaimAppLocalizations(locale));
      if (text != null) return text;
    }
    return null;
  }

  static String translate(BuildContext context, MaybeTranslationCallback cb) {
    final text = maybeTranslate(context, cb);
    if (text != null) return text;
    throw FlutterError('No translation available');
  }

  Widget wrap({required Widget child}) {
    return _ProviderScope(notifier: this, child: child);
  }

  void update(Locale? newValue) {
    value = newValue;
  }

  void updateSilently(Locale? newValue) {
    super.setValueSilently(newValue);
  }

  static Locale? lastKnownLocale;
}

class _ProviderScope extends InheritedNotifier<ReclaimLocalizationProvider> {
  const _ProviderScope({required super.child, required ReclaimLocalizationProvider super.notifier});

  @override
  bool updateShouldNotify(covariant _ProviderScope oldWidget) {
    return oldWidget.notifier?.value != notifier?.value;
  }
}
