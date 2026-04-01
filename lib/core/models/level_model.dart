import 'package:flutter/material.dart';

class LevelModel {
  final String leftImage;
  final String rightImage;
  final List<Rect> differences;

  LevelModel({
    required this.leftImage,
    required this.rightImage,
    required this.differences,
  });
}