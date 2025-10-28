import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';

class SessionInfoFooter extends StatelessWidget {
  const SessionInfoFooter({super.key});

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Token copiado al portapapeles',
            style: TextStyle(color: colors.getTextColorForBackground(colors.success)),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: colors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authProvider = Provider.of<AuthProvider>(context);
    final accessToken = authProvider.accessToken;

    if (accessToken == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            size: 16,
            color: colors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Token: ${accessToken.substring(0, 20)}...',
              style: TextStyle(
                color: colors.textOnDark,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            color: colors.textOnDarkSecondary,
            tooltip: 'Copiar token',
            onPressed: () => _copyToClipboard(context, accessToken),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: colors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Activo',
                  style: TextStyle(
                    color: colors.getTextColorForBackground(colors.success),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}