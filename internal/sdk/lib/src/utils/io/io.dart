import 'io_web.dart' // Stubbed implementation by default.
    // Concrete implementation if File IO is available.
    if (dart.library.io) 'io_platform.dart'
    as io;

bool testingSetIsFlutterTest = false;

bool get isFlutterTest => testingSetIsFlutterTest || io.isFlutterTest;
