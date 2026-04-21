import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:inspector/inspector.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Inspector Showcase',
      home: const ShowcaseApp(),
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      builder: (context, child) => Inspector(
        isEnabled: true,
        child: child!,
      ),
    ),
  );
}

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inspector Showcase'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Typography'),
              Tab(text: 'Layout'),
              Tab(text: 'Decoration'),
              Tab(text: 'Spacing'),
              Tab(text: 'Mixed'),
              Tab(text: 'Transform & Clip'),
              Tab(text: 'Fields'),
              Tab(text: 'Images'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TypographyTab(),
            _LayoutTab(),
            _DecorationTab(),
            _SpacingTab(),
            _MixedTab(),
            _TransformClipTab(),
            _FieldsTab(),
            _ImagesTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Typography ───────────────────────────────────────────────────────────────

class _TypographyTab extends StatelessWidget {
  const _TypographyTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text('Display Large', style: theme.textTheme.displayLarge),
          Text('Display Medium', style: theme.textTheme.displayMedium),
          Text('Headline Large', style: theme.textTheme.headlineLarge),
          Text('Headline Medium', style: theme.textTheme.headlineMedium),
          Text('Title Large', style: theme.textTheme.titleLarge),
          Text('Title Medium', style: theme.textTheme.titleMedium),
          Text('Body Large', style: theme.textTheme.bodyLarge),
          Text('Body Medium', style: theme.textTheme.bodyMedium),
          Text('Body Small', style: theme.textTheme.bodySmall),
          Text('Label Large', style: theme.textTheme.labelLarge),
          Text('Label Small', style: theme.textTheme.labelSmall),
          const Divider(),
          Text(
            'Custom styled text',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 4,
              height: 2.0,
              color: Colors.deepPurple,
              decoration: TextDecoration.underline,
            ),
          ),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                TextSpan(text: 'Rich '),
                TextSpan(
                  text: 'text ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                TextSpan(
                  text: 'with ',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 20,
                  ),
                ),
                TextSpan(
                  text: 'spans',
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Text('textAlign variants'),
          _AlignedText(
            text:
                'Left aligned text that wraps onto multiple lines to show alignment clearly.',
            align: TextAlign.left,
          ),
          _AlignedText(
            text:
                'Center aligned text that wraps onto multiple lines to show alignment clearly.',
            align: TextAlign.center,
          ),
          _AlignedText(
            text:
                'Right aligned text that wraps onto multiple lines to show alignment clearly.',
            align: TextAlign.right,
          ),
          _AlignedText(
            text:
                'Justify aligned text that wraps onto multiple lines to show how justify alignment spreads words.',
            align: TextAlign.justify,
          ),
          const Divider(),
          const Text('overflow + maxLines variants'),
          _OverflowText(
            label: 'ellipsis, maxLines: 1',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          _OverflowText(
            label: 'ellipsis, maxLines: 2',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          _OverflowText(
            label: 'fade, maxLines: 1',
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
          _OverflowText(
            label: 'clip, maxLines: 1',
            overflow: TextOverflow.clip,
            maxLines: 1,
          ),
          _OverflowText(
            label: 'no maxLines (unrestricted)',
            overflow: TextOverflow.ellipsis,
            maxLines: null,
          ),
        ],
      ),
    );
  }
}

class _AlignedText extends StatelessWidget {
  const _AlignedText({required this.text, required this.align});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, textAlign: align, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _OverflowText extends StatelessWidget {
  const _OverflowText({
    required this.label,
    required this.overflow,
    required this.maxLines,
  });
  final String label;
  final TextOverflow overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'This is a long text that is intentionally long to trigger overflow behaviour in the inspector showcase.',
            overflow: overflow,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Layout ───────────────────────────────────────────────────────────────────

class _LayoutTab extends StatelessWidget {
  const _LayoutTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          const Text('Row with MainAxisAlignment.spaceBetween'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(color: Colors.red.shade200, size: 40),
              _Box(color: Colors.green.shade200, size: 60),
              _Box(color: Colors.blue.shade200, size: 50),
              _Box(color: Colors.orange.shade200, size: 45),
            ],
          ),
          const Text('Nested containers with different sizes'),
          Center(
            child: Container(
              width: 280,
              height: 180,
              color: Colors.teal.shade100,
              child: Center(
                child: Container(
                  width: 200,
                  height: 120,
                  color: Colors.teal.shade300,
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 60,
                      color: Colors.teal.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Text('Stack with Positioned children'),
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                Container(color: Colors.grey.shade200),
                Positioned(
                  left: 16,
                  top: 16,
                  width: 80,
                  height: 80,
                  child: Container(color: Colors.pink.shade300),
                ),
                Positioned(
                  left: 60,
                  top: 30,
                  width: 80,
                  height: 60,
                  child: Container(
                    color: Colors.amber.shade400.withValues(alpha: 0.8),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 10,
                  width: 100,
                  height: 40,
                  child: Container(color: Colors.cyan.shade300),
                ),
              ],
            ),
          ),
          const Text('Intrinsic height row'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.purple.shade100,
                    padding: const EdgeInsets.all(12),
                    child: const Text('Short'),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Container(
                    color: Colors.indigo.shade100,
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                        'This one is much taller because it has more content here'),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Container(
                    color: Colors.blue.shade100,
                    padding: const EdgeInsets.all(12),
                    child: const Text('Medium text'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color),
    );
  }
}

// ─── Decoration ───────────────────────────────────────────────────────────────

class _DecorationTab extends StatelessWidget {
  const _DecorationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _DecoratedCard(
            label: 'Circular radius',
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blue.shade400, width: 2),
            ),
          ),
          _DecoratedCard(
            label: 'Asymmetric radius',
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          _DecoratedCard(
            label: 'Shadow',
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          _DecoratedCard(
            label: 'Gradient',
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _DecoratedCard(
            label: 'Circle shape',
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          _DecoratedCard(
            label: 'Thick border',
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              border: Border.all(color: Colors.red.shade700, width: 4),
            ),
          ),
          _DecoratedCard(
            label: 'LTRB border',
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                left: BorderSide(color: Colors.red.shade400, width: 4),
                bottom: BorderSide(color: Colors.blue.shade400, width: 4),
              ),
            ),
          ),
          _DecoratedCard(
            label: 'Multi shadow',
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(-4, -4),
                ),
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecoratedCard extends StatelessWidget {
  const _DecoratedCard({required this.label, required this.decoration});
  final String label;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 80,
          decoration: decoration,
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ─── Spacing ──────────────────────────────────────────────────────────────────

class _SpacingTab extends StatelessWidget {
  const _SpacingTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          const Text('Asymmetric padding'),
          Container(
            color: Colors.amber.shade100,
            child: Container(
              padding: const EdgeInsets.only(
                left: 32,
                top: 8,
                right: 16,
                bottom: 24,
              ),
              color: Colors.amber.shade300,
              child: const Text('Inspect my padding'),
            ),
          ),
          const Text('Margin simulation via nested containers'),
          Container(
            color: Colors.teal.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Container(
              color: Colors.teal.shade400,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Inner box',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const Text('Spacing between siblings (compare mode test)'),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 0,
              children: [
                Container(
                  height: 40,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 40,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 32),
                Container(
                  height: 40,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 40,
                  color: Colors.purple.shade300,
                ),
              ],
            ),
          ),
          const Text('Inline elements with letter spacing'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'TRACKING',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
                color: Colors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mixed ────────────────────────────────────────────────────────────────────

class _MixedTab extends StatelessWidget {
  const _MixedTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 16,
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 16,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'JD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Doe',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Senior Flutter Engineer',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          // Stats row
          Row(
            spacing: 8,
            children: [
              _StatCard(label: 'Commits', value: '1,204', color: Colors.green),
              _StatCard(label: 'PRs', value: '84', color: Colors.blue),
              _StatCard(label: 'Issues', value: '12', color: Colors.orange),
            ],
          ),
          // Badge row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(label: 'Flutter', color: Colors.blue.shade700),
              _Badge(label: 'Dart', color: Colors.teal.shade700),
              _Badge(label: 'Firebase', color: Colors.orange.shade700),
              _Badge(label: 'GraphQL', color: Colors.pink.shade700),
              _Badge(label: 'iOS', color: Colors.grey.shade700),
              _Badge(label: 'Android', color: Colors.green.shade700),
            ],
          ),
          // Image placeholder with overlay text
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade800,
                      Colors.blueGrey.shade400
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Inspector Showcase',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap any widget to inspect',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Deeply nested padding
          Container(
            color: Colors.red.shade50,
            padding: const EdgeInsets.all(24),
            child: Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                color: Colors.red.shade200,
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  color: Colors.red.shade400,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'Deeply nested',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Transform & Clip ─────────────────────────────────────────────────────────

class _TransformClipTab extends StatelessWidget {
  const _TransformClipTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          const Text('Transform.rotate / scale / translate'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _LabelledTile(
                label: 'rotate 15°',
                child: Transform.rotate(
                  angle: 15 * math.pi / 180,
                  child: _SolidBox(color: Colors.red.shade300),
                ),
              ),
              _LabelledTile(
                label: 'scale 1.3',
                child: Transform.scale(
                  scale: 1.3,
                  child: _SolidBox(color: Colors.green.shade300),
                ),
              ),
              _LabelledTile(
                label: 'translate (8, -6)',
                child: Transform.translate(
                  offset: const Offset(8, -6),
                  child: _SolidBox(color: Colors.blue.shade300),
                ),
              ),
              _LabelledTile(
                label: 'rotate + scale',
                child: Transform.rotate(
                  angle: -20 * math.pi / 180,
                  child: Transform.scale(
                    scale: 1.1,
                    child: _SolidBox(color: Colors.orange.shade300),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          const Text('Clip variants'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _LabelledTile(
                label: 'ClipRRect',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _SolidBox(color: Colors.pink.shade300),
                ),
              ),
              _LabelledTile(
                label: 'ClipOval',
                child: ClipOval(
                  child: _SolidBox(color: Colors.indigo.shade300),
                ),
              ),
              _LabelledTile(
                label: 'ClipRect hardEdge',
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: _SolidBox(color: Colors.teal.shade300),
                ),
              ),
              _LabelledTile(
                label: 'ClipPath (star)',
                child: ClipPath(
                  clipper: _StarClipper(),
                  child: _SolidBox(color: Colors.amber.shade400),
                ),
              ),
              _LabelledTile(
                label: 'elliptical radius',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(32, 12),
                    bottomRight: Radius.elliptical(32, 12),
                  ),
                  child: _SolidBox(color: Colors.deepPurple.shade300),
                ),
              ),
            ],
          ),
          const Divider(),
          const Text('BackdropFilter'),
          Stack(
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.amber,
                      Colors.green,
                      Colors.blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        width: 160,
                        height: 60,
                        alignment: Alignment.center,
                        color: Colors.white.withValues(alpha: 0.2),
                        child: const Text(
                          'Blurred',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          const Text('Shadow with spreadRadius'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _LabelledTile(
                label: 'spread: 0',
                child: Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              _LabelledTile(
                label: 'spread: 4',
                child: Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              _LabelledTile(
                label: 'spread: -4 (inset-ish)',
                child: Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: -4,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          const Text('Gradient variants'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _LabelledTile(
                label: 'linear + stops',
                child: Container(
                  width: 100,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.yellow, Colors.blue],
                      stops: [0.0, 0.4, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              _LabelledTile(
                label: 'radial + tile',
                child: Container(
                  width: 100,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.white, Colors.black],
                      radius: 0.3,
                      tileMode: TileMode.mirror,
                    ),
                  ),
                ),
              ),
              _LabelledTile(
                label: 'sweep',
                child: Container(
                  width: 100,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.green,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolidBox extends StatelessWidget {
  const _SolidBox({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color),
      child: const Text('box'),
    );
  }
}

class _LabelledTile extends StatelessWidget {
  const _LabelledTile({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 80, width: 100, child: Center(child: child)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.shortestSide / 2;
    final inner = outer / 2.5;
    const pts = 5;
    for (var i = 0; i < pts * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / pts;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Fields ───────────────────────────────────────────────────────────────────

class _FieldsTab extends StatelessWidget {
  const _FieldsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const Text('TextField (RenderEditable)'),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Plain field',
              border: OutlineInputBorder(),
            ),
          ),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password (obscured)',
              border: OutlineInputBorder(),
            ),
          ),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: 'Read-only value'),
            decoration: const InputDecoration(
              labelText: 'Read-only',
              border: OutlineInputBorder(),
            ),
          ),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Multiline (maxLines: 4)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const TextField(
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.deepPurple,
            ),
            decoration: InputDecoration(
              labelText: 'Styled centered',
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(),
          const Text('RichText with recognizer / long preview'),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: const [
                TextSpan(text: 'Inspect this long paragraph to see '),
                TextSpan(
                  text: 'preview truncation',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(
                  text: ' and span style extraction across multiple styled '
                      'segments — this should be long enough to trigger the '
                      'ellipsis on the preview line of the info panel.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Images ───────────────────────────────────────────────────────────────────

class _ImagesTab extends StatelessWidget {
  const _ImagesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          const Text('RenderImage — network source'),
          Image.network(
            'https://picsum.photos/seed/inspector/300/160',
            width: 300,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 300,
              height: 160,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Text('network image unavailable'),
            ),
          ),
          const Text('RenderImage with color tint'),
          Image.network(
            'https://picsum.photos/seed/tint/200/120',
            width: 200,
            height: 120,
            fit: BoxFit.cover,
            color: Colors.deepOrange,
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (_, __, ___) => Container(
              width: 200,
              height: 120,
              color: Colors.grey.shade300,
            ),
          ),
          const Text('DecorationImage (BoxDecoration.image)'),
          Container(
            width: 300,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://picsum.photos/seed/deco/600/240',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black38,
                  BlendMode.darken,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Overlay content',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          const Text('Repeated pattern'),
          Container(
            width: 300,
            height: 80,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://picsum.photos/seed/tile/60/60',
                ),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
