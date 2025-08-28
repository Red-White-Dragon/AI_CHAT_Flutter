// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с системными сервисами (буфер обмена)
import 'package:flutter/services.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт для работы со шрифтами Google
import 'package:google_fonts/google_fonts.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт модели сообщения
import '../models/message.dart';
// Импорт виджета для ошибок авторизации
import '../widgets/auth_error_widget.dart';
// Импорт виджета поиска моделей
import '../widgets/searchable_model_selector.dart';
// Импорт экрана настроек
import 'settings_screen.dart';

// Виджет для обработки ошибок в UI
class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          debugPrint('Error in ErrorBoundary: $error');
          debugPrint('Stack trace: $stackTrace');
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red,
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        }
      },
    );
  }
}

// Виджет для отображения отдельного сообщения в чате
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final List<ChatMessage> messages;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.messages,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFF1A73E8)
                  : const Color(0xFF424242),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SelectableText(
              message.cleanContent,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 13,
                locale: const Locale('ru', 'RU'),
              ),
            ),
          ),
          if (message.tokens != null || message.cost != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.tokens != null)
                    Text(
                      'Токенов: ${message.tokens}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  if (message.tokens != null && message.cost != null)
                    const SizedBox(width: 8),
                  if (message.cost != null)
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        final isVsetgpt =
                            chatProvider.baseUrl?.contains('vsetgpt.ru') ==
                                true;
                        return Text(
                          message.cost! < 0.001
                              ? isVsetgpt
                                  ? 'Стоимость: <0.001₽'
                                  : 'Стоимость: <\$0.001'
                              : isVsetgpt
                                  ? 'Стоимость: ${message.cost!.toStringAsFixed(3)}₽'
                                  : 'Стоимость: \$${message.cost!.toStringAsFixed(3)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: Colors.white54,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    onPressed: () {
                      final textToCopy = message.isUser
                          ? message.cleanContent
                          : '${messages[index - 1].cleanContent}\n\n${message.cleanContent}';
                      Clipboard.setData(ClipboardData(text: textToCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Текст скопирован',
                              style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Копировать текст',
                  ),
                  const Spacer()
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Виджет для ввода сообщений
class _MessageInput extends StatefulWidget {
  final void Function(String) onSubmitted;

  const _MessageInput({required this.onSubmitted});

  @override
  _MessageInputState createState() => _MessageInputState();
}

// Состояние виджета ввода сообщений
class _MessageInputState extends State<_MessageInput> {
  // Контроллер для управления текстовым полем
  final _controller = TextEditingController();
  // Флаг, указывающий, вводится ли сейчас сообщение
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (String text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
              onSubmitted: _isComposing ? _handleSubmitted : null,
              decoration: const InputDecoration(
                hintText: 'Введите сообщение...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 20),
            color: _isComposing ? Colors.blue : Colors.grey,
            onPressed:
                _isComposing ? () => _handleSubmitted(_controller.text) : null,
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

// Основной экран чата
class ChatScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSettings;
  
  const ChatScreen({super.key, this.onNavigateToSettings});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ScrollController _scrollController;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Добавляем слушатель для отслеживания пользовательского скролла
    _scrollController.addListener(_onScroll);
    
    // Скроллим к концу после первой загрузки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Определяем, скроллит ли пользователь вручную
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      _isUserScrolling = (maxScroll - currentScroll) > 100; // Порог в 100 пикселей
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  bool _shouldAutoScroll() {
    // Автоскролл только если пользователь не скроллит вручную или находится близко к концу
    return !_isUserScrolling;
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildInputArea(context),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // Построение верхней панели приложения
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF262626),
      toolbarHeight: 48,
      title: Row(
        children: [
          _buildModelSelector(context),
          const Spacer(),
          _buildBalanceDisplay(context),
          _buildMenuButton(context),
        ],
      ),
    );
  }

  // Построение селектора моделей с поиском
  Widget _buildModelSelector(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: SearchableModelSelector(
            models: chatProvider.availableModels,
            selectedModel: chatProvider.currentModel,
            onModelSelected: (modelId) {
              chatProvider.setCurrentModel(modelId);
            },
            formatPricing: chatProvider.formatPricing,
          ),
        );
      },
    );
  }

  // Отображение текущего баланса пользователя
  Widget _buildBalanceDisplay(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: BalanceDisplayWidget(
            balance: chatProvider.balance,
            hasError: chatProvider.hasAuthError,
            errorMessage: chatProvider.authErrorMessage,
            onSettingsPressed: () {
              // Переход на страницу настроек через callback
              if (widget.onNavigateToSettings != null) {
                widget.onNavigateToSettings!();
              } else {
                // Fallback для случаев, когда callback не передан
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }
            },
          ),
        );
      },
    );
  }

  // Построение кнопки меню с дополнительными опциями
  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 16),
      color: const Color(0xFF333333),
      onSelected: (String choice) async {
        final chatProvider = context.read<ChatProvider>();
        switch (choice) {
          case 'export':
            final path = await chatProvider.exportMessagesAsJson();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('История сохранена в: $path',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.green,
                ),
              );
            }
            break;
          case 'logs':
            final path = await chatProvider.exportLogs();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Логи сохранены в: $path',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.green,
                ),
              );
            }
            break;
          case 'clear':
            _showClearHistoryDialog(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'export',
          height: 40,
          child: Text('Экспорт истории',
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const PopupMenuItem<String>(
          value: 'logs',
          height: 40,
          child: Text('Скачать логи',
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const PopupMenuItem<String>(
          value: 'clear',
          height: 40,
          child: Text('Очистить историю',
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }

  // Построение списка сообщений чата
  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Автоматический скролл при изменении количества сообщений или состояния загрузки
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_shouldAutoScroll()) {
            _scrollToBottom();
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          reverse: false,
          itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // Показываем индикатор загрузки в конце списка
            if (index == chatProvider.messages.length && chatProvider.isLoading) {
              return _buildLoadingIndicator();
            }
            
            final message = chatProvider.messages[index];
            return _MessageBubble(
              message: message,
              messages: chatProvider.messages,
              index: index,
            );
          },
        );
      },
    );
  }

  // Построение индикатора загрузки
  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI печатает...',
              style: GoogleFonts.roboto(
                color: Colors.white70,
                fontSize: 13,
                locale: const Locale('ru', 'RU'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Построение области ввода сообщений
  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      color: const Color(0xFF262626),
      child: Row(
        children: [
          Expanded(
            child: _MessageInput(
              onSubmitted: (String text) {
                if (text.trim().isNotEmpty) {
                  // Сбрасываем флаг пользовательского скролла при отправке сообщения
                  _isUserScrolling = false;
                  context.read<ChatProvider>().sendMessage(text);
                  // Принудительно скроллим к концу после отправки
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Построение панели с кнопками действий
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      color: const Color(0xFF262626),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.save,
            label: 'Сохранить',
            color: const Color(0xFF1A73E8),
            onPressed: () async {
              final path =
                  await context.read<ChatProvider>().exportMessagesAsJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('История сохранена в: $path',
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          _buildActionButton(
            context: context,
            icon: Icons.analytics,
            label: 'Аналитика',
            color: const Color(0xFF33CC33),
            onPressed: () => _showAnalyticsDialog(context),
          ),
          _buildActionButton(
            context: context,
            icon: Icons.delete,
            label: 'Очистить',
            color: const Color(0xFFCC3333),
            onPressed: () => _showClearHistoryDialog(context),
          ),
        ],
      ),
    );
  }

  // Создание отдельной кнопки действия с заданными параметрами
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
      ),
    );
  }

  // Отображение диалога с аналитикой использования чата
  void _showAnalyticsDialog(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text(
            'Статистика',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Всего сообщений: ${chatProvider.messages.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'Баланс: ${chatProvider.balance}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Использование по моделям:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...chatProvider.messages
                    .fold<Map<String, Map<String, dynamic>>>(
                      {},
                      (map, msg) {
                        if (msg.modelId != null) {
                          if (!map.containsKey(msg.modelId)) {
                            map[msg.modelId!] = {
                              'count': 0,
                              'tokens': 0,
                              'cost': 0.0,
                            };
                          }
                          map[msg.modelId]!['count'] =
                              map[msg.modelId]!['count']! + 1;
                          if (msg.tokens != null) {
                            map[msg.modelId]!['tokens'] =
                                map[msg.modelId]!['tokens']! + msg.tokens!;
                          }
                          if (msg.cost != null) {
                            map[msg.modelId]!['cost'] =
                                map[msg.modelId]!['cost']! + msg.cost!;
                          }
                        }
                        return map;
                      },
                    )
                    .entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Сообщений: ${entry.value['count']}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              if (entry.value['tokens'] > 0) ...[
                                Text(
                                  'Токенов: ${entry.value['tokens']}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Consumer<ChatProvider>(
                                  builder: (context, chatProvider, child) {
                                    final isVsetgpt = chatProvider.baseUrl
                                            ?.contains('vsetgpt.ru') ==
                                        true;
                                    return Text(
                                      isVsetgpt
                                          ? 'Стоимость: ${entry.value['cost'] < 1e-8 ? '0.0' : entry.value['cost'].toStringAsFixed(8)}₽'
                                          : 'Стоимость: \$${entry.value['cost'] < 1e-8 ? '0.0' : entry.value['cost'].toStringAsFixed(8)}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  // Отображение диалога подтверждения очистки истории
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text(
            'Очистить историю',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          content: const Text(
            'Вы уверены? Это действие нельзя отменить.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                context.read<ChatProvider>().clearHistory();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Очистить',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
