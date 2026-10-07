// ResponsiveScaffold: every screen renders inside this (frontend MEDIUM-11).
// Max content width 720 dp centered on tablets/large screens; 16 dp phone /
// 24 dp tablet side margins (design §2.3).

import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double margin = width >= 600 ? 24 : 16;
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: margin),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
