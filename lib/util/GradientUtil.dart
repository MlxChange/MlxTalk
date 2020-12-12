///
///
import "package:flutter/material.dart";

import '../const.dart';

class GradientUtil {
  static LinearGradient _getLinearGradient(Color left, Color right,
          {begin = AlignmentDirectional.centerStart,
          end = AlignmentDirectional.centerEnd,
          opacity = 1.0}) =>
      LinearGradient(
        colors: [
          left.withOpacity(opacity),
          right.withOpacity(opacity),
        ],
        begin: begin,
        end: end,
      );

  static LinearGradient yellowGreen(
          {begin = AlignmentDirectional.centerStart,
          end = AlignmentDirectional.centerEnd,
          opacity = 1.0}) =>
      _getLinearGradient(YELLOW, GREEN,
          begin: begin, end: end, opacity: opacity);

  static LinearGradient red(
          {begin = AlignmentDirectional.centerStart,
          end = AlignmentDirectional.centerEnd,
          opacity = 1.0}) =>
      _getLinearGradient(RED_LIGHT, RED,
          begin: begin, end: end, opacity: opacity);

  static LinearGradient yellowBlue(
          {begin = AlignmentDirectional.centerStart,
          end = AlignmentDirectional.centerEnd,
          opacity = 1.0}) =>
      _getLinearGradient(YELLOW, BLUE,
          begin: begin, end: end, opacity: opacity);

  static LinearGradient blue(
          {begin = AlignmentDirectional.centerStart,
          end = AlignmentDirectional.centerEnd,
          opacity = 1.0}) =>
      _getLinearGradient(BLUE_LIGHT, BLUE_DEEP,
          begin: begin, end: end, opacity: opacity);

  static LinearGradient greenRed(
          {begin = AlignmentDirectional.centerStart,
          end = AlignmentDirectional.centerEnd,
          opacity = 1.0}) =>
      _getLinearGradient(GREEN, RED, begin: begin, end: end, opacity: opacity);

  static LinearGradient greenPurple(
          {begin = AlignmentDirectional.centerStart,
          end = AlignmentDirectional.centerEnd,
          opacity = 0.5}) =>
      _getLinearGradient(GREEN, PURPLE,
          begin: begin, end: end, opacity: opacity);
}
