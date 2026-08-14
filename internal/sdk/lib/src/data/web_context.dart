import 'dart:async';
import 'dart:ui';

import '../logging/logging.dart';

/// A class that holds web context data that can be used by the coordinator and handlers
class WebContext {
  static final _log = logging.child('WebContext');

  String? _currentWebPageUrl;
  String _lastInputUrl = '';
  bool _aiFlowDone = false;
  bool _isLoggedIn = false;
  bool _markedLoggedInByAI = false;
  String _infoText = '';
  DateTime? _lastAiResponseTime;
  VoidCallback? _hideReviewSheet;
  final int _potentialLoginTimeoutS;

  // Callback function type for infoText changes
  void Function(String)? _onInfoTextChanged;

  /// Constructor for WebContext
  /// [_potentialLoginTimeoutS] - Timeout in seconds to show the review sheet if the user is potentially logged in
  WebContext({this._potentialLoginTimeoutS = 20});

  String? get currentWebPageUrl => _currentWebPageUrl;
  String get lastInputUrl => _lastInputUrl;
  bool get aiFlowDone => _aiFlowDone;
  bool get isLoggedIn => _isLoggedIn;
  bool get markedLoggedInByAI => _markedLoggedInByAI;
  String get infoText => _infoText;
  int get potentialLoginTimeoutS => _potentialLoginTimeoutS;
  void setHideReviewSheetCallback(VoidCallback? cb) {
    _hideReviewSheet = cb;
  }

  /// Register a callback to be notified when infoText changes
  void onInfoTextChanged(void Function(String newInfoText) callback) {
    _onInfoTextChanged = callback;
  }

  /// Remove the infoText change listener
  void removeInfoTextListener() {
    _onInfoTextChanged = null;
  }

  bool aiRespondedRecently() {
    if (_lastAiResponseTime == null) {
      return true;
    }
    return DateTime.now().difference(_lastAiResponseTime!).inSeconds < 20;
  }

  void setCurrentWebPageUrl(String? url) {
    _currentWebPageUrl = url;
  }

  void setLastInputUrl(String url) {
    _lastInputUrl = url;
  }

  void setAiFlowDone() {
    _lastAiResponseTime = DateTime.now();
    _aiFlowDone = true;
  }

  void setIsLoggedIn(bool isLoggedIn) {
    _isLoggedIn = isLoggedIn;
    if (!isLoggedIn) {
      // Hiding the review sheet because the user isn't logged in and user has to interact with the page to login
      final cb = _hideReviewSheet;
      if (cb != null) {
        try {
          cb();
        } catch (e, s) {
          _log.warning('Error calling hideReviewSheet callback for WebContext', e, s);
        }
      } else {
        _log.info('No hideReviewSheet callback set');
      }
    }
  }

  void setMarkedLoggedInByAI() {
    _markedLoggedInByAI = true;
    _isLoggedIn = true;
  }

  void setInfoText(String infoText) {
    _infoText = infoText;
    _lastAiResponseTime = DateTime.now();
    // Notify listener if registered
    _onInfoTextChanged?.call(infoText);
  }

  void waitForAILoginResponse() {
    _log.info('Waiting for AI login response for $_potentialLoginTimeoutS seconds');
    // Add delay and check if markedLoggedInByAI is false
    Timer(Duration(seconds: _potentialLoginTimeoutS), () {
      if (!markedLoggedInByAI) {
        _log.info(
          'LoginDetectionHandler: markedLoggedInByAI is false after $_potentialLoginTimeoutS seconds, setting isLoggedIn to false',
        );
        setIsLoggedIn(false);
      }
    });
  }

  void handlePotentialLoginTimeout() {
    setLastInputUrl('');
    setIsLoggedIn(true);
    waitForAILoginResponse();
  }
}
