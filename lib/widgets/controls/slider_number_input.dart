import 'package:flutter/material.dart';
import '../../theme/chiromo_colors.dart';

class SliderNumberInput extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final Color? activeColor;

  const SliderNumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.round();
    final color = activeColor ?? _defaultColor(display.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$display/${max.round()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: color,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: TextFormField(
                initialValue: display.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                ),
                onChanged: (s) {
                  final n = int.tryParse(s);
                  if (n != null) {
                    var v = n.toDouble();
                    if (v < min) v = min;
                    if (v > max) v = max;
                    onChanged(v);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _defaultColor(double value) {
    if (value <= 3) return ChiromoColors.success;
    if (value <= 6) return ChiromoColors.warning;
    return ChiromoColors.error;
  }
}
