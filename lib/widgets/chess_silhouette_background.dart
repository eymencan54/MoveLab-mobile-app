import 'dart:math' as math;
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';

enum _StauntonPiece { king, queen, rook, bishop, knight, pawn }

class _FloatingImperialPiece {
  final _StauntonPiece piece;
  final double startX;
  final double startY;
  final double sizeFactor;
  final double speedCycles;
  final double swayAmplitude;
  final double phase;
  final double baseAngle;
  final List<Color> metallicStops;
  final double opacity;

  const _FloatingImperialPiece({
    required this.piece,
    required this.startX,
    required this.startY,
    required this.sizeFactor,
    required this.speedCycles,
    required this.swayAmplitude,
    required this.phase,
    required this.baseAngle,
    required this.metallicStops,
    required this.opacity,
  });
}

/// Imperial Ottoman-Roman-Chess ambient background animation.
/// Combines:
/// 1. A slow-panning engraved bas-relief tapestry (`assets/button_texture.jpg`),
/// 2. Carved, metallic-shaded Staunton chess reliefs embedded beneath the
///    vignette and gallery lighting so they feel part of the stone/gold world,
/// 3. Soft obsidian vignette + moving antique-gold gallery light sheen.
class ChessSilhouetteBackground extends StatefulWidget {
  final Color accentColor;

  const ChessSilhouetteBackground({
    super.key,
    required this.accentColor,
  });

  @override
  State<ChessSilhouetteBackground> createState() =>
      _ChessSilhouetteBackgroundState();
}

class _ChessSilhouetteBackgroundState extends State<ChessSilhouetteBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color _antiqueGold = Color(0xFFD4AF37);

  static const List<Color> _goldRelief = [
    Color(0xFFC8AF70),
    Color(0xFF8C6E36),
    Color(0xFF453418),
  ];

  static const List<Color> _silverRelief = [
    Color(0xFF9AA5B6),
    Color(0xFF667387),
    Color(0xFF333B4A),
  ];

  static const List<Color> _bronzeRelief = [
    Color(0xFFB89468),
    Color(0xFF7B5935),
    Color(0xFF3D2917),
  ];

  static const List<_FloatingImperialPiece> _pieces = [
    _FloatingImperialPiece(
      piece: _StauntonPiece.knight,
      startX: 0.14,
      startY: 0.18,
      sizeFactor: 0.19,
      speedCycles: 1.0,
      swayAmplitude: 0.032,
      phase: 0.0,
      baseAngle: -0.14,
      metallicStops: _goldRelief,
      opacity: 0.11,
    ),
    _FloatingImperialPiece(
      piece: _StauntonPiece.queen,
      startX: 0.85,
      startY: 0.12,
      sizeFactor: 0.20,
      speedCycles: 1.0,
      swayAmplitude: 0.028,
      phase: 1.3,
      baseAngle: 0.12,
      metallicStops: _silverRelief,
      opacity: 0.09,
    ),
    _FloatingImperialPiece(
      piece: _StauntonPiece.rook,
      startX: 0.50,
      startY: 0.36,
      sizeFactor: 0.14,
      speedCycles: 1.0,
      swayAmplitude: 0.024,
      phase: 2.5,
      baseAngle: 0.08,
      metallicStops: _bronzeRelief,
      opacity: 0.09,
    ),
    _FloatingImperialPiece(
      piece: _StauntonPiece.bishop,
      startX: 0.18,
      startY: 0.58,
      sizeFactor: 0.16,
      speedCycles: 1.0,
      swayAmplitude: 0.030,
      phase: 3.4,
      baseAngle: -0.10,
      metallicStops: _silverRelief,
      opacity: 0.085,
    ),
    _FloatingImperialPiece(
      piece: _StauntonPiece.king,
      startX: 0.84,
      startY: 0.56,
      sizeFactor: 0.21,
      speedCycles: 1.0,
      swayAmplitude: 0.026,
      phase: 4.5,
      baseAngle: 0.09,
      metallicStops: _goldRelief,
      opacity: 0.11,
    ),
    _FloatingImperialPiece(
      piece: _StauntonPiece.pawn,
      startX: 0.36,
      startY: 0.80,
      sizeFactor: 0.13,
      speedCycles: 2.0,
      swayAmplitude: 0.022,
      phase: 0.8,
      baseAngle: -0.08,
      metallicStops: _bronzeRelief,
      opacity: 0.09,
    ),
    _FloatingImperialPiece(
      piece: _StauntonPiece.knight,
      startX: 0.72,
      startY: 0.88,
      sizeFactor: 0.17,
      speedCycles: 1.0,
      swayAmplitude: 0.028,
      phase: 2.1,
      baseAngle: 0.15,
      metallicStops: _silverRelief,
      opacity: 0.09,
    ),
    _FloatingImperialPiece(
      piece: _StauntonPiece.rook,
      startX: 0.10,
      startY: 0.94,
      sizeFactor: 0.15,
      speedCycles: 1.0,
      swayAmplitude: 0.025,
      phase: 5.2,
      baseAngle: -0.11,
      metallicStops: _goldRelief,
      opacity: 0.10,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Uses detailed White Staunton vectors so `BlendMode.modulate` turns the
  /// piece body into sculpted antique metal while preserving all dark engraved
  /// interior linework (mane, crown, collar, base rings).
  Widget _buildEngravedStauntonVector(_StauntonPiece piece, double size) {
    switch (piece) {
      case _StauntonPiece.king:
        return WhiteKing(size: size);
      case _StauntonPiece.queen:
        return WhiteQueen(size: size);
      case _StauntonPiece.rook:
        return WhiteRook(size: size);
      case _StauntonPiece.bishop:
        return WhiteBishop(size: size);
      case _StauntonPiece.knight:
        return WhiteKnight(size: size);
      case _StauntonPiece.pawn:
        return WhitePawn(size: size);
    }
  }

  Widget _buildCarvedReliefPiece(_FloatingImperialPiece spec, double pieceSize) {
    final List<Color> tintedStops = spec.metallicStops
        .map((c) => Color.lerp(c, widget.accentColor, 0.12) ?? c)
        .toList(growable: false);

    final Widget detailedVector = _buildEngravedStauntonVector(
      spec.piece,
      pieceSize,
    );

    return Opacity(
      opacity: spec.opacity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle recessed stone drop-shadow for physical bas-relief depth
          Transform.translate(
            offset: const Offset(2.0, 3.0),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.70),
                BlendMode.srcIn,
              ),
              child: detailedVector,
            ),
          ),
          // Sculpted metallic gradient modulated onto the engraved Staunton piece
          ShaderMask(
            blendMode: BlendMode.modulate,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tintedStops,
              stops: const [0.0, 0.52, 1.0],
            ).createShader(bounds),
            child: detailedVector,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final shortestSide = math.min(width, height);

              if (width <= 0 || height <= 0) {
                return const SizedBox.shrink();
              }

              // Pre-build sculpted relief pieces once per layout/theme change
              final List<Widget> pieceWidgets = _pieces
                  .map((spec) =>
                      _buildCarvedReliefPiece(spec, shortestSide * spec.sizeFactor))
                  .toList(growable: false);

              // Seamless engraved Ottoman-Roman-Chess relief tile
              final Widget engravedTile = Opacity(
                opacity: 0.25,
                child: Image.asset(
                  'assets/button_texture.jpg',
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  color: Color.lerp(
                    const Color(0xFFA89268),
                    widget.accentColor,
                    0.22,
                  ),
                  colorBlendMode: BlendMode.modulate,
                ),
              );

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final double p = _controller.value;
                  const double twoPi = math.pi * 2.0;
                  final double t = p * twoPi;

                  // Slow, continuous upward scroll of the engraved relief tapestry
                  final double bgOffsetY = -(p * height);
                  // Soft diagonal antique-gold ambient light drift
                  final double sheenX = math.sin(t) * 0.65;
                  final double sheenY = -0.35 + math.cos(t) * 0.30;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Slowly panning engraved Ottoman-Roman-Chess bas-relief
                      Positioned(
                        left: 0,
                        top: bgOffsetY,
                        width: width,
                        height: height,
                        child: engravedTile,
                      ),
                      Positioned(
                        left: 0,
                        top: bgOffsetY + height,
                        width: width,
                        height: height,
                        child: engravedTile,
                      ),

                      // 2. Sculpted metallic Staunton reliefs EMBEDDED beneath vignette & lighting
                      for (int i = 0; i < _pieces.length; i++)
                        Builder(
                          builder: (context) {
                            final spec = _pieces[i];
                            final pieceSize = shortestSide * spec.sizeFactor;
                            final travelHeight = height + pieceSize * 2.0;

                            // Continuous seamless upward float
                            final normalizedY =
                                (spec.startY - (p * spec.speedCycles)) % 1.0;
                            final top =
                                (normalizedY * travelHeight) - pieceSize;

                            // Gentle horizontal sway
                            final sway = math.sin(t + spec.phase) *
                                (width * spec.swayAmplitude);
                            final left =
                                (spec.startX * width) - (pieceSize / 2) + sway;

                            final angle = spec.baseAngle +
                                math.cos(t + spec.phase) * 0.07;

                            return Positioned(
                              left: left,
                              top: top,
                              child: Transform.rotate(
                                angle: angle,
                                child: pieceWidgets[i],
                              ),
                            );
                          },
                        ),

                      // 3. Soft dark obsidian vignette blending tapestry + pieces into the background
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.08,
                            colors: [
                              Color(0x440B0F19),
                              Color(0xB30B0F19),
                            ],
                          ),
                        ),
                      ),

                      // 4. Subtle moving antique-gold gallery light sheen illuminating both layers
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(sheenX, sheenY),
                            radius: 0.95,
                            colors: [
                              _antiqueGold.withValues(alpha: 0.075),
                              widget.accentColor.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
