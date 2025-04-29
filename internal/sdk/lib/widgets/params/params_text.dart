import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/src/components/loading/param_value.dart';
import 'package:reclaim_flutter_sdk/types/create_claim.dart';
import 'package:reclaim_flutter_sdk/utils/data.dart';
import 'package:reclaim_flutter_sdk/widgets/claim_creation/claim_creation.dart';
import 'package:reclaim_flutter_sdk/widgets/icon/icons.dart';
import 'package:reclaim_flutter_sdk/widgets/spoiler/widget.dart';
import 'package:reclaim_flutter_sdk/widgets/svg_icon.dart';

import 'string.dart';

class ProvingParameter implements Comparable<ProvingParameter> {
  final String key;
  final String? value;
  final String? unhashedValue;
  final num? order;
  final String? requestIdentifier;
  final bool isPublic;
  final bool markedForHashing;
  final bool isPending;
  final double progress;

  const ProvingParameter({
    required this.key,
    required this.value,
    required this.requestIdentifier,
    required this.order,
    required this.unhashedValue,
    required this.isPublic,
    required this.markedForHashing,
    required this.isPending,
    required this.progress,
  });

  @override
  int compareTo(ProvingParameter other) {
    if (isPublic && !other.isPublic) return 1;
    if (!isPublic && other.isPublic) return -1;

    if (isPending && !other.isPending) return 1;
    if (!isPending && other.isPending) return -1;
    if (isPending && other.isPending) {
      // position the one with the higher progress first
      final result = other.progress.compareTo(progress);
      if (result != 0) return result;
    }

    final order = this.order;
    final otherOrder = other.order;
    if (order != null || otherOrder != null) {
      if (order == null) return 1;
      if (otherOrder == null) return -1;
      return order.compareTo(otherOrder);
    }

    return key.compareTo(other.key);
  }

  @override
  bool operator ==(Object other) {
    if (other is! ProvingParameter) return false;
    return key == other.key && requestIdentifier == other.requestIdentifier;
  }

  @override
  int get hashCode => Object.hash(key, requestIdentifier);

  @override
  String toString() {
    return 'ProvingParameter(key: $key, value: $value, requestIdentifier: $requestIdentifier, order: $order, unhashedValue: $unhashedValue, isPublic: $isPublic, markedForHashing: $markedForHashing, isPending: $isPending, progress: $progress)';
  }
}

class ParamInfo {
  final List<ProvingParameter> params;

  const ParamInfo({required this.params});

  int get uniqueParamsCount {
    return params.length;
  }

  static ParamInfo fromBuildContext(BuildContext context) {
    final controller = ClaimCreationController.of(context);
    final provingParams = <ProvingParameter>{};

    for (final requestData in controller.value.httpProvider.requestData) {
      final paramKeys = requestData.getParameterNames();
      for (final key in paramKeys) {
        final selection = requestData.getResponseSelectionByParameterName(key);

        final markedForHashing = selection?.redaction?.markedForHashing == true;

        _addParamInSet(
          provingParams,
          ProvingParameter(
            key: key,
            value: null,
            requestIdentifier: requestData.requestIdentifier,
            order: null,
            unhashedValue: null,
            isPublic: false,
            markedForHashing: markedForHashing,
            isPending: true,
            progress: 0.0,
          ),
        );
      }
    }

    final claims = controller.value.claims;

    for (final claim in claims) {
      for (final entry in claim.request.extractedData.witnessParams.entries) {
        final selection = claim.request.requestData.getResponseSelectionByParameterName(
          entry.key,
        );

        final markedForHashing = selection?.redaction?.markedForHashing == true;

        _addParamInSet(
          provingParams,
          ProvingParameter(
            key: entry.key,
            value: entry.value,
            requestIdentifier: claim.requestIdentifier,
            order: null,
            unhashedValue: markedForHashing ? entry.value : null,
            isPublic: false,
            markedForHashing: markedForHashing,
            isPending: claim.progress != 1.0,
            progress: claim.progress,
          ),
        );
      }

      final proofs = claim.proofs;
      final proofContext = proofs?.firstOrNull?.claimData.context;

      if (proofContext == null || proofContext.isEmpty) continue;
      final map = json.decode(proofContext);
      if (map is! Map) continue;
      final extractedParameters = map['extractedParameters'];
      if (extractedParameters is! Map) continue;

      for (final entry in extractedParameters.entries) {
        final key = entry.key;
        final value = entry.value;
        if (entry is! String && value is! String) continue;
        final selection = claim.request.requestData.getResponseSelectionByParameterName(
          key,
        );

        final markedForHashing = selection?.redaction?.markedForHashing == true;

        _addParamInSet(
          provingParams,
          ProvingParameter(
            key: key,
            value: value,
            requestIdentifier: claim.requestIdentifier,
            order: selection?.match?.order,
            unhashedValue: null,
            isPublic: false,
            markedForHashing: markedForHashing,
            isPending: false,
            progress: 1.0,
          ),
        );
      }
    }

    final publicParams = processPublicData(controller.value.publicData);
    if (publicParams != null) {
      for (final entry in publicParams.entries) {
        _addParamInSet(
          provingParams,
          ProvingParameter(
            key: entry.key,
            value: entry.value,
            requestIdentifier: null,
            order: null,
            unhashedValue: null,
            isPublic: true,
            markedForHashing: false,
            isPending: false,
            progress: 1.0,
          ),
        );
      }
    }

    final params =
        provingParams
            .where((entry) {
              final key = entry.key.toUpperCase().trim();
              // Hide entries that starts with 'REQ_' (case insensitive)
              return !key.startsWith('REQ_') &&
                  !key.startsWith('URL_') &&
                  !key.startsWith('DYNAMIC_GEO');
            })
            .toSet()
            .toList();

    params.sort();

    return ParamInfo(params: params);
  }

  static ProvingParameter _addParamInSet(
    Set<ProvingParameter> provingParams,
    ProvingParameter param,
  ) {
    final existingParam =
        provingParams.where((e) {
          return e.hashCode == param.hashCode;
        }).firstOrNull;

    if (existingParam == null) {
      provingParams.add(param);
      return param;
    }

    provingParams.remove(existingParam);
    final newParam = ProvingParameter(
      key: param.key,
      value: param.value,
      requestIdentifier:
          param.requestIdentifier ?? existingParam.requestIdentifier,
      order: param.order ?? existingParam.order,
      unhashedValue: param.unhashedValue ?? existingParam.unhashedValue,
      isPublic: param.isPublic,
      markedForHashing: param.markedForHashing,
      isPending: param.isPending,
      progress: param.progress,
    );

    provingParams.add(newParam);

    return newParam;
  }

  static ParamInfo fromProofs(List<CreateClaimOutput> proofs) {
    final provingParams = <ProvingParameter>{};
    for (final proof in proofs) {
      final proofContext = proof.claimData.context;

      if (proofContext.isEmpty) continue;
      final map = json.decode(proofContext);
      if (map is! Map) continue;
      final extractedParameters = map['extractedParameters'];
      if (extractedParameters is! Map) continue;

      for (final entry in extractedParameters.entries) {
        final key = entry.key;
        final value = entry.value;
        if (entry is! String && value is! String) continue;
        final selection = proof.providerRequest?.getResponseSelectionByParameterName(key);

        final markedForHashing = selection?.redaction?.markedForHashing == true;

        _addParamInSet(
          provingParams,
          ProvingParameter(
            key: key,
            value: value,
            requestIdentifier: proof.providerRequest?.requestIdentifier,
            order: selection?.match?.order,
            unhashedValue: null,
            isPublic: false,
            markedForHashing: markedForHashing,
            isPending: false,
            progress: 1.0,
          ),
        );
      }
    }

    final publicParams = processPublicData(proofs.firstOrNull?.publicData);
    if (publicParams != null) {
      for (final entry in publicParams.entries) {
        _addParamInSet(
          provingParams,
          ProvingParameter(
            key: entry.key,
            value: entry.value,
            requestIdentifier: null,
            order: null,
            unhashedValue: null,
            isPublic: true,
            markedForHashing: false,
            isPending: false,
            progress: 1.0,
          ),
        );
      }
    }

    final params =
        provingParams
            .where((entry) {
              final key = entry.key.toUpperCase().trim();
              // Hide entries that starts with 'REQ_' (case insensitive)
              return !key.startsWith('REQ_') &&
                  !key.startsWith('URL_') &&
                  !key.startsWith('DYNAMIC_GEO');
            })
            .toSet()
            .toList();

    params.sort();

    return ParamInfo(params: params);
  }
}

class ParamsText extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final ParamInfo? info;
  final Iterable<Widget>? tiles;

  ParamsText({super.key, required List<ProvingParameter> params, this.padding})
    : info = ParamInfo(params: params),
      tiles = null;
  const ParamsText.fromParamInfo({super.key, required this.info, this.padding})
    : tiles = null;
  const ParamsText.fromTiles({super.key, required this.tiles, this.padding})
    : info = null;

  static Iterable<Widget> buildTiles(
    BuildContext context,
    ParamInfo info, {
    bool onlyShowPublicAndInProgressParams = false,
  }) {
    final double size = 20;

    final params = info.params.where((it) {
      if (!onlyShowPublicAndInProgressParams) return true;
      if (it.isPublic) return true;
      if (it.isPending) return true;
      return false;
    });

    return params.map<ParamsTile>((entry) {
        return ParamsTile(
          onlyShowPublicAndInProgressParams: onlyShowPublicAndInProgressParams,
          param: entry,
          size: size,
        );
      }).toList()
      ..sort((a, b) {
        return a.param.compareTo(b.param);
      });
  }

  @override
  Widget build(BuildContext context) {
    final tiles =
        info != null ? buildTiles(context, info!) : (this.tiles ?? const []);

    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4.0,
        children:
            tiles.isNotEmpty ? tiles.toList() : const [LoadingParamValue()],
      ),
    );
  }
}

class ParamsTile extends StatelessWidget {
  const ParamsTile({
    super.key,
    this.onlyShowPublicAndInProgressParams = false,
    required this.param,
    this.size = 20,
  });

  final ProvingParameter param;
  final bool onlyShowPublicAndInProgressParams;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = formatParamsLabel(param.key);
    final value = formatParamsValue(param.value ?? '');
    final unhashedValue = formatParamsValue(param.unhashedValue ?? '');

    final isHashedParam = param.markedForHashing;
    final isPublic = param.isPublic;
    final isPending = param.isPending;
    final progress = param.progress;

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    final loadingWidget = Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox.square(
        dimension: size - 4,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          strokeWidth: 2.0,
          value: null,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: () {
            if (onlyShowPublicAndInProgressParams) {
              if (isPublic) {
                return Icon(Icons.data_object_rounded, size: size);
              } else {
                return SvgImageIcon(AppSvgIcons.encrypted, size: size);
              }
            }
            if (isPending) {
              return Icon(
                Icons.hourglass_empty_rounded,
                color: accentColor,
                size: size,
              );
            }
            if (!isPublic) {
              return Icon(Icons.verified, color: Colors.green, size: size);
            }
            if (progress < 1) {
              return loadingWidget;
            }
            return Icon(Icons.data_object_rounded, size: size);
          }(),
        ),
        Expanded(
          child: Text.rich(
            key: ValueKey(param),
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isHashedParam)
                  HashedValueSpoilerTextSpan(
                    value: value,
                    realValue: unhashedValue,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                else if (value.isNotEmpty)
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                else
                  WidgetSpan(child: const LoadingParamValue()),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
