import 'package:flutter/material.dart';

class SearchableModelSelector extends StatefulWidget {
  final List<Map<String, dynamic>> models;
  final String? selectedModel;
  final Function(String) onModelSelected;
  final Function(double) formatPricing;

  const SearchableModelSelector({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
    required this.formatPricing,
  });

  @override
  State<SearchableModelSelector> createState() =>
      _SearchableModelSelectorState();
}

class _SearchableModelSelectorState extends State<SearchableModelSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  List<Map<String, dynamic>> _filteredModels = [];
  OverlayEntry? _overlayEntry;
  bool _isUpdatingFromSelection = false;

  @override
  void initState() {
    super.initState();
    _filteredModels = widget.models;
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
    _updateSelectedModelText();
  }

  @override
  void didUpdateWidget(SearchableModelSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновляем список моделей, если он изменился
    if (oldWidget.models != widget.models) {
      _filteredModels = widget.models;
    }

    // Всегда обновляем текст при изменении виджета, чтобы гарантировать синхронизацию
    if (oldWidget.selectedModel != widget.selectedModel ||
        oldWidget.models != widget.models) {
      _updateSelectedModelText();
    }
  }

  void _updateSelectedModelText() {
    if (widget.selectedModel != null && widget.models.isNotEmpty) {
      final matchingModels = widget.models
          .where(
            (model) => model['id'] == widget.selectedModel,
          )
          .toList();

      if (matchingModels.isNotEmpty) {
        final selectedModelData = matchingModels.first;
        final name = selectedModelData['name'];
        final newText = name != null ? name.toString() : '';

        // Устанавливаем флаг, что это обновление от выбора модели
        _isUpdatingFromSelection = true;
        
        // Используем setState для принудительного обновления UI
        setState(() {
          _searchController.text = newText;
        });
        
        _isUpdatingFromSelection = false;
      }
    } else if (widget.selectedModel == null) {
      // Очищаем поле, если модель не выбрана
      _isUpdatingFromSelection = true;
      
      setState(() {
        _searchController.text = '';
      });
      
      _isUpdatingFromSelection = false;
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Игнорируем изменения, если это обновление от выбора модели
    if (_isUpdatingFromSelection) {
      return;
    }

    final query = _searchController.text.toLowerCase();
    
    // Проверяем, не является ли это текстом выбранной модели
    if (widget.selectedModel != null && widget.models.isNotEmpty) {
      final matchingModels = widget.models
          .where((model) => model['id'] == widget.selectedModel)
          .toList();
      
      if (matchingModels.isNotEmpty) {
        final selectedModelName = matchingModels.first['name']?.toString() ?? '';
        // Если текст совпадает с названием выбранной модели, показываем все модели
        if (_searchController.text == selectedModelName) {
          setState(() {
            _filteredModels = widget.models;
            _isDropdownOpen = _focusNode.hasFocus;
          });
          
          if (_isDropdownOpen && _filteredModels.isNotEmpty) {
            _showOverlay();
          } else {
            _hideOverlay();
          }
          return;
        }
      }
    }

    setState(() {
      if (query.isEmpty) {
        _filteredModels = widget.models;
      } else {
        _filteredModels = widget.models.where((model) {
          final name = model['name']?.toString().toLowerCase() ?? '';
          final id = model['id']?.toString().toLowerCase() ?? '';
          return name.contains(query) || id.contains(query);
        }).toList();
      }
      _isDropdownOpen = _focusNode.hasFocus;
    });

    if (_isDropdownOpen && _filteredModels.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isDropdownOpen = _focusNode.hasFocus;
    });

    if (_isDropdownOpen && _filteredModels.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _selectModel(Map<String, dynamic> model) {
    final name = model['name'];
    final id = model['id'];

    _hideOverlay();
    _focusNode.unfocus();

    setState(() {
      _isDropdownOpen = false;
    });

    if (id != null) {
      // Немедленно обновляем текст в поле поиска
      final modelName = name?.toString() ?? '';
      _isUpdatingFromSelection = true;
      _searchController.text = modelName;
      _isUpdatingFromSelection = false;

      // Вызываем коллбэк для обновления провайдера
      widget.onModelSelected(id.toString());

      // Показываем уведомление
      if (name != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Выбрана модель: $name'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focusNode.hasFocus ? Colors.blue : Colors.white70,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Поиск модели...',
            hintStyle: const TextStyle(color: Colors.white70, fontSize: 12),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            suffixIcon: Icon(
              _isDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _getTextFieldWidth(),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF333333),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white70, width: 1),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredModels.length,
                  itemBuilder: (context, index) {
                    final model = _filteredModels[index];
                    final isSelected = model['id'] == widget.selectedModel;
                    final modelName = model['name']?.toString() ?? '';
                    final promptPrice =
                        model['pricing']?['prompt']?.toString() ?? '0';
                    final completionPrice =
                        model['pricing']?['completion']?.toString() ?? '0';
                    final contextLength =
                        model['context_length']?.toString() ?? '0';

                    return MouseRegion(
                      child: GestureDetector(
                        onTapDown: (details) {
                          _selectModel(model);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                modelName,
                                style: TextStyle(
                                  color: isSelected ? Colors.blue : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.arrow_upward,
                                      size: 10, color: Colors.white70),
                                  const SizedBox(width: 2),
                                  Text(
                                    '\$$promptPrice',
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.white70),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_downward,
                                      size: 10, color: Colors.white70),
                                  const SizedBox(width: 2),
                                  Text(
                                    '\$$completionPrice',
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.white70),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.memory,
                                      size: 10, color: Colors.white70),
                                  const SizedBox(width: 2),
                                  Text(
                                    contextLength,
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getTextFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 200;
  }
}
