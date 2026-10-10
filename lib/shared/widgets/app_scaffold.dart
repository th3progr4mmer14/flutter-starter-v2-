import 'package:flutter/material.dart';

import 'app_menu.dart';

/// Scaffold para pantallas principales: Drawer en móvil, menú fijo en pantallas anchas.
class AppScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  static const double wideBreakpoint = 900;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;

    final content = Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: wide
          ? null
          : Drawer(
              child: AppMenu(currentRoute: currentRoute, closeOnTap: true),
            ),
      floatingActionButton: floatingActionButton,
      body: body,
    );

    if (!wide) return content;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: AppMenu(currentRoute: currentRoute, closeOnTap: false),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}
