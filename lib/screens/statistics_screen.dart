import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика токенов'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showExportDialog(context),
            icon: const Icon(Icons.file_download),
            tooltip: 'Экспорт статистики',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final messages = chatProvider.messages;
          
          if (messages.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Общая статистика
                _buildOverallStats(messages, chatProvider),
                const SizedBox(height: 24),
                
                // Статистика по моделям
                _buildModelStats(messages, chatProvider),
                const SizedBox(height: 24),
                
                // Круговая диаграмма использования токенов
                _buildTokenUsageChart(messages),
                const SizedBox(height: 24),
                
                // Таблица детальной статистики
                _buildDetailedTable(messages, chatProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет данных для отображения',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Начните общение с AI, чтобы увидеть статистику',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(List<ChatMessage> messages, ChatProvider chatProvider) {
    final totalMessages = messages.length;
    final aiMessages = messages.where((m) => !m.isUser).length;
    final userMessages = messages.where((m) => m.isUser).length;
    final totalTokens = messages
        .where((m) => m.tokens != null)
        .fold<int>(0, (sum, m) => sum + (m.tokens ?? 0));
    final totalCost = messages
        .where((m) => m.cost != null)
        .fold<double>(0.0, (sum, m) => sum + (m.cost ?? 0.0));
    final avgTokensPerMessage = aiMessages > 0 ? totalTokens / aiMessages : 0.0;

    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Всего сообщений',
                    totalMessages.toString(),
                    Icons.message,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'От пользователя',
                    userMessages.toString(),
                    Icons.person,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'От AI',
                    aiMessages.toString(),
                    Icons.smart_toy,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Всего токенов',
                    totalTokens.toString(),
                    Icons.token,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Среднее на ответ',
                    avgTokensPerMessage.toStringAsFixed(1),
                    Icons.analytics,
                    Colors.cyan,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Общие расходы',
                    chatProvider.baseUrl?.contains('vsegpt.ru') == true
                        ? '${totalCost.toStringAsFixed(2)}₽'
                        : '\$${totalCost.toStringAsFixed(4)}',
                    Icons.monetization_on,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
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
    );
  }

  Widget _buildModelStats(List<ChatMessage> messages, ChatProvider chatProvider) {
    final modelStats = <String, Map<String, dynamic>>{};
    
    for (final message in messages.where((m) => !m.isUser && m.modelId != null)) {
      final modelId = message.modelId!;
      if (!modelStats.containsKey(modelId)) {
        modelStats[modelId] = {
          'count': 0,
          'tokens': 0,
          'cost': 0.0,
        };
      }
      modelStats[modelId]!['count']++;
      modelStats[modelId]!['tokens'] += message.tokens ?? 0;
      modelStats[modelId]!['cost'] += message.cost ?? 0.0;
    }

    if (modelStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика по моделям',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...modelStats.entries.map((entry) {
              final modelName = entry.key.split('/').last;
              final stats = entry.value;
              final avgTokens = stats['count'] > 0 ? stats['tokens'] / stats['count'] : 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF404040),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildModelStatItem('Сообщений', '${stats['count']}'),
                        _buildModelStatItem('Токенов', '${stats['tokens']}'),
                        _buildModelStatItem('Среднее', avgTokens.toStringAsFixed(1)),
                        _buildModelStatItem(
                          'Стоимость',
                          chatProvider.baseUrl?.contains('vsegpt.ru') == true
                              ? '${stats['cost'].toStringAsFixed(2)}₽'
                              : '\$${stats['cost'].toStringAsFixed(4)}',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTokenUsageChart(List<ChatMessage> messages) {
    final modelTokens = <String, int>{};
    
    for (final message in messages.where((m) => !m.isUser && m.modelId != null && m.tokens != null)) {
      final modelName = message.modelId!.split('/').last;
      modelTokens[modelName] = (modelTokens[modelName] ?? 0) + message.tokens!;
    }

    if (modelTokens.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalTokens = modelTokens.values.fold<int>(0, (sum, tokens) => sum + tokens);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.cyan,
      Colors.yellow,
      Colors.pink,
    ];

    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Распределение токенов по моделям',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: modelTokens.entries.toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final modelEntry = entry.value;
                          final percentage = (modelEntry.value / totalTokens * 100);
                          
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: modelEntry.value.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: modelTokens.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final modelEntry = entry.value;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  modelEntry.key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTable(List<ChatMessage> messages, ChatProvider chatProvider) {
    final aiMessages = messages.where((m) => !m.isUser).toList();
    
    if (aiMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Детальная статистика сообщений',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF404040)),
                dataRowColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Модель',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Токены',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Стоимость',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Время',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: aiMessages.take(10).map((message) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          message.modelId?.split('/').last ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${message.tokens ?? 0}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          chatProvider.baseUrl?.contains('vsegpt.ru') == true
                              ? '${(message.cost ?? 0.0).toStringAsFixed(2)}₽'
                              : '\$${(message.cost ?? 0.0).toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (aiMessages.length > 10) ...[
              const SizedBox(height: 8),
              Text(
                'Показано 10 из ${aiMessages.length} сообщений',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Экспорт статистики',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Выберите формат для экспорта статистики:',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportAsJson(context);
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportAsText(context);
            },
            child: const Text('Текст'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsJson(BuildContext context) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final path = await chatProvider.exportMessagesAsJson();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Статистика экспортирована: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAsText(BuildContext context) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final path = await chatProvider.exportLogs();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Статистика экспортирована: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
