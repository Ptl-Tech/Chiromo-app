import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/chiromo_colors.dart';

/// A reusable Scaffold that provides a consistent AppBar with a back button.
///
/// - [title] is shown in the AppBar.
/// - [body] is the main content.
/// - [showBack] can be set to false for root screens (e.g., login).
class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final bool showBack;
  final bool showAppBar;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    required this.title,
    required this.body,
    this.showBack = true,
    this.showAppBar = true,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          // Fallback to home if stuck
                          context.go('/patient');
                        }
                      },
                    )
                  : null,
              title: Text(
                title,
                style: const TextStyle(color: ChiromoColors.textPrimary),
              ),
              actions: actions,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            )
          : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
