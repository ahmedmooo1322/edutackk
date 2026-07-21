import 'package:flutter/material.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({super.key, required this.message, this.onRetry, this.icon = Icons.info_outline});
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42), const SizedBox(height: 16), Text(message, textAlign: TextAlign.center), if (onRetry != null) ...[const SizedBox(height: 16), OutlinedButton(onPressed: onRetry, child: const Text('حاول تاني'))]])));
}

