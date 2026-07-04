import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/app_strings.dart';
import '../main.dart';

class ChatAttachmentView extends StatelessWidget {
  const ChatAttachmentView({super.key, required this.attachment, this.foregroundColor});

  final Map attachment;
  final Color? foregroundColor;

  String? _rawUrl() {
    final candidates = [
      attachment['signed_download_url'],
      attachment['admin_signed_url'],
      attachment['download_url'],
      attachment['url'],
    ];
    for (final item in candidates) {
      final value = item?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  bool get _isImage => (attachment['mime_type']?.toString() ?? '').toLowerCase().startsWith('image/');
  String get _name => attachment['original_name']?.toString() ?? 'file';

  Future<void> _open(BuildContext context, String url) async {
    if (_isImage) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.tr('connectionProblem'), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('connectionProblem'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = AppScope.of(context).apiClient;
    final raw = _rawUrl();
    if (raw == null) return const SizedBox.shrink();

    return FutureBuilder<String?>(
      future: api.absoluteUrl(raw),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(_name, style: TextStyle(color: foregroundColor)),
              ],
            ),
          );
        }

        if (_isImage) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () => _open(context, url),
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 220,
                        height: 160,
                        alignment: Alignment.center,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 220,
                      padding: const EdgeInsets.all(14),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Text(context.tr('connectionProblem')),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: () => _open(context, url),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, color: foregroundColor),
                  const SizedBox(width: 8),
                  Flexible(child: Text(_name, style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
