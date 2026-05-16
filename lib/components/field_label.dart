import 'package:flutter/material.dart';

/// Field label used above text inputs in Quality-Bar form screens.
///
/// Conforms to: `textTheme.labelLarge`, `FontWeight.w600`,
/// `letterSpacing: 0.3`. The [color] parameter is required so callers can
/// distinguish on-surface labels (forms over `surfaceContainerHighest`)
/// from on-background labels (auth screens over `surface`).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      );
}
