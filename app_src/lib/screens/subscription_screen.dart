import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await AppScope.of(context).apiClient.subscription();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _subscription = result.data;
        _error = '';
      } else {
        _error = result.error ?? 'Could not load subscription.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = (_subscription?['plan'] as Map<String, dynamic>?) ?? const {};
    final status = _subscription?['subscription_status']?.toString() ?? plan['subscription_status']?.toString() ?? 'inactive';
    final expiresAt = _subscription?['subscription_expires_at']?.toString() ?? plan['subscription_expires_at']?.toString() ?? '-';
    final active = plan['active'] == true || _subscription?['active'] == true;
    final planName = plan['plan_name']?.toString() ?? (active ? 'Active Plan' : 'Free Plan');
    final limit = plan['daily_ai_limit']?.toString() ?? (active ? '-' : '3');
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('subscription'))),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AppErrorBox(message: _error),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(active ? Icons.verified : Icons.card_giftcard_rounded, size: 38),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    active ? context.tr('subscriptionActive') : context.tr('subscriptionNotActive'),
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(planName, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('${context.tr('status')}: $status'),
                            const SizedBox(height: 8),
                            Text('${context.tr('expiresAt')}: $expiresAt'),
                            const SizedBox(height: 8),
                            Text('${context.tr('dailyLimit')}: $limit'),
                            const SizedBox(height: 16),
                            Text(active ? context.tr('paidPlanNote') : context.tr('freePlanNote')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(context.tr('refresh'))),
                  ],
                ),
              ),
      ),
    );
  }
}
