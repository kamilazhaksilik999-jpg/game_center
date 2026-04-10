import 'package:flutter/material.dart';
import '../core/models/level_model.dart';

final levels = [
  LevelModel(
    id: 1,
    image1: "assets/level1_a.png",
    image2: "assets/level1_b.png",
    differences: [
      Rect.fromLTWH(0.32, 0.05, 0.18, 0.18), // волосы (чуть выше и уже)
      Rect.fromLTWH(0.42, 0.22, 0.16, 0.12), // рот (ниже и компактнее)
      Rect.fromLTWH(0.06, 0.68, 0.18, 0.22), // нижняя часть карандаша (чуть выше)
      Rect.fromLTWH(0.43, 0.52, 0.12, 0.12), // живот (центр точнее)
      Rect.fromLTWH(0.62, 0.48, 0.22, 0.38), // хвост (немного уже и выше)
    ],
  ),
];