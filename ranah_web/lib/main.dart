import 'package:flutter/material.dart';

import 'app/ranah_app.dart';
import 'theme/ranah_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _textScale = 1;
  bool _showTextSizes = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RANAH',
      debugShowCheckedModeBanner: false,
      theme: RanahTheme.light,
      home: const RanahShell(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(_textScale)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              Positioned(
                right: 12,
                bottom: 12,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_showTextSizes)
                        _TextSizeOptions(
                          selectedScale: _textScale,
                          onSelected: (scale) => setState(() {
                            _textScale = scale;
                            _showTextSizes = false;
                          }),
                        ),
                      if (_showTextSizes) const SizedBox(height: 8),
                      _TextSizeControl(
                        onPressed: () => setState(() {
                          _showTextSizes = !_showTextSizes;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextSizeControl extends StatelessWidget {
  const _TextSizeControl({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RanahColors.primary,
      shape: const CircleBorder(),
      elevation: 5,
      child: Semantics(
        key: const ValueKey('text-size-control'),
        button: true,
        label: 'Atur ukuran teks',
        child: IconButton(
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onPressed,
          icon: const Icon(Icons.text_fields, color: Colors.white),
        ),
      ),
    );
  }
}

class _TextSizeOptions extends StatelessWidget {
  const _TextSizeOptions({
    required this.selectedScale,
    required this.onSelected,
  });

  final double selectedScale;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 6,
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 184,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Ukuran teks',
                style: TextStyle(
                  color: RanahColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final scale in [1.0, 1.15, 1.3])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => onSelected(scale),
                    child: Text(
                      '${(scale * 100).round()}%${selectedScale == scale ? ' · Dipilih' : ''}',
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
