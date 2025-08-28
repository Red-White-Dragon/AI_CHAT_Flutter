import 'package:flutter/material.dart';

class AuthErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onSettingsPressed;

  const AuthErrorWidget({
    super.key,
    required this.errorMessage,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Проверьте настройки API ключа',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onSettingsPressed != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onSettingsPressed,
              icon: const Icon(
                Icons.settings,
                size: 16,
                color: Colors.red,
              ),
              label: const Text(
                'Настройки',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BalanceDisplayWidget extends StatelessWidget {
  final String balance;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onSettingsPressed;

  const BalanceDisplayWidget({
    super.key,
    required this.balance,
    this.hasError = false,
    this.errorMessage,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card, size: 12, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            'ошибка авторизации',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.credit_card, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          balance,
          style: const TextStyle(
            color: Color(0xFF33CC33),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
