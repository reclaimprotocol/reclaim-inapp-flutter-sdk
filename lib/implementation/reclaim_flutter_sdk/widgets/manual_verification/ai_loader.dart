import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AILoader
    extends StatelessWidget {
  const AILoader(
      {super.key});

  @override
  Widget build(
      BuildContext
          context) {
    return Positioned(
      right:
          0,
      bottom:
          0,
      child:
          Material(
        color: const Color(0xff007AFF),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4.0),
            topRight: Radius.circular(2.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 4.0,
          ),
          child: SpinKitFadingCircle(
            color: Colors.white,
            size: 32.0,
          ),
        ),
      ),
    );
  }
}
