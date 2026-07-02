import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import 'friend_requests_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _onTap(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/chat');
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const ProfileScreen(embedded: true),
      const FriendRequestsScreen(embedded: true),
      const SizedBox.shrink(),
      const InboxScreen(embedded: true),
      const SettingsScreen(embedded: true),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index == 2 ? 0 : _index, children: pages)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.large(
        heroTag: 'aiTeacherFab',
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        tooltip: context.tr('aiTeacher'),
        child: const Icon(Icons.school_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: context.tr('profile'), selected: _index == 0, onTap: () => _onTap(0)),
              _NavItem(icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt, label: context.tr('friends'), selected: _index == 1, onTap: () => _onTap(1)),
              const SizedBox(width: 74),
              _NavItem(icon: Icons.inbox_outlined, selectedIcon: Icons.inbox, label: context.tr('inbox'), selected: _index == 3, onTap: () => _onTap(3)),
              _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: context.tr('settings'), selected: _index == 4, onTap: () => _onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
