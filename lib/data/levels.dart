import 'package:flutter/material.dart';
import '../../core/models/level_model.dart';
final levels = [
  LevelModel(
    leftImage: 'assets/level1_a.png',
    rightImage: 'assets/level1_b.png',
    differences: [
      Rect.fromLTWH(0.2, 0.3, 0.1, 0.1),
      Rect.fromLTWH(0.6, 0.4, 0.1, 0.1),
      Rect.fromLTWH(0.4, 0.7, 0.1, 0.1),
    ],
  ),

];