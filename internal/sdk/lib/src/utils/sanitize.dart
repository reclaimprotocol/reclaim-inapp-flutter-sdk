Map<K, V>? ensureMap<K, V>(dynamic data) {
  if (data is Map) {
    if (data is Map<K, V>) {
      return data;
    }
    return <K, V>{
      for (final entry in data.entries.where((e) => e.key is K && e.value is V))
        (entry.key as K): entry.value as V,
    };
  }
  return null;
}
