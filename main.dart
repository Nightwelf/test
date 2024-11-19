import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock<IconData>(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: ({required IconData e, GlobalKey? key}) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function({required T e, GlobalKey? key}) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  final GlobalKey _draggableKey = GlobalKey();
  int? _currentDockIndex;
  DragTargetDetails? onWillAcceptWithDetails;

  /// Когда пользователь выходит за пределы [Dock]
  /// убираем отступы
  void _onLeave(_) => setState(() {
        _currentDockIndex = null;
      });

  /// Устанавливаем первую принятую позицию
  /// далее обновляем индекс для реактивного
  /// отображения отступов
  bool _onWillAcceptWithDetails(details, index) {
    onWillAcceptWithDetails ??= details;
    setState(() {
      _currentDockIndex = index;
    });
    return true;
  }

  /// Отлавливаем событие onAcceptWithDetails
  /// в котором производим сортировку
  void _onAcceptWithDetails(details) {
    final offset =
        details.offset.dx - (onWillAcceptWithDetails?.offset.dx ?? 0);
    final newIndex = (((64 * details.data + offset)) / 64).toInt();
    final absIndex = newIndex < 0
        ? 0
        : newIndex > _items.length - 1
            ? _items.length - 1
            : newIndex;
    onWillAcceptWithDetails = null;
    setState(() {
      final item = _items.removeAt(details.data);
      _items.insert(absIndex, item);
      _currentDockIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.map((e) {
          /// Получаем индекс текущего элемента
          final int index = _items.indexOf(e);

          /// Вычисляем отступ
          final margin =
              _currentDockIndex != null && _currentDockIndex == index ? 48 : 0;
          return Draggable<int>(
            data: index,
            feedback: SizedBox(
              key: _draggableKey,
              child: widget.builder(e: _items[index]),
            ),
            childWhenDragging: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: const SizedBox()),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (details) =>
                  _onWillAcceptWithDetails(details, index),
              onLeave: _onLeave,
              onAcceptWithDetails: _onAcceptWithDetails,
              builder: (context, candidateData, rejectedData) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  margin: EdgeInsets.symmetric(
                    horizontal: margin.toDouble(),
                  ),
                  child: widget.builder(
                    e: _items[index],
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
