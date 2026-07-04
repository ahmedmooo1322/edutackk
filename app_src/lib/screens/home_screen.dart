import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import 'friend_requests_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../widgets/whatsapp_floating_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = -1;
  String _studentName = '';
  String _role = 'student';
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
      _role = (summary['role'] ?? 'student').trim();
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
    final name = _studentName.isEmpty ? context.tr(_role == 'teacher' ? 'teacher' : 'student') : _studentName;
    final cards = <_HomeCardData>[
      _HomeCardData(Icons.school_rounded, context.tr('askAiTeacher'), context.tr('askAiSubtitle'), '/chat'),
      if (_role == 'student') _HomeCardData(Icons.groups_2_outlined, context.tr('levelRoom'), context.tr('levelRoomSubtitle'), '/level-room'),
      _HomeCardData(Icons.quiz_outlined, context.tr('quizzes'), context.tr('quizzesSubtitle'), '/quizzes'),
      _HomeCardData(Icons.search, context.tr('searchStudents'), context.tr('searchStudentsSubtitle'), '/student-search'),
      _HomeCardData(Icons.people_alt_outlined, context.tr('friends'), context.tr('friendsSubtitle'), '/friends'),
      _HomeCardData(Icons.inbox_outlined, context.tr('inbox'), context.tr('messageRequests'), '/inbox', badge: _unreadConversations),
      if (_role == 'student') _HomeCardData(Icons.workspace_premium_outlined, context.tr('subscription'), context.tr('subscriptionSubtitle'), '/subscription'),
      _HomeCardData(Icons.person_outline, context.tr('profile'), context.tr('profileSubtitle'), '/profile'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, size: 44, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('homeGreeting').replaceAll('{name}', name), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(context.tr('chooseAction'), style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 3 : 2,
                childAspectRatio: wide ? 1.55 : 1.05,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => _HomeActionCard(data: cards[index]),
            ),
          ],
        );
      },
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
        body: Stack(
          children: [
            SafeArea(child: _index == -1 ? _homeGreeting(context) : IndexedStack(index: _index, children: pages)),
            const WhatsAppFloatingButton(),
          ],
        ),
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
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: context.tr('profile'), selected: _index == 0, onTap: () => _onTap(0))),
                Expanded(child: _NavItem(icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt, label: context.tr('friends'), selected: _index == 1, onTap: () => _onTap(1))),
                const SizedBox(width: 64),
                Expanded(child: _NavItem(icon: Icons.inbox_outlined, selectedIcon: Icons.inbox, label: context.tr('inbox'), selected: _index == 3, badge: _unreadConversations, onTap: () => _onTap(3))),
                Expanded(child: _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: context.tr('settings'), selected: _index == 4, onTap: () => _onTap(4))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _HomeCardData {
  const _HomeCardData(this.icon, this.title, this.subtitle, this.route, {this.badge = 0});

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final int badge;
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({required this.data});

  final _HomeCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, data.route),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(data.icon, color: Theme.of(context).colorScheme.primary),
                  const Spacer(),
                  if (data.badge > 0)
                    CircleAvatar(radius: 11, backgroundColor: Theme.of(context).colorScheme.error, child: Text('${data.badge}', style: const TextStyle(fontSize: 10, color: Colors.white))),
                ],
              ),
              const Spacer(),
              Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(data.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
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
