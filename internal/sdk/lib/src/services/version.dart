import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

import '../overrides/overrides.dart';
import 'feature_flag.dart';
import 'source/source.dart';

enum SDKUpdateRequirementType { immediate, flexible, none }

class SDKUpdateRequirement extends ReclaimOverride<SDKUpdateRequirement> {
  final Version? immediate;
  final Version? flexible;

  const SDKUpdateRequirement({required this.immediate, required this.flexible});

  @override
  SDKUpdateRequirement copyWith({Version? immediate, Version? flexible}) {
    return SDKUpdateRequirement(flexible: flexible, immediate: immediate);
  }
}

class VersionInformationService {
  Future<SDKUpdateRequirement> getLatest() async {
    final overridenRequirements = ReclaimOverrides.sdkUpdateRequirements;
    if (overridenRequirements != null) {
      return overridenRequirements;
    }

    const key = 'inAppUpdateRequirements';
    final result = await FeatureFlagService.fetchFeatureFlagsFromServer(featureFlagNames: [key]);
    final versions = json.decode(result[key] ?? '{}') as Map;
    final immediate = versions['immediate'];
    final flexible = versions['flexible'];
    return SDKUpdateRequirement(
      immediate: immediate is String ? Version.parse(immediate) : null,
      flexible: flexible is String ? Version.parse(flexible) : null,
    );
  }

  Future<SDKUpdateRequirementType> getUpdateRequirement() async {
    final current = await getReclaimMainSdkVersion();
    if (current.isEmpty || current == 'unknown') return SDKUpdateRequirementType.none;
    final latest = await getLatest();
    final immediate = latest.immediate;
    final flexible = latest.flexible;
    final currentVersion = Version.parse(current.replaceFirst('v', ''));
    if (immediate != null) {
      if (immediate > currentVersion) {
        return SDKUpdateRequirementType.immediate;
      }
    }
    if (flexible != null) {
      if (flexible > currentVersion) {
        return SDKUpdateRequirementType.flexible;
      }
    }
    return SDKUpdateRequirementType.none;
  }
}
