import 'dart:typed_data';

bool isContiguousSubsequence<T>(List<T> subsequence, List<T> sequence) {
  int subLength = subsequence.length;
  int seqLength = sequence.length;

  if (subLength == 0) {
    return true; // Empty subsequence is always a contiguous subsequence
  }

  if (subLength > seqLength) {
    return false; // Subsequence can't be longer than the sequence
  }

  for (int i = 0; i <= seqLength - subLength; i++) {
    bool match = true;
    for (int j = 0; j < subLength; j++) {
      if (sequence[i + j] != subsequence[j]) {
        match = false;
        break; // No need to continue checking if a mismatch is found
      }
    }
    if (match) {
      return true;
    }
  }

  return false; // Subsequence not found
}

bool hasSubview(Uint8List view, Uint8List subview) {
  return isContiguousSubsequence<int>(subview, view);
}
