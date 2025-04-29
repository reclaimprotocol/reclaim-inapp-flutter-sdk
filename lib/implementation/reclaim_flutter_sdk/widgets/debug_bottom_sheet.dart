import 'package:flutter/material.dart';
import '../logging/logging.dart';
import '../utils/source/source.dart';
import '../utils/widget.dart';

class DebugBottomSheet
    extends StatelessWidget {
  final VoidCallback
      refreshPage;
  final VoidCallback
      toggleCookiePersist;
  final VoidCallback
      copySessionId;
  final VoidCallback
      toggleUseSingleRequest;
  final ValueChanged<bool>
      setIsWebInspectable;
  final bool
      cookiePersist;
  final bool
      useSingleRequest;

  const DebugBottomSheet({
    super.key,
    required this.refreshPage,
    required this.toggleCookiePersist,
    required this.copySessionId,
    required this.cookiePersist,
    required this.setIsWebInspectable,
    required this.useSingleRequest,
    required this.toggleUseSingleRequest,
  });

  @override
  Widget build(
      BuildContext
          context) {
    final theme =
        Theme.of(context);
    final elevatedButtonTheme =
        ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        foregroundBuilder: (context, states, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(child: child!)
            ],
          );
        },
      ).merge(theme.elevatedButtonTheme.style),
    );
    return Padding(
      padding:
          const EdgeInsets.all(16.0) + const EdgeInsets.only(bottom: 16),
      child:
          ElevatedButtonTheme(
        data: elevatedButtonTheme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Debug Menu 👾",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: refreshPage,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Page"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: copySessionId,
              icon: const Icon(Icons.content_copy),
              label: const Text("Copy Session ID"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: toggleCookiePersist,
              icon: Icon(
                cookiePersist ? Icons.cookie_outlined : Icons.cookie,
              ),
              label: Text("Cookie Save: ${cookiePersist ? 'ON' : 'OFF'}"),
              style: ElevatedButton.styleFrom(
                backgroundColor: cookiePersist ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: toggleUseSingleRequest,
              icon: Icon(
                useSingleRequest ? Icons.toggle_on : Icons.toggle_off,
              ),
              label: Text(
                "Single Claim Request: ${useSingleRequest ? 'ON' : 'OFF'}",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: useSingleRequest ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
              ),
            ),
            ChangeLogLevelTile(setIsWebInspectable: setIsWebInspectable),
            const _ConsumerIdentifierLabel(),
          ].map((e) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: e,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ChangeLogLevelTile
    extends StatefulWidget {
  final ValueChanged<bool>?
      setIsWebInspectable;

  const ChangeLogLevelTile(
      {super.key,
      this.setIsWebInspectable});

  @override
  State<ChangeLogLevelTile>
      createState() =>
          _ChangeLogLevelTileState();
}

class _ChangeLogLevelTileState
    extends State<
        ChangeLogLevelTile> {
  final _levelChangeButtonKey =
      GlobalKey();

  void
      openDropdown() {
    final dropdownInkWell =
        findChildWidgetByType<InkWell>(
      _levelChangeButtonKey.currentContext!,
    );
    assert(dropdownInkWell !=
        null);

    dropdownInkWell
        ?.onTap
        ?.call();
  }

  @override
  Widget build(
      BuildContext
          context) {
    final theme =
        Theme.of(context);
    final mediaWidth =
        MediaQuery.sizeOf(context).width;

    return DropdownButtonHideUnderline(
      child:
          ListTile(
        onTap: openDropdown,
        tileColor: theme.colorScheme.primary,
        iconColor: theme.colorScheme.onPrimary,
        textColor: theme.colorScheme.onPrimary,
        minVerticalPadding: 0,
        horizontalTitleGap: 10,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: const Icon(Icons.bug_report_rounded),
        title: const Text("Log Level"),
        trailing: StreamBuilder<Level?>(
          stream: logging.onLevelChanged,
          initialData: logging.level,
          builder: (context, snapshot) {
            final currentLevel = snapshot.data;
            final levelOptions = [
              ...Level.LEVELS
            ];
            if (currentLevel != null && !Level.LEVELS.contains(currentLevel)) {
              // if custom level is added, add it to the dropdown options
              levelOptions.add(currentLevel);
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
              style: TextStyle(color: theme.colorScheme.onPrimary),
              items: levelOptions.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.name),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _ConsumerIdentifierLabel
    extends StatelessWidget {
  const _ConsumerIdentifierLabel();

  @override
  Widget build(
      BuildContext
          context) {
    return FutureBuilder<
        String>(
      future:
          getSdkConsumerIdentifier(),
      builder:
          (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        return Text(
          snapshot.data!,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall,
        );
      },
    );
  }
}
