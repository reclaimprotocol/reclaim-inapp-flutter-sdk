import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/providers.dart';
import '../../services/ai_flow_service.dart';
import '../../src/components/loading/param_value.dart';
import '../action_button.dart';
import '../icon.dart';
import '../params/string.dart';
import '../webview_bottom.dart';

class ResultBottomSheet
    extends StatefulWidget {
  final HttpProvider
      providerData;
  final List<AIFlowDataReceipt>
      params;
  final AIFlowService
      aiFlowService;
  final String
      sessionId;
  final VoidCallback
      onSubmit;
  final String
      webviewUrl;
  final Function(List<AIFlowDataReceipt>)
      onUpdate;
  final Future<bool>
          Function(String)
      onContinue;
  final Future<void>
          Function()
      onSubmitManualVerification;
  final Future<void>
          Function()
      onAiDismiss;

  const ResultBottomSheet({
    super.key,
    required this.providerData,
    required this.params,
    required this.aiFlowService,
    required this.sessionId,
    required this.webviewUrl,
    required this.onSubmit,
    required this.onUpdate,
    required this.onContinue,
    required this.onSubmitManualVerification,
    required this.onAiDismiss,
  });

  static Future<void>
      show(
    BuildContext
        context, {
    required HttpProvider
        providerData,
    required List<AIFlowDataReceipt>
        params,
    required AIFlowService
        aiFlowService,
    required String
        sessionId,
    required String
        webviewUrl,
    required VoidCallback
        onSubmit,
    required Function(List<AIFlowDataReceipt>)
        onUpdate,
    required Future<bool> Function(String)
        onContinue,
    required Future<void> Function()
        onSubmitManualVerification,
    required Future<void> Function()
        onAiDismiss,
  }) {
    return showModalBottomSheet(
      context:
          context,
      isScrollControlled:
          true,
      enableDrag:
          false,
      isDismissible:
          false,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) =>
          ResultBottomSheet(
        providerData: providerData,
        params: params,
        aiFlowService: aiFlowService,
        sessionId: sessionId,
        webviewUrl: webviewUrl,
        onSubmit: onSubmit,
        onUpdate: onUpdate,
        onContinue: onContinue,
        onSubmitManualVerification: onSubmitManualVerification,
        onAiDismiss: onAiDismiss,
      ),
    );
  }

  @override
  State<ResultBottomSheet>
      createState() =>
          _ResultBottomSheetState();
}

class _ResultBottomSheetState
    extends State<
        ResultBottomSheet> {
  List<AIFlowDataReceipt>
      _params =
      [];
  bool
      _isLoading =
      false;
  String?
      _error;

  @override
  void
      initState() {
    super
        .initState();
    _params =
        widget.params;
    WidgetsBinding
        .instance
        .addPostFrameCallback((timeStamp) {
      _submitData();
    });
  }

  void
      _submitData() async {
    setState(
        () {
      _isLoading =
          true;
      _error =
          null;
    });

    try {
      final result =
          await widget.aiFlowService.extractData(
        widget.webviewUrl,
        widget.sessionId,
      );
      if (!mounted)
        return;

      if (result.isEmpty) {
        throw Exception('No data found');
      }

      setState(() {
        _params = _params.map((param) {
          final matchingResult = result.firstWhere(
            (r) => r.name == param.name,
            orElse: () => param,
          );

          if (param.extractedValue == null && (matchingResult.extractedValue != null || matchingResult.recommendation != null)) {
            return matchingResult;
          }
          return param;
        }).toList();

        _isLoading = false;
      });
      widget.onUpdate(_params);
    } catch (e) {
      if (!mounted)
        return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to extract data.';
      });
    }
  }

  void
      _showMissingFieldsAlert() {
    final missingFields = _params
        .where((param) => param.extractedValue == null)
        .map((param) => formatParamsLabel(param.name))
        .toList();

    showDialog(
      context:
          context,
      builder: (context) =>
          AlertDialog(
        title: const Text('Missing Information'),
        content: Text(
          'Please provide the following required fields: ${missingFields.join(", ")}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSubmit();
            },
            child: const Text('Submit Anyway'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  bool
      _shouldAlert() {
    final allProviders = (_params.any((param) =>
        param.extractedValue ==
        null));
    final shouldAlert =
        !_isLoading && (_error != null || allProviders);
    return shouldAlert;
  }

  @override
  Widget build(
      BuildContext
          context) {
    return SafeArea(
      bottom:
          true,
      child:
          Padding(
        padding: const EdgeInsets.only(
          right: 16,
          left: 16,
          bottom: 16,
          top: 11,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  alignment: AlignmentDirectional.topEnd,
                  fit: StackFit.passthrough,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: 4.0,
                        top: 5,
                        end: 5,
                      ),
                      child: Tooltip(
                        message: widget.providerData.name,
                        child: LogoIcon(logoUrl: widget.providerData.logoUrl),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onAiDismiss();
                  },
                ),
              ],
            ),
            if (_error == null) const SizedBox(height: 12.0),
            if (_error == null)
              Text(
                _error != null ? '' : (_isLoading ? 'AI is trying to find your data...' : 'You are sharing:'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1.2,
                  color: Color(0xFF1D2126),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            if (_error == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ParamsText(
                      params: aiParamsText(
                        _params,
                        _error != null && !_isLoading,
                      ),
                      inProgressParams: aiInProgressParamsText(_params),
                      actionUrls: aiActionUrlsText(_params),
                      onContinue: (actionUrl) async {
                        Navigator.of(context).pop();
                        return await widget.onContinue(actionUrl);
                      },
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                const SizedBox(height: 16.0),
                if (!_isLoading && _params.any((param) => param.extractedValue != null))
                  ActionButton(
                    onPressed: () {
                      if (_shouldAlert()) {
                        _showMissingFieldsAlert();
                      } else {
                        widget.onSubmit();
                      }
                    },
                    child: const Text('Submit'),
                  )
                else if (_error != null)
                  ActionButton(
                    onPressed: () {
                      widget.onSubmitManualVerification();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Submit For Manual Verification'),
                  ),
              ],
            ),
            WebviewBottomBar(sessionId: widget.sessionId),
          ],
        ),
      ),
    );
  }
}

Map<String,
        String>
    aiParamsText(
  List<AIFlowDataReceipt>
      params,
  bool
      hasError,
) {
  final Map<String,
          String>
      result =
      {};
  for (final param
      in params) {
    if (param.extractedValue !=
        null) {
      result[param.name] =
          param.extractedValue!;
    } else {
      result[param.name] = hasError
          ? 'Error'
          : (param.recommendation ?? '');
    }
  }
  return result;
}

Map<String,
        double>
    aiInProgressParamsText(
        List<AIFlowDataReceipt> params) {
  final Map<String,
          double>
      result =
      {};
  for (final param
      in params) {
    if (param.extractedValue !=
        null) {
      result[param.name] =
          1.0;
    } else {
      result[param.name] = param.recommendation == null
          ? 0.5
          : 1.0;
    }
  }
  return result;
}

Map<String,
        String>
    aiActionUrlsText(
        List<AIFlowDataReceipt> params) {
  final Map<String,
          String>
      result =
      {};
  for (final param
      in params) {
    result[param.name] =
        param.actionUrl ?? '';
  }
  return result;
}

class ParamsText
    extends StatelessWidget {
  final Map<
      String,
      String> params;
  final Map<
      String,
      double> inProgressParams;
  final Map<
      String,
      String> actionUrls;
  final Future<bool>
          Function(String)
      onContinue;

  const ParamsText({
    super.key,
    required this.params,
    this.inProgressParams =
        const {},
    this.actionUrls =
        const {},
    required this.onContinue,
  });

  @override
  Widget build(
      BuildContext
          context) {
    final filteredParams = params
        .entries
        .where((entry) {
      final key =
          entry.key.toUpperCase().trim();
      // Hide entries that starts with 'REQ_' (case insensitive)
      return !key.startsWith('REQ_') &&
          !key.startsWith('URL_');
    });

    final displayedParams =
        [
      ...filteredParams
    ].toList();

    final displayedParamsValues = List.generate(
        displayedParams.length,
        (
      index,
    ) {
      final entry =
          displayedParams.elementAt(index);
      final label =
          formatParamsLabel(entry.key);
      final isLast =
          index == displayedParams.length - 1;
      final value =
          entry.value.trim();
      final progress =
          inProgressParams[entry.key];

      final actionUrl =
          actionUrls[entry.key];
      Widget
          valueWidget;
      if (actionUrl?.isNotEmpty ==
          true) {
        valueWidget = GestureDetector(
          onTap: () async {
            await onContinue(actionUrl!);
          },
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  key: ValueKey(entry.key),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$label:  ',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (progress != null && progress < 1)
                        WidgetSpan(child: const LoadingParamValue())
                      else
                        TextSpan(
                          text: value,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF2563EB),
                            decorationThickness: 2,
                          ),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 16, color: Color(0xFF2563EB)),
            ],
          ),
        );
      } else {
        valueWidget = Text.rich(
          key: ValueKey(entry.key),
          TextSpan(
            children: [
              TextSpan(
                text: '$label:  ',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (progress != null && progress < 1)
                WidgetSpan(child: const LoadingParamValue())
              else
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        );
      }

      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: valueWidget),
            if (progress != null && progress < 1)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const LoadingParamValue(
                  height: null,
                  width: null,
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
              )
            else if (actionUrl == null && value.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: VerifiedIcon(),
              ),
          ],
        ),
      );
    });

    return Padding(
      padding:
          const EdgeInsets.all(8.0),
      child:
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayedParamsValues,
      ),
    );
  }
}
