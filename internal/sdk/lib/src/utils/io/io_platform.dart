import 'dart:io';

bool get isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');
