import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import '../widgets/auth_error_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSettings;
  
  const HomeScreen({super.key, this.onNavigateToSettings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        centerTitle: true,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Карточка баланса
                _buildBalanceCard(chatProvider, context),
                const SizedBox(height: 16),

                // Статистика
                _buildStatsRow(chatProvider),
                const SizedBox(height: 16),

                // Последние сообщения
                _buildRecentMessages(chatProvider),
                const SizedBox(height: 16),

                // Кнопка начать чат
                _buildStartChatButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(ChatProvider chatProvider, BuildContext context) {
    return Column(
      children: [
        Card(
          color: const Color(0xFF333333),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: chatProvider.hasAuthError ? Colors.red : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Текущий баланс',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      chatProvider.balance,
                      style: TextStyle(
                        color: chatProvider.hasAuthError ? Colors.red : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (chatProvider.currentModel != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Модель',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _getModelDisplayName(chatProvider),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (chatProvider.hasAuthError)
          AuthErrorWidget(
            errorMessage: chatProvider.authErrorMessage ?? 'Ошибка авторизации',
            onSettingsPressed: () {
              // Переход на страницу настроек через callback
              if (onNavigateToSettings != null) {
                onNavigateToSettings!();
              } else {
                // Fallback для случаев, когда callback не передан
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildStatsRow(ChatProvider chatProvider) {
    final messages = chatProvider.messages;
    final totalMessages = messages.length;
    final totalTokens = messages
        .where((m) => m.tokens != null)
        .fold<int>(0, (sum, m) => sum + (m.tokens ?? 0));
    final totalCost = messages
        .where((m) => m.cost != null)
        .fold<double>(0.0, (sum, m) => sum + (m.cost ?? 0.0));

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Сообщений',
            totalMessages.toString(),
            Icons.message,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Токенов',
            totalTokens.toString(),
            Icons.token,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Потрачено',
            chatProvider.baseUrl?.contains('vsegpt.ru') == true
                ? '${totalCost.toStringAsFixed(2)}₽'
                : '\$${totalCost.toStringAsFixed(4)}',
            Icons.monetization_on,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMessages(ChatProvider chatProvider) {
    final recentMessages = chatProvider.messages.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Последние сообщения',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (recentMessages.isEmpty)
          Card(
            color: const Color(0xFF333333),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Пока нет сообщений.\nНачните новый чат!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentMessages.map((message) => _buildMessagePreview(message)),
      ],
    );
  }

  Widget _buildMessagePreview(ChatMessage message) {
    return Card(
      color: const Color(0xFF333333),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              message.isUser ? Icons.person : Icons.smart_toy,
              color: message.isUser ? Colors.blue : Colors.green,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isUser ? 'Вы' : 'AI',
                    style: TextStyle(
                      color: message.isUser ? Colors.blue : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content.length > 100
                        ? '${message.content.substring(0, 100)}...'
                        : message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.tokens != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${message.tokens} токенов',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartChatButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Переключиться на вкладку чата через callback
          // Поскольку мы не можем напрямую обратиться к NavigationWrapper,
          // просто показываем сообщение пользователю
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Перейдите на вкладку "Чат" для начала общения'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.chat),
        label: const Text('Начать новый чат'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  String _getModelDisplayName(ChatProvider chatProvider) {
    if (chatProvider.currentModel == null) {
      return 'Не выбрана';
    }

    // Ищем модель в списке доступных моделей
    final currentModelId = chatProvider.currentModel!;
    final matchingModels = chatProvider.availableModels
        .where((model) => model['id'] == currentModelId)
        .toList();

    if (matchingModels.isNotEmpty) {
      final modelName = matchingModels.first['name']?.toString();
      if (modelName != null && modelName.isNotEmpty) {
        return modelName;
      }
    }

    // Если не нашли полное название, возвращаем ID без префикса
    return currentModelId.split('/').last;
  }
}
