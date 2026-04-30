import 'package:flutter/material.dart';

class LevelModel {
  final int id;
  final String image1;
  final String image2;
  final List<Rect> differences;

  LevelModel({
    required this.id,
    required this.image1,
    required this.image2,
    required this.differences,
  });
}