String
    _interpolateParamsInString(
  String
      template,
  Map<String,
          String>
      params, {
  String prefix =
      '{{',
  String suffix =
      '}}',
}) {
  String
      text =
      template;
  for (final param
      in params.keys) {
    if (!text
        .contains(prefix))
      break;
    if (params[param]?.isNotEmpty !=
        true)
      continue;
    final templateVariable =
        '$prefix$param$suffix';
    final templateVariableParamLowerCase =
        '$prefix${param.toLowerCase()}$suffix';
    // case insensitive contains
    if (!text
        .toLowerCase()
        .contains(templateVariable.toLowerCase()))
      continue;
    text = text.replaceAll(
        templateVariable,
        params[param] ?? '');
    text = text.replaceAll(
        templateVariable.toLowerCase(),
        params[param] ?? '');
    text = text.replaceAll(
        templateVariableParamLowerCase,
        params[param] ?? '');
  }
  return text;
}

String
    interpolateParamsInTemplate(
  String
      template,
  Map<String,
          String>
      params,
) {
  String text = _interpolateParamsInString(
      template,
      params);
  text =
      _interpolateParamsInString(
    text,
    params,
    prefix:
        '%7B%7B',
    suffix:
        '%7D%7D',
  );
  return text;
}
