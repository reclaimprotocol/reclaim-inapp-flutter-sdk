class AIResponse {
  final List<AIJob> jobs;

  AIResponse({required this.jobs});

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(jobs: (json['jobs'] as List).map((job) => AIJob.fromJson(job as Map<String, dynamic>)).toList());
  }
}

class AIJob {
  final int jobId;
  // TODO: change this to enum
  final String status;
  final List<AIAction> actions;

  AIJob({required this.jobId, required this.status, required this.actions});

  factory AIJob.fromJson(Map<String, dynamic> json) {
    return AIJob(
      jobId: json['chunkId'],
      status: json['status'],
      actions: (json['aiActions'] as List).map((action) => AIAction.fromJson(action as Map<String, dynamic>)).toList(),
    );
  }
}

sealed class AIAction {
  const AIAction();

  String get type;

  factory AIAction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;

    switch (typeStr) {
      case 'show_info_text':
        final text = json['content'] as String?;
        if (text == null) {
          throw ArgumentError('content is required for RECOMMENDATION type');
        }
        return ShowInfoAction(text);

      case 'show_recommendation_text':
        final text = json['content'] as String?;
        if (text == null) {
          throw ArgumentError('content is required for RECOMMENDATION type');
        }
        return RecommendationAction(text);

      case 'recommended_navigation':
        final url = json['content'] as String?;
        if (url == null) {
          throw ArgumentError('content is required for URL_NAVIGATION type');
        }
        return NavigationAction(url);

      case 'update_provider_version':
        final versionNumber = json['content'] as String?;
        if (versionNumber == null) {
          throw ArgumentError('versionNumber is required for $typeStr type');
        }
        return ProviderVersionUpdateAction(versionNumber);

      case 'click_button':
        final jsSelector = json['metadata']['jsSelector'] as String?;
        if (jsSelector == null) {
          throw ArgumentError('jsSelector is required for BUTTON_CLICK type');
        }
        return ButtonClickAction(jsSelector);

      case 'go_back':
        return const GoBackAction();

      case 'no_action':
        return const NoAction();

      default:
        throw ArgumentError('Invalid action type: $typeStr');
    }
  }
}

class ShowInfoAction extends AIAction {
  final String text;
  const ShowInfoAction(this.text);

  @override
  String get type => 'show_info_text';

  factory ShowInfoAction.fromJson(Map<String, dynamic> json) {
    return ShowInfoAction(json['content'] as String);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShowInfoAction && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

class RecommendationAction extends AIAction {
  final String text;
  const RecommendationAction(this.text);

  @override
  String get type => 'show_recommendation_text';

  factory RecommendationAction.fromJson(Map<String, dynamic> json) {
    return RecommendationAction(json['content'] as String);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendationAction && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

class NavigationAction extends AIAction {
  final String url;
  const NavigationAction(this.url);

  @override
  String get type => 'navigation';

  factory NavigationAction.fromJson(Map<String, dynamic> json) {
    return NavigationAction(json['content'] as String);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationAction && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}

class ProviderVersionUpdateAction extends AIAction {
  final String versionNumber;
  const ProviderVersionUpdateAction(this.versionNumber);

  @override
  String get type => 'update_provider_version';

  factory ProviderVersionUpdateAction.fromJson(Map<String, dynamic> json) {
    return ProviderVersionUpdateAction(json['content'] as String);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProviderVersionUpdateAction && other.versionNumber == versionNumber;
  }

  @override
  int get hashCode => versionNumber.hashCode;
}

class ButtonClickAction extends AIAction {
  final String jsSelector;
  const ButtonClickAction(this.jsSelector);

  @override
  String get type => 'buttonClick';

  factory ButtonClickAction.fromJson(Map<String, dynamic> json) {
    return ButtonClickAction(json['metadata']['jsSelector'] as String);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ButtonClickAction && other.jsSelector == jsSelector;
  }

  @override
  int get hashCode => jsSelector.hashCode;
}

class GoBackAction extends AIAction {
  const GoBackAction();

  @override
  String get type => 'go_back';

  @override
  bool operator ==(Object other) {
    return other is GoBackAction;
  }

  @override
  int get hashCode => 0;
}

class NoAction extends AIAction {
  const NoAction();

  @override
  String get type => 'noAction';

  @override
  bool operator ==(Object other) {
    return other is NoAction;
  }

  @override
  int get hashCode => 0;
}

// Extension methods for creating actions
extension AIActionFactory on AIAction {
  static AIAction recommendation(String text) => ShowInfoAction(text);
  static AIAction navigation(String url) => NavigationAction(url);
  static AIAction providerVersionUpdate(String versionNumber) => ProviderVersionUpdateAction(versionNumber);
  static AIAction buttonClick(String jsSelector) => ButtonClickAction(jsSelector);
  static AIAction goBack() => const GoBackAction();
  static AIAction noAction() => const NoAction();
}

class ActionHistory {
  final AIAction action;
  final DateTime timestamp;

  ActionHistory(this.action, this.timestamp);
}
