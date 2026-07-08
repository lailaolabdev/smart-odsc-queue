import 'package:flutter/material.dart';

/// Branded loading spinner used across the app in place of
/// [CircularProgressIndicator]. Backed by an animated GIF so the
/// motion + colors match the ODSC visual identity instead of the
/// generic Material spinner.
class LoadingIndicator extends StatelessWidget {
  final double size;

  const LoadingIndicator({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/loading/icon-doc-odsc.gif',
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}
