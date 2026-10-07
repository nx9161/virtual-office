// WeatherIcon: decorative weather icon (R-15).
//
// Marked decorative via ExcludeSemantics — the condition is ALWAYS conveyed
// in adjacent text (design §6, US-7 AC2). Never carries meaning alone.

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/weather_code_mapper.dart';

class WeatherIcon extends StatelessWidget {
  final int? code;
  final bool isDay;
  final double size;
  final Color? color;

  const WeatherIcon({
    super.key,
    required this.code,
    required this.isDay,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        WeatherCodeMapper.iconFor(code, isDay: isDay),
        size: size,
        color: color,
      ),
    );
  }
}
