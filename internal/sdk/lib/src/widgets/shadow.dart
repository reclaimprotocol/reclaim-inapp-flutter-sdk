import 'package:flutter/widgets.dart';

// Shamelessly borrowed from Sophon's design
const List<BoxShadow> reclaimBoxShadow = <BoxShadow>[
  BoxShadow(
    offset: Offset(0.0, 1.5),
    blurRadius: 2.0,
    color: Color(0x29000000),
    spreadRadius: 0.5,
    blurStyle: BlurStyle.inner,
  ),
  BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 0.0, color: Color(0xB8FFFFFF)),
];
