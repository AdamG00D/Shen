import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.showAppBar = true,
    this.floatingActionButton,
    this.bottom,
    this.leading,
    this.safeTop = true,
  });

  /// لو false والـ AppBar مخفي، الصفحة نفسها مسؤولة عن مسافة شريط الحالة.
  final bool safeTop;
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;
  final Widget? floatingActionButton;
  final Widget? bottom;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: showAppBar ? AppBar(title: title == null ? null : Text(title!), actions: actions, leading: leading) : null,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottom,
      body: showAppBar || !safeTop ? body : SafeArea(bottom: false, child: body),
    );
  }
}

/// كارت بحدود رفيعة.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radius,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: color ?? p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, onLongPress: onLongPress, child: Padding(padding: padding, child: child)),
    );
  }
}

/// الزرار الأساسي (حبر في الفاتح، نحاس في الغامق).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = color ?? p.ink;
    final fg = color == null ? p.onInk : Palette.onColor(bg);
    final enabled = onPressed != null && !loading;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: fg.withValues(alpha: 0.85),
          minimumSize: Size(64, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
        ),
        child: loading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// زرار ثانوي: إطار رفيع من غير خلفية.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.height = 48,
    this.stacked = false,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;

  /// الأيقونة فوق الكلمة (لما الزرار ضيق) — والكلمة تنزل سطرين بدل ما تتقص.
  final bool stacked;

  /// الهامش الأفقي جوه الزرار (null = بتاع الثيم).
  final double? padding;

  static const textStyle = TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600, fontSize: 14.5);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = color ?? p.text;
    return SizedBox(
      height: stacked ? null : height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: color == null ? p.border : fg.withValues(alpha: 0.5)),
          minimumSize: Size(64, height),
          padding: padding == null
              ? null
              : EdgeInsets.symmetric(horizontal: padding!, vertical: stacked ? 10 : 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
          textStyle: textStyle,
        ),
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(height: 4)],
                  Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// أزرار النتيجة (نسخ / مشاركة / حفظ...) بشكل SecondaryButton العادي — الأيقونة جنب الكلمة.
/// لو مفيش مكان للكل في سطر واحد: الأول لوحده بعرض الشاشة والباقي تحته جنب بعض.
/// ولو الخط كبير جداً ولسه مش مكفي: الأيقونة فوق الكلمة. في كل الحالات مفيش كلمة بتتقص.
class ButtonRow extends StatelessWidget {
  const ButtonRow({super.key, required this.items});

  final List<({IconData icon, String label, VoidCallback onPressed})> items;

  static const _gap = 8.0;
  static const _pad = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final dir = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        double widest = 0;
        for (final i in items) {
          final tp = TextPainter(
            text: TextSpan(text: i.label, style: SecondaryButton.textStyle),
            textDirection: dir,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          if (tp.width > widest) widest = tp.width;
          tp.dispose();
        }
        // الكلمة + الأيقونة + المسافة + الهامش + الإطار
        final need = widest + 18 + 8 + _pad * 2 + 4;
        double each(int n) => (c.maxWidth - _gap * (n - 1)) / n;

        if (need <= each(items.length)) return _row(items, stacked: false);
        final rest = items.length > 2 ? items.sublist(1) : items;
        if (need <= each(rest.length)) {
          if (rest.length == items.length) return _row(items, stacked: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _row(items.sublist(0, 1), stacked: false),
              const SizedBox(height: _gap),
              _row(rest, stacked: false),
            ],
          );
        }
        return _row(items, stacked: true);
      },
    );
  }

  Widget _row(List<({IconData icon, String label, VoidCallback onPressed})> list, {required bool stacked}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(
              child: SecondaryButton(
                label: list[i].label,
                icon: list[i].icon,
                onPressed: list[i].onPressed,
                stacked: stacked,
                padding: _pad,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// أيقونة جوه دايرة بخط رفيع (من غير خلفية ملوّنة).
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.color, this.size = 44, this.filled = false});

  final IconData icon;
  final Color? color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.text;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? c : null,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: color == null ? p.border : c.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, color: filled ? Palette.onColor(c) : c, size: size * 0.46),
    );
  }
}

/// عنوان قسم صغير.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// عنوان الصفحة الكبير (مفاتيحي، جهات الاتصال...).
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// حالة فاضية: حلقة رفيعة فيها أيقونة + عنوان + شرح + زرار اختياري.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.accent, width: 1.5)),
              child: Icon(icon, size: 34, color: p.text),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, height: 1.7)),
            ],
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}

/// شارة رقم صغيرة.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(11)),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(color: p.onInk, fontSize: 12, fontWeight: FontWeight.w700, height: 1.1),
      ),
    );
  }
}

/// صف إعدادات: أيقونة + عنوان + شرح + حاجة في الآخر.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? p.text),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color ?? p.text)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.5)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              ...[const SizedBox(width: 8), trailing!]
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: p.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// أول حرف من الاسم — آمن مع الأسماء الفاضية.
String initialOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return String.fromCharCode(t.runes.first).toUpperCase();
}

/// حرف أول جوه حلقة (زي الختم): لون الحلقة بيقول نوع المفتاح.
class Monogram extends StatelessWidget {
  const Monogram({super.key, required this.name, this.ring, this.size = 44, this.icon});

  final String name;
  final Color? ring;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring ?? p.border, width: 2)),
      child: icon != null
          ? Icon(icon, size: size * 0.45, color: p.text)
          : Text(
              initialOf(name),
              style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w700, height: 1.1, color: p.text),
            ),
    );
  }
}

/// دايرة بلون البروفايل وأول حرف من اسمه.
class ProfileDot extends StatelessWidget {
  const ProfileDot({super.key, required this.name, required this.color, this.size = 36, this.locked = false});

  final String name;
  final int color;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = profileColor(color);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      child: locked
          ? Icon(Icons.lock_rounded, size: size * 0.5, color: Palette.onColor(c))
          : Text(
              initialOf(name),
              style: TextStyle(color: Palette.onColor(c), fontWeight: FontWeight.w700, fontSize: size * 0.42, height: 1.1),
            ),
    );
  }
}

/// الخرطوش: إطار بيضاوي فيه الاسم وفي آخره خط نحاسي — زي الخرطوش اللي كان بيحمي اسم الملك.
class Cartouche extends StatelessWidget {
  const Cartouche({super.key, required this.child, this.height = 44, this.onTap, this.barColor});

  final Widget child;
  final double height;
  final VoidCallback? onTap;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: p.text, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: height * 0.36, end: height * 0.28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: child),
                SizedBox(width: height * 0.22),
                Container(
                  width: 3.5,
                  height: height * 0.55,
                  decoration: BoxDecoration(color: barColor ?? p.accent, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// حالة صغيرة (الافتراضي، منتهي، متأكد منه...): نقطة + نص ملوّن، من غير خلفية.
class Chip2 extends StatelessWidget {
  const Chip2(this.label, {super.key, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
      ],
    );
  }
}
