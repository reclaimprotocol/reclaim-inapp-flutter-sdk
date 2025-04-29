import 'dart:math';

String generateRequestId() {
  final random = Random();
  final randomNumber = random.nextDouble();
  final hexString = randomNumber.toStringAsFixed(16).substring(2);
  return hexString;
}
