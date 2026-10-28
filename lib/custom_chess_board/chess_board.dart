import 'dart:math';

import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_engine;
import 'board_arrow.dart';
import 'chess_board_controller.dart';
import 'constants.dart';

class ChessBoard extends StatefulWidget {
  /// An instance of [ChessBoardController] which holds the game and allows
  /// manipulating the board programmatically.
  final ChessBoardController controller;

  /// Size of chessboard
  final double? size;

  /// A boolean which checks if the user should be allowed to make moves
  final bool enableUserMoves;

  /// The color type of the board
  final BoardColor boardColor;

  final PlayerColor boardOrientation;

  final VoidCallback? onMove;
  
  /// Callback before a move is applied. Return false to reject the move.
  final bool Function(String from, String to, String? promotion)? onMoveAttempt;
  
  /// Annotations to draw on specific squares (e.g. {'e4': '!!', 'd5': '?'})
  final Map<String, String>? annotations;
  
  /// Light square color
  final Color lightSquareColor;
  
  /// Dark square color
  final Color darkSquareColor;

  final List<BoardArrow> arrows;

  const ChessBoard({
    super.key,
    required this.controller,
    this.size,
    this.enableUserMoves = true,
    this.boardColor = BoardColor.brown,
    this.boardOrientation = PlayerColor.white,
    this.onMove,
    this.onMoveAttempt,
    this.annotations,
    this.lightSquareColor = const Color(0xFFEEEED2),
    this.darkSquareColor = const Color(0xFF769656),
    this.arrows = const [],
  });

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}


class _PieceData {
  final String id;
  final String pieceStr;
  String square;
  _PieceData(this.id, this.pieceStr, this.square);
}

class _ChessBoardState extends State<ChessBoard> {
  List<_PieceData> _pieces = [];
  String _lastFen = '';
  String? _draggingSquare;

  @override
  void initState() {
    super.initState();
    _updatePieces(widget.controller.value);
    widget.controller.addListener(_onGameChanged);
  }

  @override
  void didUpdateWidget(ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onGameChanged);
      widget.controller.addListener(_onGameChanged);
      _lastFen = '';
      _updatePieces(widget.controller.value);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onGameChanged);
    super.dispose();
  }

  void _onGameChanged() {
    _updatePieces(widget.controller.value);
  }

  void _updatePieces(chess_engine.Chess game) {
    if (game.fen == _lastFen) return;
    _lastFen = game.fen;

    List<_PieceData> newPieces = [];
    List<_PieceData> oldPieces = List.from(_pieces);
    
    List<Map<String, dynamic>> boardState = [];
    for (int i = 0; i < 64; i++) {
      var column = i % 8;
      var row = i ~/ 8;
      var sq = files[column] + (8 - row).toString();
      var p = game.get(sq);
      if (p != null) {
        String pStr = (p.color == chess_engine.Color.WHITE ? 'W' : 'B') + p.type.toUpperCase();
        boardState.add({'sq': sq, 'pStr': pStr});
      }
    }

    // 1. Adım: Hareketsiz taşları (yerinde duranları) kendi ID'leriyle eşleştir
    for (var b in boardState) {
      String sq = b['sq'];
      String pStr = b['pStr'];
      int matchIdx = oldPieces.indexWhere((o) => o.pieceStr == pStr && o.square == sq);
      if (matchIdx != -1) {
        var matched = oldPieces.removeAt(matchIdx);
        newPieces.add(_PieceData(matched.id, matched.pieceStr, matched.square));
        b['matched'] = true;
      } else {
        b['matched'] = false;
      }
    }

    // 2. Adım: Kalanları (hareket eden veya yeni çıkan taşları) eşleştir
    for (var b in boardState) {
      if (b['matched'] == true) continue;
      String sq = b['sq'];
      String pStr = b['pStr'];
      
      int matchIdx = oldPieces.indexWhere((o) => o.pieceStr == pStr);
      if (matchIdx != -1) {
        var matched = oldPieces.removeAt(matchIdx);
        newPieces.add(_PieceData(matched.id, matched.pieceStr, sq));
      } else {
        newPieces.add(_PieceData(UniqueKey().toString(), pStr, sq));
      }
    }

    if (mounted) {
      setState(() {
        _pieces = newPieces;
      });
    }
  }

  double _getLeft(String square, double squareSize) {
    int fileIdx = files.indexOf(square[0]);
    if (widget.boardOrientation == PlayerColor.black) fileIdx = 7 - fileIdx;
    return fileIdx * squareSize;
  }

  double _getTop(String square, double squareSize) {
    int rankIdx = 8 - int.parse(square[1]);
    if (widget.boardOrientation == PlayerColor.black) rankIdx = 7 - rankIdx;
    return rankIdx * squareSize;
  }

  @override
  Widget build(BuildContext context) {
    Color lightColor;
    Color darkColor;

    switch (BoardThemeService.boardColor) {
      case BoardColor.brown:
        lightColor = const Color(0xFFF0D9B5);
        darkColor = const Color(0xFFB58863);
        break;
      case BoardColor.blue:
        lightColor = const Color(0xFFD6DFDF);
        darkColor = const Color(0xFF5C7E9A);
        break;
      case BoardColor.grey:
        lightColor = const Color(0xFFB3B3B3);
        darkColor = const Color(0xFF737373);
        break;
      case BoardColor.green:
        lightColor = const Color(0xFFEEEED2);
        darkColor = const Color(0xFF769656);
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double boardSize = widget.size ?? constraints.maxWidth;
        if (boardSize == double.infinity) boardSize = MediaQuery.of(context).size.width;
        double squareSize = boardSize / 8;

        return ValueListenableBuilder<chess_engine.Chess>(
          valueListenable: widget.controller,
          builder: (context, game, _) {
            return SizedBox(
              width: boardSize,
              height: boardSize,
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                        itemBuilder: (context, index) {
                          var row = index ~/ 8;
                          var column = index % 8;
                          var boardRank = widget.boardOrientation == PlayerColor.black ? '${row + 1}' : '${(7 - row) + 1}';
                          var boardFile = widget.boardOrientation == PlayerColor.white ? files[column] : files[7 - column];
                          var squareName = '$boardFile$boardRank';
                          var pieceOnSquare = game.get(squareName);

                          bool isLightSquare = (row + column) % 2 == 0;
                          Color squareColor = isLightSquare ? lightColor : darkColor;
                          Color textColor = isLightSquare ? darkColor : lightColor;

                          var pieceW = BoardPiece(squareName: squareName, game: game);

                          var draggable = pieceOnSquare != null
                              ? Draggable<PieceMoveData>(
                                  feedback: pieceW,
                                  childWhenDragging: const SizedBox(),
                                  data: PieceMoveData(
                                    squareName: squareName,
                                    pieceType: pieceOnSquare.type.toUpperCase(),
                                    pieceColor: pieceOnSquare.color,
                                  ),
                                  onDragStarted: () => setState(() => _draggingSquare = squareName),
                                  onDragEnd: (_) => setState(() => _draggingSquare = null),
                                  onDraggableCanceled: (_, __) => setState(() => _draggingSquare = null),
                                  onDragCompleted: () => setState(() => _draggingSquare = null),
                                  child: Opacity(opacity: 0, child: pieceW),
                                )
                              : Container();

                          Widget squareContent = Stack(
                            children: [
                              if (column == 0)
                                Positioned(
                                  top: 2, left: 2,
                                  child: Text(boardRank, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              if (row == 7)
                                Positioned(
                                  bottom: 2, right: 2,
                                  child: Text(boardFile, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              Center(child: draggable),
                            ],
                          );

                          return DragTarget<PieceMoveData>(
                            builder: (context, list, _) => Container(color: squareColor, child: squareContent),
                            onWillAcceptWithDetails: (details) => widget.enableUserMoves,
                            onAcceptWithDetails: (details) async {
                              PieceMoveData pieceMoveData = details.data;
                              chess_engine.Color moveColor = game.turn;

                              if (pieceMoveData.pieceType == "P" &&
                                  ((pieceMoveData.squareName[1] == "7" && squareName[1] == "8" && pieceMoveData.pieceColor == chess_engine.Color.WHITE) ||
                                      (pieceMoveData.squareName[1] == "2" && squareName[1] == "1" && pieceMoveData.pieceColor == chess_engine.Color.BLACK))) {
                                var val = await _promotionDialog(context);
                                if (val != null) {
                                  if (widget.onMoveAttempt != null) {
                                    if (!widget.onMoveAttempt!(pieceMoveData.squareName, squareName, val)) return;
                                  }
                                  widget.controller.makeMoveWithPromotion(from: pieceMoveData.squareName, to: squareName, pieceToPromoteTo: val);
                                } else {
                                  return;
                                }
                              } else {
                                if (widget.onMoveAttempt != null) {
                                  if (!widget.onMoveAttempt!(pieceMoveData.squareName, squareName, null)) return;
                                }
                                widget.controller.makeMove(from: pieceMoveData.squareName, to: squareName);
                              }
                              if (game.turn != moveColor) {
                                widget.onMove?.call();
                              }
                            },
                          );
                        },
                        itemCount: 64,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                    ),
                  ),

                  IgnorePointer(
                    child: Stack(
                      children: _pieces.map((p) {
                        return AnimatedPositioned(
                          key: ValueKey(p.id),
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          left: _getLeft(p.square, squareSize),
                          top: _getTop(p.square, squareSize),
                          width: squareSize,
                          height: squareSize,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 50),
                            opacity: _draggingSquare == p.square ? 0.0 : 1.0,
                            child: BoardPiece(squareName: p.square, game: game),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  IgnorePointer(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        margin: const EdgeInsets.all(5.0),
                        child: GridView.builder(
                          clipBehavior: Clip.none,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                          itemCount: 64,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            var row = index ~/ 8;
                            var column = index % 8;
                            var boardRank = widget.boardOrientation == PlayerColor.black ? '${row + 1}' : '${(7 - row) + 1}';
                            var boardFile = widget.boardOrientation == PlayerColor.white ? files[column] : files[7 - column];
                            var squareName = '$boardFile$boardRank';
                            
                            if (widget.annotations != null && widget.annotations!.containsKey(squareName)) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: Transform.translate(
                                  offset: const Offset(8, -8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
                                    ),
                                    child: Text(
                                      widget.annotations![squareName]!,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                  ),

                  IgnorePointer(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: CustomPaint(
                        painter: _ArrowPainter(widget.arrows, widget.boardOrientation),
                        child: Container(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
Future<String?> _promotionDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: WhiteQueen(),
                onTap: () {
                  Navigator.of(context).pop("q");
                },
              ),
              InkWell(
                child: WhiteRook(),
                onTap: () {
                  Navigator.of(context).pop("r");
                },
              ),
              InkWell(
                child: WhiteBishop(),
                onTap: () {
                  Navigator.of(context).pop("b");
                },
              ),
              InkWell(
                child: WhiteKnight(),
                onTap: () {
                  Navigator.of(context).pop("n");
                },
              ),
            ],
          ),
        );
      },
    ).then((value) {
      return value;
    });
  }
}

class BoardPiece extends StatelessWidget {
  final String squareName;
  final chess_engine.Chess game;

  const BoardPiece({
    super.key,
    required this.squareName,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    late Widget imageToDisplay;
    var square = game.get(squareName);

    if (game.get(squareName) == null) {
      return Container();
    }

    String piece = (square?.color == chess_engine.Color.WHITE ? 'W' : 'B') +
        (square?.type.toUpperCase() ?? 'P');

    switch (piece) {
      case "WP":
        imageToDisplay = WhitePawn();
        break;
      case "WR":
        imageToDisplay = WhiteRook();
        break;
      case "WN":
        imageToDisplay = WhiteKnight();
        break;
      case "WB":
        imageToDisplay = WhiteBishop();
        break;
      case "WQ":
        imageToDisplay = WhiteQueen();
        break;
      case "WK":
        imageToDisplay = WhiteKing();
        break;
      case "BP":
        imageToDisplay = BlackPawn();
        break;
      case "BR":
        imageToDisplay = BlackRook();
        break;
      case "BN":
        imageToDisplay = BlackKnight();
        break;
      case "BB":
        imageToDisplay = BlackBishop();
        break;
      case "BQ":
        imageToDisplay = BlackQueen();
        break;
      case "BK":
        imageToDisplay = BlackKing();
        break;
      default:
        imageToDisplay = WhitePawn();
    }

    return imageToDisplay;
  }
}

class PieceMoveData {
  final String squareName;
  final String pieceType;
  final chess_engine.Color pieceColor;

  PieceMoveData({
    required this.squareName,
    required this.pieceType,
    required this.pieceColor,
  });
}

class _ArrowPainter extends CustomPainter {
  List<BoardArrow> arrows;
  PlayerColor boardOrientation;

  _ArrowPainter(this.arrows, this.boardOrientation);

  @override
  void paint(Canvas canvas, Size size) {
    var blockSize = size.width / 8;
    var halfBlockSize = size.width / 16;

    for (var arrow in arrows) {
      var startFile = files.indexOf(arrow.from[0]);
      var startRank = int.parse(arrow.from[1]) - 1;
      var endFile = files.indexOf(arrow.to[0]);
      var endRank = int.parse(arrow.to[1]) - 1;

      int effectiveRowStart = 0;
      int effectiveColumnStart = 0;
      int effectiveRowEnd = 0;
      int effectiveColumnEnd = 0;

      if (boardOrientation == PlayerColor.black) {
        effectiveColumnStart = 7 - startFile;
        effectiveColumnEnd = 7 - endFile;
        effectiveRowStart = startRank;
        effectiveRowEnd = endRank;
      } else {
        effectiveColumnStart = startFile;
        effectiveColumnEnd = endFile;
        effectiveRowStart = 7 - startRank;
        effectiveRowEnd = 7 - endRank;
      }

      var startOffset = Offset(
          ((effectiveColumnStart + 1) * blockSize) - halfBlockSize,
          ((effectiveRowStart + 1) * blockSize) - halfBlockSize);
      var endOffset = Offset(
          ((effectiveColumnEnd + 1) * blockSize) - halfBlockSize,
          ((effectiveRowEnd + 1) * blockSize) - halfBlockSize);

      var yDist = 0.8 * (endOffset.dy - startOffset.dy);
      var xDist = 0.8 * (endOffset.dx - startOffset.dx);

      var paint = Paint()
        ..strokeWidth = halfBlockSize * 0.8
        ..color = arrow.color;

      canvas.drawLine(startOffset,
          Offset(startOffset.dx + xDist, startOffset.dy + yDist), paint);

      var slope =
          (endOffset.dy - startOffset.dy) / (endOffset.dx - startOffset.dx);

      var newLineSlope = -1 / slope;

      var points = _getNewPoints(
          Offset(startOffset.dx + xDist, startOffset.dy + yDist),
          newLineSlope,
          halfBlockSize);
      var newPoint1 = points[0];
      var newPoint2 = points[1];

      var path = Path();

      path.moveTo(endOffset.dx, endOffset.dy);
      path.lineTo(newPoint1.dx, newPoint1.dy);
      path.lineTo(newPoint2.dx, newPoint2.dy);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  List<Offset> _getNewPoints(Offset start, double slope, double length) {
    if (slope == double.infinity || slope == double.negativeInfinity) {
      return [
        Offset(start.dx, start.dy + length),
        Offset(start.dx, start.dy - length)
      ];
    }

    return [
      Offset(start.dx + (length / sqrt(1 + (slope * slope))),
          start.dy + ((length * slope) / sqrt(1 + (slope * slope)))),
      Offset(start.dx - (length / sqrt(1 + (slope * slope))),
          start.dy - ((length * slope) / sqrt(1 + (slope * slope)))),
    ];
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) {
    return arrows != oldDelegate.arrows;
  }
}
