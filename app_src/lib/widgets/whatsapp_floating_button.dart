import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/app_strings.dart';
import '../main.dart';

class WhatsAppFloatingButton extends StatefulWidget {
  const WhatsAppFloatingButton({super.key});

  @override
  State<WhatsAppFloatingButton> createState() => _WhatsAppFloatingButtonState();
}

class _WhatsAppFloatingButtonState extends State<WhatsAppFloatingButton> {
  bool _loaded = false;
  bool _enabled = false;
  String _number = '';
  String _messageEn = 'Hello admin, I want to activate my EduTrack account.';
  String _messageAr = 'مرحباً، أريد تفعيل حساب EduTrack الخاص بي.';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final res = await AppScope.of(context).apiClient.publicAppSettings();
    if (!mounted || !res.ok) return;
    final whatsapp = (res.data?['settings'] as Map<String, dynamic>?)?['activation_whatsapp'] as Map<String, dynamic>?;
    setState(() {
      _enabled = whatsapp?['enabled'] == true;
      _number = whatsapp?['number']?.toString() ?? '';
      _messageEn = whatsapp?['message_en']?.toString() ?? _messageEn;
      _messageAr = whatsapp?['message_ar']?.toString() ?? _messageAr;
    });
  }

  Future<void> _open() async {
    final number = _number.replaceAll(RegExp(r'[^0-9]'), '');
    if (!_enabled || number.isEmpty) return;
    final lang = AppScope.of(context).languageCode;
    final message = lang == 'en' ? _messageEn : _messageAr;
    final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _number.isEmpty) return const SizedBox.shrink();
    return PositionedDirectional(
      end: 14,
      bottom: 86,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: FloatingActionButton.small(
            heroTag: 'globalWhatsappActivation',
            onPressed: _open,
            tooltip: context.tr('contactAdminActivation'),
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            child: const Icon(Icons.chat_bubble_outline),
          ),
        ),
      ),
    );
  }
}
