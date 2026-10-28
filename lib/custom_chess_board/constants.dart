import 'package:shared_preferences/shared_preferences.dart';

const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

/// Enum which stores board types
enum BoardColor {
  green,
  brown,
  blue,
  grey,
}

enum PlayerColor {
  white,
  black,
}

enum BoardPieceType { pawn, rook, knight, bishop, queen, king }

RegExp squareRegex = RegExp("^[A-H|a-h][1-8]\$");

class BoardThemeService {
  static BoardColor _boardColor = BoardColor.green;

  static BoardColor get boardColor => _boardColor;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    int colorIndex = prefs.getInt('board_color') ?? 0;
    if (colorIndex >= 0 && colorIndex < BoardColor.values.length) {
      _boardColor = BoardColor.values[colorIndex];
    } else {
      _boardColor = BoardColor.green;
    }
  }

  static Future<void> setBoardColor(BoardColor color) async {
    _boardColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('board_color', color.index);
  }
}
