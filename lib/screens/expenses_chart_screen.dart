import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

class ExpensesChartScreen extends StatefulWidget {
  const ExpensesChartScreen({super.key});

  @override
  State<ExpensesChartScreen> createState() => _ExpensesChartScreenState();
}

class _ExpensesChartScreenState extends State<ExpensesChartScreen> {
  String _selectedPeriod = 'week';
  String _selectedChartType = 'line';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('График расходов'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedChartType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'line',
                child: Text('Линейный график'),
              ),
              const PopupMenuItem(
                value: 'bar',
                child: Text('Столбчатая диаграмма'),
              ),
            ],
            icon: const Icon(Icons.bar_chart),
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
                // Селектор периода
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                
                // Основной график
                _buildMainChart(messages, chatProvider),
                const SizedBox(height: 24),
                
                // Статистика по периоду
                _buildPeriodStats(messages, chatProvider),
                const SizedBox(height: 24),
                
                // График по моделям
                _buildModelExpensesChart(messages, chatProvider),
                const SizedBox(height: 24),
                
                // Прогноз расходов
                _buildExpensesForecast(messages, chatProvider),
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
            Icons.show_chart,
            size: 64,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет данных о расходах',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Начните общение с AI, чтобы увидеть график расходов',
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

  Widget _buildPeriodSelector() {
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Период отображения',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodButton('week', 'Неделя'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton('month', 'Месяц'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton('year', 'Год'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : const Color(0xFF404040),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildMainChart(List<ChatMessage> messages, ChatProvider chatProvider) {
    final expenseData = _getExpenseData(messages);
    
    if (expenseData.isEmpty) {
      return _buildNoDataCard('Нет данных о расходах за выбранный период');
    }

    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Расходы за ${_getPeriodLabel()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _selectedChartType == 'line'
                  ? _buildLineChart(expenseData, chatProvider)
                  : _buildBarChart(expenseData, chatProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<MapEntry<DateTime, double>> expenseData, ChatProvider chatProvider) {
    final spots = expenseData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white24,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white24,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < expenseData.length) {
                  final date = expenseData[value.toInt()].key;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: null,
              getTitlesWidget: (value, meta) {
                return Text(
                  chatProvider.baseUrl?.contains('vsegpt.ru') == true
                      ? '${value.toStringAsFixed(1)}₽'
                      : '\$${value.toStringAsFixed(3)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        minX: 0,
        maxX: expenseData.length.toDouble() - 1,
        minY: 0,
        maxY: expenseData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue.withValues(alpha: 0.8),
              Colors.blue.withValues(alpha: 0.3),
            ],
          ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<DateTime, double>> expenseData, ChatProvider chatProvider) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: expenseData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.1,
        barTouchData: BarTouchData(
          enabled: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < expenseData.length) {
                  final date = expenseData[value.toInt()].key;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  chatProvider.baseUrl?.contains('vsegpt.ru') == true
                      ? '${value.toStringAsFixed(1)}₽'
                      : '\$${value.toStringAsFixed(3)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: expenseData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.blue.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget _buildPeriodStats(List<ChatMessage> messages, ChatProvider chatProvider) {
    final expenseData = _getExpenseData(messages);
    
    if (expenseData.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExpenses = expenseData.fold<double>(0.0, (sum, entry) => sum + entry.value);
    final avgDaily = totalExpenses / expenseData.length;
    final maxDaily = expenseData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minDaily = expenseData.map((e) => e.value).reduce((a, b) => a < b ? a : b);

    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика за ${_getPeriodLabel()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Общие расходы',
                    chatProvider.baseUrl?.contains('vsegpt.ru') == true
                        ? '${totalExpenses.toStringAsFixed(2)}₽'
                        : '\$${totalExpenses.toStringAsFixed(4)}',
                    Icons.monetization_on,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Среднее в день',
                    chatProvider.baseUrl?.contains('vsegpt.ru') == true
                        ? '${avgDaily.toStringAsFixed(2)}₽'
                        : '\$${avgDaily.toStringAsFixed(4)}',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Максимум в день',
                    chatProvider.baseUrl?.contains('vsegpt.ru') == true
                        ? '${maxDaily.toStringAsFixed(2)}₽'
                        : '\$${maxDaily.toStringAsFixed(4)}',
                    Icons.arrow_upward,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Минимум в день',
                    chatProvider.baseUrl?.contains('vsegpt.ru') == true
                        ? '${minDaily.toStringAsFixed(2)}₽'
                        : '\$${minDaily.toStringAsFixed(4)}',
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF404040),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModelExpensesChart(List<ChatMessage> messages, ChatProvider chatProvider) {
    final modelExpenses = <String, double>{};
    
    for (final message in messages.where((m) => !m.isUser && m.modelId != null && m.cost != null)) {
      final modelName = message.modelId!.split('/').last;
      modelExpenses[modelName] = (modelExpenses[modelName] ?? 0.0) + message.cost!;
    }

    if (modelExpenses.isEmpty) {
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
              'Расходы по моделям',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: modelExpenses.values.reduce((a, b) => a > b ? a : b) * 1.1,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final models = modelExpenses.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < models.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                models[value.toInt()],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 38,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            chatProvider.baseUrl?.contains('vsegpt.ru') == true
                                ? '${value.toStringAsFixed(1)}₽'
                                : '\$${value.toStringAsFixed(3)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: modelExpenses.entries.toList().asMap().entries.map((entry) {
                    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: colors[entry.key % colors.length],
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesForecast(List<ChatMessage> messages, ChatProvider chatProvider) {
    final expenseData = _getExpenseData(messages);
    
    if (expenseData.length < 3) {
      return _buildNoDataCard('Недостаточно данных для прогноза');
    }

    final totalExpenses = expenseData.fold<double>(0.0, (sum, entry) => sum + entry.value);
    final avgDaily = totalExpenses / expenseData.length;
    
    // Простой прогноз на основе среднего
    final forecastDays = _selectedPeriod == 'week' ? 7 : (_selectedPeriod == 'month' ? 30 : 365);
    final forecastExpenses = avgDaily * forecastDays;

    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Прогноз расходов',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Прогноз на ${_getPeriodLabel()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        chatProvider.baseUrl?.contains('vsegpt.ru') == true
                            ? '${forecastExpenses.toStringAsFixed(2)}₽'
                            : '\$${forecastExpenses.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'На основе среднего: ${chatProvider.baseUrl?.contains('vsegpt.ru') == true ? '${avgDaily.toStringAsFixed(2)}₽' : '\$${avgDaily.toStringAsFixed(4)}'}/день',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  List<MapEntry<DateTime, double>> _getExpenseData(List<ChatMessage> messages) {
    final now = DateTime.now();
    final startDate = _selectedPeriod == 'week'
        ? now.subtract(const Duration(days: 7))
        : _selectedPeriod == 'month'
            ? DateTime(now.year, now.month - 1, now.day)
            : DateTime(now.year - 1, now.month, now.day);

    final dailyExpenses = <DateTime, double>{};
    
    for (final message in messages.where((m) => !m.isUser && m.cost != null)) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      
      if (messageDate.isAfter(startDate) || messageDate.isAtSameMomentAs(startDate)) {
        dailyExpenses[messageDate] = (dailyExpenses[messageDate] ?? 0.0) + message.cost!;
      }
    }

    final sortedEntries = dailyExpenses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries;
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'week':
        return 'неделю';
      case 'month':
        return 'месяц';
      case 'year':
        return 'год';
      default:
        return 'период';
    }
  }
}
