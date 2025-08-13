/// A class that holds web context data that can be used by the coordinator and handlers
class WebContext {
  String? _currentWebPageUrl;
  String _lastInputUrl = '';
  bool _aiFlowDone = false;
  bool _isLoggedIn = false;
  bool _markedLoggedInByAI = false;
  String _infoText = '';
  DateTime? _lastAiResponseTime;
  bool _signedOutByAi = false;

  // Callback function type for infoText changes
  void Function(String)? _onInfoTextChanged;

  String? get currentWebPageUrl => _currentWebPageUrl;
  String get lastInputUrl => _lastInputUrl;
  bool get aiFlowDone => _aiFlowDone;
  bool get isLoggedIn => _isLoggedIn;
  bool get markedLoggedInByAI => _markedLoggedInByAI;
  String get infoText => _infoText;
  bool get signedOutByAi => _signedOutByAi;

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

  void setSignedOutByAi() {
    _signedOutByAi = true;
    _markedLoggedInByAI = false;
    _isLoggedIn = false;
  }
}
