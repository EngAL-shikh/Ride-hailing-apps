import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'sdui_node.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/ride/controllers/ride_controller.dart';
import '../../theme/app_theme.dart';
import '../../core/storage/auth_store.dart';

// Converts SDUI JSON nodes into Flutter widgets.
class SduiWidgetFactory {
  const SduiWidgetFactory();

  Widget build(BuildContext context, SduiNode node) {
    switch (node.type) {
      case 'column':
        final mainAxisSize = node.props['mainAxisSize']?.toString() == 'min'
            ? MainAxisSize.min
            : MainAxisSize.max;
        final isScrollable = node.props['scrollable'] == true;
        
        Widget column = Column(
          crossAxisAlignment: _crossAxisAlignment(
            node.props['crossAxisAlignment'],
          ),
          mainAxisAlignment: _mainAxisAlignment(
            node.props['mainAxisAlignment'],
          ),
          mainAxisSize: mainAxisSize,
          children: node.children.map((c) => build(context, c)).toList(),
        );

        if (isScrollable) {
          column = SingleChildScrollView(
            child: column,
          );
        }
        
        return column;
      case 'row':
        return Row(
          crossAxisAlignment: _crossAxisAlignment(
            node.props['crossAxisAlignment'],
          ),
          mainAxisAlignment: _mainAxisAlignment(
            node.props['mainAxisAlignment'],
          ),
          children: node.children.map((c) => build(context, c)).toList(),
        );
      case 'text':
        final v = node.props['value'] ?? node.props['text'] ?? '';
        return Text(
          v.toString(),
          textAlign: _textAlign(node.props['textAlign']),
          style: _textStyle(context, node.props),
        );
      case 'spacer':
        final height = _double(node.props['height']);
        final width = _double(node.props['width']);
        final flex = _int(node.props['flex']);

        // If flex is specified, use Flexible instead of Spacer
        // (Spacer uses Expanded which doesn't work in unbounded constraints)
        if (flex != null && flex > 0) {
          return Flexible(flex: flex, child: SizedBox.shrink());
        }

        return SizedBox(height: height, width: width);
      case 'padding':
        final all = _double(node.props['all']);
        final padding = all != null
            ? EdgeInsets.all(all)
            : _edgeInsets(node.props) ?? EdgeInsets.zero;
        return Padding(
          padding: padding,
          child: node.children.isNotEmpty
              ? build(context, node.children.first)
              : const SizedBox.shrink(),
        );
      case 'center':
        return Center(
          child: node.children.isNotEmpty
              ? build(context, node.children.first)
              : const SizedBox.shrink(),
        );
      case 'card':
        final color = _color(node.props['color']) ?? AppTheme.white;
        final elevation = _double(node.props['elevation']) ?? 2.0;
        final borderRadius = _double(node.props['borderRadius']) ?? 16.0;
        final margin =
            _edgeInsets(node.props['margin']) ??
            const EdgeInsets.only(bottom: 16);

        // Check if card has a transparent button (for tappable cards)
        String? route;
        bool hasTransparentButton = false;
        for (var child in node.children) {
          if (child.type == 'button') {
            final buttonStyle = child.props['style']?.toString();
            if (buttonStyle == 'transparent') {
              hasTransparentButton = true;
              route = child.props['route']?.toString();
              break;
            }
          }
        }

        final isScrollable = node.props['scrollable'] == true;

        // Build card content
        Widget cardContent = node.children.isNotEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: node.children
                    .where((c) {
                      if (c.type == 'button') {
                        final buttonStyle = c.props['style']?.toString();
                        return buttonStyle != 'transparent';
                      }
                      return true;
                    })
                    .map((c) => build(context, c))
                    .toList(),
              )
            : const SizedBox.shrink();

        // Handle padding if not already present in children
        final hasPadding = node.children.any((c) => c.type == 'padding');
        if (!hasPadding && node.children.isNotEmpty) {
          cardContent = Padding(
            padding: const EdgeInsets.all(16.0),
            child: cardContent,
          );
        }

        // Apply visual safety wrappers
        if (isScrollable) {
          cardContent = SingleChildScrollView(
            child: cardContent,
          );
        }

        final card = Card(
          color: color,
          elevation: elevation,
          shadowColor: AppTheme.primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          margin: margin,
          clipBehavior: _clipBehavior(node.props['clipBehavior']) ?? Clip.antiAlias,
          child: cardContent,
        );

        // Make card tappable if it has a transparent button
        if (hasTransparentButton && route != null && route.isNotEmpty) {
          return InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              Get.toNamed(route!);
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: card,
          );
        }

        return card;
      case 'button':
        final label =
            (node.props['label'] ??
                    node.props['text'] ??
                    node.props['value'] ??
                    '')
                .toString();
        final route = (node.props['route'] ?? '').toString();
        final action = node.props['action']?.toString();
        final iconName = node.props['icon']?.toString();
        final iconData = iconName != null ? _iconData(iconName) : null;
        final buttonStyle = node.props['style']?.toString();
        final isTransparent = buttonStyle == 'transparent';

        // If transparent, return empty widget (card will handle tap)
        if (isTransparent) {
          return const SizedBox.shrink();
        }

        final buttonColor =
            _color(node.props['backgroundColor']) ?? AppTheme.white;
        final textColor =
            _color(node.props['textColor']) ?? AppTheme.primaryColor;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: route.isEmpty && action == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    if (route.isNotEmpty) {
                      Get.toNamed(route);
                    } else if (action != null) {
                      // Handle custom actions (e.g., 'refresh', 'logout')
                      _handleAction(action, node.props);
                    }
                  },
            icon: iconData != null
                ? Icon(iconData, color: textColor, size: 22)
                : const SizedBox.shrink(),
            label: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: textColor,
              elevation: 0,
              shadowColor: AppTheme.primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        );
      case 'image':
        final url = (node.props['url'] ?? node.props['src'] ?? '').toString();
        if (url.isEmpty) return const SizedBox.shrink();
        return Image.network(
          url,
          width: _double(node.props['width']),
          height: _double(node.props['height']),
          fit: _boxFit(node.props['fit']),
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
        );
      case 'list':
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: node.children.map((c) => build(context, c)).toList(),
        );
      case 'listTile':
        final title = (node.props['title'] ?? '').toString();
        final subtitle = (node.props['subtitle'] ?? '').toString();
        final leading = node.props['leading'] != null
            ? build(
                context,
                SduiNode.fromJson({
                  'type': 'icon',
                  'props': {'icon': node.props['leading']},
                }),
              )
            : null;
        final trailing = node.props['trailing'] != null
            ? build(
                context,
                SduiNode.fromJson({
                  'type': 'icon',
                  'props': {'icon': node.props['trailing']},
                }),
              )
            : null;
        final route = (node.props['route'] ?? '').toString();
        return ListTile(
          title: title.isNotEmpty ? Text(title) : null,
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          leading: leading,
          trailing: trailing,
          onTap: route.isNotEmpty ? () => Get.toNamed(route) : null,
        );
      case 'grid':
        final crossAxisCount = _int(node.props['crossAxisCount']) ?? 2;
        final spacing = _double(node.props['spacing']) ?? 8.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: node.children.length,
          itemBuilder: (context, index) => build(context, node.children[index]),
        );
      case 'divider':
        return Divider(
          height: _double(node.props['height']),
          thickness: _double(node.props['thickness']),
        );
      case 'container':
        final borderRadius = _double(node.props['borderRadius']);
        final flex = _int(node.props['flex']);
        final alignment = _alignment(node.props['alignment']);
        final clipBehavior = _clipBehavior(node.props['clipBehavior']) ?? Clip.none;

        Widget? child = node.children.isNotEmpty
            ? build(context, node.children.first)
            : null;

        if (child != null) {
          if (alignment != null) {
            child = Align(alignment: alignment, child: child);
          } else {
            child = Center(child: child);
          }
        }

        final opacity = _double(node.props['opacity']) ?? 1.0;

        Widget containerWidget = Container(
          width: _double(node.props['width']),
          height: _double(node.props['height']),
          padding: _edgeInsets(node.props['padding']),
          margin: _edgeInsets(node.props['margin']),
          clipBehavior: clipBehavior,
          decoration: BoxDecoration(
            color: _color(node.props['color']),
            gradient: _gradient(node.props['gradient']),
            boxShadow: _boxShadows(node.props['boxShadow']),
            borderRadius: borderRadius != null
                ? BorderRadius.circular(borderRadius)
                : _borderRadius(node.props['borderRadius']),
            border: node.props['border'] != null
                ? Border.all(
                    color:
                        _color(node.props['borderColor']) ?? AppTheme.lightGrey,
                    width: _double(node.props['borderWidth']) ?? 1.0,
                  )
                : null,
          ),
          child: child,
        );

        if (opacity < 1.0) {
          containerWidget = Opacity(opacity: opacity, child: containerWidget);
        }

        final action = node.props['action']?.toString();

        if (action != null && action.isNotEmpty) {
          containerWidget = InkWell(
            onTap: () => _handleAction(action, node.props),
            borderRadius: borderRadius != null
                ? BorderRadius.circular(borderRadius)
                : (_borderRadius(node.props['borderRadius']) as BorderRadius?),
            child: containerWidget,
          );
        }

        // If flex is specified, wrap in Expanded
        if (flex != null && flex > 0) {
          return Expanded(flex: flex, child: containerWidget);
        }

        return containerWidget;
      case 'stack':
        return Stack(
          alignment: _alignment(node.props['alignment']) ?? Alignment.topLeft,
          children: node.children.map((c) => build(context, c)).toList(),
        );
      case 'positioned':
        return Positioned(
          top: _double(node.props['top']),
          bottom: _double(node.props['bottom']),
          left: _double(node.props['left']),
          right: _double(node.props['right']),
          child: node.children.isNotEmpty
              ? build(context, node.children.first)
              : const SizedBox.shrink(),
        );
      case 'icon':
        final iconName = (node.props['icon'] ?? node.props['name'] ?? '')
            .toString();
        final iconData = _iconData(iconName);
        return Icon(
          iconData,
          size: _double(node.props['size']),
          color: _color(node.props['color']),
        );
      case 'chip':
        final label = (node.props['label'] ?? node.props['text'] ?? '')
            .toString();
        return Chip(
          label: Text(label),
          avatar: node.props['avatar'] != null
              ? build(
                  context,
                  SduiNode.fromJson({
                    'type': 'icon',
                    'props': {'icon': node.props['avatar']},
                  }),
                )
              : null,
          backgroundColor: _color(node.props['backgroundColor']),
          onDeleted: node.props['onDelete'] != null
              ? () => _handleAction('delete', node.props)
              : null,
        );
      case 'circularProgress':
        return Center(
          child: CircularProgressIndicator(
            value: _double(node.props['value']),
            strokeWidth: _double(node.props['strokeWidth']) ?? 4.0,
          ),
        );
      case 'sizedBox':
        return SizedBox(
          width: _double(node.props['width']),
          height: _double(node.props['height']),
          child: node.children.isNotEmpty
              ? build(context, node.children.first)
              : null,
        );
      case 'fittedBox':
        return FittedBox(
          fit: _boxFit(node.props['fit']) ?? BoxFit.scaleDown,
          alignment: _alignment(node.props['alignment']) ?? Alignment.center,
          child: node.children.isNotEmpty
              ? build(context, node.children.first)
              : const SizedBox.shrink(),
        );
      case 'expanded':
        return Expanded(
          flex: _int(node.props['flex']) ?? 1,
          child: node.children.isNotEmpty
              ? build(context, node.children.first)
              : const SizedBox.shrink(),
        );
      case 'flexible':
        return Flexible(
          flex: _int(node.props['flex']) ?? 1,
          fit: node.props['fit']?.toString() == 'tight'
              ? FlexFit.tight
              : FlexFit.loose,
          child: node.children.isNotEmpty
              ? build(context, node.children.first)
              : const SizedBox.shrink(),
        );
      case 'driversList':
        // Dynamic drivers list widget (reads from RideController)
        // As per plan: show list of drivers instead of heavy map
        return _buildDriversList(context);
      case 'activeTripCard':
        // Active trip floating card widget (for riders)
        // Shows persistent trip card when there's an active trip
        return _buildActiveTripCard(context);
      case 'staggeredGrid':
        final crossAxisCount = _int(node.props['crossAxisCount']) ?? 4;
        final mainAxisSpacing = _double(node.props['mainAxisSpacing']) ?? 8.0;
        final crossAxisSpacing = _double(node.props['crossAxisSpacing']) ?? 8.0;
        
        return StaggeredGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          children: node.children.map((c) {
            final crossAxisCellCount = _int(c.props['crossAxisCellCount']) ?? 2;
            final mainAxisCellCount = _int(c.props['mainAxisCellCount']) ?? 2;
            
            return StaggeredGridTile.count(
              crossAxisCellCount: crossAxisCellCount,
              mainAxisCellCount: mainAxisCellCount,
              child: build(context, c),
            );
          }).toList(),
        );
      case 'profileHeader':
        return _buildProfileHeader(context, node.props);
      default:
        // Unknown widget type: render nothing to avoid crashes.
        return const SizedBox.shrink();
    }
  }

  CrossAxisAlignment _crossAxisAlignment(dynamic v) {
    switch ((v ?? '').toString()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'center':
      default:
        return CrossAxisAlignment.center;
    }
  }

  MainAxisAlignment _mainAxisAlignment(dynamic v) {
    switch ((v ?? '').toString()) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      case 'center':
      default:
        return MainAxisAlignment.center;
    }
  }

  Alignment? _alignment(dynamic v) {
    switch ((v ?? '').toString()) {
      case 'center':
        return Alignment.center;
      case 'topLeft':
        return Alignment.topLeft;
      case 'topRight':
        return Alignment.topRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomRight':
        return Alignment.bottomRight;
      case 'topCenter':
        return Alignment.topCenter;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      default:
        return null;
    }
  }

  TextAlign? _textAlign(dynamic v) {
    switch ((v ?? '').toString()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      case 'justify':
        return TextAlign.justify;
      default:
        return null;
    }
  }

  TextStyle? _textStyle(BuildContext context, Map<String, dynamic> props) {
    final raw = props['style'];

    // Allow shorthand styles like "title" for convenience.
    if (raw is String) {
      switch (raw) {
        case 'title':
          return Theme.of(context).textTheme.titleLarge;
        case 'subtitle':
          return Theme.of(context).textTheme.titleMedium;
        case 'body':
        default:
          return Theme.of(context).textTheme.bodyMedium;
      }
    }

    final style = (raw is Map<String, dynamic>) ? raw : null;
    if (style == null) return null;

    final fontSize = _double(style['fontSize']);
    final fontWeight = _fontWeight(style['fontWeight']);
    final color = _color(style['color']);
    final letterSpacing = _double(style['letterSpacing']);
    final height = _double(style['height']) ?? _double(style['lineHeight']);
    
    final base = Theme.of(context).textTheme.bodyMedium;
    return base?.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  FontWeight? _fontWeight(dynamic v) {
    switch ((v ?? '').toString()) {
      case 'bold':
      case 'w700':
        return FontWeight.w700;
      case 'w600':
        return FontWeight.w600;
      case 'w500':
        return FontWeight.w500;
      case 'normal':
      case 'w400':
        return FontWeight.w400;
      default:
        return null;
    }
  }

  double? _double(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Color? _color(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return null;
    // Supports hex like #RRGGBB or #AARRGGBB
    final hex = s.startsWith('#') ? s.substring(1) : s;
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return null;
  }

  Gradient? _gradient(dynamic v) {
    if (v is! Map<String, dynamic>) return null;
    final colors = (v['colors'] as List?)?.map((c) => _color(c) ?? Colors.transparent).toList() ?? [];
    if (colors.isEmpty) return null;

    final begin = _alignment(v['begin']) ?? Alignment.topCenter;
    final end = _alignment(v['end']) ?? Alignment.bottomCenter;

    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }

  List<BoxShadow>? _boxShadows(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v.map((item) => _boxShadow(item)).whereType<BoxShadow>().toList();
    }
    final shadow = _boxShadow(v);
    return shadow != null ? [shadow] : null;
  }

  BoxShadow? _boxShadow(dynamic v) {
    if (v is! Map<String, dynamic>) return null;
    return BoxShadow(
      color: _color(v['color']) ?? Colors.black.withOpacity(0.1),
      blurRadius: _double(v['blurRadius']) ?? 0,
      spreadRadius: _double(v['spreadRadius']) ?? 0,
      offset: Offset(
        _double(v['offsetX']) ?? 0,
        _double(v['offsetY']) ?? 0,
      ),
    );
  }

  Clip? _clipBehavior(dynamic v) {
    switch ((v ?? '').toString()) {
      case 'hardEdge':
        return Clip.hardEdge;
      case 'antiAlias':
        return Clip.antiAlias;
      case 'antiAliasWithSaveLayer':
        return Clip.antiAliasWithSaveLayer;
      case 'none':
      default:
        return Clip.none;
    }
  }

  BoxFit? _boxFit(dynamic v) {
    switch ((v ?? '').toString()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return null;
    }
  }

  int? _int(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  EdgeInsets? _edgeInsets(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final val = v.toDouble();
      return EdgeInsets.all(val);
    }
    if (v is Map<String, dynamic>) {
      return EdgeInsets.only(
        left: _double(v['left']) ?? 0,
        right: _double(v['right']) ?? 0,
        top: _double(v['top']) ?? 0,
        bottom: _double(v['bottom']) ?? 0,
      );
    }
    return null;
  }

  BorderRadius? _borderRadius(dynamic v) {
    if (v == null) return null;
    final radius = _double(v);
    if (radius != null) {
      return BorderRadius.circular(radius);
    }
    return null;
  }

  IconData? _iconData(String name) {
    // Map common icon names to Iconsax (preferred) or Material Icons
    switch (name.toLowerCase()) {
      // Iconsax icons (preferred)
      case 'home':
      case 'home_2':
        return Iconsax.home_2;
      case 'wallet':
      case 'wallet_1':
      case 'account_balance_wallet':
        return Iconsax.wallet_1;
      case 'ride':
      case 'driving':
      case 'directions_bike':
        return Iconsax.driving;
      case 'map':
      case 'map_1':
        return Iconsax.map_1;
      case 'history':
      case 'clock':
        return Iconsax.clock;
      case 'person':
      case 'user':
        return Iconsax.user;
      case 'settings':
      case 'setting_2':
        return Iconsax.setting_2;
      case 'notifications':
      case 'notification':
        return Iconsax.notification;
      case 'arrow_back':
      case 'arrow_right_3':
        return Iconsax.arrow_right_3;
      case 'arrow_forward':
      case 'arrow_left_2':
        return Iconsax.arrow_left_2;
      case 'add':
      case 'add_circle':
        return Iconsax.add_circle;
      case 'delete':
      case 'trash':
        return Iconsax.trash;
      case 'edit':
      case 'edit_2':
        return Iconsax.edit_2;
      case 'check':
      case 'tick_circle':
        return Iconsax.tick_circle;
      case 'close':
      case 'close_circle':
        return Iconsax.close_circle;
      case 'star':
        return Iconsax.star;
      case 'location':
      case 'location_on':
        return Iconsax.location;
      case 'refresh':
        return Iconsax.refresh;
      case 'my_trips':
      case 'document':
        return Iconsax.document;
      // Fallback to Material Icons if not found
      default:
        return Icons.help_outline;
    }
  }

  /// Build drivers list widget (as per plan - list instead of heavy map)
Widget _buildDriversList(BuildContext context) {
  if (!Get.isRegistered<RideController>()) {
    return const SizedBox.shrink();
  }

  final rideController = Get.find<RideController>();

  return Obx(() {
    if (rideController.nearbyDrivers.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937).withOpacity(0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.info_circle,
                size: 40,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا يوجد سائقون قريبون حالياً',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'سنخبرك فور توفر كباتن بالقرب منك',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => rideController.loadNearbyDrivers(),
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('تحديث'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Row(
            children: [
              const Text(
                'الآن بالقرب منك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (rideController.isLoadingDrivers.value)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Iconsax.refresh),
                  onPressed: () => rideController.loadNearbyDrivers(),
                  color: const Color(0xFF10B981),
                  iconSize: 20,
                ),
            ],
          ),
        ),
        ...rideController.nearbyDrivers.map((driver) {
          return _buildDriverCard(context, driver, rideController);
        }),
      ],
    );
  });
}

  /// Build individual driver card
Widget _buildDriverCard(
  BuildContext context,
  Map<String, dynamic> driver,
  RideController rideController,
) {
  final driverProfile = driver['driver_profile'] as Map<String, dynamic>?;
  final driverName = driver['name']?.toString() ?? 'سائق';
  final rating = (driverProfile?['rating'] as num?)?.toDouble() ?? 0;
  final tripsCount = (driverProfile?['trips_count'] as num?)?.toInt() ?? 0;
  final distanceKm = (driver['distance_km'] as num?)?.toDouble();
  final bikePlate = driverProfile?['bike_plate']?.toString() ?? '';

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937).withOpacity(0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: InkWell(
      onTap: () => _showDriverDetails(context, driver, rideController),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.2),
                    const Color(0xFF3B82F6).withOpacity(0.2),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(
                Iconsax.user,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Iconsax.star, color: Color(0xFFFFB800), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Iconsax.truck,
                        size: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$tripsCount رحلة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  if (distanceKm != null || bikePlate.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (distanceKm != null) ...[
                          Icon(
                            Iconsax.location,
                            size: 13,
                            color: const Color(0xFF10B981).withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} كم',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF10B981).withOpacity(0.8),
                            ),
                          ),
                          if (bikePlate.isNotEmpty) const SizedBox(width: 12),
                        ],
                        if (bikePlate.isNotEmpty) ...[
                          Icon(
                            Iconsax.driving,
                            size: 13,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bikePlate,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Get.toNamed('/ride-map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(60, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'طلب',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> props) {
    final userName = AuthStore.name ?? 'مرحباً بك';
    final userPhone = AuthStore.phone ?? '';
    
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Iconsax.user,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userPhone,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (AuthStore.userType == 'driver')
          GestureDetector(
            onTap: () => Get.toNamed('/driver-verification'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.verify, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'توثيق',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build active trip card widget (for SDUI)
  Widget _buildActiveTripCard(BuildContext context) {
    if (!Get.isRegistered<RideController>()) {
      return const SizedBox.shrink();
    }

    final rideController = Get.find<RideController>();

    return Obx(() {
      final activeTrip = rideController.activeTrip.value;

      if (activeTrip == null) {
        return const SizedBox.shrink();
      }

      final status = activeTrip['status']?.toString() ?? 'unknown';
      final driverName = activeTrip['driver']?['name']?.toString() ?? 'السائق';
      final acceptedPrice = (activeTrip['accepted_price'] as num?)?.toDouble();
      final tripId = activeTrip['id']?.toString() ?? '';

      // Only show for assigned or in_progress trips
      if (!['assigned', 'in_progress'].contains(status)) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: status == 'assigned'
                ? [AppTheme.info, AppTheme.info.withOpacity(0.8)]
                : [AppTheme.success, AppTheme.success.withOpacity(0.8)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (status == 'assigned' ? AppTheme.info : AppTheme.success)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent, // Keep transparent for specific use cases
          child: InkWell(
            onTap: () {
              rideController.tripId.value = tripId;
              Get.toNamed('/trip-tracking', arguments: {'trip': activeTrip});
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      status == 'assigned'
                          ? Icons.directions_bike
                          : Icons.local_taxi,
                      color: AppTheme.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status == 'assigned'
                              ? 'السائق في الطريق'
                              : 'الرحلة جارية',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'السائق: $driverName',
                          style: TextStyle(
                            color: AppTheme.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        if (acceptedPrice != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${acceptedPrice.toStringAsFixed(0)} ريال',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Show driver details bottom sheet
  void _showDriverDetails(
    BuildContext context,
    Map<String, dynamic> driver,
    RideController rideController,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['name']?.toString() ?? 'سائق',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final rating =
                                (driver['driver_profile']?['rating'] as num?)
                                    ?.toDouble() ??
                                0;
                            return Icon(
                              index < rating.floor()
                                  ? Icons.star
                                  : (index < rating
                                        ? Icons.star_half
                                        : Icons.star_border),
                              color: AppTheme.warning,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '${(driver['driver_profile']?['rating'] as num?)?.toDouble() ?? 0}',
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.toNamed('/ride-map');
                },
                icon: const Icon(Icons.directions_bike),
                label: const Text('طلب رحلة مع هذا السائق'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.toNamed(
                    '/driver-details',
                    arguments: driver,
                  ); // Routes.driverDetails
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('عرض التفاصيل'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _handleAction(String action, Map<String, dynamic> props) {
    HapticFeedback.lightImpact();
    
    if (action.startsWith('route:')) {
      final route = action.replaceFirst('route:', '');
      if (route.isNotEmpty) {
        Get.toNamed(route);
      }
      return;
    }

    switch (action) {
      case 'refresh':
        // Trigger refresh in parent controller if available
        Get.find<HomeController>().fetchHomeLayout();
        break;
      case 'logout':
        // Handle logout
        Get.offAllNamed('/login');
        break;
      default:
        Get.log('[SDUI] Unknown action: $action');
    }
  }
}
