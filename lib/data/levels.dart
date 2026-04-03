import 'package:flutter/material.dart';
import '../../core/models/level_model.dart';
final levels = [

  LevelModel(
    id: 1,
    image1: "assets/level1_a.png",
    image2: "assets/level1_b.png",
    differences: [
      Rect.fromLTWH(0.2, 0.3, 0.15, 0.15),
      Rect.fromLTWH(0.6, 0.5, 0.15, 0.15),
    ],
  ),

  LevelModel(
    id: 2,
    image1: "assets/level2_a.png",
    image2: "assets/level2_b.png",
    differences: [
      Rect.fromLTWH(0.3, 0.2, 0.15, 0.15),
      Rect.fromLTWH(0.7, 0.6, 0.15, 0.15),
    ],
  ),

];