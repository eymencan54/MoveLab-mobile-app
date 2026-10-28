import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'custom_chess_board/custom_chess_board.dart';
import 'package:chess/chess.dart' as chess_engine;
import 'main.dart';

/// AI Bot Kişilik Modeli
class BotPersonality {
  final String id;
  final String nameTr;
  final String nameEn;
  final int elo;
  final String titleTr;
  final String titleEn;
  final String descTr;
  final String descEn;
  final IconData avatarIcon;
  final Color badgeColor;
  final String playStyle; // 'random', 'defensive', 'aggressive', 'positional', 'master'

  const BotPersonality({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.elo,
    required this.titleTr,
    required this.titleEn,
    required this.descTr,
    required this.descEn,
    required this.avatarIcon,
    required this.badgeColor,
    required this.playStyle,
  });
}

/// 5 Efsanevi Bot Kişiliği
const List<BotPersonality> kBotPersonalities = [
  BotPersonality(
    id: 'efe',
    nameTr: 'Çömez Bot',
    nameEn: 'Rookie Bot',
    elo: 800,
    titleTr: 'Meraklı Başlangıç',
    titleEn: 'Curious Beginner',
    descTr: 'Satrançta yeniyim! Bazen taş uyuturum ama değişik hamleler denemeyi çok seviyorum.',
    descEn: 'I am new to chess! I sometimes blunder pieces but I love trying creative moves.',
    avatarIcon: Icons.child_care,
    badgeColor: Colors.greenAccent,
    playStyle: 'random',
  ),
  BotPersonality(
    id: 'selim',
    nameTr: 'Savunma Botu',
    nameEn: 'Defender Bot',
    elo: 1100,
    titleTr: 'Sağlam Kale',
    titleEn: 'Solid Fortress',
    descTr: 'Sürekli taş takası ararım, risk almam ve sağlam bir savunma kalesi örerim.',
    descEn: 'I look for piece trades, avoid risks, and build a solid defensive fortress.',
    avatarIcon: Icons.shield,
    badgeColor: Colors.blueAccent,
    playStyle: 'defensive',
  ),
  BotPersonality(
    id: 'caner',
    nameTr: 'Taktikçi Bot',
    nameEn: 'Tactician Bot',
    elo: 1600,
    titleTr: 'Agresif Saldırgan',
    titleEn: 'Aggressive Attacker',
    descTr: 'Saldırı en iyi savunmadır! Feda yapmaya ve şahına saldırmaya bayılırım!',
    descEn: 'Attack is the best defense! I love sacrifices and targeting your king directly!',
    avatarIcon: Icons.flash_on,
    badgeColor: Colors.orangeAccent,
    playStyle: 'aggressive',
  ),
  BotPersonality(
    id: 'bilge',
    nameTr: 'Strateji Botu',
    nameEn: 'Strategist Bot',
    elo: 2000,
    titleTr: 'Konumsal Dahi',
    titleEn: 'Positional Genius',
    descTr: 'Her hamlem 10 adım sonrasını planlar. Konumsal üstünlüğü ve merkez kontrolünü severim.',
    descEn: 'Every move plans 10 steps ahead. I value positional dominance and center control.',
    avatarIcon: Icons.psychology,
    badgeColor: Colors.purpleAccent,
    playStyle: 'positional',
  ),
  BotPersonality(
    id: 'grandmaster',
    nameTr: 'Büyük Usta Botu',
    nameEn: 'Grandmaster Bot',
    elo: 2400,
    titleTr: 'Yenilmez Efsane',
    titleEn: 'Invincible Legend',
    descTr: 'Kusursuz satranç. En küçük hatanı affetmem ve oyunu acımasızca bitiririm.',
    descEn: 'Flawless chess. I will punish your slightest mistake and crush your position.',
    avatarIcon: Icons.military_tech,
    badgeColor: Colors.amberAccent,
    playStyle: 'master',
  ),
];

/// Bot Seçim Ekranı
class BotSelectionPage extends StatefulWidget {
  const BotSelectionPage({super.key});

  @override
  State<BotSelectionPage> createState() => _BotSelectionPageState();
}

class _BotSelectionPageState extends State<BotSelectionPage> {
  String _selectedColor = 'white'; // 'white', 'black', 'random'

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageService.currentLang == 'en';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1523),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C2C),
        elevation: 0,
        centerTitle: true,
        title: Text(
          LanguageService.get('play_vs_bot'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Renk Seçim Çubuğu
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2738),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEn ? "Your Color:" : "Taş Rengin:",
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Row(
                  children: [
                    _buildColorButton('white', isEn ? "White" : "Beyaz", Icons.circle, Colors.white),
                    const SizedBox(width: 6),
                    _buildColorButton('black', isEn ? "Black" : "Siyah", Icons.circle, Colors.black),
                    const SizedBox(width: 6),
                    _buildColorButton('random', isEn ? "Random" : "Rastgele", Icons.shuffle, Colors.amberAccent),
                  ],
                ),
              ],
            ),
          ),

          // Bot Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: kBotPersonalities.length,
              itemBuilder: (context, index) {
                final bot = kBotPersonalities[index];
                return _buildBotCard(bot, isEn);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(String colorKey, String label, IconData icon, Color iconColor) {
    final isSelected = _selectedColor == colorKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedColor = colorKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: icon == Icons.circle && iconColor == Colors.black ? Colors.grey[400] : iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purpleAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotCard(BotPersonality bot, bool isEn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bot.badgeColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: bot.badgeColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            PlayerColor playerColor;
            if (_selectedColor == 'random') {
              playerColor = Random().nextBool() ? PlayerColor.white : PlayerColor.black;
            } else {
              playerColor = _selectedColor == 'white' ? PlayerColor.white : PlayerColor.black;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayVsBotGamePage(bot: bot, playerColor: playerColor),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bot.badgeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: bot.badgeColor, width: 2),
                      ),
                      child: Icon(bot.avatarIcon, color: bot.badgeColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEn ? bot.nameEn : bot.nameTr,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bot.badgeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: bot.badgeColor),
                                ),
                                child: Text(
                                  "${bot.elo} ELO",
                                  style: TextStyle(color: bot.badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn ? bot.titleEn : bot.titleTr,
                            style: TextStyle(color: bot.badgeColor.withValues(alpha: 0.9), fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isEn ? bot.descEn : bot.descTr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [bot.badgeColor.withValues(alpha: 0.8), bot.badgeColor]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: bot.elo > 2000 ? Colors.black : Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            isEn ? "Play vs. Bot" : "Meydan Oku",
                            style: TextStyle(
                              color: bot.elo > 2000 ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bot ile Oyun Ekranı
class PlayVsBotGamePage extends StatefulWidget {
  final BotPersonality bot;
  final PlayerColor playerColor;

  const PlayVsBotGamePage({super.key, required this.bot, required this.playerColor});

  @override
  State<PlayVsBotGamePage> createState() => _PlayVsBotGamePageState();
}

class _PlayVsBotGamePageState extends State<PlayVsBotGamePage> {
  late ChessBoardController controller;
  late chess_engine.Chess _engineChess;
  late PlayerColor _boardOrientation;

  bool _isBotThinking = false;
  String _currentSpeech = "";
  final List<String> _moveHistory = [];
  final List<String> _uciMoveList = []; // UCI hamle geçmişi (analiz için)
  bool _isGameOver = false;

  String? selectedSquare;
  List<String> legalDestinations = [];

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    _engineChess = chess_engine.Chess();
    _boardOrientation = widget.playerColor;
    ChessEngineService().initEngine();

    final isEn = LanguageService.currentLang == 'en';
    _currentSpeech = isEn ? "Good luck! Let's see what you can do." : "İyi şanslar! Görelim bakalım neler yapacaksın.";

    // Eğer oyuncu siyahsa ilk hamleyi bot (beyaz) yapsın
    if (widget.playerColor == PlayerColor.black) {
      Timer(const Duration(milliseconds: 600), _makeBotMove);
    }
  }

  void _onMove() {
    var sans = controller.getSan();
    String lastMove = '?';
    bool isCapture = false;
    if (sans.isNotEmpty && sans.last != null) {
      String lastPair = sans.last!.trim();
      List<String> parts = lastPair.split(RegExp(r'\s+'));
      lastMove = parts.last;
      isCapture = lastMove.contains('x');
    }

    setState(() {
      _moveHistory.add(lastMove);
      _engineChess.load(controller.game.fen);
    });

    SoundService.playMoveSound(isCapture);
    _checkGameOver();

    final isWhiteTurn = _engineChess.turn == chess_engine.Color.WHITE;
    final isPlayerTurn = (isWhiteTurn && widget.playerColor == PlayerColor.white) ||
        (!isWhiteTurn && widget.playerColor == PlayerColor.black);

    if (!_isGameOver && !isPlayerTurn && !_isBotThinking) {
      _makeBotMove();
    }
  }


  // Bot hamlesi için: UCI zaten _makeBotMove'da kaydedildi, burada sadece SAN ve oyun durumu güncellenir
  void _onMoveBot() {
    var sans = controller.getSan();
    String lastMove = '?';
    bool isCapture = false;
    if (sans.isNotEmpty && sans.last != null) {
      String lastPair = sans.last!.trim();
      List<String> parts = lastPair.split(RegExp(r'\s+'));
      lastMove = parts.last;
      isCapture = lastMove.contains('x');
    }

    setState(() {
      _moveHistory.add(lastMove);
      _engineChess.load(controller.game.fen);
    });

    SoundService.playMoveSound(isCapture);
    _checkGameOver();
  }


  void _checkGameOver() {
    final isEn = LanguageService.currentLang == 'en';
    if (_engineChess.in_checkmate) {
      _isGameOver = true;
      final winnerIsPlayer = (_engineChess.turn == chess_engine.Color.WHITE && widget.playerColor == PlayerColor.black) ||
          (_engineChess.turn == chess_engine.Color.BLACK && widget.playerColor == PlayerColor.white);
      final winner = winnerIsPlayer ? (widget.playerColor == PlayerColor.white ? 'white' : 'black') : (widget.playerColor == PlayerColor.white ? 'black' : 'white');

      setState(() {
        if (winnerIsPlayer) {
          _currentSpeech = isEn ? "Unbelievable! You defeated me! You are a master!" : "İnanılmaz! Beni yendin! Gerçek bir ustasın!";
        } else {
          _currentSpeech = isEn ? "Checkmate! My strategy worked flawlessly!" : "Şah mat! Stratejim tıkır tıkır işledi! 😎";
        }
      });
      _showGameOverDialog(
        winnerIsPlayer ? (isEn ? "You Won! 🏆" : "Kazandınız! 🏆") : (isEn ? "Bot Won! 🤖" : "Bot Kazandı! 🤖"),
        winner: winner,
      );
    } else if (_engineChess.in_draw || _engineChess.in_stalemate) {
      _isGameOver = true;
      setState(() {
        _currentSpeech = isEn ? "A well-fought draw! Excellent game." : "Berabere! İkimiz de çok iyi mücadele ettik.";
      });
      _showGameOverDialog(isEn ? "Draw 🤝" : "Berabere 🤝", winner: 'draw');
    } else if (_engineChess.in_check) {
      setState(() {
        final isPlayerTurn = (_engineChess.turn == chess_engine.Color.WHITE && widget.playerColor == PlayerColor.white) ||
            (_engineChess.turn == chess_engine.Color.BLACK && widget.playerColor == PlayerColor.black);
        if (isPlayerTurn) {
          _currentSpeech = isEn ? "Check! Watch out for your king!" : "Şah! Şahına dikkat et!";
        }
      });
    }
  }

  void _showGameOverDialog(String title, {String winner = 'draw'}) {
    final isEn = LanguageService.currentLang == 'en';
    final uciMovesSnapshot = List<String>.from(_uciMoveList);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2738),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        content: Text(_currentSpeech, style: const TextStyle(color: Colors.white, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restartGame();
            },
            child: Text(isEn ? "Play Again" : "Tekrar Oyna", style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final playerName = isEn ? 'You' : 'Sen';
              final botName = isEn ? widget.bot.nameEn : widget.bot.nameTr;
              final isPlayerWhite = widget.playerColor == PlayerColor.white;
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => AnalysisPage(
                  matchData: {
                    'white': isPlayerWhite ? playerName : botName,
                    'black': isPlayerWhite ? botName : playerName,
                    'whiteRating': isPlayerWhite ? 0 : widget.bot.elo,
                    'blackRating': isPlayerWhite ? widget.bot.elo : 0,
                    'moves': uciMovesSnapshot.join(' '),
                    'pgn': '',
                    'winner': winner,
                    'speed': 'Bot',
                    'platform': 'MoveLab',
                    'whiteTitle': '',
                    'blackTitle': '',
                  },
                  boardOrientation: widget.playerColor,
                  apiHeaders: const {},
                ),
              ));
            },
            child: Text(isEn ? "Analyze" : "Analiz Et", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.bot.badgeColor),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(isEn ? "Exit" : "Çık", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _makeBotMove() async {
    if (!mounted || _isGameOver) return;

    setState(() {
      _isBotThinking = true;
      final isEn = LanguageService.currentLang == 'en';
      _currentSpeech = isEn ? "Thinking... 🤔" : "Düşünüyor... 🤔";
    });

    // Stockfish ile ELO gücüne göre analiz
    ChessEngineService().initEngine();
    int targetDepth = 12;
    int maxTime = 1000;
    int skillLevel = 20;
    int multiPv = 3;

    if (widget.bot.playStyle == 'random') {
      targetDepth = 3; maxTime = 300; skillLevel = 0; multiPv = 2;
    } else if (widget.bot.playStyle == 'defensive') {
      targetDepth = 6; maxTime = 500; skillLevel = 5; multiPv = 3;
    } else if (widget.bot.playStyle == 'aggressive') {
      targetDepth = 8; maxTime = 700; skillLevel = 10; multiPv = 3;
    } else if (widget.bot.playStyle == 'positional') {
      targetDepth = 12; maxTime = 900; skillLevel = 15; multiPv = 3;
    } else if (widget.bot.playStyle == 'master') {
      targetDepth = 24; maxTime = 4000; skillLevel = 20; multiPv = 1; // En güçlü, tek varyant odaklı, tam isabet
    }

    final moves = _engineChess.moves({'verbose': true});
    if (moves.isEmpty) return;

    Map? selectedMove;
    try {
      final evalData = await ChessEngineService().evaluateFen(
        _engineChess.fen, 
        depth: targetDepth, 
        maxTimeMs: maxTime,
        multiPvOverride: multiPv,
        skillLevelOverride: skillLevel,
      );
      if (!mounted || _isGameOver) return;

      final bestMoveStr = evalData['bestmove'] as String?;
      final suggs = (evalData['suggestions'] as List?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? [];
      if (bestMoveStr != null && !suggs.contains(bestMoveStr)) {
        suggs.insert(0, bestMoveStr);
      }

      List<Map> candidateMoves = [];
      for (final uci in suggs) {
        final match = moves.firstWhere((m) {
          final from = (m as Map)['from'] as String;
          final to = m['to'] as String;
          final promo = m.containsKey('promotion') && m['promotion'] != null ? (m['promotion'] as String).toLowerCase() : '';
          return "$from$to$promo" == uci;
        }, orElse: () => null) as Map?;
        if (match != null && !candidateMoves.contains(match)) {
          candidateMoves.add(match);
        }
      }

      if (candidateMoves.isEmpty && bestMoveStr != null) {
        final match = moves.firstWhere((m) {
          final from = (m as Map)['from'] as String;
          final to = m['to'] as String;
          final promo = m.containsKey('promotion') && m['promotion'] != null ? (m['promotion'] as String).toLowerCase() : '';
          return "$from$to$promo" == bestMoveStr;
        }, orElse: () => null) as Map?;
        if (match != null) candidateMoves.add(match);
      }

      if (candidateMoves.isNotEmpty) {
        if (widget.bot.playStyle == 'master') {
          selectedMove = candidateMoves.first;
        } else if (widget.bot.playStyle == 'positional') {
          selectedMove = (candidateMoves.length >= 2 && Random().nextInt(10) < 2) ? candidateMoves[1] : candidateMoves.first;
        } else if (widget.bot.playStyle == 'aggressive') {
          final tactical = candidateMoves.where((m) => (m['san'] as String).contains('+') || (m.containsKey('captured') && m['captured'] != null)).toList();
          if (tactical.isNotEmpty) {
            selectedMove = tactical.first;
          } else {
            selectedMove = candidateMoves[Random().nextInt(min(2, candidateMoves.length))];
          }
        } else if (widget.bot.playStyle == 'defensive') {
          selectedMove = candidateMoves[Random().nextInt(min(3, candidateMoves.length))];
        } else {
          selectedMove = (Random().nextBool() && candidateMoves.isNotEmpty) ? candidateMoves.first : moves[Random().nextInt(moves.length)] as Map;
        }
      }
    } catch (e) {
      debugPrint("Stockfish Bot Hatası: $e");
    }

    selectedMove ??= moves[Random().nextInt(moves.length)] as Map;

    final from = selectedMove['from'] as String;
    final to = selectedMove['to'] as String;
    final promotion = selectedMove.containsKey('promotion') ? selectedMove['promotion'] as String? : null;

    if (promotion != null) {
      controller.makeMoveWithPromotion(from: from, to: to, pieceToPromoteTo: promotion);
    } else {
      controller.makeMove(from: from, to: to);
    }
    // UCI'yi doğrudan kaydet (bot için kesin bilgi)
    _uciMoveList.add('$from$to${promotion?.toLowerCase() ?? ''}');

    setState(() {
      _isBotThinking = false;
      final isEn = LanguageService.currentLang == 'en';
      final san = selectedMove!['san'] as String;
      if (san.contains('x')) {
        _currentSpeech = isEn ? "I took that piece! 😋" : "Bu taşı aldım, lezizdi! 😋";
      } else if (san.contains('+')) {
        _currentSpeech = isEn ? "Check! Watch your king!" : "Şah! Şahına dikkat et!";
      } else {
        final quotesTr = ["Hımm, hamleme ne diyeceksin?", "Sıra sende dostum.", "Planlamak önemli.", "İyi gidiyoruz!"];
        final quotesEn = ["Hmm, what do you say to this?", "Your turn, my friend.", "Planning is key.", "Good match!"];
        _currentSpeech = isEn ? quotesEn[Random().nextInt(quotesEn.length)] : quotesTr[Random().nextInt(quotesTr.length)];
      }
    });

    _onMoveBot();
  }

  void _restartGame() {
    setState(() {
      controller.resetBoard();
      _engineChess.reset();
      _moveHistory.clear();
      _uciMoveList.clear();
      _isGameOver = false;
      _isBotThinking = false;
      selectedSquare = null;
      legalDestinations.clear();

      final isEn = LanguageService.currentLang == 'en';
      _currentSpeech = isEn ? "Good luck! Let's see what you can do." : "İyi şanslar! Görelim bakalım neler yapacaksın.";
    });

    if (widget.playerColor == PlayerColor.black) {
      Timer(const Duration(milliseconds: 600), _makeBotMove);
    }
  }

  void _safeUndoOneMove() {
    if (controller.game.history.isNotEmpty) {
      controller.game.undo_move();
    }
  }

  void _undoMove() {
    if (_isBotThinking || _moveHistory.isEmpty) return;
    setState(() {
      _isGameOver = false;
      // 1. hamleyi geri al
      _safeUndoOneMove();
      if (_moveHistory.isNotEmpty) _moveHistory.removeLast();
      if (_uciMoveList.isNotEmpty) _uciMoveList.removeLast();

      // Sıra tekrar oyuncuya gelene kadar (veya geçmiş bitene kadar) hamleleri geri almaya devam et
      while (_moveHistory.isNotEmpty &&
          ((controller.game.turn == chess_engine.Color.WHITE && widget.playerColor != PlayerColor.white) ||
              (controller.game.turn == chess_engine.Color.BLACK && widget.playerColor != PlayerColor.black))) {
        _safeUndoOneMove();
        _moveHistory.removeLast();
        if (_uciMoveList.isNotEmpty) _uciMoveList.removeLast();
      }

      // Tahtayı ve UI'ı public API üzerinden yenile
      controller.loadFen(controller.game.fen);
      _engineChess.load(controller.game.fen);
      selectedSquare = null;
      legalDestinations.clear();
      final isEn = LanguageService.currentLang == 'en';
      _currentSpeech = isEn ? "Move undone. Think carefully!" : "Hamle geri alındı. Dikkatli düşün!";

      // Eğer siyah oyuncuyken tüm hamleler geri alınıp başa dönüldüyse bot tekrar ilk hamleyi yapsın
      if (_moveHistory.isEmpty && widget.playerColor == PlayerColor.black) {
        Timer(const Duration(milliseconds: 600), _makeBotMove);
      }
    });
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
    if (_isBotThinking || _isGameOver) return;
    
    final isWhiteTurn = _engineChess.turn == chess_engine.Color.WHITE;
    final isPlayerTurn = (isWhiteTurn && widget.playerColor == PlayerColor.white) ||
        (!isWhiteTurn && widget.playerColor == PlayerColor.black);
    if (!isPlayerTurn) return;

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
        
        final moves = controller.game.moves({'square': from, 'verbose': true});
        final moveMap = moves.firstWhere((m) => (m as Map)['to'] == to, orElse: () => null) as Map?;
        final hasPromo = moveMap != null && moveMap.containsKey('promotion') && moveMap['promotion'] != null;
        if (hasPromo) {
          controller.makeMoveWithPromotion(from: from, to: to, pieceToPromoteTo: 'q');
          _uciMoveList.add('$from${to}q');
        } else {
          controller.makeMove(from: from, to: to);
          _uciMoveList.add('$from$to');
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

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageService.currentLang == 'en';
    final bot = widget.bot;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1523),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C2C),
        elevation: 0,
        title: Row(
          children: [
            Icon(bot.avatarIcon, color: bot.badgeColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn ? "vs. ${bot.nameEn}" : "vs. ${bot.nameTr}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert, color: Colors.white70),
            onPressed: () {
              setState(() {
                _boardOrientation = _boardOrientation == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amberAccent),
            onPressed: _restartGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. BOT KARTI & CANLI REPLİK BALONU
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bot.badgeColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bot.badgeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: bot.badgeColor, width: 2),
                  ),
                  child: Icon(bot.avatarIcon, color: bot.badgeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? bot.nameEn : bot.nameTr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            "${bot.elo} ELO",
                            style: TextStyle(color: bot.badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Replik Balonu
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2738),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _currentSpeech,
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 12.5, fontStyle: FontStyle.italic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. HAMLE GEÇMİŞİ ŞERİDİ
          Container(
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2738),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _moveHistory.length,
              itemBuilder: (context, index) {
                final move = _moveHistory[index];
                final isWhiteMove = index % 2 == 0;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      isWhiteMove ? "${(index ~/ 2) + 1}. $move" : move,
                      style: TextStyle(
                        color: isWhiteMove ? Colors.white : Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 3. SATRANÇ TAHTASI
          Expanded(
            child: Center(
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
                            boardColor: BoardThemeService.boardColor,
                            boardOrientation: _boardOrientation,
                            enableUserMoves: !_isBotThinking && !_isGameOver,
                            onMove: _onMove,
                          ),
                          // Dokunmatik Vurgular
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
                          // Dokunmatik Tık Katmanı
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
          ),

          // 4. KONTROL BUTONLARI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2C),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.undo,
                  label: isEn ? "Undo" : "Geri Al",
                  color: Colors.orangeAccent,
                  onTap: _undoMove,
                ),
                _buildActionButton(
                  icon: Icons.refresh,
                  label: isEn ? "Restart" : "Yeniden",
                  color: Colors.cyanAccent,
                  onTap: _restartGame,
                ),
                _buildActionButton(
                  icon: Icons.flag,
                  label: isEn ? "Resign" : "Pes Et",
                  color: Colors.redAccent,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E2738),
                        title: Text(isEn ? "Resign?" : "Pes mi Ediyorsun?", style: const TextStyle(color: Colors.white)),
                        content: Text(
                          isEn ? "Do you want to surrender this match?" : "Bu maçı bırakıp ana menüye dönmek istiyor musun?",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(isEn ? "Cancel" : "İptal", style: const TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: Text(isEn ? "Yes, Resign" : "Evet, Pes Et", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
