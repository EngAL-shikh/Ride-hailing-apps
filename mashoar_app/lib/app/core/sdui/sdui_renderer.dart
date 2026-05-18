import 'package:flutter/material.dart';
import 'sdui_node.dart';
import 'sdui_widget_factory.dart';

class SduiRenderer extends StatelessWidget {
  final Map<String, dynamic> json;
  final SduiWidgetFactory factory;

  const SduiRenderer({
    super.key,
    required this.json,
    this.factory = const SduiWidgetFactory(),
  });

  @override
  Widget build(BuildContext context) {
    final node = SduiNode.fromJson(json);
    return factory.build(context, node);
  }
}

