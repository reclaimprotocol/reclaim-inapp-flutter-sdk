T? maybeGetAtIndex<T>(Iterable<T>? list, int index) {
  if (list == null) return null;
  if (index < 0 || index >= list.length) {
    return null;
  }
  return list.elementAt(index);
}
