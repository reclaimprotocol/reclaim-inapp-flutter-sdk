void setValuesInRange(
    List<int>
        list,
    int
        start,
    int
        end,
    List<int>
        values) {
  final count =
      end -
          start;
  final length =
      values.length;
  final isPaddingRequired =
      count >
          length;
  final padding = isPaddingRequired
      ? count -
          length
      : 0;
  list.setRange(
      start,
      end,
      isPaddingRequired
          ? (List.filled(padding, 0) + values)
          : values);
}
