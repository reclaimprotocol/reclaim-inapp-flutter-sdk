import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logging/logging.dart';
import '../../widgets/params/string.dart';

class DevController extends ValueNotifier<Map<String, Object?>> {
  DevController() : super({});

  static final shared = DevController();

  @override
  set value(Map<String, Object?> value) {
    if (logging.level >= Level.INFO) return;
    super.value = value;
  }

  void update(String key, Object? data) {
    value = {...value, key: data};
  }

  void push(String key, Object? data) {
    final entry = value[key] as List? ?? [];
    update(key, [...entry, data]);
  }

  void clear(String key) {
    update(key, null);
  }

  void clearAll() {
    value = {};
  }
}

class Dev extends StatefulWidget {
  const Dev({super.key});

  static void open(BuildContext context) {
    if (logging.level >= Level.INFO) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const Dev()));
  }

  @override
  State<Dev> createState() => _DevState();
}

class _DevState extends State<Dev> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev')),
      body: ValueListenableBuilder(
        valueListenable: DevController.shared,
        builder: (context, map, child) {
          return ListView.builder(
            itemCount: map.entries.length,
            itemBuilder: (context, index) {
              final entry = map.entries.elementAt(index);
              return ListTile(
                title: Text(formatParamsLabel(entry.key)),
                trailing: IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: json.encode(entry.value)));
                  },
                  icon: const Icon(Icons.copy),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          DevController.shared.clearAll();
        },
        label: const Text('Clear'),
        icon: const Icon(Icons.clear),
      ),
    );
  }
}
