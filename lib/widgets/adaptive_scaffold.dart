import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation destination for the adaptive navigation system
class NavigationDestination {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Adaptive scaffold that switches between BottomNavigationBar and NavigationRail
/// based on screen width for optimal user experience across devices
class AdaptiveScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String currentRoute;
  final bool showNavigationLabels;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    required this.currentRoute,
    this.showNavigationLabels = true,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold>
    with TickerProviderStateMixin {
  late AnimationController _pageTransitionController;
  late AnimationController _navigationTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isMobile = true;

  // Navigation destinations for the app
  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      route: '/home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    NavigationDestination(
      route: '/practice',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
      label: 'Practice',
    ),
    NavigationDestination(
      route: '/progress',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Progress',
    ),
    NavigationDestination(
      route: '/settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  // Breakpoint for switching between mobile and desktop navigation
  static const double _mobileBreakpoint = 600.0;

  @override
  void initState() {
    super.initState();

    // Controller for page content transitions
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Controller for navigation mode transitions
    _navigationTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageTransitionController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _pageTransitionController,
            curve: Curves.easeOutCubic,
          ),
        );

    _pageTransitionController.forward();
    _navigationTransitionController.forward();
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    _navigationTransitionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdaptiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger page transition animation when route changes
    if (oldWidget.currentRoute != widget.currentRoute) {
      _pageTransitionController.reset();
      _pageTransitionController.forward();
    }
  }

  int get _currentIndex {
    for (int i = 0; i < _destinations.length; i++) {
      if (widget.currentRoute.startsWith(_destinations[i].route)) {
        return i;
      }
    }
    return 0; // Default to Home if no match
  }

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) {
      // Add smooth transition animation
      _pageTransitionController.reset();
      _pageTransitionController.forward();

      context.go(_destinations[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < _mobileBreakpoint;

        // Detect navigation mode transition
        if (_isMobile != isMobile) {
          _isMobile = isMobile;
          _navigationTransitionController.reset();
          _navigationTransitionController.forward();
        }

        return AnimatedBuilder(
          animation: _navigationTransitionController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            );
          },
        );
      },
    );
  }

  /// Build mobile layout with BottomNavigationBar
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: widget.actions,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            )
          : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Build desktop/tablet layout with NavigationRail
  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: widget.actions,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            )
          : null,
      body: Row(
        children: [
          _buildNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.body),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  /// Build BottomNavigationBar for mobile devices
  /// Optimized for single-handed mobile use with proper touch targets
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onDestinationSelected,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withAlpha(153),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0, // Using custom shadow instead
        selectedFontSize: 12,
        unselectedFontSize: 11,
        iconSize: 24, // Optimal size for mobile touch targets
        items: _destinations.map((destination) {
          final isSelected =
              _destinations.indexOf(destination) == _currentIndex;
          return BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: isSelected
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(isSelected),
                    size: isSelected ? 26 : 24,
                  ),
                ),
              ),
            ),
            label: widget.showNavigationLabels ? destination.label : null,
            tooltip: destination.label,
            // Enhanced accessibility
            activeIcon: Semantics(
              label: '${destination.label} - Currently selected',
              child: Icon(
                destination.selectedIcon,
                size: 26,
                semanticLabel: '${destination.label} - Currently selected',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build NavigationRail for desktop/tablet devices
  /// Optimized for large screens with proper spacing and accessibility
  Widget _buildNavigationRail() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: NavigationRail(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        labelType: widget.showNavigationLabels
            ? NavigationRailLabelType.all
            : NavigationRailLabelType.none,
        backgroundColor: Colors.transparent,
        elevation: null,
        useIndicator: true,
        indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(31),
        selectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 32, // Larger icons for desktop
        ),
        unselectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
          size: 28, // Slightly smaller for unselected
        ),
        selectedLabelTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14, // Larger text for desktop
          letterSpacing: 0.1,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.1,
        ),
        minWidth: 88, // Wider for better touch targets on tablets
        minExtendedWidth: 180, // More space for labels
        destinations: _destinations.map((destination) {
          final isSelected =
              _destinations.indexOf(destination) == _currentIndex;
          return NavigationRailDestination(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: isSelected
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isSelected ? destination.selectedIcon : destination.icon,
                    key: ValueKey('${destination.route}_$isSelected'),
                  ),
                ),
              ),
            ),
            selectedIcon: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(destination.selectedIcon),
              ),
            ),
            label: Text(
              destination.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
