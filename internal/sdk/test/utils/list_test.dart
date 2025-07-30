import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/utils/list.dart';

void main() {
  test('maybeGetAtIndex', () {
    expect(maybeGetAtIndex([], 0), null);
    expect(maybeGetAtIndex([1, 2, 3], -1), null);
    expect(maybeGetAtIndex([1, 2, 3], 0), 1);
    expect(maybeGetAtIndex([1, 2, 3], 1), 2);
    expect(maybeGetAtIndex([1, 2, 3], 2), 3);
    expect(maybeGetAtIndex([1, 2, 3], 3), null);
  });
}
