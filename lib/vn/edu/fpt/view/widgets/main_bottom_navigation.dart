import 'package:flutter/material.dart';

enum MainNavigationItem { home, events, profile }

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({
    super.key,
    this.selectedItem = MainNavigationItem.home,
    this.onHome,
    this.onEvents,
    this.onProfile,
  });

  final MainNavigationItem selectedItem;
  final VoidCallback? onHome;
  final VoidCallback? onEvents;
  final VoidCallback? onProfile;

  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF9800);
  static const _inactive = Color(0xFF9EACBE);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavigationButton(
              tooltip: 'Trang chủ',
              icon: Icons.home_filled,
              selected: selectedItem == MainNavigationItem.home,
              onTap: onHome,
            ),
            _NavigationButton(
              tooltip: 'Sự kiện',
              icon: Icons.event_note_rounded,
              selected: selectedItem == MainNavigationItem.events,
              onTap: onEvents,
            ),
            _NavigationButton(
              tooltip: 'Cá nhân',
              icon: Icons.person,
              selected: selectedItem == MainNavigationItem.profile,
              onTap: onProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF3F4652) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: selected
                  ? MainBottomNavigation._orange
                  : MainBottomNavigation._inactive,
              size: icon == Icons.event_note_rounded ? 25 : 27,
            ),
          ),
        ),
      ),
    );
  }
}
