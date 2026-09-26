import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/ui/page_interactions.dart';
import 'package:konush/src/core/ui/konush_brand.dart';
export 'package:konush/src/core/ui/page_interactions.dart';

const ink = Color(0xFF12211F);
const muted = Color(0xFF7A8884);
const teal = konushBrandColor;
const tint = Color(0xFFE7F3F1);
const border = Color(0xFFE9EEEB);
const canvas = Color(0xFFF5F7F5);

class KonushShell extends StatelessWidget {
  const KonushShell({
    super.key,
    required this.child,
    required this.path,
    this.navigationShell,
  });
  final Widget child;
  final String path;
  final StatefulNavigationShell? navigationShell;
  @override
  Widget build(BuildContext context) {
    if (const [
          '/login',
          '/register',
          '/verify-phone',
          '/forgot-password',
          '/reset-code',
          '/new-password',
          '/submit',
          '/support',
        ].contains(path) ||
        path.startsWith('/listings/')) {
      return child;
    }
    final selected = navigationShell != null
        ? [0, 1, 3, 4][navigationShell!.currentIndex]
        : path == '/favorites'
        ? 1
        : path == '/messages'
        ? 3
        : const ['/profile', '/settings', '/my-listings'].contains(path)
        ? 4
        : 0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: border)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(
                height: 66,
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Expanded(
                        child: _NavItem(
                          index: i,
                          selected: selected == i,
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            final destination = [
                              '/',
                              '/favorites',
                              '/submit',
                              '/messages',
                              '/profile',
                            ][i];
                            if (i == 2) {
                              openPage(context, destination);
                            } else if (navigationShell != null) {
                              navigationShell!.goBranch([0, 1, 0, 2, 3][i]);
                            } else if (destination != path) {
                              context.go(destination);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selected,
    required this.onTap,
  });
  final int index;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final label = [
      context.tr("Главная"),
      context.tr("Избранное"),
      context.tr("Подать"),
      context.tr("Сообщения"),
      context.tr("Кабинет"),
    ][index];
    final icons = [
      Icons.home_outlined,
      Icons.favorite_border_rounded,
      Icons.add,
      Icons.chat_bubble_outline_rounded,
      Icons.person_outline_rounded,
    ];
    final active = [
      Icons.home_rounded,
      Icons.favorite_rounded,
      Icons.add,
      Icons.chat_bubble_rounded,
      Icons.person_rounded,
    ];
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (index == 2)
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              else
                SizedBox(
                  height: 30,
                  child: Icon(
                    selected ? active[index] : icons[index],
                    color: selected ? teal : muted,
                    size: 24,
                  ),
                ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected || index == 2 ? teal : muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void closePage(BuildContext context, {String fallback = '/'}) {
  FocusManager.instance.primaryFocus?.unfocus();
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

class KonushAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KonushAppBar({
    super.key,
    required this.title,
    this.back = false,
    this.actions,
    this.fallback = '/',
    this.brand = false,
  });
  final String title, fallback;
  final bool back, brand;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(60);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    leading: back
        ? IconButton(
            tooltip: context.tr("Назад"),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => closePage(context, fallback: fallback),
          )
        : null,
    titleSpacing: back ? 0 : 20,
    title: brand
        ? const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: KonushWordmark(),
          )
        : Text(title),
    actions: actions == null ? null : [...actions!, const SizedBox(width: 8)],
  );
}

class KonushWordmark extends StatelessWidget {
  const KonushWordmark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const KonushMark(),
      const SizedBox(width: 8),
      const Text(
        'konush',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: ink,
        ),
      ),
    ],
  );
}

/// Округлая K с акцентом, единая с иконками приложения.
class KonushMark extends StatelessWidget {
  const KonushMark({super.key, this.size = 29});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: const KonushSymbolPainter(),
  );
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(icon, color: teal, size: 34),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.55, fontSize: 14),
        ),
        if (action != null) ...[const SizedBox(height: 22), action!],
      ],
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon = Icons.info_outline_rounded});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: teal, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: teal, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

String displayPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 12 || !digits.startsWith('996')) return value;
  return '+996 ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
}
