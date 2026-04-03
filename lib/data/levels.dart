import 'package:flutter/material.dart';
import '../core/models/level_model.dart';

final levels = [
  LevelModel(
    id: 1,
    image1: "assets/level1_a.png",
    image2: "assets/level1_b.png",
    differences: [
      // 1. Солнце (в самом углу справа сверху)
      Rect.fromLTWH(0.82, 0.01, 0.16, 0.14),

      // 2. Воздушный шар (верхняя левая часть)
      Rect.fromLTWH(0.18, 0.05, 0.22, 0.28),

      // 3. Бабочка (справа, посередине высоты)
      Rect.fromLTWH(0.72, 0.40, 0.16, 0.14),

      // 4. Глаз лебедя (чуть левее центра)
      Rect.fromLTWH(0.32, 0.43, 0.08, 0.08),

      // 5. Яблоко (на подстилке слева)
      Rect.fromLTWH(0.20, 0.78, 0.14, 0.14),

      // 6. Бутылочка/Напиток (на подстилке справа)
      Rect.fromLTWH(0.58, 0.70, 0.14, 0.25),

      // 7. Розовый/Фиолетовый цветок (в левом нижнем углу)
      Rect.fromLTWH(0.02, 0.75, 0.18, 0.20),
    ],
  ),
];