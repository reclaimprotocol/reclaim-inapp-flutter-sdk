import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_gnark_zkoperator/src/utils/list.dart';

void main() {
  group('isContiguousSubsequence', () {
    test('empty subsequence returns true', () {
      expect(isContiguousSubsequence([], [1, 2, 3]), true);
    });

    test('subsequence longer than sequence returns false', () {
      expect(isContiguousSubsequence([1, 2, 3, 4], [1, 2, 3]), false);
    });

    test('finds subsequence at start', () {
      expect(isContiguousSubsequence([1, 2], [1, 2, 3, 4]), true);
    });

    test('finds subsequence in middle', () {
      expect(isContiguousSubsequence([2, 3], [1, 2, 3, 4]), true);
    });

    test('finds subsequence at end', () {
      expect(isContiguousSubsequence([3, 4], [1, 2, 3, 4]), true);
    });

    test('non-contiguous subsequence returns false', () {
      expect(isContiguousSubsequence([1, 3], [1, 2, 3, 4]), false);
    });

    test('works with strings', () {
      expect(isContiguousSubsequence(['b', 'c'], ['a', 'b', 'c', 'd']), true);
      expect(isContiguousSubsequence(['a', 'c'], ['a', 'b', 'c', 'd']), false);
    });

    test('single element subsequence', () {
      expect(isContiguousSubsequence([2], [1, 2, 3]), true);
    });

    test('exact match sequence', () {
      expect(isContiguousSubsequence([1, 2, 3], [1, 2, 3]), true);
    });

    test('duplicate elements in subsequence', () {
      expect(isContiguousSubsequence([1, 2, 2, 3], [1, 2, 2, 3]), true);
    });

    test('recurring subsequence in sequence', () {
      expect(isContiguousSubsequence([1, 2, 3], [1, 2, 2, 4, 2, 1, 2, 3, 1, 2, 3]), true);
    });
  });
}
