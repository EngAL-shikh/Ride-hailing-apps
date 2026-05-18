// SDUI node model.
// Comments in English as per project rules.

class SduiNode {
  final String type;
  final Map<String, dynamic> props;
  final List<SduiNode> children;

  const SduiNode({
    required this.type,
    this.props = const <String, dynamic>{},
    this.children = const <SduiNode>[],
  });

  factory SduiNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final children = <SduiNode>[];
    if (rawChildren is List) {
      for (final c in rawChildren) {
        if (c is Map<String, dynamic>) {
          children.add(SduiNode.fromJson(c));
        }
      }
    }

    // Prefer schema: { type, props: {...}, children: [...] }
    // Keep backward compatibility by merging any extra top-level keys into props.
    final props = <String, dynamic>{};
    final rawProps = json['props'];
    if (rawProps is Map) {
      props.addAll(Map<String, dynamic>.from(rawProps));
    }
    for (final entry in json.entries) {
      if (entry.key == 'type' || entry.key == 'children' || entry.key == 'props') continue;
      props[entry.key] = entry.value;
    }

    return SduiNode(
      type: (json['type'] ?? '').toString(),
      props: props,
      children: children,
    );
  }
}

