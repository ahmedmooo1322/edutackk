import 'package:flutter/material.dart';

import '../main.dart';

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    this.avatarUrl,
    this.name = '',
    this.radius = 22,
  });

  final String? avatarUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
    final raw = avatarUrl?.trim();
    if (raw == null || raw.isEmpty || raw == 'null') {
      return CircleAvatar(radius: radius, child: Text(initials));
    }
    return FutureBuilder<String?>(
      future: AppScope.of(context).apiClient.absoluteUrl(raw),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) return CircleAvatar(radius: radius, child: Text(initials));
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(url),
          onBackgroundImageError: (_, __) {},
          child: null,
        );
      },
    );
  }
}
