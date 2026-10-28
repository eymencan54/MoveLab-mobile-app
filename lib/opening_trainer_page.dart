import 'package:flutter/material.dart';
import 'custom_chess_board/custom_chess_board.dart';
import 'package:chess/chess.dart' as chess_engine;
import 'main.dart';
import 'opening_database.dart';

/// Açılış Antrenmanı Veri Modeli
class OpeningRepertoire {
  final String id;
  final String eco;
  final String titleTr;
  final String titleEn;
  final String categoryTr;
  final String categoryEn;
  final String descTr;
  final String descEn;
  final bool isWhite; // True: Beyaz açılışı (e.g. Italian), False: Siyah savunması (e.g. Sicilian)
  final List<String> moves; // UCI hamle listesi, örn: ['e2e4', 'e7e5', ...]

  const OpeningRepertoire({
    required this.id,
    required this.eco,
    required this.titleTr,
    required this.titleEn,
    required this.categoryTr,
    required this.categoryEn,
    required this.descTr,
    required this.descEn,
    required this.isWhite,
    required this.moves,
  });

  String get title => LanguageService.currentLang == 'en' ? titleEn : titleTr;
  String get category => LanguageService.currentLang == 'en' ? categoryEn : categoryTr;
  String get desc => LanguageService.currentLang == 'en' ? descEn : descTr;
}



enum TrainingMode {
  guided,   // Rehberli Pratik & Öğrenme
  quiz,     // Hafıza & Test Modu
  explorer, // Serbest Keşif & Lichess Ağacı
}

class OpeningTrainerPage extends StatefulWidget {
  const OpeningTrainerPage({super.key});

  @override
  State<OpeningTrainerPage> createState() => _OpeningTrainerPageState();
}

class _OpeningTrainerPageState extends State<OpeningTrainerPage> {
  late ChessBoardController controller;
  final chess_engine.Chess _engineChess = chess_engine.Chess();

  int _selectedRepertoireIndex = 0;
  TrainingMode _mode = TrainingMode.guided;
  PlayerColor _boardOrientation = PlayerColor.white;

  int _currentMoveIndex = 0;
  int _mistakes = 0;
  bool _isCompleted = false;
  bool _showQuizHint = false;
  String? _feedbackMsg;
  Color _feedbackColor = Colors.greenAccent;

  // Dokunmatik Oynama (Tap-to-move)
  String? selectedSquare;
  List<String> legalDestinations = [];

  // Live Explorer State
  String _liveOpeningName = '';
  double _evaluationValue = 0.0;
  String _evaluationText = "0.0";
  List<String> _topEngineMoves = [];
  
  List<String> _explorerFens = [];
  List<String> _explorerMoves = [];
  int _explorerIndex = 0;

  OpeningRepertoire get currentRepertoire => kOpeningLibrary[_selectedRepertoireIndex];

  @override
  void initState() {
    super.initState();
    ChessEngineService().initEngine();
    controller = ChessBoardController();
    
    // Default to Italian Game or Sicilian if available
    final defaultIndex = kOpeningLibrary.indexWhere((r) => r.id.startsWith('c50') || r.eco == 'C50' || r.eco == 'B90');
    if (defaultIndex != -1) {
      _selectedRepertoireIndex = defaultIndex;
    }
    
    _initRepertoire();
  }

  @override
  void dispose() {
    ChessEngineService().stopContinuousAnalysis();
    super.dispose();
  }

  void _updateLiveExplorerData(String fen) async {
    if (_mode != TrainingMode.explorer) return;
    
    // Anında açılış ismini kendi devasa veritabanımızdan bul
    final fenParts = fen.split(' ');
    if (fenParts.length >= 3) {
      final fenKey = "${fenParts[0]} ${fenParts[1]} ${fenParts[2]}";
      if (kLocalOpeningsDatabase.containsKey(fenKey)) {
        setState(() {
          _liveOpeningName = kLocalOpeningsDatabase[fenKey]!;
        });
      }
    }

    // Lichess alt ağacı için HTTP isteğini arkaplanda atıyoruz, UI beklemeyecek
    OpeningExplorerService.fetchOpening(fen);

    // Bilgisayar Analizi
    ChessEngineService().startContinuousAnalysis(fen, (updateData) {
      if (!mounted || _mode != TrainingMode.explorer) return;
      double rawEval = updateData['best_eval'] ?? 0.0;
      bool isMate = updateData['is_mate'] ?? false;
      String evalTxt = isMate || rawEval.abs() > 14.0 
          ? (rawEval > 0 ? '+M' : '-M') 
          : (rawEval > 0 ? '+${rawEval.toStringAsFixed(1)}' : rawEval.toStringAsFixed(1));
      
      List<String> suggs = List<String>.from(updateData['suggestions'] ?? ['', '', '', '', '']);
      final temp = chess_engine.Chess();
      temp.load(fen);
      final verboseMoves = temp.moves({'verbose': true});

      List<String> sanSuggs = [];
      for (var uci in suggs.take(3).where((m) => m.isNotEmpty && m != '-')) {
        if (uci.length >= 4) {
          String from = uci.substring(0, 2);
          String to = uci.substring(2, 4);
          String? promotion = uci.length > 4 ? uci.substring(4, 5) : null;
          
          final moveMap = verboseMoves.firstWhere(
              (m) => (m as Map)['from'] == from && m['to'] == to && (promotion == null || m['promotion'] == promotion),
              orElse: () => null) as Map?;
          sanSuggs.add(moveMap != null ? moveMap['san'] : uci);
        } else {
          sanSuggs.add(uci);
        }
      }

      setState(() {
        _evaluationValue = rawEval;
        _evaluationText = evalTxt;
        _topEngineMoves = sanSuggs;
      });
    });
  }

  void _initRepertoire() {
    controller.resetBoard();
    _engineChess.reset();
    _currentMoveIndex = 0;
    _mistakes = 0;
    _isCompleted = false;
    _showQuizHint = false;
    _feedbackMsg = null;
    selectedSquare = null;
    legalDestinations.clear();

    _explorerFens = [controller.game.fen];
    _explorerMoves = [];
    _explorerIndex = 0;

    // Tahta yönünü ayarla
    _boardOrientation = currentRepertoire.isWhite ? PlayerColor.white : PlayerColor.black;

    // Eğer siyah açılışıysa ve ilk hamle beyazınsa (indeks 0), uygulama otomatik yapsın
    if (!currentRepertoire.isWhite && _currentMoveIndex == 0 && _mode != TrainingMode.explorer) {
      _scheduleOpponentMove();
    }
  }

  void _scheduleOpponentMove() {
    if (_currentMoveIndex >= currentRepertoire.moves.length) {
      _finishTraining();
      return;
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _mode == TrainingMode.explorer) return;
      final expectedUci = currentRepertoire.moves[_currentMoveIndex];
      _playUciOnBoard(expectedUci);
      _currentMoveIndex++;
      SoundService.playMoveSound(false);
      setState(() {});

      if (_currentMoveIndex >= currentRepertoire.moves.length) {
        _finishTraining();
      }
    });
  }

  void _playUciOnBoard(String uci) {
    if (uci.length < 4) return;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    if (uci.length > 4) {
      controller.makeMoveWithPromotion(from: from, to: to, pieceToPromoteTo: uci.substring(4, 5));
      _engineChess.move({"from": from, "to": to, "promotion": uci.substring(4, 5)});
    } else {
      controller.makeMove(from: from, to: to);
      _engineChess.move({"from": from, "to": to});
    }
  }

  void _finishTraining() {
    setState(() {
      _isCompleted = true;
      _feedbackMsg = LanguageService.currentLang == 'en'
          ? "🎉 Congratulations! You completed the repertoire!"
          : "🎉 Tebrikler! Bu açılış varyantını başarıyla tamamladınız!";
      _feedbackColor = Colors.amberAccent;
    });
    _showCelebrationDialog();
  }

  void _showCelebrationDialog() {
    final isEn = LanguageService.currentLang == 'en';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.amberAccent)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 28),
            const SizedBox(width: 8),
            Text(isEn ? "Repertoire Mastered!" : "Açılıfta Ustalaştın!", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          isEn
              ? "You successfully practiced '${currentRepertoire.titleEn}' with $_mistakes mistake(s)."
              : "'${currentRepertoire.titleTr}' varyantını $_mistakes hata ile başarıyla tamamladın.",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _initRepertoire());
            },
            child: Text(isEn ? "Practice Again" : "Tekrar Pratik Yap", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? "Close" : "Kapat", style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _goToExplorerMove(int index) {
    if (index < 0 || index >= _explorerFens.length) return;
    
    if (index > 0 && index - 1 < _explorerMoves.length) {
      bool isCapture = _explorerMoves[index - 1].contains('x');
      SoundService.playMoveSound(isCapture);
    } else if (index == 0) {
      SoundService.playMoveSound(false);
    }

    setState(() {
      _explorerIndex = index;
      _engineChess.load(_explorerFens[index]);
      controller.game.load(_explorerFens[index]); // Use game.load directly if loadFen isn't used
      // Safest way to sync board:
      controller.resetBoard();
      controller.game.load(_explorerFens[index]);
      selectedSquare = null;
      legalDestinations.clear();
    });
    _updateLiveExplorerData(_explorerFens[index]);
  }

  bool _onMoveAttempt(String from, String to, String? promotion) {
    if (_mode == TrainingMode.explorer || _isCompleted) return true;
    if (_currentMoveIndex >= currentRepertoire.moves.length) return false;

    final expectedUci = currentRepertoire.moves[_currentMoveIndex];
    final attemptedUci = from + to + (promotion ?? '');

    if (attemptedUci == expectedUci) {
      return true;
    } else {
      SoundService.playMoveSound(true);
      _mistakes++;
      final expectedSan = _getExpectedSan();
      setState(() {
        _feedbackMsg = LanguageService.currentLang == 'en'
            ? "❌ Incorrect move! Expected: $expectedSan"
            : "❌ Yanlış hamle! Doğrusu: $expectedSan";
        _feedbackColor = Colors.redAccent;
        
        selectedSquare = null;
        legalDestinations.clear();
      });
      return false; // HAMLEYİ REDDET!
    }
  }

  // Hamle yapıldığında doğrulama (Guided veya Quiz modu)
  void _onMove() {
    if (selectedSquare != null) {
      setState(() {
        selectedSquare = null;
        legalDestinations.clear();
      });
    }

    if (_mode == TrainingMode.explorer) {
      _engineChess.load(controller.game.fen);
      
      if (_explorerIndex < _explorerFens.length - 1) {
        _explorerFens = _explorerFens.sublist(0, _explorerIndex + 1);
        _explorerMoves = _explorerMoves.sublist(0, _explorerIndex);
      }
      
      var sans = controller.getSan();
      String lastMove = '?';
      if (sans.isNotEmpty && sans.last != null) {
        String lastPair = sans.last!.trim();
        List<String> parts = lastPair.split(RegExp(r'\s+'));
        lastMove = parts.last;
      }
      
      _explorerMoves.add(lastMove);
      _explorerFens.add(controller.game.fen);
      _explorerIndex++;

      SoundService.playMoveSound(lastMove.contains('x'));

      setState(() {});
      _updateLiveExplorerData(_engineChess.fen);
      return;
    }
    if (_isCompleted) return;

    if (_currentMoveIndex >= currentRepertoire.moves.length) {
      _finishTraining();
      return;
    }

    // Doğru hamle yapılmış demektir (çünkü yanlışsa onMoveAttempt reddetti)
    final expectedUci = currentRepertoire.moves[_currentMoveIndex];
    final tempValidation = chess_engine.Chess();
    tempValidation.load(_engineChess.fen);
    final from = expectedUci.substring(0, 2);
    final to = expectedUci.substring(2, 4);
    final moveObj = <String, dynamic>{"from": from, "to": to};
    if (expectedUci.length > 4) moveObj["promotion"] = expectedUci.substring(4, 5);
    tempValidation.move(moveObj);

    SoundService.playMoveSound(false);
    _engineChess.load(tempValidation.fen);
    _currentMoveIndex++;
    _feedbackMsg = LanguageService.currentLang == 'en' ? "✨ Excellent move!" : "✨ Harika hamle!";
    _feedbackColor = Colors.greenAccent;
    _showQuizHint = false;
    setState(() {});

    if (_currentMoveIndex >= currentRepertoire.moves.length) {
      _finishTraining();
    } else {
      _scheduleOpponentMove();
    }
  }

  // Lichess Ağacından hamleye tıklandığında (Serbest keşif veya antrenmanda)
  void _onExplorerMoveTap(String uci) {
    if (uci.length < 4) return;
    
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    String? promotionStr;
    if (uci.length > 4) promotionStr = uci.substring(4, 5);

    // Eğer rehberli veya quiz modundaysak, bu hamleyi ana varyant ile doğrulayalım!
    if (_mode != TrainingMode.explorer && !_isCompleted) {
       // Sadece kullanıcının sırasında kendi taşına tıklamasına izin ver
       final piece = controller.game.get(from);
       if (piece != null) {
          final isWhitePiece = piece.color == chess_engine.Color.WHITE;
          if (isWhitePiece != (_engineChess.turn == chess_engine.Color.WHITE)) return;
       }
       
       if (!_onMoveAttempt(from, to, promotionStr)) {
          return; // Yanlış hamle, reddet!
       }
    }

    if (promotionStr != null) {
      controller.makeMoveWithPromotion(from: from, to: to, pieceToPromoteTo: promotionStr);
      _engineChess.move({"from": from, "to": to, "promotion": promotionStr});
    } else {
      controller.makeMove(from: from, to: to);
      _engineChess.move({"from": from, "to": to});
    }
    
    SoundService.playMoveSound(false);

    if (_mode != TrainingMode.explorer && !_isCompleted) {
       _onMove();
    } else {
       setState(() {});
       if (_mode == TrainingMode.explorer) _updateLiveExplorerData(_engineChess.fen);
    }
  }

  String _indexToSquare(int index, bool isWhiteBottom) {
    int rank, file;
    if (isWhiteBottom) {
      rank = 7 - (index ~/ 8);
      file = index % 8;
    } else {
      rank = index ~/ 8;
      file = 7 - (index % 8);
    }
    final fileChar = String.fromCharCode('a'.codeUnitAt(0) + file);
    final rankChar = (rank + 1).toString();
    return '$fileChar$rankChar';
  }

  void _onSquareTapped(String square) {
    if (_mode != TrainingMode.explorer && _isCompleted) return;

    if (selectedSquare == null) {
      final piece = controller.game.get(square);
      if (piece == null) return;
      final isWhitePiece = piece.color == chess_engine.Color.WHITE;
      if (isWhitePiece != (_engineChess.turn == chess_engine.Color.WHITE)) return;

      final moves = controller.game.moves({'square': square, 'verbose': true});
      if (moves.isEmpty) return;

      setState(() {
        selectedSquare = square;
        legalDestinations = moves.map((m) => (m as Map)['to'] as String).toList();
      });
    } else {
      if (selectedSquare == square) {
        setState(() {
          selectedSquare = null;
          legalDestinations.clear();
        });
      } else if (legalDestinations.contains(square)) {
        final from = selectedSquare!;
        final to = square;
        setState(() {
          selectedSquare = null;
          legalDestinations.clear();
        });
        // Hamleyi yap
        final moves = controller.game.moves({'square': from, 'verbose': true});
        final moveMap = moves.firstWhere((m) => (m as Map)['to'] == to, orElse: () => null) as Map?;
        String? promotionStr;
        if (moveMap != null && moveMap.containsKey('promotion') && moveMap['promotion'] != null) {
          promotionStr = 'q';
        }
        
        if (!_onMoveAttempt(from, to, promotionStr)) {
           return;
        }

        if (promotionStr != null) {
          controller.makeMoveWithPromotion(from: from, to: to, pieceToPromoteTo: 'q');
          _engineChess.move({"from": from, "to": to, "promotion": "q"});
        } else {
          controller.makeMove(from: from, to: to);
          _engineChess.move({"from": from, "to": to});
        }
        _onMove();
      } else {
        final piece = controller.game.get(square);
        if (piece != null && (piece.color == chess_engine.Color.WHITE) == (_engineChess.turn == chess_engine.Color.WHITE)) {
          final moves = controller.game.moves({'square': square, 'verbose': true});
          setState(() {
            selectedSquare = square;
            legalDestinations = moves.map((m) => (m as Map)['to'] as String).toList();
          });
        } else {
          setState(() {
            selectedSquare = null;
            legalDestinations.clear();
          });
        }
      }
    }
  }

  String _getExpectedSan() {
    if (_currentMoveIndex >= currentRepertoire.moves.length) return "✓";
    final uci = currentRepertoire.moves[_currentMoveIndex];
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final temp = chess_engine.Chess();
    temp.load(_engineChess.fen);
    final moves = temp.moves({'verbose': true});
    for (final m in moves) {
      final map = m as Map;
      if (map['from'] == from && map['to'] == to) {
        return map['san'] ?? uci;
      }
    }
    return uci;
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageService.currentLang == 'en';
    final currentFen = controller.game.fen;
    final rep = currentRepertoire;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1523),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C2C),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.amber, Colors.orangeAccent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  LanguageService.get('opening_trainer'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.explore, color: LichessWidgets.showOpeningExplorer ? Colors.blueAccent : Colors.white38),
            tooltip: isEn ? "Toggle Live Explorer" : "Canlı Ağaç Değiştir",
            onPressed: () => setState(() { LichessWidgets.showOpeningExplorer = !LichessWidgets.showOpeningExplorer; }),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert, color: Colors.white70),
            tooltip: isEn ? "Rotate Board" : "Tahtayı Çevir",
            onPressed: () {
              setState(() {
                _boardOrientation = _boardOrientation == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amberAccent),
            tooltip: isEn ? "Reset Repertoire" : "Yeniden Başlat",
            onPressed: () => setState(() => _initRepertoire()),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: isEn ? "Settings" : "Ayarlar",
            onPressed: () => showSettingsSheet(context, onChanged: () => setState(() {})),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÜST MOD SEÇİM BAR (Segmented Control)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2738),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  _buildModeButton(
                    mode: TrainingMode.guided,
                    icon: Icons.school,
                    label: isEn ? "Guided Study" : "Rehberli Pratik",
                    color: Colors.amberAccent,
                  ),
                  _buildModeButton(
                    mode: TrainingMode.quiz,
                    icon: Icons.psychology,
                    label: isEn ? "Memory Quiz" : "Hafıza Testi",
                    color: Colors.cyanAccent,
                  ),
                  _buildModeButton(
                    mode: TrainingMode.explorer,
                    icon: Icons.explore,
                    label: isEn ? "Live Explorer" : "Serbest Keşif",
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_mode != TrainingMode.explorer)
              // 2. AÇILIŞ REPERTUVARI SEÇİCİ
              GestureDetector(
                onTap: () => _showOpeningSelector(context, isEn),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE6A800), Color(0xFFFFCC33)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kOpeningLibrary[_selectedRepertoireIndex].eco,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEn ? kOpeningLibrary[_selectedRepertoireIndex].titleEn : kOpeningLibrary[_selectedRepertoireIndex].titleTr,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_circle, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            
            if (_mode == TrainingMode.explorer)
              Container(
                margin: const EdgeInsets.only(bottom: 0, left: 16, right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2738),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _evaluationValue >= 0 ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _evaluationText,
                            style: TextStyle(
                              color: _evaluationValue >= 0 ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _liveOpeningName.isEmpty ? (isEn ? "Analyzing..." : "Analiz ediliyor...") : _liveOpeningName,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_topEngineMoves.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          _topEngineMoves.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join("    "),
                          style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // 3. SATRANÇ TAHTASI (Etkileşimli)
            Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            ChessBoard(
                              controller: controller,
                              boardOrientation: _boardOrientation,
                              enableUserMoves: _mode == TrainingMode.explorer || !_isCompleted,
                              onMove: _onMove,
                              onMoveAttempt: _onMoveAttempt,
                            ),
                          // Dokunmatik oynama & vurgu katmanı
                          IgnorePointer(
                            child: Column(
                              children: List.generate(8, (row) {
                                return Expanded(
                                  child: Row(
                                    children: List.generate(8, (col) {
                                      final index = row * 8 + col;
                                      final square = _indexToSquare(index, _boardOrientation == PlayerColor.white);
                                      final isSelected = square == selectedSquare;
                                      final isLegalMove = legalDestinations.contains(square);
                                      final piece = controller.game.get(square);
                                      final isCapture = isLegalMove && piece != null;

                                      Widget? highlightWidget;
                                      if (isCapture) {
                                        highlightWidget = Center(
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.8), width: 3.5),
                                            ),
                                          ),
                                        );
                                      } else if (isLegalMove) {
                                        highlightWidget = Center(
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      } else if (isSelected) {
                                        highlightWidget = Container(color: Colors.amber.withValues(alpha: 0.45));
                                      }
                                      return Expanded(child: highlightWidget ?? const SizedBox.shrink());
                                    }),
                                  ),
                                );
                              }),
                            ),
                          ),
                          // Görünmez tık katmanı
                          Column(
                            children: List.generate(8, (row) {
                              return Expanded(
                                child: Row(
                                  children: List.generate(8, (col) {
                                    final index = row * 8 + col;
                                    final square = _indexToSquare(index, _boardOrientation == PlayerColor.white);
                                    return Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () => _onSquareTapped(square),
                                        child: const SizedBox.expand(),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_mode == TrainingMode.explorer) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.fast_rewind),
                  color: _explorerIndex > 0 ? Colors.white : Colors.white30,
                  onPressed: _explorerIndex > 0 ? () => _goToExplorerMove(0) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: _explorerIndex > 0 ? Colors.white : Colors.white30,
                  onPressed: _explorerIndex > 0 ? () => _goToExplorerMove(_explorerIndex - 1) : null,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: _explorerIndex < _explorerFens.length - 1 ? Colors.white : Colors.white30,
                  onPressed: _explorerIndex < _explorerFens.length - 1 ? () => _goToExplorerMove(_explorerIndex + 1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.fast_forward),
                  color: _explorerIndex < _explorerFens.length - 1 ? Colors.white : Colors.white30,
                  onPressed: _explorerIndex < _explorerFens.length - 1 ? () => _goToExplorerMove(_explorerFens.length - 1) : null,
                ),
              ],
            ),
            if (_explorerMoves.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2738),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 6,
                  children: List.generate(_explorerMoves.length, (index) {
                    bool isWhite = index % 2 == 0;
                    String moveNumber = isWhite ? '${(index ~/ 2) + 1}. ' : '';
                    bool isCurrent = index == _explorerIndex - 1;
                    
                    return GestureDetector(
                      onTap: () => _goToExplorerMove(index + 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$moveNumber${_explorerMoves[index]}',
                          style: TextStyle(
                            color: isCurrent ? Colors.blueAccent : Colors.white70,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // 4. ALT BİLGİ VE KONTROL KARTLARI
          if (_mode != TrainingMode.explorer)
            Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151C2C),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Durum / İpucu / Bildirim Satırı
                  if (_mode != TrainingMode.explorer)
                    SizedBox(
                      height: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        Expanded(
                          child: _feedbackMsg != null
                              ? Text(_feedbackMsg!, style: TextStyle(color: _feedbackColor, fontWeight: FontWeight.bold, fontSize: 13.5))
                              : _mode == TrainingMode.guided
                                  ? Row(
                                      children: [
                                        const Icon(Icons.lightbulb, color: Colors.amberAccent, size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isEn
                                                ? "Target Move: ${_getExpectedSan()} (Turn: ${rep.isWhite ? 'White' : 'Black'})"
                                                : "Hedef Hamle: ${_getExpectedSan()} (Sıra: ${rep.isWhite ? 'Beyaz' : 'Siyah'})",
                                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13.5),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        const Icon(Icons.quiz, color: Colors.cyanAccent, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          isEn ? "Test your memory! Mistakes: $_mistakes" : "Hafızanı sına! Hata Sayısı: $_mistakes",
                                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        const Spacer(),
                                        if (!_isCompleted)
                                          InkWell(
                                            onTap: () => setState(() => _showQuizHint = !_showQuizHint),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                              child: Text(isEn ? (_showQuizHint ? "Hide Hint" : "Show Hint") : (_showQuizHint ? "İpucu Gizle" : "İpucu Göster"), style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                      ],
                                    ),
                        ),
                      ],
                    ),
                    ),
                  if (_mode == TrainingMode.quiz && _showQuizHint && !_isCompleted) ...[
                    const SizedBox(height: 6),
                    Text(
                      isEn ? "💡 Hint: Try playing ${_getExpectedSan()}" : "💡 İpucu: ${_getExpectedSan()} hamlesini oynamayı dene.",
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (_mode != TrainingMode.explorer) ...[
                    const SizedBox(height: 10),
                    // Açıklama / Stratejik Rehber
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2738),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rep.category, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(rep.desc, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Lichess Canlı Açılış Ağacı
                  LichessWidgets.buildOpeningExplorerPanel(currentFen, _onExplorerMoveTap),
                ],
              ),
            ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpeningSelector(BuildContext context, bool isEn) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final filteredOpenings = kOpeningLibrary.asMap().entries.where((entry) {
              final title = isEn ? entry.value.titleEn.toLowerCase() : entry.value.titleTr.toLowerCase();
              final eco = entry.value.eco.toLowerCase();
              final search = searchQuery.toLowerCase();
              return title.contains(search) || eco.contains(search);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFF151C2C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEn ? "Select Opening" : "Açılış Seç",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: isEn ? "Search openings..." : "Açılış ara...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0F1523),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredOpenings.length,
                      itemBuilder: (ctx, index) {
                        final entry = filteredOpenings[index];
                        final originalIndex = entry.key;
                        final item = entry.value;
                        final isSelected = _selectedRepertoireIndex == originalIndex;

                        return ListTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedRepertoireIndex = originalIndex;
                              _initRepertoire();
                            });
                          },
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amberAccent : Colors.white12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.eco,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.amberAccent,
                              ),
                            ),
                          ),
                          title: Text(
                            isEn ? item.titleEn : item.titleTr,
                            style: TextStyle(
                              color: isSelected ? Colors.amberAccent : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check, color: Colors.amberAccent) : null,
                        );
                      },
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

  Widget _buildModeButton({required TrainingMode mode, required IconData icon, required String label, required Color color}) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = mode;
            if (mode != TrainingMode.explorer) {
              ChessEngineService().stopContinuousAnalysis();
              _initRepertoire();
            } else {
              controller.resetBoard();
              _engineChess.reset();
              _explorerFens = [controller.game.fen];
              _explorerMoves = [];
              _explorerIndex = 0;
              selectedSquare = null;
              legalDestinations.clear();
              _updateLiveExplorerData(_engineChess.fen);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white54, size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : Colors.white54,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
