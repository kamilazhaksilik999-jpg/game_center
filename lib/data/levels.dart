import 'package:flutter/material.dart';
import '../core/models/level_model.dart';

final levels = [
  LevelModel(
    id: 1,
    image1: "assets/level1_a.png",
    image2: "assets/level1_b.png",
    differences: [
      Rect.fromLTWH(0.30, 0.10, 0.20, 0.20), // головы (волосы)
      Rect.fromLTWH(0.45, 0.20, 0.18, 0.15), // рот
      Rect.fromLTWH(0.05, 0.70, 0.20, 0.25), // нижняя часть карандаша
      Rect.fromLTWH(0.40, 0.55, 0.15, 0.15), // живот (точка)
      Rect.fromLTWH(0.60, 0.50, 0.25, 0.40), // хвост
    ],
  ),
];