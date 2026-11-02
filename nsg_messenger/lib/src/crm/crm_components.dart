import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// CRM surfaces use the same ColorScheme slots as ChatistaTheme._buildGlass.
class CrmGlassCard extends StatelessWidget {
  const CrmGlassCard({
    super.key,
    required this.child,
    this.inverse = false,
    this.strong = false,
    this.alert = false,
    this.radius = 22,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final bool inverse, strong, alert;
  final double radius;
  final EdgeInsetsGeometry padding;
  static Color paper(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return c.brightness == Brightness.dark
        ? c.onSurface.withValues(alpha: 1)
        : c.surface;
  }

  static Color ink(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return c.brightness == Brightness.dark ? c.onPrimary : c.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: inverse
                ? paper(context)
                : strong
                ? c.surfaceContainerHigh
                : c.surfaceContainer,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: inverse
                  ? Colors.transparent
                  : alert
                  ? c.error.withValues(alpha: .45)
                  : c.outline,
            ),
          ),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: inverse ? ink(context) : c.onSurface),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: inverse ? ink(context) : c.onSurface,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum CrmPillTone { glass, white, accent, alert, dark, outline }

Color crmAlertForeground(BuildContext context) {
  final c = Theme.of(context).colorScheme;
  return c.brightness == Brightness.dark
      ? Color.lerp(c.error, c.onSurface, .85)!
      : c.error;
}

Color crmAlertBackground(BuildContext context) {
  final c = Theme.of(context).colorScheme;
  // Dark glass must remain legible even over the brightest wallpaper stop.
  return c.brightness == Brightness.dark
      ? c.onPrimary.withValues(alpha: .86)
      : Color.alphaBlend(c.error.withValues(alpha: .08), c.surface);
}

class CrmPill extends StatelessWidget {
  const CrmPill({
    super.key,
    required this.child,
    this.onPressed,
    this.tone = CrmPillTone.glass,
    this.height = 38,
    this.inverse = false,
    this.radius = 999,
    this.padding = 14,
    this.stretch = false,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final CrmPillTone tone;
  final double height, radius, padding;
  final bool inverse;
  final bool stretch;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final ink = CrmGlassCard.ink(context), paper = CrmGlassCard.paper(context);
    final foreground = switch (tone) {
      CrmPillTone.white || CrmPillTone.accent => ink,
      CrmPillTone.dark => paper,
      CrmPillTone.alert => crmAlertForeground(context),
      _ => inverse ? ink : c.onSurface,
    };
    final background = switch (tone) {
      CrmPillTone.white => paper,
      CrmPillTone.accent => c.primary,
      CrmPillTone.dark => ink,
      CrmPillTone.alert => crmAlertBackground(context),
      CrmPillTone.outline => Colors.transparent,
      _ => inverse ? ink.withValues(alpha: .06) : c.surfaceContainer,
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side:
          [
            CrmPillTone.glass,
            CrmPillTone.alert,
            CrmPillTone.outline,
          ].contains(tone)
          ? BorderSide(
              color: tone == CrmPillTone.alert
                  ? foreground.withValues(alpha: .55)
                  : inverse
                  ? ink.withValues(alpha: .25)
                  : c.outline,
            )
          : BorderSide.none,
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Center(
              widthFactor: stretch ? null : 1,
              heightFactor: 1,
              child: Container(
                constraints: BoxConstraints(minHeight: height, minWidth: 44),
                decoration: ShapeDecoration(color: background, shape: shape),
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 6),
                child: Center(
                  widthFactor: stretch ? null : 1,
                  heightFactor: 1,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: foreground, size: 20),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable fields and a separate action row, both above the keyboard.
class CrmQuickSheetLayout extends StatelessWidget {
  const CrmQuickSheetLayout({
    super.key,
    required this.content,
    required this.actions,
  });
  final Widget content, actions;
  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maximum = math.max(
      0.0,
      MediaQuery.sizeOf(context).height -
          keyboard -
          MediaQuery.viewPaddingOf(context).top -
          12,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maximum),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('crm-activity-scroll'),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: content,
                ),
              ),
              Padding(
                key: const ValueKey('crm-activity-actions'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CrmCircleButton extends StatelessWidget {
  const CrmCircleButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.accent = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool accent;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      label: label,
      child: SizedBox.square(
        dimension: 44,
        child: CrmPill(
          height: 44,
          padding: 0,
          tone: accent ? CrmPillTone.accent : CrmPillTone.glass,
          onPressed: onPressed,
          child: Icon(icon, size: 20),
        ),
      ),
    ),
  );
}

class CrmSectionHeader extends StatelessWidget {
  const CrmSectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.alert = false,
    this.uppercase = true,
  });
  final String title;
  final Widget? trailing;
  final bool alert, uppercase;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            uppercase ? title.toUpperCase() : title,
            style: TextStyle(
              fontSize: uppercase ? 12 : 14,
              fontWeight: FontWeight.w600,
              letterSpacing: uppercase ? 1.2 : 0,
              color: alert ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class CrmScreenHeader extends StatelessWidget {
  const CrmScreenHeader({
    super.key,
    required this.accent,
    required this.subtitle,
    this.leading,
    this.actions = const [],
  });
  final String accent, subtitle;
  final Widget? leading;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'CRM',
                  children: [
                    TextSpan(
                      text: ' · $accent',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...actions.map(
          (w) => Padding(padding: const EdgeInsets.only(left: 8), child: w),
        ),
      ],
    ),
  );
}

class CrmSegmented extends StatelessWidget {
  const CrmSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => CrmGlassCard(
    radius: 999,
    padding: const EdgeInsets.all(4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++)
          CrmPill(
            height: 34,
            tone: i == selected ? CrmPillTone.white : CrmPillTone.outline,
            onPressed: () => onSelected(i),
            child: Text(labels[i]),
          ),
      ],
    ),
  );
}

class CrmStageBar extends StatelessWidget {
  const CrmStageBar({super.key, required this.count, required this.current});
  final int count, current;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i <= current
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
    ],
  );
}

/// A filled, rounded field shared by CRM forms, with its label above the fill.
class CrmField extends StatelessWidget {
  const CrmField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CrmSectionHeader(label),
      Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: CrmGlassCard.ink(context).withValues(alpha: .04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: CrmGlassCard.ink(context).withValues(alpha: .18),
              ),
            ),
          ),
        ),
        child: child,
      ),
    ],
  );
}

class CrmFlatRow extends StatelessWidget {
  const CrmFlatRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final Widget title;
  final Widget? subtitle, leading, trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 12),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    ),
  );
}

/// Catalog selection is a pill opening a separate choice sheet, never an
/// underlined Material dropdown. Only server-provided options are rendered.
class CrmSelect<T> extends StatelessWidget {
  const CrmSelect({
    super.key,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    this.isExpanded = false,
  });
  final T? initialValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final bool isExpanded;
  @override
  Widget build(BuildContext context) => CrmField(
    label: decoration.labelText ?? '',
    child: CrmPill(
      height: 44,
      onPressed: onChanged == null
          ? null
          : () async {
              final value = await showModalBottomSheet<T>(
                context: context,
                backgroundColor: CrmGlassCard.paper(context),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (ctx) => SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in items ?? <DropdownMenuItem<T>>[])
                          CrmPill(
                            inverse: true,
                            onPressed: () => Navigator.pop(ctx, item.value),
                            child: item.child,
                          ),
                      ],
                    ),
                  ),
                ),
              );
              if (value != null) onChanged!(value);
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          items
                  ?.where((item) => item.value == initialValue)
                  .firstOrNull
                  ?.child ??
              const Text('—'),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more),
        ],
      ),
    ),
  );
}

class CrmAgentHeader extends StatelessWidget {
  const CrmAgentHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => CrmFlatRow(
    leading: CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      child: Text(
        title.characters.first,
        style: const TextStyle(
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontSize: 18,
        ),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

double crmColumnWidth(double available, int count) =>
    math.max(220, (available - 32) / math.max(1, count));
