import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D flippable Player Style Card with an Ottoman-Roman-Chess imperial back
/// featuring the centered MoveLab emblem. Starts face-down and flips smoothly
/// on tap to reveal the player's analysis card.
class FlipPlayerStyleCard extends StatefulWidget {
  final Widget frontCard;
  final Color accentColor;
  final String playerName;
  final bool isEnglish;

  const FlipPlayerStyleCard({
    super.key,
    required this.frontCard,
    required this.accentColor,
    required this.playerName,
    required this.isEnglish,
  });

  @override
  State<FlipPlayerStyleCard> createState() => _FlipPlayerStyleCardState();
}

class _FlipPlayerStyleCardState extends State<FlipPlayerStyleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnimation;
  bool _isRevealed = false;

  static const Color _antiqueGold = Color(0xFFD4AF37);
  static const Color _softGold = Color(0xFFE6CC80);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flipAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant FlipPlayerStyleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset face-down whenever a different player is searched
    if (oldWidget.playerName.toLowerCase() != widget.playerName.toLowerCase()) {
      _isRevealed = false;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_controller.isAnimating) return;
    setState(() {
      _isRevealed = !_isRevealed;
    });
    if (_isRevealed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Widget _buildImperialCardBack() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF101624),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _antiqueGold.withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // 1. Engraved Ottoman-Roman-Chess bas-relief background
              Positioned.fill(
                child: Opacity(
                  opacity: 0.34,
                  child: Image.asset(
                    'assets/button_texture.jpg',
                    fit: BoxFit.cover,
                    color: const Color(0xFFC9A65B),
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ),

              // 2. Soft dark obsidian radial vignette for depth & center focus
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        const Color(0xFF141C2E).withValues(alpha: 0.55),
                        const Color(0xFF0A0E18).withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Recessed imperial double filigree frame & corner ornaments
              const Positioned.fill(
                child: CustomPaint(
                  painter: _ImperialCardFramePainter(
                    goldColor: _antiqueGold,
                  ),
                ),
              ),

              // 4. Centerpiece: Dead-center medallion with MoveLab logo & reveal prompt
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.isEnglish
                              ? 'PLAY STYLE ANALYSIS'
                              : 'OYUNCU STİLİ ANALİZİ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _softGold.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Double imperial gold medallion framing the MoveLab logo
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _antiqueGold.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _antiqueGold.withValues(alpha: 0.14),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Container(
                            width: 112,
                            height: 112,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF1C2438),
                                  Color(0xFF0E1422),
                                ],
                              ),
                              border: Border.all(
                                color: _antiqueGold.withValues(alpha: 0.78),
                                width: 1.8,
                              ),
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.auto_awesome,
                                color: _antiqueGold,
                                size: 46,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          widget.playerName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          width: 52,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _antiqueGold.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Subtle reveal pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF151B2B).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _antiqueGold.withValues(alpha: 0.55),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                color: _softGold,
                                size: 16,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                widget.isEnglish
                                    ? 'Tap to Reveal Card'
                                    : 'Kartı Açmak İçin Dokun',
                                style: const TextStyle(
                                  color: _softGold,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, _) {
          final double angle = _flipAnimation.value * math.pi;
          final bool showFront = angle > (math.pi / 2);

          final Matrix4 transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0011)
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Front card always defines the exact bounding box (zero size jump on flip!)
                Visibility(
                  visible: showFront,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: widget.frontCard,
                  ),
                ),
                // Back card fills the exact same width & height as the front card
                if (!showFront)
                  Positioned.fill(
                    child: _buildImperialCardBack(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImperialCardFramePainter extends CustomPainter {
  final Color goldColor;

  const _ImperialCardFramePainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 10.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    final innerFramePaint = Paint()
      ..color = goldColor.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      innerFramePaint,
    );

    // Classic geometric corner accents (Ottoman/Roman inspired)
    final cornerPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const double cLen = 14.0;
    const double cOff = 16.0;

    // Top-left
    canvas.drawLine(
        const Offset(cOff, cOff + cLen), const Offset(cOff, cOff), cornerPaint);
    canvas.drawLine(
        const Offset(cOff, cOff), const Offset(cOff + cLen, cOff), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(size.width - cOff - cLen, cOff),
        Offset(size.width - cOff, cOff), cornerPaint);
    canvas.drawLine(Offset(size.width - cOff, cOff),
        Offset(size.width - cOff, cOff + cLen), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(cOff, size.height - cOff - cLen),
        Offset(cOff, size.height - cOff), cornerPaint);
    canvas.drawLine(Offset(cOff, size.height - cOff),
        Offset(cOff + cLen, size.height - cOff), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - cOff - cLen, size.height - cOff),
        Offset(size.width - cOff, size.height - cOff), cornerPaint);
    canvas.drawLine(Offset(size.width - cOff, size.height - cOff - cLen),
        Offset(size.width - cOff, size.height - cOff), cornerPaint);

    // Subtle center top & bottom diamonds
    final diamondPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    void drawDiamond(Offset center, double r) {
      final path = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r, center.dy)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }

    drawDiamond(Offset(size.width / 2, inset), 3.5);
    drawDiamond(Offset(size.width / 2, size.height - inset), 3.5);
  }

  @override
  bool shouldRepaint(covariant _ImperialCardFramePainter oldDelegate) {
    return oldDelegate.goldColor != goldColor;
  }
}
