import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// The bottom navigation of code.html: Home · Read · Bookmarks · My Journal.
/// Each tab keeps its own navigation stack; tapping the current tab returns
/// to its root.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Read',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Bookmarks',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note),
              label: 'My Journal',
            ),
          ],
        ),
      ),
    );
  }
}

/// Holds the tab branches like an `IndexedStack` (every tab keeps its state
/// and scroll position), but fades the newly selected tab in.
///
/// Inactive tabs are offstage (not painted, not in the semantics tree) and
/// their tickers are paused, so they cost nothing while hidden.
class FadingBranchContainer extends StatelessWidget {
  const FadingBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (final (i, child) in children.indexed)
        Offstage(
          offstage: i != currentIndex,
          child: TickerMode(
            enabled: i == currentIndex,
            child: _BranchFade(active: i == currentIndex, child: child),
          ),
        ),
    ],
  );
}

class _BranchFade extends StatefulWidget {
  const _BranchFade({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_BranchFade> createState() => _BranchFadeState();
}

class _BranchFadeState extends State<_BranchFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Motion.enter,
  );

  @override
  void didUpdateWidget(_BranchFade old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !Motion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
