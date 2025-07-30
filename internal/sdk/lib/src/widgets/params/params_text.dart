import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/create_claim.dart';
import '../../data/providers.dart';
import '../../utils/data.dart';
import '../claim_creation/claim_creation.dart';
import '../icon/icons.dart';
import '../icon/spinning_hour_glass.dart';
import '../loading/param_value.dart';
import '../spoiler/widget.dart';
import '../svg_icon.dart';
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

    final order = this.order;
    final otherOrder = other.order;
    if (order != null || otherOrder != null) {
      if (order == null) return 1;
      if (otherOrder == null) return -1;
      if (order != otherOrder) {
        return order.compareTo(otherOrder);
      }
    }

    if (key != other.key) {
      return key.compareTo(other.key);
    }

    final requestIdentifier = this.requestIdentifier;
    final otherRequestIdentifier = other.requestIdentifier;

    if (requestIdentifier == null && otherRequestIdentifier == null) return 0;
    if (requestIdentifier == null || requestIdentifier.isEmpty) return 1;
    if (otherRequestIdentifier == null || otherRequestIdentifier.isEmpty) return -1;

    return requestIdentifier.compareTo(otherRequestIdentifier);
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

    final requests = controller.value.httpProvider?.requestData ?? const <DataProviderRequest>[];

    for (final requestData in requests) {
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
            order: selection?.match?.order,
            unhashedValue: null,
            isPublic: false,
            markedForHashing: markedForHashing,
            isPending: true,
            progress: 0.0,
          ),
        );
      }
    }

    final claimState = controller.value;
    final claims = claimState.claims;

    for (final claim in claims) {
      for (final entry in claim.request.extractedData.witnessParams.entries) {
        final selection = claim.request.requestData.getResponseSelectionByParameterName(entry.key);

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
        final selection = claim.request.requestData.getResponseSelectionByParameterName(key);

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

    final params = provingParams
        .where((entry) {
          final key = entry.key.toUpperCase().trim();
          // Hide entries that starts with 'REQ_' (case insensitive)
          return !key.startsWith('REQ_') && !key.startsWith('URL_') && !key.startsWith('DYNAMIC_GEO');
        })
        .where((entry) {
          final isCompleted = claimState.isFinished && !claimState.hasError;
          if (!isCompleted) return true;

          // Only show params that have a value when claim creation is completed
          return !entry.isPending;
        })
        .toSet()
        .toList();

    params.sort();

    return ParamInfo(params: params);
  }

  static ProvingParameter _addParamInSet(Set<ProvingParameter> provingParams, ProvingParameter param) {
    final existingParam = provingParams.where((e) {
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
      requestIdentifier: param.requestIdentifier ?? existingParam.requestIdentifier,
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

    final params = provingParams
        .where((entry) {
          final key = entry.key.toUpperCase().trim();
          // Hide entries that starts with 'REQ_' (case insensitive)
          return !key.startsWith('REQ_') && !key.startsWith('URL_') && !key.startsWith('DYNAMIC_GEO');
        })
        .toSet()
        .toList();

    params.sort();

    return ParamInfo(params: params);
  }
}

class ParamsText extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final ParamInfo? info;
  final List<Widget>? tiles;
  final bool shrinkWrap;

  ParamsText({super.key, required List<ProvingParameter> params, this.padding, this.shrinkWrap = true})
    : info = ParamInfo(params: params),
      tiles = null;
  const ParamsText.fromParamInfo({super.key, required this.info, this.padding, this.shrinkWrap = true}) : tiles = null;
  const ParamsText.fromTiles({super.key, required this.tiles, this.padding, this.shrinkWrap = true}) : info = null;

  static List<Widget> buildTiles(
    BuildContext context,
    ParamInfo info, {
    bool pendingOnly = false,
    bool onlyShowPublicAndInProgressParams = false,
  }) {
    final double size = 20;

    final params = info.params.where((it) {
      if (!onlyShowPublicAndInProgressParams) {
        if (pendingOnly) {
          return it.isPending;
        }
        return true;
      }
      if (it.isPublic) return true;
      if (it.isPending) return true;
      return false;
    }).toList()..sort();

    return [
      for (final entry in params)
        ParamsTile(onlyShowPublicAndInProgressParams: onlyShowPublicAndInProgressParams, param: entry, size: size),
    ];
  }

  @override
  State<ParamsText> createState() => _ParamsTextState();
}

class _ParamsTextState extends State<ParamsText> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    Future.microtask(_postBuild);
  }

  void _postBuild() {
    if (mounted) {
      setState(() {
        _isScrollbarVisible = _controller.position.extentAfter > 0;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final _key = GlobalKey(debugLabel: 'ParamsText');

  bool _isScrollbarVisible = false;

  @override
  Widget build(BuildContext context) {
    final tiles = widget.info != null ? ParamsText.buildTiles(context, widget.info!) : (widget.tiles ?? const []);
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    final isScrollbarVisible = _isScrollbarVisible && tiles.length > 1;

    return Scrollbar(
      controller: _controller,
      thumbVisibility: isScrollbarVisible,
      thickness: 6,
      radius: const Radius.circular(10),
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.passthrough,
        children: [
          ShaderMask(
            shaderCallback: (Rect rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [surface, surface, surface.withValues(alpha: 0)],
                stops: [0.0, 0.9, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: ListView(
              key: _key,
              controller: _controller,
              shrinkWrap: widget.shrinkWrap,
              physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: widget.padding ?? const EdgeInsets.all(8.0),
              children: tiles.isNotEmpty
                  ? tiles.indexed.map((e) {
                      final index = e.$1;
                      final isLast = index == tiles.length - 1;
                      final double bottomPadding;
                      if (tiles.length == 1) {
                        bottomPadding = 0;
                      } else if (isLast) {
                        bottomPadding = 20;
                      } else {
                        bottomPadding = 8.0;
                      }
                      return Padding(
                        padding: EdgeInsets.only(bottom: bottomPadding),
                        child: e.$2,
                      );
                    }).toList()
                  : const [
                      LoadingParamValue(
                        // adjustment for size difference when values are available
                        height: 14 + 5.3,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class ParamsTile extends StatefulWidget {
  const ParamsTile({super.key, this.onlyShowPublicAndInProgressParams = false, required this.param, this.size = 20});

  final ProvingParameter param;
  final bool onlyShowPublicAndInProgressParams;
  final double size;

  @override
  State<ParamsTile> createState() => _ParamsTileState();
}

class _ParamsTileState extends State<ParamsTile> {
  late final _key = GlobalKey(debugLabel: 'ParamsTileKey#$hashCode');
  late final _valueKey = GlobalKey(debugLabel: 'ParamsTileValueKey#$hashCode');

  late final String keyPrefix = 'paramstile-$hashCode';

  bool _canShowHumanizedValue = true;

  @override
  Widget build(BuildContext context) {
    final label = formatParamsLabel(widget.param.key);
    final rawValue = widget.param.value;

    final isCollection = rawValue == null && widget.param.isPending ? false : isValueCollection(rawValue ?? '');
    final value = rawValue == null && widget.param.isPending
        ? null
        : formatParamsValue(rawValue ?? '', humanize: _canShowHumanizedValue);
    final unhashedValue = widget.param.unhashedValue == null
        ? null
        : formatParamsValue(widget.param.unhashedValue ?? '');

    final isHashedParam = widget.param.markedForHashing;
    final isPublic = widget.param.isPublic;
    final isPending = widget.param.isPending;
    final progress = widget.param.progress;

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    final loadingWidget = Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox.square(
        dimension: widget.size - 4,
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
          child: AnimatedSwitcher(
            key: _key,
            duration: Durations.medium1,
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: () {
              if (widget.onlyShowPublicAndInProgressParams) {
                if (isPublic) {
                  return Icon(key: Key('$keyPrefix-public'), Icons.summarize_outlined, size: widget.size);
                } else {
                  return SvgImageIcon(key: Key('$keyPrefix-encrypted'), AppSvgIcons.encrypted, size: widget.size);
                }
              }
              if (isPending) {
                return SpinningHourglass(key: Key('$keyPrefix-pending'), color: accentColor, size: widget.size);
              }
              if (!isPublic) {
                return Icon(key: Key('$keyPrefix-verified'), Icons.verified, color: Colors.green, size: widget.size);
              }
              if (progress < 1) {
                return loadingWidget;
              }
              return Icon(key: Key('$keyPrefix-data-object'), Icons.summarize_outlined, size: widget.size);
            }(),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Flexible(
                flex: 0,
                child: Builder(
                  builder: (context) {
                    final width = MediaQuery.of(context).size.width;
                    final maxWidth = width * 0.5;

                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0).add(EdgeInsetsDirectional.only(end: 8)),
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.normal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Flexible(
                child: AnimatedSwitcher(
                  key: _valueKey,
                  duration: Durations.medium1,
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: () {
                    if (value == null) {
                      return LoadingParamValue(color: accentColor.withValues(alpha: 0.4));
                    } else if (isHashedParam) {
                      return HashedValueTextSpanWidget(
                        value: value,
                        realValue: unhashedValue,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w400,
                          fontVariations: [FontVariation.weight(400)],
                        ),
                      );
                    } else {
                      Widget child = Text(
                        value,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w500,
                          fontVariations: [FontVariation.weight(500)],
                        ),
                        maxLines: 1,
                      );
                      if (isCollection) {
                        final borderRadius = BorderRadius.circular(10);

                        if (_canShowHumanizedValue) {
                          child = Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_file_rounded, size: 14),
                                SizedBox(width: 4),
                                Padding(padding: const EdgeInsetsDirectional.only(end: 4.0), child: child),
                              ],
                            ),
                          );
                        }

                        child = InkWell(
                          onTap: () {
                            setState(() {
                              _canShowHumanizedValue = !_canShowHumanizedValue;
                            });
                          },
                          borderRadius: borderRadius,
                          child: child,
                        );

                        if (_canShowHumanizedValue) {
                          child = Material(
                            color: Colors.white30,
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius,
                              side: BorderSide(color: Color(0xFFccd6df)),
                            ),
                            child: child,
                          );
                        }
                      }
                      return child;
                    }
                  }(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
