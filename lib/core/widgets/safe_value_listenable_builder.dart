import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A ValueListenableBuilder that safely defers setState() if a notification
/// is dispatched during Flutter's persistentCallbacks build phase (such as from
/// background video texture or route transition animations).
class SafeValueListenableBuilder<T> extends StatefulWidget {
  const SafeValueListenableBuilder({
    required this.valueListenable,
    required this.builder,
    this.child,
    super.key,
  });

  final ValueListenable<T> valueListenable;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  @override
  State<SafeValueListenableBuilder<T>> createState() =>
      _SafeValueListenableBuilderState<T>();
}

class _SafeValueListenableBuilderState<T>
    extends State<SafeValueListenableBuilder<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(SafeValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      _value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    if (!mounted) return;
    final SchedulerBinding binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _value = widget.valueListenable.value;
          });
        }
      });
    } else {
      setState(() {
        _value = widget.valueListenable.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value, widget.child);
  }
}
