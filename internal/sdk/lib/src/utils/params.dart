import '../data/providers.dart';

Set<String> paramNamesFromRequestData(List<DataProviderRequest>? requestData) {
  if (requestData == null) return <String>{};
  return requestData
      .map<Set<String>>((e) {
        final matches = e.responseMatches;
        final paramNames = <String>{};
        if (matches == null) return <String>{};
        for (final match in matches) {
          final value = match.value;
          if (value == null || value.isEmpty) continue;
          final regex = RegExp(r'\{\{(.*?)\}\}');
          final matches = regex.allMatches(value);
          for (final match in matches) {
            final key = match.group(1);
            if (key != null) {
              paramNames.add(key);
            }
          }
        }
        return paramNames;
      })
      .fold(<String>{}, (previous, next) {
        return {...previous, ...next};
      });
}

Map<String, double> attachProgressToParams(Set<String> paramNames, double progress) {
  return paramNames
      .map((param) {
        return {param: progress};
      })
      .fold(<String, double>{}, (prev, next) {
        return {...prev, ...next};
      });
}
