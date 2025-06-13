import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../session.dart';
import '../verification_request/verification_request.dart';

export 'package:reclaim_inapp_sdk/src/data/session.dart';

export '../verification_request/verification_request.dart';
export 'version.dart';

class ReclaimVerificationRequest {
  final SessionProvider sessionProvider;
  final String providerId;
  final String applicationId;
  final String? contextString;
  final Map<String, String> parameters;

  const ReclaimVerificationRequest({
    required this.applicationId,
    this.contextString,
    required this.providerId,
    required this.sessionProvider,
    this.parameters = const {},
  });

  factory ReclaimVerificationRequest.fromSdkRequest(ClientSdkVerificationRequest template) {
    final log = logging.child('request');
    try {
      final versionConstraintExpression = template.providerVersion ?? '';
      final resolvedVersion = template.resolvedProviderVersion;

      return ReclaimVerificationRequest(
        // allow template, and applicationId to be null.
        applicationId: template.applicationId ?? '',
        providerId: template.providerId ?? '',
        sessionProvider: () {
          return ReclaimSessionInformation(
            sessionId: template.sessionId ?? '',
            signature: template.signature ?? '',
            timestamp: template.timestamp ?? '',
            // SDK (external js sdk) initiated sessions provides resolved version for a verification session.
            version: ProviderVersionExact(
              resolvedVersion != null && resolvedVersion.isNotEmpty ? resolvedVersion : '',
              versionExpression: versionConstraintExpression,
            ),
          );
        },
        parameters: template.parameters ?? const {},
        contextString: template.contextString,
      );
    } catch (e, s) {
      log.severe('Request creation failed from sdk url', e, s);
      throw InvalidRequestReclaimException('Request creation failed from sdk url');
    }
  }
}
