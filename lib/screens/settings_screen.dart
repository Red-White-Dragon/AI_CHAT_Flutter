import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _temperatureController = TextEditingController();
  
  String _selectedProvider = 'openrouter';
  bool _isLoading = false;
  bool _connectionTested = false;
  bool _connectionSuccess = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _maxTokensController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _selectedProvider = prefs.getString('provider') ?? 'openrouter';
      _apiKeyController.text = prefs.getString('api_key') ?? '';
      _maxTokensController.text = prefs.getString('max_tokens') ?? '1000';
      _temperatureController.text = prefs.getString('temperature') ?? '0.7';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('provider', _selectedProvider);
    await prefs.setString('api_key', _apiKeyController.text);
    await prefs.setString('max_tokens', _maxTokensController.text);
    await prefs.setString('temperature', _temperatureController.text);

    // Обновляем настройки API клиента
    if (mounted) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.updateApiSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите API ключ для тестирования'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _connectionTested = false;
    });

    try {
      final chatProvider = context.read<ChatProvider>();
      
      // Создаем временный API клиент с новыми настройками
      final tempApiClient = chatProvider.createTempApiClient(
        provider: _selectedProvider,
        apiKey: _apiKeyController.text,
        maxTokens: int.tryParse(_maxTokensController.text) ?? 1000,
        temperature: double.tryParse(_temperatureController.text) ?? 0.7,
      );
      
      // Проверяем баланс для проверки авторизации
      final balanceResult = await tempApiClient.getBalanceWithResult();
      
      if (!balanceResult.isSuccess) {
        throw Exception(balanceResult.errorMessage ?? 'Ошибка авторизации');
      }
      
      // Проверяем доступность моделей
      final models = await tempApiClient.getAvailableModels();
      if (models.isEmpty) {
        throw Exception('Не удалось загрузить список моделей');
      }
      
      setState(() {
        _connectionSuccess = true;
        _connectionTested = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Соединение успешно! Баланс: ${balanceResult.data}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _connectionTested = true;
      });

      String errorMessage = 'Ошибка соединения';
      if (e.toString().contains('401') || e.toString().contains('авторизации')) {
        errorMessage = 'Ошибка авторизации: проверьте API ключ';
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'Ошибка сети: проверьте подключение к интернету';
      } else {
        errorMessage = 'Ошибка: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: 'Сохранить настройки',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор провайдера
            _buildProviderSection(),
            const SizedBox(height: 24),
            
            // API ключ
            _buildApiKeySection(),
            const SizedBox(height: 24),
            
            // Параметры генерации
            _buildGenerationSection(),
            const SizedBox(height: 24),
            
            // Тест соединения
            _buildConnectionTestSection(),
            const SizedBox(height: 24),
            
            // Информация о провайдере
            _buildProviderInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection() {
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Провайдер API',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _selectedProvider == 'openrouter' ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedProvider == 'openrouter' ? Colors.blue : Colors.transparent,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _selectedProvider == 'openrouter' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: Colors.blue,
                ),
                title: const Text(
                  'OpenRouter.ai',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Международный провайдер, оплата в долларах',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  setState(() {
                    _selectedProvider = 'openrouter';
                    _connectionTested = false;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _selectedProvider == 'vsegpt' ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedProvider == 'vsegpt' ? Colors.blue : Colors.transparent,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _selectedProvider == 'vsegpt' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: Colors.blue,
                ),
                title: const Text(
                  'VseGPT.ru',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Российский провайдер, оплата в рублях',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  setState(() {
                    _selectedProvider = 'vsegpt';
                    _connectionTested = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Ключ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите ваш API ключ',
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _connectionTested = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationSection() {
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Параметры генерации',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxTokensController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Максимум токенов',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '1000',
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _temperatureController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Температура (0.0 - 1.0)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '0.7',
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTestSection() {
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тест соединения',
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
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_protected_setup),
                    label: Text(_isLoading ? 'Тестирование...' : 'Тест соединения'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_connectionTested) ...[
                  const SizedBox(width: 16),
                  Icon(
                    _connectionSuccess ? Icons.check_circle : Icons.error,
                    color: _connectionSuccess ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfo() {
    final isOpenRouter = _selectedProvider == 'openrouter';
    
    return Card(
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Информация о ${isOpenRouter ? 'OpenRouter.ai' : 'VseGPT.ru'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Валюта баланса:',
              isOpenRouter ? 'Доллары США (\$)' : 'Российские рубли (₽)',
            ),
            _buildInfoRow(
              'Единица расчета:',
              isOpenRouter ? 'За миллион токенов' : 'За тысячу токенов',
            ),
            _buildInfoRow(
              'Доступные модели:',
              isOpenRouter ? 'GPT, Claude, Gemini и др.' : 'GPT, Claude, Llama и др.',
            ),
            if (isOpenRouter) ...[
              const SizedBox(height: 8),
              const Text(
                'Для получения API ключа зарегистрируйтесь на openrouter.ai',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Для получения API ключа зарегистрируйтесь на vsegpt.ru',
                style: TextStyle(
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
