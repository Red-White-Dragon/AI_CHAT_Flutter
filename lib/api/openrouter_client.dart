// Import JSON library
import 'dart:convert';
// Import HTTP client
import 'package:http/http.dart' as http;
// Import Flutter core classes
import 'package:flutter/foundation.dart';
// Import SharedPreferences for settings
import 'package:shared_preferences/shared_preferences.dart';

// Enum для типов ошибок API
enum ApiErrorType {
  unauthorized,
  networkError,
  invalidResponse,
  unknown
}

// Класс для результата API операций
class ApiResult<T> {
  final T? data;
  final ApiErrorType? errorType;
  final String? errorMessage;
  final bool isSuccess;

  ApiResult.success(this.data) 
    : errorType = null, 
      errorMessage = null, 
      isSuccess = true;

  ApiResult.error(this.errorType, this.errorMessage) 
    : data = null, 
      isSuccess = false;
}

// Класс клиента для работы с API OpenRouter
class OpenRouterClient {
  // API ключ для авторизации
  String? _apiKey;
  // Базовый URL API
  String? _baseUrl;
  // Заголовки HTTP запросов
  Map<String, String> _headers = {};

  // Единственный экземпляр класса (Singleton)
  static final OpenRouterClient _instance = OpenRouterClient._internal();

  // Фабричный метод для получения экземпляра
  factory OpenRouterClient() {
    return _instance;
  }

  // Приватный конструктор для реализации Singleton
  OpenRouterClient._internal();

  // Геттеры для доступа к настройкам
  String? get apiKey => _apiKey;
  String? get baseUrl => _baseUrl;
  Map<String, String> get headers => _headers;

  // Метод инициализации клиента с настройками из SharedPreferences
  Future<void> initializeFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _apiKey = prefs.getString('api_key') ?? '';
      final provider = prefs.getString('provider') ?? 'openrouter';
      
      _baseUrl = provider == 'openrouter' 
          ? 'https://openrouter.ai/api/v1'
          : 'https://api.vsetgpt.ru/v1';

      _headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'X-Title': 'AI Chat Flutter',
      };

      if (kDebugMode) {
        print('OpenRouterClient initialized from settings');
        print('Provider: $provider');
        print('Base URL: $_baseUrl');
        print('API Key present: ${_apiKey?.isNotEmpty == true}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing OpenRouterClient from settings: $e');
        print('Stack trace: $stackTrace');
      }
      // Устанавливаем значения по умолчанию
      _apiKey = '';
      _baseUrl = 'https://openrouter.ai/api/v1';
      _headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'X-Title': 'AI Chat Flutter',
      };
    }
  }

  // Метод обновления настроек
  Future<void> updateSettings(String apiKey, String provider) async {
    _apiKey = apiKey;
    _baseUrl = provider == 'openrouter' 
        ? 'https://openrouter.ai/api/v1'
        : 'https://api.vsetgpt.ru/v1';

    _headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'X-Title': 'AI Chat Flutter',
    };

    if (kDebugMode) {
      print('OpenRouterClient settings updated');
      print('Provider: $provider');
      print('Base URL: $_baseUrl');
    }
  }

  // Метод инициализации с конкретными настройками (для тестирования)
  void initializeWithSettings({
    required String provider,
    required String apiKey,
    required int maxTokens,
    required double temperature,
  }) {
    _apiKey = apiKey;
    _baseUrl = provider == 'openrouter' 
        ? 'https://openrouter.ai/api/v1'
        : 'https://api.vsetgpt.ru/v1';

    _headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'X-Title': 'AI Chat Flutter',
    };

    if (kDebugMode) {
      print('OpenRouterClient initialized with custom settings');
      print('Provider: $provider');
      print('Base URL: $_baseUrl');
      print('API Key present: ${_apiKey?.isNotEmpty == true}');
    }
  }

  // Метод получения списка доступных моделей (алиас для getModels)
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    return await getModels();
  }

  // Метод получения списка доступных моделей
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      // Выполнение GET запроса для получения моделей
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Models response status: ${response.statusCode}');
        print('Models response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о моделях
        final modelsData = json.decode(response.body);
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List)
              .map((model) => {
                    'id': model['id'] as String,
                    'name': (() {
                      try {
                        return utf8.decode((model['name'] as String).codeUnits);
                      } catch (e) {
                        // Remove invalid UTF-8 characters and try again
                        final cleaned = (model['name'] as String)
                            .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
                        return utf8.decode(cleaned.codeUnits);
                      }
                    })(),
                    'pricing': {
                      'prompt': model['pricing']['prompt'] as String,
                      'completion': model['pricing']['completion'] as String,
                    },
                    'context_length': (model['context_length'] ??
                            model['top_provider']['context_length'] ??
                            0)
                        .toString(),
                  })
              .toList();
        }
        throw Exception('Invalid API response format');
      } else {
        // Возвращение моделей по умолчанию, если API недоступен
        return [
          {'id': 'deepseek-coder', 'name': 'DeepSeek'},
          {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
          {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
        ];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting models: $e');
      }
      // Возвращение моделей по умолчанию в случае ошибки
      return [
        {'id': 'deepseek-coder', 'name': 'DeepSeek'},
        {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
        {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
      ];
    }
  }

  // Метод отправки сообщения через API
  Future<Map<String, dynamic>> sendMessage(String message, String model) async {
    try {
      // Получаем настройки из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final maxTokens = int.parse(prefs.getString('max_tokens') ?? '1000');
      final temperature = double.parse(prefs.getString('temperature') ?? '0.7');

      // Подготовка данных для отправки
      final data = {
        'model': model, // Модель для генерации ответа
        'messages': [
          {'role': 'user', 'content': message} // Сообщение пользователя
        ],
        'max_tokens': maxTokens, // Максимальное количество токенов
        'temperature': temperature, // Температура генерации
        'stream': false, // Отключение потоковой передачи
      };

      if (kDebugMode) {
        print('Sending message to API: ${json.encode(data)}');
      }

      // Выполнение POST запроса
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: headers,
        body: json.encode(data),
      );

      if (kDebugMode) {
        print('Message response status: ${response.statusCode}');
        print('Message response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Успешный ответ
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        // Обработка ошибки
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'error': errorData['error']?['message'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Метод получения текущего баланса с обработкой ошибок
  Future<ApiResult<String>> getBalanceWithResult() async {
    try {
      // Проверка наличия API ключа
      if (_apiKey == null || _apiKey!.isEmpty) {
        return ApiResult.error(ApiErrorType.unauthorized, 'API ключ не установлен');
      }

      // Выполнение GET запроса для получения баланса
      final response = await http.get(
        Uri.parse(baseUrl?.contains('vsegpt.ru') == true
            ? '$baseUrl/balance'
            : '$baseUrl/credits'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Balance response status: ${response.statusCode}');
        print('Balance response body: ${response.body}');
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResult.error(ApiErrorType.unauthorized, 'Неверный API ключ');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о балансе
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          if (baseUrl?.contains('vsegpt.ru') == true) {
            final credits =
                double.tryParse(data['data']['credits'].toString()) ??
                    0.0; // Доступно средств
            return ApiResult.success('${credits.toStringAsFixed(2)}₽');
          } else {
            final credits = data['data']['total_credits'] ?? 0; // Общие кредиты
            final usage =
                data['data']['total_usage'] ?? 0; // Использованные кредиты
            return ApiResult.success('\$${(credits - usage).toStringAsFixed(2)}');
          }
        }
        return ApiResult.error(ApiErrorType.invalidResponse, 'Неверный формат ответа API');
      }
      
      return ApiResult.error(ApiErrorType.networkError, 'Ошибка сети: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting balance: $e');
      }
      return ApiResult.error(ApiErrorType.networkError, 'Ошибка соединения: $e');
    }
  }

  // Метод получения текущего баланса (для обратной совместимости)
  Future<String> getBalance() async {
    final result = await getBalanceWithResult();
    if (result.isSuccess) {
      return result.data!;
    } else {
      return 'ошибка авторизации';
    }
  }

  // Метод проверки валидности API ключа
  Future<ApiResult<bool>> validateApiKey() async {
    final result = await getBalanceWithResult();
    return ApiResult.success(result.isSuccess);
  }

  // Метод форматирования цен
  String formatPricing(double pricing) {
    try {
      if (baseUrl?.contains('vsegpt.ru') == true) {
        return '${pricing.toStringAsFixed(3)}₽/K';
      } else {
        return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting pricing: $e');
      }
      return '0.00';
    }
  }
}
