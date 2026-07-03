import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
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
  int _index = -1;
  String _studentName = '';
  int _unreadConversations = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHomeData());
  }

  Future<void> _loadHomeData() async {
    final scope = AppScope.of(context);
    final summary = await scope.sessionStore.getUserSummary();
    final inbox = await scope.apiClient.privateConversations();
    if (!mounted) return;
    var unread = 0;
    if (inbox.ok) {
      final list = (inbox.data?['conversations'] as List? ?? const []).whereType<Map>();
      unread = list.where((c) => (int.tryParse('${c['unread_count'] ?? 0}') ?? 0) > 0).length;
    }
    setState(() {
      _studentName = (summary['name'] ?? '').trim();
      _unreadConversations = unread;
    });
  }

  void _onTap(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/chat');
      return;
    }
    setState(() => _index = index);
    if (index == 3) _loadHomeData();
  }

  Future<bool> _onBack() async {
    if (_index != -1) {
      setState(() => _index = -1);
      return false;
    }
    return true;
  }

  Widget _homeGreeting(BuildContext context) {
    final name = _studentName.isEmpty ? context.tr('student') : _studentName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.school_rounded, size: 44, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 22),
            Text(
              context.tr('homeGreeting').replaceAll('{name}', name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('chooseFromBottom'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
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

    return WillPopScope(
      onWillPop: _onBack,
      child: Scaffold(
        body: SafeArea(child: _index == -1 ? _homeGreeting(context) : IndexedStack(index: _index, children: pages)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          width: 58,
          height: 58,
          child: FloatingActionButton(
            heroTag: 'aiTeacherFab',
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            tooltip: context.tr('aiTeacher'),
            child: const Icon(Icons.school_rounded, size: 26),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 6,
          shape: const CircularNotchedRectangle(),
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: context.tr('profile'), selected: _index == 0, onTap: () => _onTap(0)),
                _NavItem(icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt, label: context.tr('friends'), selected: _index == 1, onTap: () => _onTap(1)),
                const SizedBox(width: 58),
                _NavItem(icon: Icons.inbox_outlined, selectedIcon: Icons.inbox, label: context.tr('inbox'), selected: _index == 3, badge: _unreadConversations, onTap: () => _onTap(3)),
                _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: context.tr('settings'), selected: _index == 4, onTap: () => _onTap(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.onTap, this.badge = 0});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? selectedIcon : icon, color: color, size: 22),
                if (badge > 0)
                  Positioned(
                    right: -9,
                    top: -7,
                    child: CircleAvatar(radius: 9, backgroundColor: Theme.of(context).colorScheme.error, child: Text('$badge', style: const TextStyle(fontSize: 9, color: Colors.white))),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
