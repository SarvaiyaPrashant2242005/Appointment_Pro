import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final double strokeWidth;
  final TextStyle? messageStyle;

  const AppLoader({
    super.key,
    this.message,
    this.color,
    this.size,
    this.strokeWidth = 4.0,
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator = CircularProgressIndicator(
      color: color,
      strokeWidth: strokeWidth,
    );

    if (size != null) {
      indicator = SizedBox(width: size, height: size, child: indicator);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: messageStyle),
          ],
        ],
      ),
    );
  }
}
