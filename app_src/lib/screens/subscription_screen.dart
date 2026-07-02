import 'package:flutter/material.dart';

import '../main.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await AppScope.of(context).apiClient.me();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        final user = result.data?['user'] as Map<String, dynamic>?;
        _profile = user?['profile'] as Map<String, dynamic>?;
      } else {
        _error = result.error ?? 'Could not load subscription.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _profile?['subscription_status']?.toString() ?? 'unknown';
    final expiresAt = _profile?['subscription_expires_at']?.toString() ?? '-';
    final active = status == 'active';
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(active ? Icons.verified : Icons.warning_amber_rounded, size: 38),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  active ? 'Subscription Active' : 'Subscription Not Active',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Status: $status'),
                          const SizedBox(height: 8),
                          Text('Expires at: $expiresAt'),
                          const SizedBox(height: 16),
                          const Text('Subscription activation is currently controlled from the admin API / future admin website.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                ],
              ),
      ),
    );
  }
}
