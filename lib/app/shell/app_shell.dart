import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/journal/presentation/providers/personal_providers.dart';
import '../../features/shlokas/presentation/providers/scripture_providers.dart';

import '../motion/motion.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// The bottom navigation of code.html: Home · Read · Bookmarks · My Journal.
/// Each tab keeps its own navigation stack; tapping the current tab returns
/// to its root.
///
/// It also keeps the reading data loaded in memory while signed in (all
/// verses, bookmarks, journal), so pages and tabs open with their content
/// already there rather than loading after they appear.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..listen(liveShlokasByIdProvider, (_, _) {})
      ..listen(bookmarksProvider, (_, _) {})
      ..listen(allReflectionsProvider, (_, _) {})
      ..listen(allNotesProvider, (_, _) {});

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

/// Holds the tab branches side by side: swipe left / right and the tabs
/// follow the finger; tapping a tab in the bar slides to it (or jumps, when
/// it is not a neighbour). Every tab keeps its state and scroll position.
///
/// Swiping between tabs works on each tab's first page. On deeper pages (a
/// chapter, the verse reader) horizontal swipes belong to the page: verse
/// paging and the edge swipe back.
///
/// Only the visible tab's tickers run, so hidden tabs cost nothing.
class SwipeBranchContainer extends StatefulWidget {
  const SwipeBranchContainer({
    super.key,
    required this.shell,
    required this.children,
  });

  final StatefulNavigationShell shell;
  final List<Widget> children;

  /// The tabs' first pages, where swiping between tabs is allowed.
  static const roots = {
    AppRoutes.home,
    AppRoutes.chapters,
    AppRoutes.bookmarks,
    AppRoutes.journal,
  };

  @override
  State<SwipeBranchContainer> createState() => _SwipeBranchContainerState();
}

class _SwipeBranchContainerState extends State<SwipeBranchContainer> {
  late final PageController _pages = PageController(
    initialPage: widget.shell.currentIndex,
  );

  @override
  void didUpdateWidget(SwipeBranchContainer old) {
    super.didUpdateWidget(old);
    final index = widget.shell.currentIndex;
    if (index == old.shell.currentIndex) return;
    // Selected from the bar (or a link): bring that tab into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      final current = _pages.page?.round() ?? index;
      if (current == index) return;
      if ((current - index).abs() == 1 && !Motion.reduced(context)) {
        _pages.animateToPage(
          index,
          duration: Motion.medium,
          curve: Motion.enter,
        );
      } else {
        _pages.jumpToPage(index);
      }
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// A swipe settled on another tab: select it (on settle, not mid-swipe,
  /// so nothing rebuilds while the pages move).
  bool _settled(ScrollEndNotification n) {
    if (n.depth != 0) return false; // scrolling inside a tab
    final p = _pages.page?.round();
    if (p != null && p != widget.shell.currentIndex) widget.shell.goBranch(p);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.shell.shellRouteContext.routerState.uri.path;
    final atRoot = SwipeBranchContainer.roots.contains(path);
    return NotificationListener<ScrollEndNotification>(
      onNotification: _settled,
      child: PageView(
        controller: _pages,
        physics: atRoot ? null : const NeverScrollableScrollPhysics(),
        children: [
          for (final (i, child) in widget.children.indexed)
            TickerMode(enabled: i == widget.shell.currentIndex, child: child),
        ],
      ),
    );
  }
}
