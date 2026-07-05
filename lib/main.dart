import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert'; 
import 'dart:math'; 
import 'dart:ui' as ui;
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color; 
import 'package:chess/chess.dart' as chess_engine; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stockfish/stockfish.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// =====================================================================
// 0. SES SİSTEMİ VE AYARLAR
// =====================================================================

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isMuted = false;
  static double _volume = 1.0;
  static bool _showArrows = true; 

  static bool get isMuted => _isMuted;
  static double get volume => _volume;
  static bool get showArrows => _showArrows;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('sound_muted') ?? false;
    _volume = prefs.getDouble('sound_volume') ?? 1.0;
    _showArrows = prefs.getBool('show_arrows') ?? true;
    await _player.setVolume(_volume);
  }

  static Future<void> setMuted(bool val) async {
    _isMuted = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', val);
  }

  static Future<void> setVolume(double val) async {
    _volume = val;
    await _player.setVolume(val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', val);
  }
  
  static Future<void> setShowArrows(bool val) async {
    _showArrows = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_arrows', val);
  }

  static Future<void> playMoveSound(bool isCapture) async {
    if (_isMuted) return;
    try {
      String url = isCapture
          ? 'https://images.chesscomfiles.com/chess-themes/sounds/_MP3_/default/capture.mp3'
          : 'https://images.chesscomfiles.com/chess-themes/sounds/_MP3_/default/move-self.mp3';
      await _player.play(UrlSource(url), volume: _volume);
    } catch (e) {
      debugPrint("Ses çalma hatası: $e");
    }
  }
}

class LanguageService {
  static String _currentLang = 'tr'; // Varsayılan dil Türkçe
  static final ValueNotifier<String> localeNotifier = ValueNotifier<String>('tr');

  static String get currentLang => _currentLang;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Hafızada kayıtlı dil varsa onu al, yoksa 'tr' kullan
    _currentLang = prefs.getString('app_lang') ?? 'tr';
    localeNotifier.value = _currentLang;
  }

  static Future<void> setLanguage(String langCode) async {
    _currentLang = langCode;
    localeNotifier.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', langCode);
  }

  // UYGULAMANIN SÖZLÜĞÜ
  static const Map<String, Map<String, String>> _dict = {
    'settings': {'tr': 'Ayarlar', 'en': 'Settings'},
    'analysis_laboratory': {'tr': 'MoveLab Analiz Laboratuvarı', 'en': 'MoveLab Analysis Lab'},
    'puzzle_congratulations': {'tr': 'Tebrikler! 🎉', 'en': 'Congratulations! 🎉'},
    'puzzle_difficulty': {'tr': 'ZORLUK', 'en': 'DIFFICULTY'},
    'puzzle_diff_easy': {'tr': 'Kolay', 'en': 'Easy'},
    'puzzle_diff_medium': {'tr': 'Orta', 'en': 'Medium'},
    'puzzle_diff_hard': {'tr': 'Zor', 'en': 'Hard'},
    'puzzle_diff_elite': {'tr': 'Elit', 'en': 'Elite'},
    'puzzle_diff_select': {'tr': 'Zorluk Seviyesi Seç', 'en': 'Select Difficulty Level'},
    'puzzle_diff_points': {'tr': 'Puan', 'en': 'Points'},
    'library_title': {'tr': 'MoveLab - Kütüphane', 'en': 'MoveLab - Library'},
    'piece_sounds': {'tr': 'Taş Sesleri', 'en': 'Piece Sounds'},
    'show_arrows': {'tr': 'En İyi Hamle Oklarını Göster', 'en': 'Show Best Move Arrows'},
    'language': {'tr': 'Dil / Language', 'en': 'Language / Dil'},
    'turkish': {'tr': 'Türkçe', 'en': 'Turkish'},
    'english': {'tr': 'English', 'en': 'English'},
    'analyze_match': {'tr': 'Maçı Analiz Et', 'en': 'Analyze Match'},
    'library': {'tr': 'Kütüphane', 'en': 'Library'},
    'library_saved_matches': {'tr': 'Kütüphane (Kayıtlı Maçlar)', 'en': 'Library (Saved Games)'},
    'no_library_matches': {'tr': 'Henüz kütüphaneye maç eklenmemiş.', 'en': 'No games have been added to the library yet.'},
    'match_deleted': {'tr': 'Maç kütüphaneden silindi.', 'en': 'Game removed from library.'},
    'match_added': {'tr': 'Maç kütüphaneye eklendi!', 'en': 'Game added to the library!'},
    'cancel': {'tr': 'İptal', 'en': 'Cancel'},
    'analyze': {'tr': 'Analiz Et', 'en': 'Analyze'},
    'pgn_paste': {'tr': 'PGN Yapıştır', 'en': 'Paste PGN'},
    'pgn_placeholder': {'tr': 'PGN metnini buraya yapıştırın...', 'en': 'Paste the PGN text here...'},
    'pgn_empty': {'tr': 'PGN boş olamaz.', 'en': 'PGN cannot be empty.'},
    'connection_error': {'tr': 'Bağlantı sağlanamadı.', 'en': 'Connection could not be established.'},
    'filter_error': {'tr': 'Filtreleme hatası.', 'en': 'Filtering error.'},
    'share_error': {'tr': 'Paylaşım sırasında bir hata oluştu.', 'en': 'An error occurred while sharing.'},
    'analysis_share': {'tr': 'Analizi Paylaş', 'en': 'Share Analysis'},
    'back_home': {'tr': 'Ana Ekrana Dön', 'en': 'Back to Home'},
    'player_search_placeholder': {'tr': 'kullanıcı adı...', 'en': 'username...'},
    'find_player': {'tr': 'Oyuncuyu Bul', 'en': 'Find Player'},
    'analyze_with_pgn': {'tr': 'PGN ile Analiz Et', 'en': 'Analyze with PGN'},
    'recent_matches': {'tr': 'Son Maçlar', 'en': 'Recent Games'},
    'all': {'tr': 'Tümü', 'en': 'All'},
    'no_match_data': {'tr': 'Maç verisi alınamadı.', 'en': 'No game data could be retrieved.'},
    'load_more_games': {'tr': 'Önceki 10 Maçı Daha Getir', 'en': 'Load 10 More Previous Games'},
    'user_not_found': {'tr': 'Oyuncu bulunamadı.', 'en': 'Player not found.'},
    'analysis_title': {'tr': 'OYUN STİLİ ANALİZİ', 'en': 'PLAY STYLE ANALYSIS'},
    'player': {'tr': 'Oyuncu', 'en': 'Player'},
    'rating': {'tr': 'Rating', 'en': 'Rating'},
    'share_style': {'tr': 'Analizi Paylaş', 'en': 'Share Analysis'},
    'style_aggressive': {'tr': 'Agresiflik', 'en': 'Aggression'},
    'style_defensive': {'tr': 'Defansiflik', 'en': 'Defense'},
    'style_tactical': {'tr': 'Taktik', 'en': 'Tactical'},
    'style_positional': {'tr': 'Pozisyonel', 'en': 'Positional'},
    'style_risk': {'tr': 'Risk Alma', 'en': 'Risk Taking'},
    'style_opening': {'tr': 'Açılış Bilgisi', 'en': 'Opening Knowledge'},
    'analysis_engine': {'tr': 'Motor Analizi', 'en': 'Engine Analysis'},
    'move_quality_distribution': {'tr': 'HAMLE KALİTE DAĞILIMI', 'en': 'MOVE QUALITY DISTRIBUTION'},
    'brilliant_move': {'tr': 'Etkileyici Hamle (!!)', 'en': 'Impressive Move (!!)'},
    'great_move': {'tr': 'Harika Hamle (!)', 'en': 'Great Move (!)'},
    'best_move': {'tr': 'En İyi Hamle', 'en': 'Best Move'},
    'excellent_move': {'tr': 'Mükemmel', 'en': 'Excellent'},
    'good_move': {'tr': 'İyi Hamle', 'en': 'Good Move'},
    'inaccuracy_move': {'tr': 'Şüpheli (?!)', 'en': 'Inaccuracy (?!)'},
    'mistake_move': {'tr': 'Kötü Hamle (?)', 'en': 'Mistake (?)'},
    'blunder_move': {'tr': 'Çok Kötü Hamle (??)', 'en': 'Blunder (??)'},
    'rotate_board': {'tr': 'Tahtayı Çevir', 'en': 'Rotate Board'},
    'share_pgn': {'tr': 'PGN Paylaş', 'en': 'Share PGN'},
    'save_to_library': {'tr': 'Kütüphaneye Ekle', 'en': 'Add to Library'},
    'remove_from_library': {'tr': 'Kütüphaneden Sil', 'en': 'Remove from Library'},
    'analyzing': {'tr': 'Analiz Ediliyor...', 'en': 'Analyzing...'},
    'engine_move': {'tr': 'Motor Analizi', 'en': 'Engine Analysis'},
    'best_move_nav': {'tr': 'En İyi', 'en': 'Best'},
    'excellent_nav': {'tr': 'Mükemmel', 'en': 'Excellent'},
    'good_nav': {'tr': 'İyi', 'en': 'Good'},
    'inaccuracy_nav': {'tr': 'Şüpheli', 'en': 'Inaccuracy'},
    'mistake_nav': {'tr': 'Kötü', 'en': 'Mistake'},
    'blunder_nav': {'tr': 'Çok Kötü', 'en': 'Blunder'},
    'puzzles': {'tr': 'Bulmacalar', 'en': 'Puzzles'},
    'puzzle_leaderboard': {'tr': 'Sıralama', 'en': 'Leaderboard'},
    'puzzle_username_title': {'tr': 'Dünya Sıralaması', 'en': 'Global Ranking'},
    'puzzle_username_hint': {'tr': 'Sıralama için bir kullanıcı adı girin...', 'en': 'Enter a username for the ranking...'},
    'puzzle_start': {'tr': 'Başla', 'en': 'Start'},
    'puzzle_player': {'tr': 'Oyuncu', 'en': 'Player'},
    'puzzle_turn_white': {'tr': 'HAMLE BEYAZDA', 'en': 'WHITE TO MOVE'},
    'puzzle_turn_black': {'tr': 'HAMLE SİYAHTA', 'en': 'BLACK TO MOVE'},
    'puzzle_hint': {'tr': 'İpucu:', 'en': 'Hint:'},
    'puzzle_wrong_move': {'tr': 'Yanlış hamle, tekrar dene!', 'en': 'Wrong move, try again!'},
    'puzzle_solved': {'tr': 'Bulmaca Çözüldü!', 'en': 'Puzzle Solved!'},
    'puzzle_no_solvers': {'tr': 'Henüz kimse bulmaca çözmedi.', 'en': 'No one has solved a puzzle yet.'},
    'puzzle_score_points': {'tr': 'Puan', 'en': 'Points'},
    'login_title': {'tr': 'Bulmacalara Giriş', 'en': 'Puzzle Login'},
    'login_lichess_desc': {'tr': 'Lichess hesabınıza güvenli bir şekilde şifrenizle giriş yapın:', 'en': 'Securely log in with your Lichess account:'},
    'login_lichess_btn': {'tr': 'Lichess İle Giriş Yap', 'en': 'Log In with Lichess'},
    'login_google_desc': {'tr': 'Google hesabınızla güvenli giriş yapın:', 'en': 'Securely log in with your Google account:'},
    'login_google_btn': {'tr': 'Google İle Giriş Yap', 'en': 'Log In with Google'},
    'login_guest_desc': {'tr': 'Veya misafir olarak bir isim girin:', 'en': 'Or enter a name to continue as a guest:'},
    'login_guest_hint': {'tr': 'Misafir Kullanıcı Adı', 'en': 'Guest Username'},
    'login_guest_btn': {'tr': 'Misafir Girişi', 'en': 'Guest Login'},
    'login_failed': {'tr': 'Giriş başarısız oldu!', 'en': 'Login failed!'},
    'login_guest_taken': {'tr': 'Bu isim Lichess, Chess.com veya MoveLab\'da kullanılıyor. Lütfen başka isim girin.', 'en': 'This name is taken on Lichess, Chess.com, or MoveLab. Please enter another name.'},
    'login_guest_conn_err': {'tr': 'Bağlantı hatası!', 'en': 'Connection error!'},
    'settings_login': {'tr': 'Giriş Yap', 'en': 'Log In'},
    'settings_logout': {'tr': 'Çıkış Yap', 'en': 'Log Out'},
    // İhtiyacın oldukça buraya yeni kelimeler ekleyebilirsin...
  };

  // Çeviriyi getiren fonksiyon
  static String get(String key) {
    return _dict[key]?[_currentLang] ?? key; 
  }

  static String displayQualityLabel(String label) {
    if (_currentLang != 'en') return label;
    switch (label) {
      case 'Etkileyici':
        return 'Brilliant';
      case 'Harika':
        return 'Great';
      case 'En İyi':
      case 'En İyi Hamle':
        return 'Best';
      case 'Mükemmel':
        return 'Excellent';
      case 'İyi':
      case 'İyi Hamle':
        return 'Good';
      case 'Şüpheli':
      case 'Şüpheli Hamle':
        return 'Inaccuracy';
      case 'Kötü':
      case 'Kötü Hamle':
        return 'Mistake';
      case 'Çok Kötü':
      case 'Çok Kötü Hamle':
        return 'Blunder';
      default:
        return label;
    }
  }

  static String tempoLabel(String tempo) {
    if (tempo == 'all') return get('all');
    return tempo.toUpperCase();
  }

  static String styleLabel(String label) {
    switch (label) {
      case 'Dengeli':
        return _currentLang == 'en' ? 'Balanced' : 'Dengeli';
      case 'Agresif Oyuncu':
      case '🔥 Agresif Oyuncu':
        return _currentLang == 'en' ? 'Aggressive Player' : 'Agresif Oyuncu';
      case 'Defansif Oyuncu':
      case '🛡️ Defansif Oyuncu':
        return _currentLang == 'en' ? 'Defensive Player' : 'Defansif Oyuncu';
      case 'Taktik Ustası':
      case '⚔️ Taktik Ustası':
        return _currentLang == 'en' ? 'Tactical Master' : 'Taktik Ustası';
      case 'Pozisyonel Oyuncu':
      case '🧠 Pozisyonel Oyuncu':
        return _currentLang == 'en' ? 'Positional Player' : 'Pozisyonel Oyuncu';
      case 'Açılış Uzmanı':
      case '🎯 Açılış Uzmanı':
        return _currentLang == 'en' ? 'Opening Specialist' : 'Açılış Uzmanı';
      case 'Risk Alan':
      case '🎲 Risk Alan':
        return _currentLang == 'en' ? 'Risk Taker' : 'Risk Alan';
      default:
        return label;
    }
  }
}

Future<void> showSettingsSheet(BuildContext context, {VoidCallback? onChanged}) async {
  final prefs = await SharedPreferences.getInstance();
  String? currentUsername = prefs.getString('puzzle_username');

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF151B2B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LanguageService.get('settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(currentUsername != null ? Icons.logout : Icons.login, color: Colors.blueAccent),
                  title: Text(currentUsername != null ? '${LanguageService.get('settings_logout')} ($currentUsername)' : LanguageService.get('settings_login'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  onTap: () async {
                    if (currentUsername != null) {
                      await prefs.remove('puzzle_username');
                      await prefs.remove('puzzle_user_title');
                      await prefs.remove('puzzle_user_patron');
                      currentUsername = null;
                      setModalState(() {});
                      onChanged?.call();
                    } else {
                      Navigator.pop(context); // Kapatıp login aç
                      Map<String, String?>? inputData = await showGlobalLoginDialog(context);
                      if (inputData != null && inputData['username'] != null) {
                        String newName = inputData['username']!.trim();
                        if (newName.toLowerCase() == 'termo_x') inputData['title'] = 'TermoGM';
                        
                        await prefs.setString('puzzle_username', newName);
                        if (inputData['title'] != null) await prefs.setString('puzzle_user_title', inputData['title']!);
                        if (inputData['patron'] == 'true') await prefs.setBool('puzzle_user_patron', true);
                        
                        await GlobalLibrary.syncWithCloud(newName);
                        onChanged?.call();
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.white70),
                  title: Text(LanguageService.get('language'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  trailing: DropdownButton<String>(
                    value: LanguageService.currentLang,
                    dropdownColor: const Color(0xFF151B2B),
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'tr', child: Text(LanguageService.get('turkish'), style: const TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'en', child: Text(LanguageService.get('english'), style: const TextStyle(color: Colors.white))),
                    ],
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await LanguageService.setLanguage(newValue);
                        onChanged?.call();
                        setModalState(() {});
                      }
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note, color: Colors.white70),
                  title: Text(LanguageService.get('piece_sounds'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  activeThumbColor: const Color(0xFF64FFDA),
                  value: !SoundService.isMuted,
                  onChanged: (val) { SoundService.setMuted(!val); setModalState(() {}); onChanged?.call(); },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.call_made, color: Colors.white70),
                  title: Text(LanguageService.get('show_arrows'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  activeThumbColor: const Color(0xFF64FFDA),
                  value: SoundService.showArrows,
                  onChanged: (val) { SoundService.setShowArrows(val); setModalState(() {}); onChanged?.call(); },
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.volume_down, color: SoundService.isMuted ? Colors.white24 : Colors.white70),
                      Expanded(child: Slider(value: SoundService.volume, activeColor: const Color(0xFF64FFDA), inactiveColor: Colors.white12, onChanged: SoundService.isMuted ? null : (val) { SoundService.setVolume(val); setModalState(() {}); onChanged?.call(); })),
                      Icon(Icons.volume_up, color: SoundService.isMuted ? Colors.white24 : Colors.white70),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}

// =====================================================================
// 1. PROFESYONEL SATRANÇ ALGORİTMALARI (STATE TRANSITION & COMPLEXITY)
// =====================================================================

class AccuracyCalculator {
  static const int mateCentipawn = 1500;
  static double evalToWinPercent(double cp) => 50.0 + 50.0 * (2.0 / (1.0 + exp(-0.00368208 * cp)) - 1.0);
  static double cpFromEval(double eval, bool isMate) {
    if (isMate || eval.abs() > 14.0) return eval.isNegative ? -mateCentipawn.toDouble() : mateCentipawn.toDouble();
    return eval * 100.0;
  }
  static double calculateMoveAccuracy(double bestEval, double playedEval, bool isWhiteMove, bool isBeforeMate, bool isAfterMate) {
    double cpBest = cpFromEval(bestEval, isBeforeMate);
    double cpPlayed = cpFromEval(playedEval, isAfterMate);
    double bestWin = evalToWinPercent(cpBest);
    double playedWin = evalToWinPercent(cpPlayed);
    double winPercentLoss = isWhiteMove ? (bestWin - playedWin) : (playedWin - bestWin);
    if (winPercentLoss <= 0) return 100.0;
    double accuracy = 103.1668 * exp(-0.04354 * winPercentLoss) - 3.1669;
    return accuracy.clamp(0.0, 100.0);
  }
}

class PositionAnalyzer {
  // 1. STATE TRANSITION MANTIĞI
  static String getState(double eval) {
    if (eval >= 3.0) return 'winning';
    if (eval >= 1.0) return 'better';
    if (eval > -1.0 && eval < 1.0) return 'equal';
    if (eval <= -1.0 && eval > -3.0) return 'worse';
    return 'losing';
  }

  // 2. POSITION COMPLEXITY (KARMAŞIKLIK)
  static double getComplexity(List<double> alternatives) {
    if (alternatives.isEmpty || alternatives.length < 2) return 0.0;

    // En iyi hamle ile diğerleri arasındaki farklara bakıyoruz
    double topGap = (alternatives[0] - alternatives[1]).abs();
    
    // Eğer ilk iki hamle birbirine çok yakınsa (örneğin ikisi de +0.2), pozisyon karmaşıktır.
    // Eğer ilk hamle +5, ikinci hamle -2 ise, pozisyon çok basittir (tek hamle).
    double complexity = 0.0;
    
    if (topGap < 0.5) {
      complexity += 5.0; // Çok karmaşık
    } else if (topGap < 1.5) complexity += 3.0; // Orta karmaşık
    else complexity += 1.0; // Basit

    // Motorun bulduğu alternatiflerin ne kadarı birbirine yakın? (Taktiksel yoğunluk)
    int nearMoves = alternatives.where((e) => (alternatives[0] - e).abs() < 1.0).length;
    complexity += nearMoves * 1.5;

    return complexity.clamp(0.0, 10.0);
  }

  // 3. HUMAN DIFFICULTY & ONLY MOVE
  static bool isForced(List<double> alternatives) {
    if (alternatives.length < 2) return true;
    double best = alternatives[0];
    double second = alternatives[1];

    // İki hamle de kazandırıyorsa (örn: +7 ve +5) tek hamle değildir.
    if (best > 3.0 && second > 2.0) return false;
    
    // Aradaki fark çok büyükse ve ikinci hamle kazandırmıyorsa, bu zorunlu tek hamledir.
    double gap = (best - second).abs();
    return gap >= 2.5; 
  }
}

class TacticalDetector {
  static const Map<String, int> _pieceValues = {
    'p': 1, 'n': 3, 'b': 3, 'r': 5, 'q': 9, 'k': 100
  };

  static String? _pieceAt(String fen, String sq) {
    if (sq.length != 2) return null;
    int file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rank = 8 - int.parse(sq[1]);
    String board = fen.split(' ')[0];
    List<String> rows = board.split('/');
    if (rank < 0 || rank >= rows.length) return null;
    String row = rows[rank];
    int currentFile = 0;
    for (int i = 0; i < row.length; i++) {
      String c = row[i];
      if (RegExp(r'[1-8]').hasMatch(c)) {
        currentFile += int.parse(c);
      } else {
        if (currentFile == file) return c;
        currentFile++;
      }
    }
    return null;
  }

  static int _countMaterial(String fen, bool isWhite) {
    int total = 0;
    String board = fen.split(' ')[0];
    for (int i = 0; i < board.length; i++) {
      String c = board[i];
      if (!_pieceValues.containsKey(c.toLowerCase())) continue;
      bool pieceIsWhite = c == c.toUpperCase();
      if (pieceIsWhite == isWhite) {
        total += _pieceValues[c.toLowerCase()]!;
      }
    }
    return total;
  }

  static int detectSacrificeType(
    int index,
    List<String> fenList,
    bool isWhiteMove,
    double playedEval,
    double bestEval,
  ) {
    if (index + 1 >= fenList.length) return 0;

    try {
      // KRİTİK FİLTRE: Kayıp Pozisyonda Feda Olmaz! (Desperado Engeli)
      // Eğer hamleyi yapan oyuncu, hamleden sonra 3 puan gerideyse veya mat oluyorsa
      // yaptığı hiçbir taş fedası "Etkileyici" sayılamaz.
      double playerEvalAfter = isWhiteMove ? playedEval : -playedEval;
      if (playerEvalAfter <= -3.0) return 0;

      String beforeFen = fenList[index];
      String afterFen = fenList[index + 1];

      bool isMate = bestEval.abs() > 14.0 || playedEval.abs() > 14.0;
      bool engineApproves = (playedEval - bestEval).abs() <= 1.5 || isMate;

      if (!engineApproves) return 0;

      int myBefore = _countMaterial(beforeFen, isWhiteMove);
      int myAfter = _countMaterial(afterFen, isWhiteMove);
      int oppBefore = _countMaterial(beforeFen, !isWhiteMove);
      int oppAfter = _countMaterial(afterFen, !isWhiteMove);

      int materialCapturedByUs = oppBefore - oppAfter;
      int materialLostByUs = myBefore - myAfter;

      // 1. DİREKT (ANINDA YENEN) FEDALAR
      int netLoss = materialLostByUs - materialCapturedByUs;
      if (netLoss > 0) {
        if (netLoss >= 5) return 3; 
        if (netLoss >= 3) return 2; 
        return 1; 
      }

      // 2. DOLAYLI FEDA / BOŞTA TAŞ SİMÜLASYONU
      chess_engine.Chess chess = chess_engine.Chess();
      chess.load(afterFen);
      List<String> legalSanMoves = List<String>.from(chess.moves());

      int maxSacrificeFound = 0;

      for (String san in legalSanMoves) {
        if (san.contains('x')) {
          String cleanSan = san.replaceAll('+', '').replaceAll('#', '');
          String targetSq = cleanSan.substring(cleanSan.length - 2);
          String? victimStr = _pieceAt(afterFen, targetSq);

          if (victimStr != null) {
            bool pieceIsWhite = victimStr == victimStr.toUpperCase();
            
            if (pieceIsWhite == isWhiteMove) {
              int victimVal = _pieceValues[victimStr.toLowerCase()] ?? 0;
              
              int attackerVal = 1; 
              if (san[0] == 'N' || san[0] == 'B') {
                attackerVal = 3;
              } else if (san[0] == 'R') attackerVal = 5;
              else if (san[0] == 'Q') attackerVal = 9;
              else if (san[0] == 'K') attackerVal = 100;

              bool isProtected = false;
              chess.move(san); 
              List<String> ourResponses = List<String>.from(chess.moves());
              for (String response in ourResponses) {
                if (response.contains('x')) {
                  String cleanResponse = response.replaceAll('+', '').replaceAll('#', '');
                  if (cleanResponse.length >= 2) {
                    String ourTargetSq = cleanResponse.substring(cleanResponse.length - 2);
                    if (ourTargetSq == targetSq) {
                      isProtected = true;
                      break;
                    }
                  }
                }
              }
              chess.undo(); 

              int estimatedRecapture = 0;
              if (isProtected && attackerVal != 100) {
                estimatedRecapture = attackerVal;
              }

              int totalLostIfCaptured = materialLostByUs + victimVal;
              int totalGained = materialCapturedByUs + estimatedRecapture;
              
              int projectedNetLoss = totalLostIfCaptured - totalGained;

              if (projectedNetLoss > 0) {
                int currentSacType = 0;
                if (projectedNetLoss >= 3) {
                  currentSacType = 3;
                } else if (projectedNetLoss == 2) currentSacType = 2; 
                else currentSacType = 1; 

                if (currentSacType > maxSacrificeFound) {
                  maxSacrificeFound = currentSacType;
                }
              }
            }
          }
        }
      }
      return maxSacrificeFound;
    } catch (e) {
      debugPrint("Sacrifice Detection Error: $e");
    }
    return 0;
  }
}

class AdvancedClassifier {
  static String classifyMove({
    required double bestEval,
    required double playedEval,
    required double accuracy,
    required List<double> alternatives,
    required bool isWhiteMove,
    required bool isMateFound,
    required int sacrificeType,
  }) {
    double evalBefore = isWhiteMove ? bestEval : -bestEval;
    double evalAfter = isWhiteMove ? playedEval : -playedEval;
    
    String stateBefore = PositionAnalyzer.getState(evalBefore);
    String stateAfter = PositionAnalyzer.getState(evalAfter);
    
    double complexity = PositionAnalyzer.getComplexity(alternatives);
    bool forcedMove = PositionAnalyzer.isForced(alternatives);
    
    // Mat kimin lehine/aleyhine bunu ayırıyoruz
    bool isMate = bestEval.abs() > 14.0 || playedEval.abs() > 14.0 || isMateFound;
    bool playerDeliversMate = evalAfter > 14.0; 
    bool playerReceivesMate = evalAfter < -14.0; 
    
    double evalLoss = (bestEval - playedEval).abs();
    
    // Sadece mat EDİYORSAK ufak eval sapmalarını affet. Mat OLUYORSAK affetme!
    bool nearBest = evalLoss <= 0.35 || playerDeliversMate; 
    bool perfectMove = evalLoss <= 0.15;

    // =====================================================
    // 1. BRILLIANT (!!) MANTIĞI
    // =====================================================
    // Sadece simülasyondan geçmiş net feda varsa ve mat OLMUYORSAK
    if (sacrificeType >= 3 && nearBest && !playerReceivesMate) {
      return "Etkileyici Hamle";
    }

    // =====================================================
    // 2. GREAT MOVE (!) MANTIĞI
    // =====================================================
    if (!playerReceivesMate && (
        (sacrificeType == 2 && nearBest) ||
        (sacrificeType == 1 && nearBest && complexity >= 3.0) || 
        (forcedMove && nearBest && !isMate && complexity >= 3.0)
       )) {
      return "Harika Hamle";
    }

    // =====================================================
    // 3. BLUNDER / MISTAKE - STATE TRANSITION
    // =====================================================
    if (stateBefore == 'winning' && (stateAfter == 'equal' || stateAfter == 'losing' || stateAfter == 'worse')) {
      return "Çok Kötü Hamle";
    }
    if (stateBefore == 'equal' && stateAfter == 'losing') {
      return "Çok Kötü Hamle";
    }
    if (stateBefore == 'better' && (stateAfter == 'worse' || stateAfter == 'losing')) {
      return "Kötü Hamle";
    }
    
    // =====================================================
    // 4. STANDART DOĞRULUK YÜZDESİ
    // =====================================================
    if (playerDeliversMate || perfectMove || accuracy >= 99.0) return "En İyi Hamle";
    if (accuracy >= 95.0) return "Mükemmel";
    if (accuracy >= 88.0) return "İyi Hamle";
    if (accuracy >= 75.0) return "Şüpheli Hamle";
    if (accuracy >= 50.0) return "Kötü Hamle";
    
    return "Çok Kötü Hamle"; 
  }
}

class AnalysisPhaseWeight {
  static double getWeight(int moveIndex) {
    int moveNumber = (moveIndex ~/ 2) + 1;
    if (moveNumber <= 10) return 0.35; 
    if (moveNumber <= 25) return 0.65; 
    if (moveNumber <= 40) return 1.0;  
    return 1.25;                           
  }
}

class MoveAnalysis {
  final double bestEval;
  final double playedEval;
  final double accuracy;
  final String qualityLabel;
  final bool isBrilliant;
  final bool isGreat;

  MoveAnalysis({
    required this.bestEval, required this.playedEval,
    required this.accuracy, required this.qualityLabel,
    required this.isBrilliant, required this.isGreat,
  });
}

// =====================================================================
// 2. KÜTÜPHANE & HAFIZA
// =====================================================================

class SavedMatch {
  final String title, whiteName, blackName, whiteTitle, blackTitle, pgn, moves, speed, winner, platform;
  final PlayerColor userColor;
  final int whiteRating, blackRating;

  SavedMatch({
    required this.title, required this.pgn, required this.speed,
    this.whiteName = 'Beyaz', this.blackName = 'Siyah',
    this.whiteTitle = '', this.blackTitle = '',
    this.moves = '', this.winner = 'draw', this.userColor = PlayerColor.white,
    this.whiteRating = 0, this.blackRating = 0, this.platform = 'Bilinmiyor',
  });

  Map<String, dynamic> toJson() => {
    'title': title, 'whiteName': whiteName, 'blackName': blackName,
    'whiteTitle': whiteTitle, 'blackTitle': blackTitle,
    'pgn': pgn, 'moves': moves, 'speed': speed,
    'winner': winner, 'userColor': userColor == PlayerColor.white ? 'w' : 'b',
    'whiteRating': whiteRating, 'blackRating': blackRating, 'platform': platform
  };

  factory SavedMatch.fromJson(Map<String, dynamic> json) {
    String wName = json['whiteName'] ?? 'Beyaz';
    String bName = json['blackName'] ?? 'Siyah';
    
    if (json['whiteName'] == null && json['title'] != null) {
      List<String> parts = json['title'].split(' vs ');
      wName = parts.isNotEmpty ? parts[0] : 'Beyaz';
      bName = parts.length > 1 ? parts[1] : 'Siyah';
    }

    return SavedMatch(
      title: json['title'] ?? '$wName vs $bName',
      whiteName: wName, blackName: bName,
      whiteTitle: json['whiteTitle'] ?? '', blackTitle: json['blackTitle'] ?? '',
      pgn: json['pgn'] ?? '', moves: json['moves'] ?? '',
      speed: json['speed'] ?? '', winner: json['winner'] ?? 'draw',
      userColor: json['userColor'] == 'b' ? PlayerColor.black : PlayerColor.white,
      whiteRating: json['whiteRating'] ?? 0, blackRating: json['blackRating'] ?? 0,
      platform: json['platform'] ?? 'Bilinmiyor',
    );
  }
}

class GlobalLibrary {
  static List<SavedMatch> matches = [];
  static List<String> searchHistory = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final matchesStr = prefs.getStringList('saved_matches') ?? [];
    matches = matchesStr.map((e) => SavedMatch.fromJson(jsonDecode(e))).toList();
    searchHistory = prefs.getStringList('search_history') ?? [];

    final username = prefs.getString('puzzle_username');
    if (username != null && username.isNotEmpty) {
      syncWithCloud(username);
    }
  }

  static Future<void> saveMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final matchesStr = matches.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('saved_matches', matchesStr);

    final username = prefs.getString('puzzle_username');
    if (username != null && username.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(username.toLowerCase()).set({
          'saved_matches': matchesStr
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud save failed: $e');
      }
    }
  }

  static Future<void> syncWithCloud(String username) async {
    if (username.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(username.toLowerCase()).get();
      if (doc.exists && doc.data()!.containsKey('saved_matches')) {
        List<dynamic> cloudMatchesRaw = doc.data()!['saved_matches'];
        List<SavedMatch> cloudMatches = cloudMatchesRaw.map((e) => SavedMatch.fromJson(jsonDecode(e.toString()))).toList();
        
        // Merge with local matches
        for (var cm in cloudMatches) {
          if (!isSaved(cm.pgn, cm.moves)) {
            matches.add(cm);
          }
        }
        
        // If we added cloud matches locally, or we have local matches not in cloud, sync up.
        // Actually, just call saveMatches() to push the merged list everywhere.
        await saveMatches();
      } else {
        // First time syncing, push local matches to cloud
        await saveMatches();
      }
    } catch (e) {
      debugPrint('Cloud sync failed: $e');
    }
  }

  static Future<void> saveSearch(String username) async {
    if (username.trim().isEmpty) { return; }
    searchHistory.removeWhere((name) => name.toLowerCase() == username.toLowerCase());
    searchHistory.insert(0, username.trim());
    if (searchHistory.length > 15) { searchHistory = searchHistory.sublist(0, 15); }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', searchHistory);
  }

  static bool isSaved(String pgn, String moves) {
    if (pgn.isEmpty && moves.isEmpty) { return false; }
    if (pgn.isNotEmpty) { return matches.any((m) => m.pgn == pgn); }
    return matches.any((m) => m.moves == moves);
  }
}

Widget buildUserTags(String title, bool isDonor) {
  List<Widget> tags = []; // Ekrana basılacak etiketleri bu listede toplayacağız
  
  // 1. EĞER UNVANI VARSA (GM, IM vs.) LİSTEYE EKLE
  if (title.trim().isNotEmpty) {
    bool isTermo = title == 'TermoGM';
    String displayTitle = isTermo ? 'GM' : title;
    Color bgColor = isTermo ? const Color(0xFFFFD700).withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.6);
    Color textColor = isTermo ? const Color(0xFFFFD700) : Colors.white;
    Border? border = isTermo ? Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1) : null;

    tags.add(Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(4),
        border: border,
      ),
      child: Text(
        displayTitle.toUpperCase(), 
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)
      ),
    ));
  }

  // 2. EĞER BAĞIŞÇIYSA DONÖR ETİKETİNİ LİSTEYE EKLE
  if (isDonor) {
    tags.add(Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.6), width: 1),
      ),
      child: const Text(
        'ELİTE 💎',
        style: TextStyle(color: Color(0xFFFF9800), fontSize: 10, fontWeight: FontWeight.bold)
      ),
    ));
  }

  // Eğer listede hiçbir etiket yoksa boşluk döndür, varsa yan yana (Row) diz
  if (tags.isEmpty) return const SizedBox.shrink();
  return Row(mainAxisSize: MainAxisSize.min, children: tags);
}

Widget buildTitleTag(String title) {
  if (title.trim().isEmpty) { return const SizedBox.shrink(); }
  
  bool isTermo = title == 'TermoGM';
  String displayTitle = isTermo ? 'GM' : title;
  Color bgColor = isTermo ? const Color(0xFFFFD700).withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.6);
  Color textColor = isTermo ? const Color(0xFFFFD700) : Colors.white;
  Border? border = isTermo ? Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1) : null;

  return Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor, 
      borderRadius: BorderRadius.circular(4),
      border: border,
    ),
    child: Text(
      displayTitle.toUpperCase(), 
      style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)
    ),
  );
}
// =====================================================================
// 3. YEREL STOCKFISH MOTORU
// =====================================================================

class ChessEngineService {
  static final ChessEngineService _instance = ChessEngineService._internal();
  factory ChessEngineService() => _instance;

  Stockfish? _stockfish;
  StreamSubscription? _outputSubscription;
  Completer<Map<String, dynamic>>? _evaluationCompleter;
  Completer<void>? _readyCompleter; 
  Function(Map<String, dynamic>)? _onContinuousUpdate;
  
  Map<String, dynamic> _currentEvalData = {};
  bool _isMultiPvSet = false;
  bool _isWhiteToMove = true; 

  ChessEngineService._internal();

  void initEngine() {
    if (_stockfish != null) { return; }
    try {
      _stockfish = Stockfish();
      _outputSubscription = _stockfish!.stdout.listen(_parseEngineOutput);
    } catch (e) {
      debugPrint("Stockfish başlatılamadı: $e");
    }
  }

  void stopEngine() {
    try {
      if (_stockfish?.state.value == StockfishState.ready) {
        _stockfish!.stdin = 'stop';
      }
    } catch (_) {}
  }

  Future<void> _waitForReady() async {
    if (_stockfish == null) { throw Exception("Stockfish başlatılmadı."); }
    int timeout = 0;
    while (_stockfish!.state.value == StockfishState.starting && timeout < 100) {
      await Future.delayed(const Duration(milliseconds: 20));
      timeout++;
    }
    
    if (!_isMultiPvSet && _stockfish!.state.value == StockfishState.ready) {
      try {
        _stockfish!.stdin = 'setoption name Threads value 2'; 
        _stockfish!.stdin = 'setoption name Hash value 64'; 
        _stockfish!.stdin = 'setoption name MultiPV value 8'; // PROFESYONEL DERİNLİK İÇİN 8 YAPINIZ (5 HIZLI VE İDEAL)
        _stockfish!.stdin = 'setoption name Ponder value false';
        _isMultiPvSet = true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  void _parseEngineOutput(String output) {
    try {
      if (output == 'readyok') {
        if (_readyCompleter != null && !_readyCompleter!.isCompleted) _readyCompleter!.complete();
        return;
      }

      if (output.startsWith('info depth') && !output.contains('currmove')) {
        int multipv = 1;
        final pvMatch = RegExp(r'multipv (\d+)').firstMatch(output);
        if (pvMatch != null) multipv = int.parse(pvMatch.group(1)!);

        double val = 0.0; bool isMate = false;
        final cpMatch = RegExp(r'score cp (-?\d+)').firstMatch(output);
        final mateMatch = RegExp(r'score mate (-?\d+)').firstMatch(output);
        
        if (cpMatch != null) {
          double rawVal = int.parse(cpMatch.group(1)!) / 100.0;
          val = _isWhiteToMove ? rawVal : -rawVal;
        } else if (mateMatch != null) {
          isMate = true; int mateIn = int.parse(mateMatch.group(1)!);
          double rawVal = mateIn > 0 ? 15.0 : -15.0; 
          val = _isWhiteToMove ? rawVal : -rawVal;
        }

        String pvMoves = output.contains(' pv ') ? output.split(' pv ').last.trim() : '';
        String firstMove = pvMoves.isNotEmpty ? pvMoves.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => '') : '';

        _currentEvalData['alternatives'] ??= <double>[0.0, 0.0, 0.0, 0.0, 0.0];
        _currentEvalData['suggestions'] ??= <String>['', '', '', '', ''];
        
        List<double> alts = _currentEvalData['alternatives'];
        List<String> suggs = _currentEvalData['suggestions'];

        if (multipv >= 1 && multipv <= 5) {
           while (alts.length < multipv) {
             alts.add(0.0);
           }
           while (suggs.length < multipv) {
             suggs.add('');
           }
           alts[multipv - 1] = val; suggs[multipv - 1] = firstMove;
        }

        if (multipv == 1) {
          _currentEvalData['best_eval'] = val;
          _currentEvalData['is_mate'] = isMate;
        }
        if (_onContinuousUpdate != null) _onContinuousUpdate!(Map<String, dynamic>.from(_currentEvalData));
      }

      if (output.startsWith('bestmove')) {
        final bestMoveMatch = RegExp(r'bestmove (\S+)').firstMatch(output);
        if (bestMoveMatch != null) _currentEvalData['bestmove'] = bestMoveMatch.group(1);
        if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted) {
          _evaluationCompleter!.complete(_currentEvalData); _evaluationCompleter = null;
        }
      }
    } catch (e) { debugPrint("Motor Parse Hatası: $e"); }
  }

  Future<void> startContinuousAnalysis(String fen, Function(Map<String, dynamic>) onUpdate) async {
    await _waitForReady(); _onContinuousUpdate = null; stopEngine();
    _readyCompleter = Completer<void>();
    if (_stockfish?.state.value == StockfishState.ready) {
      _stockfish!.stdin = 'isready';
      try { await _readyCompleter!.future.timeout(const Duration(milliseconds: 250)); } catch (_) {}
    }
    _isWhiteToMove = fen.split(' ')[1] == 'w'; _onContinuousUpdate = onUpdate;
    _currentEvalData = { 'alternatives': <double>[0.0, 0.0, 0.0, 0.0, 0.0], 'suggestions': <String>['', '', '', '', ''] };
    if (_stockfish?.state.value == StockfishState.ready) {
      _stockfish!.stdin = 'position fen $fen'; _stockfish!.stdin = 'go infinite'; 
    }
  }

  void stopContinuousAnalysis() { _onContinuousUpdate = null; stopEngine(); }

  Future<Map<String, dynamic>> evaluateFen(String fen, {int depth = 20, int maxTimeMs = 1200}) async {
    await _waitForReady(); _onContinuousUpdate = null; 
    if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted) _evaluationCompleter!.completeError("İptal edildi");
    _evaluationCompleter = null; stopEngine();
    _readyCompleter = Completer<void>();
    if (_stockfish?.state.value == StockfishState.ready) {
      _stockfish!.stdin = 'isready';
      try { await _readyCompleter!.future.timeout(const Duration(milliseconds: 250)); } catch (_) {}
    }
    _isWhiteToMove = fen.split(' ')[1] == 'w';
    _currentEvalData = { 'alternatives': <double>[0.0, 0.0, 0.0, 0.0, 0.0], 'suggestions': <String>['', '', '', '', ''] };
    _evaluationCompleter = Completer<Map<String, dynamic>>();

    try {
      if (_stockfish?.state.value == StockfishState.ready) {
        _stockfish!.stdin = 'position fen $fen'; _stockfish!.stdin = 'go movetime $maxTimeMs'; 
        Timer(Duration(milliseconds: maxTimeMs), () {
          if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted) stopEngine();
        });
      } else { _evaluationCompleter!.completeError("Motor hazır değil"); }
    } catch (e) {
      if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted) _evaluationCompleter!.completeError(e); 
    }
    return await _evaluationCompleter!.future.timeout(const Duration(seconds: 4), onTimeout: () {
      if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted) _evaluationCompleter!.completeError("Zaman Aşımı");
      return {};
    });
  }

  void dispose() {
    _outputSubscription?.cancel(); stopEngine();
    try { if (_stockfish?.state.value == StockfishState.ready) _stockfish?.stdin = 'quit'; } catch (_) {}
    _stockfish?.dispose(); _stockfish = null; _isMultiPvSet = false;
  }
}

// =====================================================================
// 4. OYUNCU PROFİLİ VE STİL ANALİZİ
// =====================================================================

class PlayerStyleProfile {
  final int aggressive;
  final int defensive;
  final int tactical;
  final int positional;
  final int opening;
  final int risk;
  final String mainStyle;
  final String mainIcon;
  final List<String> subStyles;

  PlayerStyleProfile({
    required this.aggressive, required this.defensive, required this.tactical,
    required this.positional, required this.opening, required this.risk,
    required this.mainStyle, required this.mainIcon, required this.subStyles,
  });
}

class StyleConfig {
  static const double aggActionWeight = 0.35;
  static const double aggSpeedWeight = 0.25;
  static const double aggShortWinWeight = 0.25;
  static const double aggGambitWeight = 0.15;
  
  static const double defEndgameWeight = 0.40;
  static const double defPassiveWeight = 0.30;
  static const double defAccWeight = 0.30;
  
  static const double tacActionWeight = 0.30;
  static const double tacAccWeight = 0.40;
  static const double tacShortWinWeight = 0.30;
  
  static const double posEndgameWeight = 0.35;
  static const double posAccWeight = 0.45;
  static const double posPassiveWeight = 0.20;
  
  static const double rskChaosWeight = 0.40;
  static const double rskGambitWeight = 0.30;
  static const double rskShortWinWeight = 0.30;
}

class StyleNormalizer {
  static int scale(double val, double minRaw, double maxRaw, double minOut, double maxOut, int rating) {
    // 1. Oyuncunun o stildeki ham başarısını (0.0 - 1.0 arası) hesapla
    double ratio = (val - minRaw) / (maxRaw - minRaw);
    ratio = ratio.clamp(0.0, 1.0);

    // 2. Dinamik Limitler
    double dynamicFloor = 5.0;
    double potentialCeiling = 99.0;

    if (rating > 0) {
      // Zayıf yönler için düşebileceği minimum taban (GM'ler için maks ~60'ta durur)
      dynamicFloor = (rating / 2500.0) * 55.0;
      dynamicFloor = dynamicFloor.clamp(10.0, 60.0);

      // Çıkabileceği maksimum tavan kapasitesi (GM'ler için 99, 1000 ELO için ~60)
      potentialCeiling = (rating / 2500.0) * 100.0 + 20.0;
      potentialCeiling = potentialCeiling.clamp(40.0, 99.0);
    }

    // 3. Güçlü yönleri parlatmak için "Yetenek Sıçraması (Boost)"
    double boost = 0.0;
    if (ratio > 0.5) {
        // Eğer bu özellik oyuncunun güçlü yönüyse (ratio > 0.5), ELO'ya bağlı olarak yukarı doğru fırlat!
        boost = (ratio - 0.5) * 2.0 * (rating / 2500.0) * 25.0; // Güçlü yönlere 25 puana kadar ekstra sıçrama
    }

    // 4. Temel puanı taban ve tavan arasında dağıt
    double baseScore = dynamicFloor + (ratio * (potentialCeiling - dynamicFloor));

    // 5. Sıçramayı (boost) ekle ve skoru sonlandır
    double finalScore = baseScore + boost;

    return finalScore.clamp(dynamicFloor, 99.0).toInt();
  }
}
class PlayerStyleAnalyzer {
  static PlayerStyleProfile analyze(String username, List<dynamic> games, int rating) {
    if (games.isEmpty) {
      return PlayerStyleProfile(aggressive: 50, defensive: 50, tactical: 50, positional: 50, opening: 50, risk: 50, mainStyle: "Dengeli", mainIcon: "⚖️", subStyles: []);
    }

    int shortWins = 0, longGames = 0, gambits = 0, positionalOpenings = 0;
    double totalAccuracy = 0; int gamesWithAcc = 0;
    int totalChecks = 0, totalCaptures = 0, totalMoves = 0, wins = 0;

    for (var g in games) {
      bool isWhite = g['white'].toString().toLowerCase() == username.toLowerCase();
      bool isWin = g['winner'] == (isWhite ? 'white' : 'black');
      if (isWin) wins++;
      
      String pgn = g['pgn']?.toString().toLowerCase() ?? '';
      String moves = g['moves']?.toString().toLowerCase() ?? '';
      String fullText = '$pgn $moves';

      if (fullText.contains('gambit') || fullText.contains('sicilian') || fullText.contains('dutch') || fullText.contains('vienna') || fullText.contains('benoni') || fullText.contains('evans') || fullText.contains('morra')) gambits++;
      if (fullText.contains('caro-kann') || fullText.contains('slav') || fullText.contains('petroff') || fullText.contains('london') || fullText.contains('french') || fullText.contains('berlin') || fullText.contains('philidor')) {}
      if (fullText.contains('queen\'s gambit') || fullText.contains('english') || fullText.contains('catalan') || fullText.contains('reti') || fullText.contains('nimzo') || fullText.contains('bogo') || fullText.contains('pianissimo')) positionalOpenings++;

      int moveCount = 30;
      if (moves.isNotEmpty) {
        moveCount = (moves.trim().split(RegExp(r'\s+')).length / 2).ceil();
      } else {
        var matches = RegExp(r'\d+\.').allMatches(pgn);
        if (matches.isNotEmpty) moveCount = matches.length;
      }
      if (moveCount < 5) moveCount = 5;
      totalMoves += moveCount;

      if (isWin && moveCount <= 25) shortWins++;
      if (moveCount >= 50) longGames++;

      totalChecks += RegExp(r'\+').allMatches(fullText).length;
      totalCaptures += RegExp(r'x').allMatches(fullText).length;

      double acc = isWhite ? (g['whiteAccuracy']?.toDouble() ?? 0.0) : (g['blackAccuracy']?.toDouble() ?? 0.0);
      if (acc > 0) {
        totalAccuracy += acc;
        gamesWithAcc++;
      } else {
        double guessedAcc = 75.0 + (min(20, (50 - moveCount).abs()) * 0.4);
        totalAccuracy += isWin ? min(99.0, guessedAcc + 5.0) : max(40.0, guessedAcc - 10.0);
        gamesWithAcc++;
      }
    }

    int gc = games.length;
    double avgAcc = gamesWithAcc > 0 ? totalAccuracy / gamesWithAcc : 50.0;
    double avgMoves = totalMoves / gc;
    
    double rawAction = (totalCaptures + (totalChecks * 1.5)) / totalMoves;
    double fAction = min(1.0, rawAction / 0.6); 
    
    double fSpeed = max(0.0, min(1.0, (60.0 - avgMoves) / 40.0)); 
    
    double fShortWin = shortWins / gc;
    double fGambit = min(1.0, (gambits / gc) * 2.0); 
    double fAcc = avgAcc / 100.0;
    double fEndgame = longGames / gc;
    double fWin = wins / gc;
    
    double fChaos = min(1.0, (1.0 - fAcc) * fAction * 2.5);

    double aggScore = (fAction * StyleConfig.aggActionWeight) + (fSpeed * StyleConfig.aggSpeedWeight) + (fShortWin * StyleConfig.aggShortWinWeight) + (fGambit * StyleConfig.aggGambitWeight);
    double defScore = (fEndgame * StyleConfig.defEndgameWeight) + ((1.0 - fAction) * StyleConfig.defPassiveWeight) + (fAcc * StyleConfig.defAccWeight);
    double tacScore = (fAction * StyleConfig.tacActionWeight) + (fAcc * StyleConfig.tacAccWeight) + (fShortWin * StyleConfig.tacShortWinWeight);
    double posScore = (fEndgame * StyleConfig.posEndgameWeight) + (fAcc * StyleConfig.posAccWeight) + ((1.0 - fAction) * StyleConfig.posPassiveWeight);
    double rskScore = (fChaos * StyleConfig.rskChaosWeight) + (fGambit * StyleConfig.rskGambitWeight) + (fShortWin * StyleConfig.rskShortWinWeight);
    
    double fPosOpening = positionalOpenings / gc;
    double opnScore = fAcc > 0.75 ? ((fAcc * 0.5) + (fWin * 0.3) + (fPosOpening * 0.2)) : (fAcc * 0.4);

    return _determineStyles(PlayerStyleProfile(
      aggressive: StyleNormalizer.scale(aggScore, 0.20, 0.75, 25, 99, rating),
      defensive: StyleNormalizer.scale(defScore, 0.30, 0.85, 20, 99, rating),
      tactical: StyleNormalizer.scale(tacScore, 0.30, 0.80, 30, 99, rating),
      positional: StyleNormalizer.scale(posScore, 0.35, 0.85, 30, 99, rating),
      opening: StyleNormalizer.scale(opnScore, 0.40, 0.90, 15, 99, rating),
      risk: StyleNormalizer.scale(rskScore, 0.10, 0.65, 15, 99, rating),
      mainStyle: '', mainIcon: '', subStyles: []
    ));
  }

  static PlayerStyleProfile _determineStyles(PlayerStyleProfile p) {
    Map<String, int> scores = {
      '🔥 ${LanguageService.styleLabel('Agresif Oyuncu')}': p.aggressive,
      '🛡️ ${LanguageService.styleLabel('Defansif Oyuncu')}': p.defensive,
      '⚔️ ${LanguageService.styleLabel('Taktik Ustası')}': p.tactical,
      '🧠 ${LanguageService.styleLabel('Pozisyonel Oyuncu')}': p.positional,
      '🎯 ${LanguageService.styleLabel('Açılış Uzmanı')}': p.opening,
      '🎲 ${LanguageService.styleLabel('Risk Alan')}': p.risk,
    };

    var sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    String main = sorted[0].key;
    String icon = main.split(' ')[0];
    String styleName = main.substring(main.indexOf(' ') + 1);
    List<String> subs = [sorted[1].key, sorted[2].key];

    return PlayerStyleProfile(aggressive: p.aggressive, defensive: p.defensive, tactical: p.tactical, positional: p.positional, opening: p.opening, risk: p.risk, mainStyle: styleName, mainIcon: icon, subStyles: subs);
  }
}

// =====================================================================
// 5. ARAYÜZ (UI) VE EKRANLAR
// =====================================================================

void main() async {
  // 1. Flutter'ın motorunu hazır hale getirir (Zaten yazmıştın)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Firebase'i başlat (Terminalden kurduğumuz bağlantıyı okur)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Senin orijinal kodların (Buralara hiç dokunmuyoruz)
  await GlobalLibrary.load();
  await SoundService.init();
  await LanguageService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(const ChessAnalyzerApp());
}

class ChessAnalyzerApp extends StatelessWidget {
  const ChessAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.localeNotifier,
      builder: (context, _, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MoveLab',
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color(0xFF1A237E), primary: const Color(0xFF5C6BC0)),
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            useMaterial3: true,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

Future<bool> checkDonorStatus(String username) async {
  try {
    // Firestore'daki 'users' koleksiyonundan, bu kullanıcı adına sahip belgeyi bul
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(username.toLowerCase())
        .get();

    // Eğer belge varsa ve patron değeri true ise adam bağışçıdır
    if (doc.exists && (doc.data()?['patron'] == true || doc.data()?['isDonor'] == true)) {
      return true;
    }
  } catch (e) {
    debugPrint("Veritabanı hatası: $e");
  }
  return false;
}

enum PuzzleDifficulty {
  easy(0, 1500, 5, 'puzzle_diff_easy'),
  medium(1500, 2000, 10, 'puzzle_diff_medium'),
  hard(2000, 2500, 15, 'puzzle_diff_hard'),
  elite(2500, 4000, 20, 'puzzle_diff_elite');

  final int minRating;
  final int maxRating;
  final int points;
  final String labelKey;

  const PuzzleDifficulty(this.minRating, this.maxRating, this.points, this.labelKey);
}

Future<String?> showGlobalUsernamePicker(BuildContext context) {
    TextEditingController controller = TextEditingController();
    bool isChecking = false;
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151B2B),
              title: const Text('Kullanıcı Adı Seçin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Google hesabınızla giriş yaptınız. Lütfen bulmacalarda kullanmak istediğiniz benzersiz bir isim girin.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı Adı',
                      hintStyle: const TextStyle(color: Colors.white38),
                      errorText: errorText,
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isChecking ? null : () {
                    Navigator.pop(context, null);
                  },
                  child: const Text('İptal', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: isChecking ? null : () async {
                    String name = controller.text.trim();
                    if (name.isEmpty) return;
                    setStateLocal(() {
                      isChecking = true;
                      errorText = null;
                    });
                    try {
                      bool isTaken = false;
                      var doc = await FirebaseFirestore.instance.collection('users').doc(name.toLowerCase()).get();
                      if (doc.exists) isTaken = true;

                      if (!isTaken) {
                        final lichessRes = await http.get(Uri.parse('https://lichess.org/api/user/$name'));
                        if (lichessRes.statusCode == 200) isTaken = true;
                      }

                      if (!isTaken) {
                        final chesscomRes = await http.get(Uri.parse('https://api.chess.com/pub/player/$name'));
                        if (chesscomRes.statusCode == 200) isTaken = true;
                      }

                      if (isTaken) {
                        setStateLocal(() {
                          isChecking = false;
                          errorText = 'Bu isim Lichess, Chess.com veya MoveLab\'da kullanılıyor. Lütfen başka isim seçin.';
                        });
                      } else {
                        if (context.mounted) Navigator.pop(context, name);
                      }
                    } catch (e) {
                      setStateLocal(() {
                        isChecking = false;
                        errorText = 'Bağlantı hatası!';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: isChecking 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Onayla', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

Future<Map<String, String?>?> showGlobalLoginDialog(BuildContext context) {
    TextEditingController guestController = TextEditingController();
    bool isLichessLoading = false;
    bool isGoogleLoading = false;
    bool isGuestLoading = false;
    String? guestErrorText;
    
    return showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151B2B),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(LanguageService.get('login_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(LanguageService.get('login_lichess_desc'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14)
                        ),
                        icon: isLichessLoading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                          : const Text('♞', style: TextStyle(fontSize: 24, color: Colors.black, height: 1.0)),
                        label: Text(LanguageService.get('login_lichess_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: isLichessLoading ? null : () async {
                          setStateDialog(() => isLichessLoading = true);
                          try {
                            // Lichess OAuth PKCE
                            final random = Random.secure();
                            final verifierValues = List<int>.generate(32, (i) => random.nextInt(256));
                            final codeVerifier = base64UrlEncode(verifierValues).replaceAll('=', '');
                            
                            final verifierBytes = utf8.encode(codeVerifier);
                            final challengeDigest = sha256.convert(verifierBytes);
                            final codeChallenge = base64UrlEncode(challengeDigest.bytes).replaceAll('=', '');
                            
                            const clientId = 'chess_analyzer_app';
                            const redirectUri = 'com.chessanalyzer.app://callback';
                            
                            final authUrl = Uri.https('lichess.org', '/oauth', {
                              'response_type': 'code',
                              'client_id': clientId,
                              'redirect_uri': redirectUri,
                              'code_challenge_method': 'S256',
                              'code_challenge': codeChallenge,
                            });
                            
                            final result = await FlutterWebAuth2.authenticate(
                              url: authUrl.toString(),
                              callbackUrlScheme: 'com.chessanalyzer.app',
                            );
                            
                            final code = Uri.parse(result).queryParameters['code'];
                            if (code != null) {
                              final tokenRes = await http.post(
                                Uri.parse('https://lichess.org/api/token'),
                                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                                body: {
                                  'grant_type': 'authorization_code',
                                  'code': code,
                                  'code_verifier': codeVerifier,
                                  'redirect_uri': redirectUri,
                                  'client_id': clientId,
                                },
                              );
                              
                              if (tokenRes.statusCode == 200) {
                                final tokenData = jsonDecode(tokenRes.body);
                                final accessToken = tokenData['access_token'];
                                
                                final profileRes = await http.get(
                                  Uri.parse('https://lichess.org/api/account'),
                                  headers: {'Authorization': 'Bearer $accessToken'},
                                );
                                
                                if (profileRes.statusCode == 200) {
                                  final profileData = jsonDecode(profileRes.body);
                                  String? lTitle = profileData['title'];
                                  String lichessName = profileData['username'].toString();
                                  
                                  var userDoc = await FirebaseFirestore.instance.collection('users').doc(lichessName.toLowerCase()).get();
                                  String patronStr = 'false';
                                  if (!userDoc.exists) {
                                    await FirebaseFirestore.instance.collection('users').doc(lichessName.toLowerCase()).set({
                                      'username': lichessName,
                                      'score': 0,
                                      'patron': false,
                                      'title': lTitle,
                                    });
                                  } else {
                                    var pData = userDoc.data()?['patron'];
                                    if (pData is bool) patronStr = pData ? 'true' : 'false';
                                    else if (pData is String) patronStr = pData;

                                    if (userDoc.data()?['patron'] == null) {
                                      await FirebaseFirestore.instance.collection('users').doc(lichessName.toLowerCase()).set({'patron': false, 'username': lichessName}, SetOptions(merge: true));
                                      patronStr = 'false';
                                    }
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context, <String, String?>{'username': lichessName, 'title': lTitle, 'patron': patronStr});
                                  }
                                  return;
                                }
                              }
                            }
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${LanguageService.get('login_failed')} (Bilinmeyen Hata)')));
                          } catch (e) {
                            debugPrint("Lichess Auth Error: $e");
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}'), duration: const Duration(seconds: 4)));
                          }
                          if (context.mounted) setStateDialog(() => isLichessLoading = false);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Divider(color: Colors.white24),
                    ),
                    // GOOGLE GİRİŞİ
                    Text(LanguageService.get('login_google_desc'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14)
                        ),
                        icon: isGoogleLoading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)) 
                          : Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', width: 24, height: 24),
                        label: Text(LanguageService.get('login_google_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: isGoogleLoading ? null : () async {
                          setStateDialog(() => isGoogleLoading = true);
                          try {
                            final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                            if (googleUser == null) {
                              setStateDialog(() => isGoogleLoading = false);
                              return;
                            }
                            
                            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                            final AuthCredential credential = GoogleAuthProvider.credential(
                              accessToken: googleAuth.accessToken,
                              idToken: googleAuth.idToken,
                            );
                            
                            final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                            final User? user = userCredential.user;
                            
                            if (user != null) {
                              // Eymen'in hesabını otomatik olarak Termo_x yap
                              if (user.email == 'eymencanorman09@gmail.com') {
                                await FirebaseFirestore.instance.collection('users_by_uid').doc(user.uid).set({'username': 'Termo_x'});
                                var userDoc = await FirebaseFirestore.instance.collection('users').doc('termo_x').get();
                                if (!userDoc.exists) {
                                  await FirebaseFirestore.instance.collection('users').doc('termo_x').set({
                                    'username': 'Termo_x',
                                    'score': 0,
                                    'patron': false,
                                    'title': 'TermoGM',
                                  });
                                }
                                if (context.mounted) {
                                  Navigator.pop(context, <String, String?>{'username': 'Termo_x', 'title': 'TermoGM', 'patron': 'false'});
                                }
                                return;
                              }

                                var uidDoc = await FirebaseFirestore.instance.collection('users_by_uid').doc(user.uid).get();
                                if (uidDoc.exists) {
                                  String savedUsername = uidDoc.data()!['username'];
                                  String? title;
                                  String patronStr = 'false';
                                  
                                  var userDoc = await FirebaseFirestore.instance.collection('users').doc(savedUsername.toLowerCase()).get();
                                  if (userDoc.exists) {
                                    title = userDoc.data()?['title'];
                                    var pData = userDoc.data()?['patron'];
                                    if (pData is bool) patronStr = pData ? 'true' : 'false';
                                    else if (pData is String) patronStr = pData;
                                  }
                                  
                                  if (savedUsername.toLowerCase() == 'termo_x') title = 'TermoGM';

                                  if (context.mounted) {
                                    Navigator.pop(context, <String, String?>{'username': savedUsername, 'title': title, 'patron': patronStr});
                                  }
                                return;
                              } else {
                                if (context.mounted) {
                                  String? chosenName = await showGlobalUsernamePicker(context);
                                    if (chosenName != null && chosenName.trim().isNotEmpty) {
                                      await FirebaseFirestore.instance.collection('users_by_uid').doc(user.uid).set({'username': chosenName.trim()});
                                      
                                      // Kayıt olan kişinin ismini hemen 'users' koleksiyonuna da yaz ki misafirler bu ismi alamasın!
                                      var userDoc = await FirebaseFirestore.instance.collection('users').doc(chosenName.trim().toLowerCase()).get();
                                      if (!userDoc.exists) {
                                        await FirebaseFirestore.instance.collection('users').doc(chosenName.trim().toLowerCase()).set({
                                          'username': chosenName.trim(),
                                          'score': 0,
                                          'patron': false,
                                          'title': null,
                                        });
                                      }

                                      if (context.mounted) {
                                        Navigator.pop(context, <String, String?>{'username': chosenName.trim(), 'title': null, 'patron': 'false'});
                                      }
                                      return;
                                  } else {
                                    await FirebaseAuth.instance.signOut();
                                    await GoogleSignIn().signOut();
                                  }
                                }
                              }
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google girişi başarısız: $e'), backgroundColor: Colors.redAccent));
                          }
                          if (context.mounted) setStateDialog(() => isGoogleLoading = false);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Divider(color: Colors.white24),
                    ),
                    Text(LanguageService.get('login_guest_desc'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: guestController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: LanguageService.get('login_guest_hint'),
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.person, color: Colors.grey),
                        errorText: guestErrorText,
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      onChanged: (value) {
                        if (guestErrorText != null) {
                          setStateDialog(() => guestErrorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0), foregroundColor: Colors.white),
                        onPressed: isGuestLoading ? null : () async {
                          if (guestController.text.trim().isNotEmpty) {
                            setStateDialog(() {
                              isGuestLoading = true;
                              guestErrorText = null;
                            });
                            String guestName = guestController.text.trim();
                            
                            // Misafir girişinde isim dolu mu diye veritabanından ve API'lerden bak (Termo_x hariç)
                            if (guestName.toLowerCase() != 'termo_x') {
                              try {
                                bool isTaken = false;
                                
                                // 1. Firebase (MoveLab) Kontrolü
                                var doc = await FirebaseFirestore.instance.collection('users').doc(guestName.toLowerCase()).get();
                                if (doc.exists) isTaken = true;

                                // 2. Lichess Kontrolü
                                if (!isTaken) {
                                  final lichessRes = await http.get(Uri.parse('https://lichess.org/api/user/$guestName'));
                                  if (lichessRes.statusCode == 200) isTaken = true;
                                }

                                // 3. Chess.com Kontrolü
                                if (!isTaken) {
                                  final chesscomRes = await http.get(Uri.parse('https://api.chess.com/pub/player/$guestName'));
                                  if (chesscomRes.statusCode == 200) isTaken = true;
                                }

                                if (isTaken) {
                                  setStateDialog(() {
                                    guestErrorText = LanguageService.get('login_guest_taken');
                                    isGuestLoading = false;
                                  });
                                  return;
                                }
                              } catch (e) {
                                setStateDialog(() {
                                  guestErrorText = LanguageService.get('login_guest_conn_err');
                                  isGuestLoading = false;
                                });
                                return;
                              }
                            }

                            // Misafir olarak Termo_x girilirse yine Easter Egg çalışsın
                            if (guestName.toLowerCase() == 'termo_x') {
                              if (context.mounted) Navigator.pop(context, <String, String?>{'username': guestName, 'title': 'TermoGM', 'patron': 'false'});
                            } else {
                              // Veritabanına kaydet (Eğer yoksa)
                              var userDoc = await FirebaseFirestore.instance.collection('users').doc(guestName.toLowerCase()).get();
                              if (!userDoc.exists) {
                                await FirebaseFirestore.instance.collection('users').doc(guestName.toLowerCase()).set({
                                  'username': guestName,
                                  'score': 0,
                                });
                              }
                              if (context.mounted) Navigator.pop(context, <String, String?>{'username': guestName, 'title': null, 'patron': 'false'});
                            }
                            if (context.mounted) setStateDialog(() => isGuestLoading = false);
                          }
                        },
                        child: isGuestLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(LanguageService.get('login_guest_btn')),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

class PuzzlesPage extends StatefulWidget {
  const PuzzlesPage({super.key});

  @override
  State<PuzzlesPage> createState() => _PuzzlesPageState();
}

class _PuzzlesPageState extends State<PuzzlesPage> {
  late ChessBoardController controller;
  final chess_engine.Chess _validationChess = chess_engine.Chess();
  
  List<String> solutionMoves = [];
  int currentMoveIndex = 0;
  bool isSolved = false;
  bool isLoading = true;
  bool isWhiteToMove = true; // Hamle sırasını tutacak değişken
  String puzzleId = "";
  String username = "";
  int? puzzleRating; // API'den gelen zorluk puanı
  String? puzzleThemes; // API'den gelen temalar
  bool _hasFailedCurrentPuzzle = false; // Bulmacada hata yapılıp yapılmadığını izler
  PuzzleDifficulty currentDifficulty = PuzzleDifficulty.hard;
  String? _userTitle;
  bool _isPatron = false;

  // İleride burayı Lichess veri tabanından binlerce ID ile doldurabilirsin.
  // Bunlar gerçek Lichess bulmaca ID'leridir.
  // 1. TAHTANIN DÖNMESİ İÇİN GEREKLİ DEĞİŞKEN
  PlayerColor _boardOrientation = PlayerColor.white;

  // Lichess tarzı dokunarak oynama için durum değişkenleri
  String? selectedSquare;
  List<String> legalDestinations = [];

  // BUNU EKLİYORUZ: Aynı bulmacanın gelmesini engelleyen hafıza değişkeni
  int? _lastPuzzleIndex;
  
  int _currentScore = 0;
  StreamSubscription<DocumentSnapshot>? _scoreSubscription;

  @override
  void dispose() {
    _scoreSubscription?.cancel();
    super.dispose();
  }

  void _listenToScore() {
    if (username.isEmpty || username == 'Misafir') return;
    _scoreSubscription?.cancel();
    _scoreSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(username.toLowerCase())
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _currentScore = doc.data()?['score'] ?? 0;
        });
      }
    });
  }

  // 2. SINIRSIZ KENDİ BULMACA HAVUZUMUZ (İstediğin kadar kopyala yapıştır ile ekle)
  final List<Map<String, dynamic>> localPuzzlePool = [
    {
      "id": "arka_yatay_basit",
      "fen": "6k1/1p3ppp/8/8/8/8/1q3PPP/2R3K1 w - - 0 1",
      "solution": ["c1c8"] // Beyaz tek hamlede arka yataydan mat eder
    },
    {
      "id": "vezir_fedasi_arka_yatay",
      "fen": "1r4k1/p4ppp/8/3Q4/8/8/PPP2PPP/4R1K1 w - - 0 1",
      "solution": ["d5d8", "b8d8", "e1d8"] // Vezir fedası ile zorunlu arka yatay matı
    },
    {
      "id": "anastasia_mati",
      "fen": "r4r1k/pp2Nppp/8/7Q/8/R7/PPP2PP1/6K1 w - - 0 1",
      "solution": ["h5h7", "h8h7", "a3h3"] // Klasik Anastasia Matı: Zorunlu vezir fedası ve kale matı
    },
    {
      "id": "aptal_mati",
      "fen": "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2",
      "solution": ["d8h4"] // Satrançtaki en hızlı mat: Aptal Matı (Siyah tek hamlede mat eder)
    },
    {
      "id": "coban_mati",
      "fen": "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 1",
      "solution": ["f3f7"] // Meşhur Çoban Matı
    },
    {
      "id": "hizli_mat_siyah",
      "fen": "r1b1k2r/pppp1ppp/8/4P3/1nB1n2q/8/PPPP1PPP/RNBQK2R b KQkq - 1 8",
      "solution": ["h4f2"] // Siyah atın korumasıyla f2'den tek hamlede mat eder
    },
    {
      "id": "vezir_saptirma_mati",
      "fen": "2r3k1/p4ppp/8/8/4Q3/8/1q3PPP/2R1Q1K1 w - - 0 1",
      "solution": ["e4e8", "c8e8", "c1e8"] // Kaleyi saptırmak için vezir fedası ve mat
    },
    {
      "id": "katal_taktigi_siyah",
      "fen": "6k1/5p1p/8/8/8/2n5/4QPPP/5RK1 b - - 0 1",
      "solution": ["c3e2", "g1h1"] // Siyah at ile şah-vezir çatalı atar (Rakibin tek yasal hamlesi g1h1'dir)
    },
    {
      "id": "apolet_mati",
      "fen": "k7/p1R3p1/1p6/8/8/8/8/1Q5K w - - 0 1",
      "solution": ["b1b7"] // Şahın kendi taşları tarafından sıkıştırıldığı Apolet Matı
    },
    {
      "id": "merdiven_mati_basit",
      "fen": "k7/8/1K6/8/8/8/8/1R6 w - - 0 1",
      "solution": ["b1a1"] // Kale ve Şah yardımıyla temel mat
    }
  ];

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    _checkUsernameAndLoad();
  }

// --- KOORDİNAT YARDIMCI FONKSİYONLARI ---
  List<String> _boardFiles() {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    // Eski _currentOrientation yerine _boardOrientation kullanıyoruz
    return _boardOrientation == PlayerColor.white ? files : files.reversed.toList();
  }

  List<String> _boardRanks() {
    // Eski _currentOrientation yerine _boardOrientation kullanıyoruz
    return _boardOrientation == PlayerColor.white
        ? List<String>.generate(8, (index) => '${8 - index}')
        : List<String>.generate(8, (index) => '${index + 1}');
  }

  Widget _buildCoordinateLabel(String text) {
    return SizedBox(
      width: 16, height: 16,
      child: Center(
        child: Text(
          text, 
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 9, fontWeight: FontWeight.w600, height: 1)
        ),
      ),
    );
  }

  // Lichess Dokunmatik Oynanış İçin Yardımcı Fonksiyonlar
  String indexToSquare(int index, bool isWhiteBottom) {
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
    bool isPlayerTurn = (_boardOrientation == PlayerColor.white && isWhiteToMove) || 
                        (_boardOrientation == PlayerColor.black && !isWhiteToMove);
    if (!isPlayerTurn || isSolved || isLoading) return; // Sıra bizde değilse işlem yapma
    
    final piece = controller.game.get(square);
    
    if (selectedSquare == null) {
      // Kendi taşımıza tıkladıysak onu seç ve hedefleri göster
      if (piece != null && piece.color == (isWhiteToMove ? chess_engine.Color.WHITE : chess_engine.Color.BLACK)) {
        setState(() {
          selectedSquare = square;
          final moves = controller.game.moves({"square": square, "verbose": true});
          legalDestinations = moves.map((m) => m["to"] as String).toList();
        });
      }
    } else {
      if (legalDestinations.contains(square)) {
        // Geçerli bir hedefe tıklandı, hamleyi yap
        controller.makeMove(from: selectedSquare!, to: square);
        _onMove();
        setState(() {
          selectedSquare = null;
          legalDestinations.clear();
        });
      } else if (piece != null && piece.color == (isWhiteToMove ? chess_engine.Color.WHITE : chess_engine.Color.BLACK)) {
        // Başka bir kendi taşımıza tıklandı, seçimi ona geçir
        setState(() {
          selectedSquare = square;
          final moves = controller.game.moves({"square": square, "verbose": true});
          legalDestinations = moves.map((m) => m["to"] as String).toList();
        });
      } else {
        // Boşa veya hedefsiz yere tıklandı, seçimi iptal et
        setState(() {
          selectedSquare = null;
          legalDestinations.clear();
        });
      }
    }
  }

  // 1. Kullanıcıdan sıralama için isim veya Lichess Token alma
  Future<void> _checkUsernameAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('puzzle_username');
    
    int? savedDifficultyIndex = prefs.getInt('puzzle_difficulty_index');
    if (savedDifficultyIndex != null && savedDifficultyIndex >= 0 && savedDifficultyIndex < PuzzleDifficulty.values.length) {
      currentDifficulty = PuzzleDifficulty.values[savedDifficultyIndex];
    }

    if (savedName == null || savedName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Map<String, String?>? inputData = await showGlobalLoginDialog(context);
        if (inputData != null && inputData['username'] != null && inputData['username']!.trim().isNotEmpty) {
          username = inputData['username']!.trim();
          _listenToScore();
          String? title = inputData['title'];
          String? patron = inputData['patron'];
          
          // Easter Egg: Termo_x için her zaman Sarı GM özelliği
          if (username.toLowerCase() == 'termo_x') {
            title = 'TermoGM'; // MoveLab'ın kendi mantığı
          }

          await prefs.setString('puzzle_username', username);
          if (title != null) {
            await prefs.setString('puzzle_user_title', title);
          } else {
            await prefs.remove('puzzle_user_title');
          }
          if (patron == 'true') {
            await prefs.setBool('puzzle_user_patron', true);
          } else {
            await prefs.remove('puzzle_user_patron');
          }
          
          setState(() {
            _userTitle = title;
            _isPatron = patron == 'true';
            if (username.toLowerCase() == 'termo_x') {
              _userTitle = 'TermoGM';
              _isPatron = true;
            }
          });
          
          _loadRandomPuzzle();
        } else {
          Navigator.pop(context); 
        }
      });
    } else {
      username = savedName;
      setState(() {
        _userTitle = prefs.getString('puzzle_user_title');
        _isPatron = prefs.getBool('puzzle_user_patron') ?? false;
        if (username.toLowerCase() == 'termo_x') {
          _userTitle = 'TermoGM';
          _isPatron = true;
        }
      });
      _listenToScore();
      _loadRandomPuzzle();
    }
  }
  

  // 2. Lichess'ten günlük bulmacayı çekme
  Future<void> _loadRandomPuzzle() async {
    setState(() => isLoading = true);
    
    // 1. Önce API'den çekmeyi deniyoruz
    try {
      final themes = [
        'mateIn2', 'mateIn3', 'endgame', 'middlegame', 'pin', 'fork', 'skewer', 
        'discoveredAttack', 'sacrifice', 'deflection', 'attraction', 'crushing', 'advantage'
      ];
      final random = Random();
      final randomTheme = themes[random.nextInt(themes.length)];
      
      final response = await http.get(Uri.parse('https://chess-puzzles-api.vercel.app/puzzles?limit=50&min_rating=${currentDifficulty.minRating}&max_rating=${currentDifficulty.maxRating}&themes=$randomTheme'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // Gelen 50 bulmacadan rastgele birini seç
          final puzzle = data[random.nextInt(data.length)];
          puzzleId = puzzle['PuzzleId'];
          puzzleRating = puzzle['Rating'];
          puzzleThemes = puzzle['Themes'];
          
          String apiFen = puzzle['FEN'];
          List<String> apiMoves = (puzzle['Moves'] as String).split(' ');
          String opponentFirstMove = apiMoves.removeAt(0); // Rakibin hatalı hamlesi
          
          _validationChess.reset();
          _validationChess.load(apiFen);
          
          // Rakibin hamlesini sanal tahtada oynat
          String from = opponentFirstMove.substring(0, 2);
          String to = opponentFirstMove.substring(2, 4);
          Map<String, dynamic> moveObj = {"from": from, "to": to};
          if (opponentFirstMove.length > 4) moveObj["promotion"] = opponentFirstMove.substring(4, 5);
          _validationChess.move(moveObj);
          
          solutionMoves = apiMoves; // Kalan hamleler çözüm yolumuz
          currentMoveIndex = 0;
          
          bool isWhiteTurn = _validationChess.turn == chess_engine.Color.WHITE;
          
          setState(() {
            isWhiteToMove = isWhiteTurn;
            _boardOrientation = isWhiteTurn ? PlayerColor.white : PlayerColor.black;
            controller.loadFen(_validationChess.fen);
          });
          
          if (mounted) setState(() => isLoading = false);
          return; // API başarılıysa yerel havuza geçmeden bitir
        }
      }
    } catch (e) {
      debugPrint("API Hatası (Yerel Havuza Düşülüyor): $e");
    }

    // 2. API başarısız olursa yerel havuza geri düş (Fallback)
    try {
      puzzleRating = null;
      puzzleThemes = null;
      final random = Random();
      int randomIndex;
      
      // AYNI BULMACANIN ÜST ÜSTE 2 KERE GELMESİNİ ENGELLEYEN DÖNGÜ
      do {
        randomIndex = random.nextInt(localPuzzlePool.length);
      } while (randomIndex == _lastPuzzleIndex && localPuzzlePool.length > 1);
      
      _lastPuzzleIndex = randomIndex; 
      final selectedPuzzle = localPuzzlePool[randomIndex];
      
      puzzleId = "${selectedPuzzle['id']}_${DateTime.now().millisecondsSinceEpoch}"; 
      solutionMoves = List<String>.from(selectedPuzzle['solution']);
      currentMoveIndex = 0; 
      
      _validationChess.reset();
      _validationChess.load(selectedPuzzle['fen']);
      
      bool isWhiteTurn = _validationChess.turn == chess_engine.Color.WHITE;
      
      setState(() {
        isWhiteToMove = isWhiteTurn;
        _boardOrientation = isWhiteTurn ? PlayerColor.white : PlayerColor.black;
        controller.loadFen(_validationChess.fen);
      });
      
    } catch (e) {
      debugPrint("Bulmaca Hatası: $e");
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _makeEngineMove(String uciMove) {
    String from = uciMove.substring(0, 2);
    String to = uciMove.substring(2, 4);
    Map<String, dynamic> moveObj = {"from": from, "to": to};
    
    // Eğer hamle vezir çıkma/terfi hamlesiyse (örn: e7e8q) bunu motora bildir
    if (uciMove.length > 4) {
      moveObj["promotion"] = uciMove.substring(4, 5);
    }
    _validationChess.move(moveObj);
  }

  // 3. Kullanıcının hamlesini doğrulama (FEN Karşılaştırması ile)
  void _onMove() async {
    // Sürükle bırak ile hamle yapıldığında seçili taşın vurgusunu temizle
    if (selectedSquare != null) {
      setState(() {
        selectedSquare = null;
        legalDestinations.clear();
      });
    }

    if (isSolved || currentMoveIndex >= solutionMoves.length) return;

    // Sadece taş dizilimini ve sırayı al (take(2))
    String userFen = controller.getFen().split(' ').take(2).join(' ');

    String expectedUci = solutionMoves[currentMoveIndex];
    chess_engine.Chess tempValidation = chess_engine.Chess();
    tempValidation.load(_validationChess.fen); 
    
    String from = expectedUci.substring(0, 2);
    String to = expectedUci.substring(2, 4);
    Map<String, dynamic> moveObj = {"from": from, "to": to};
    if (expectedUci.length > 4) {
      moveObj["promotion"] = expectedUci.substring(4, 5);
    }
    
    tempValidation.move(moveObj);
    String expectedFen = tempValidation.fen.split(' ').take(2).join(' ');

    if (userFen == expectedFen) {
      // DOĞRU HAMLE!
      SoundService.playMoveSound(false);
      _validationChess.load(tempValidation.fen); 
      currentMoveIndex++;

      if (currentMoveIndex >= solutionMoves.length) {
        setState(() => isSolved = true);
        await _rewardUser();
        _showSuccessDialog();
      } else {
        Future.delayed(const Duration(milliseconds: 600), () {
          _makeEngineMove(solutionMoves[currentMoveIndex]);
          controller.loadFen(_validationChess.fen); 
          currentMoveIndex++;
          SoundService.playMoveSound(false);
        });
      }
    } else {
      // YANLIŞ HAMLE
      SoundService.playMoveSound(true);
      controller.loadFen(_validationChess.fen); 
      
      if (!_hasFailedCurrentPuzzle) {
        _penalizeUser(); // _hasFailedCurrentPuzzle'ı true yapar
        _showFloatingText(context, '-${currentDifficulty.points}', Colors.redAccent);
      } else {
        _showFloatingText(context, LanguageService.get('puzzle_wrong_move'), Colors.orangeAccent);
      }
    }
  }


  void _showFloatingText(BuildContext context, String text, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final size = MediaQuery.of(context).size;
    
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: size.height / 2 - 80,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2500), // Daha uzun süre kalır
            curve: Curves.easeOutCubic,
            onEnd: () {
              overlayEntry.remove();
            },
            builder: (context, value, child) {
              // İlk %70'lık kısımda tam görünür, sonra yavaşça silinir
              double opacity = value < 0.7 ? 1.0 : (1.0 - ((value - 0.7) / 0.3)).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, -60 * value), // Yavaşça yukarı süzülme
                child: Transform.scale(
                  scale: 1.0 + (value * 0.15), // Hafif büyüme
                  child: Opacity(
                    opacity: opacity, 
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C).withValues(alpha: 0.9), // Koyu modern arka plan
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.8), width: 2), // Neon sınır çizgisi
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: text.length > 5 ? 24 : 48, // Metin kutuya sığsın diye biraz küçültüldü
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic, // Daha şık ve dinamik bir görünüm
                              color: Colors.white,
                              letterSpacing: 2.0,
                              decoration: TextDecoration.none, // Sarı alt çizgiyi kesin olarak kaldırır
                              shadows: [
                                Shadow(color: color, blurRadius: 10, offset: const Offset(0, 0)) // Metin parlaması
                              ]
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    
    overlay.insert(overlayEntry);
  }
  
  // Tıkandığında kullanıcıya doğru hamleyi gösteren fonksiyon
  void _showHint() {
    if (isSolved || currentMoveIndex >= solutionMoves.length) return;
    
    // Motorun beklediği doğru hamleyi al (Örn: "f7e8")
    String expectedUci = solutionMoves[currentMoveIndex];
    String from = expectedUci.substring(0, 2);
    String to = expectedUci.substring(2, 4);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService.currentLang == 'en'
              ? '💡 ${LanguageService.get('puzzle_hint')} Move the piece on $from to $to!'
              : '💡 ${LanguageService.get('puzzle_hint')} $from karesindeki taşı $to karesine oyna!',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      )
    );
  }
  // 4. Puanı Firebase'e Yazma
  Future<void> _rewardUser() async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(username.toLowerCase());
      final doc = await userRef.get();
      
      List<dynamic> solved = doc.exists ? (doc.data()?['solved_puzzles'] ?? []) : [];
      
      if (!solved.contains(puzzleId)) {
        await userRef.set({
          'username': username,
          if (!_hasFailedCurrentPuzzle) 'score': FieldValue.increment(currentDifficulty.points),
          'solved_puzzles': FieldValue.arrayUnion([puzzleId]),
          'last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Puan yazma hatası: $e");
    }
  }

  Future<void> _penalizeUser() async {
    if (username.isEmpty || username == 'Misafir') return;
    if (_hasFailedCurrentPuzzle) return; // Zaten hata yaptıysa bu bulmacada 2. kez puan düşme

    setState(() {
      _hasFailedCurrentPuzzle = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(username.toLowerCase());
      
      await userRef.set({
        'username': username,
        'score': FieldValue.increment(-currentDifficulty.points),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Ceza yazma hatası: $e");
    }
  }

void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101A2B),
        title: Text(LanguageService.get('puzzle_congratulations'), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        content: Text(
          LanguageService.currentLang == 'en'
              ? (_hasFailedCurrentPuzzle ? 'Puzzle solved, but no points since you made a mistake.\nWould you like to try another?' : 'You earned +${currentDifficulty.points} points!\nWould you like to solve another puzzle?')
              : (_hasFailedCurrentPuzzle ? 'Bulmaca çözüldü, ancak hata yaptığın için puan kazanamadın.\nSonraki bulmacaya geçmek ister misin?' : '+${currentDifficulty.points} Puan Kazandın!\nSonraki bulmacaya geçmek ister misin?'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialogu kapat
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LeaderboardPage()));
            },
            child: Text(LanguageService.get('puzzle_leaderboard'), style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0)),
            onPressed: () {
              Navigator.pop(context); // Dialogu kapat
              _loadNextPuzzle(); // YENİ BULMACAYA GEÇİŞ BAŞLATICI
            },
            child: Text(LanguageService.currentLang == 'en' ? 'Next Puzzle' : 'Sonraki Bulmaca', style: const TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

// Yeni bulmacayı yükleme döngüsü
void _loadNextPuzzle() {
    setState(() {
      isSolved = false;
      solutionMoves.clear();
      currentMoveIndex = 0;
      isLoading = true;
      _hasFailedCurrentPuzzle = false;
    });
    
    // Artık _loadDailyPuzzle() değil, rastgele çeken yeni fonksiyonumuzu çağırıyoruz:
    _loadRandomPuzzle(); 
  }

  void _showDifficultySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151B2B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(LanguageService.get('puzzle_diff_select'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...PuzzleDifficulty.values.map((diff) {
                bool isSelected = currentDifficulty == diff;
                return ListTile(
                  title: Text(
                    '${LanguageService.get(diff.labelKey)} (${diff.points} ${LanguageService.get('puzzle_diff_points')})',
                    style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (currentDifficulty != diff) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('puzzle_difficulty_index', diff.index);
                      setState(() {
                        currentDifficulty = diff;
                      });
                      _loadRandomPuzzle(); // Yeni zorluğa göre hemen bulmaca getir
                    }
                  },
                );
              }),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get('puzzles'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF151B2B),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: LanguageService.get('settings'),
            onPressed: () => showSettingsSheet(context, onChanged: () async {
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                username = prefs.getString('puzzle_username') ?? "";
                _userTitle = prefs.getString('puzzle_user_title');
                _isPatron = prefs.getBool('puzzle_user_patron') ?? false;
                if (username.toLowerCase() == 'termo_x') {
                  _userTitle = 'TermoGM';
                  _isPatron = true;
                }
              });
              _listenToScore();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.orangeAccent),
            tooltip: LanguageService.get('puzzle_leaderboard'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage())),
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5C6BC0)))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                if (puzzleRating != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, top: 0.0),
                    child: GestureDetector(
                      onTap: _showDifficultySelector,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.tune, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${LanguageService.get('puzzle_difficulty')}: $puzzleRating ELO (${LanguageService.get(currentDifficulty.labelKey)})',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent, size: 20),
                        ],
                      ),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${LanguageService.get('puzzle_player')}: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                          buildUserTags(_userTitle ?? '', _isPatron),
                          Flexible(
                            child: Text(
                              username, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _isPatron ? Colors.orangeAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)
                            )
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8), // İki bölüm arasına hafif boşluk
                    
                    // MODERN VE NEON SIRA GÖSTERGESİ (KÜÇÜLTÜLMÜŞ HALİ)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101A2B), // Karanlık arka plan
                        borderRadius: BorderRadius.circular(10), // Modern oval köşeler
                        border: Border.all(
                          color: isWhiteToMove ? Colors.white.withValues(alpha: 0.6) : Colors.white12,
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (isWhiteToMove)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isWhiteToMove ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 14,
                            color: isWhiteToMove ? Colors.white : Colors.white38,
                            shadows: isWhiteToMove ? [
                              const Shadow(color: Colors.white, blurRadius: 6)
                            ] : [],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isWhiteToMove ? LanguageService.get('puzzle_turn_white') : LanguageService.get('puzzle_turn_black'),
                            style: TextStyle(
                              color: isWhiteToMove ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.2, // Daha sıkı harf aralığı
                              shadows: isWhiteToMove ? [
                                const Shadow(color: Colors.white54, blurRadius: 6)
                              ] : [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00897B), Color(0xFF1A237E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: isSolved ? Colors.greenAccent : const Color(0xFF5C6BC0), width: 2),
                        ),
                        child: ClipRect(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                // Satranç Tahtası (İçte 12 birim boşluk bırakılarak oturtuldu)
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Listener(
                                          behavior: HitTestBehavior.translucent,
                                          onPointerUp: (event) {
                                            final squareSize = constraints.maxWidth / 8;
                                            final col = (event.localPosition.dx / squareSize).floor().clamp(0, 7);
                                            final row = (event.localPosition.dy / squareSize).floor().clamp(0, 7);
                                            
                                            int rank, file;
                                            if (_boardOrientation == PlayerColor.white) {
                                              rank = 7 - row;
                                              file = col;
                                            } else {
                                              rank = row;
                                              file = 7 - col;
                                            }
                                            
                                            final fileChar = String.fromCharCode('a'.codeUnitAt(0) + file);
                                            final rankChar = (rank + 1).toString();
                                            final square = '$fileChar$rankChar';
                                            
                                            _onSquareTapped(square);
                                          },
                                          child: Stack(
                                            children: [
                                              // 1. ASIL SATRANÇ TAHTASI
                                              ChessBoard(
                                                controller: controller,
                                                boardColor: BoardColor.green,
                                                boardOrientation: _boardOrientation,
                                                enableUserMoves: true, // Sürükle-bırak aktif
                                                onMove: _onMove,
                                              ),
                                              // 2. GÖRSEL KATMAN (Vurgular ve Noktalar)
                                              IgnorePointer(
                                                child: Column(
                                                  children: List.generate(8, (row) {
                                                    return Expanded(
                                                      child: Row(
                                                        children: List.generate(8, (col) {
                                                          final index = row * 8 + col;
                                                          final square = indexToSquare(index, _boardOrientation == PlayerColor.white);
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
                                                                  border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 5),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              ),
                                                            );
                                                          } else if (isLegalMove) {
                                                            highlightWidget = Center(
                                                              child: Container(
                                                                width: 14,
                                                                height: 14,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.black.withValues(alpha: 0.3),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                          
                                                          return Expanded(
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color: isSelected ? Colors.yellow.withValues(alpha: 0.4) : null,
                                                              ),
                                                              child: highlightWidget,
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    ),
                                  ),
                                ),
                                // Alt Kısım Harfler (a-h)
                                Positioned(
                                  left: 12, right: 12, bottom: 0,
                                  child: SizedBox(
                                    height: 14,
                                    child: Row(children: _boardFiles().map((e) => Expanded(child: Center(child: _buildCoordinateLabel(e)))).toList()),
                                  ),
                                ),
                                // Sol Kısım Sayılar (1-8)
                                Positioned(
                                  top: 12, bottom: 12, left: 0,
                                  child: SizedBox(
                                    width: 14,
                                    child: Column(children: _boardRanks().map((e) => Expanded(child: Center(child: _buildCoordinateLabel(e)))).toList()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!isSolved && _hasFailedCurrentPuzzle)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _showHint,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101A2B).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.yellowAccent.withValues(alpha: 0.65),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.yellowAccent.withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.yellowAccent,
                                    size: 15,
                                    shadows: [Shadow(color: Colors.yellowAccent, blurRadius: 10)],
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "İPUCU AL",
                                    style: TextStyle(
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                      letterSpacing: 1.0,
                                      shadows: [Shadow(color: Colors.yellowAccent, blurRadius: 10)],
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
              const SizedBox(height: 20),

              // MEVCUT PUAN GÖSTERİMİ
              if (username.isNotEmpty && username != 'Misafir')
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101A2B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.blueAccent, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        LanguageService.currentLang == 'en' ? "Current Score: " : "Mevcut Puan: ",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "$_currentScore",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10)]
                        ),
                      ),
                    ],
                  ),
                ),

// Satranç tahtası Container'ı burada bitiyor...
              if (isSolved)
                Text(LanguageService.get('puzzle_solved'), style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold))
            ],
          ),
        ),
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  StreamSubscription? _cloudSubscription;

  @override
  void initState() {
    super.initState();
    _initCloudSync();
  }

  void _initCloudSync() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('puzzle_username');
    if (username != null && username.isNotEmpty) {
      _cloudSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(username.toLowerCase())
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data()!.containsKey('saved_matches')) {
          List<dynamic> cloudMatchesRaw = doc.data()!['saved_matches'];
          List<SavedMatch> cloudMatches = cloudMatchesRaw
              .map((e) => SavedMatch.fromJson(jsonDecode(e.toString())))
              .toList();

          bool changed = false;
          for (var cm in cloudMatches) {
            if (!GlobalLibrary.isSaved(cm.pgn, cm.moves)) {
              GlobalLibrary.matches.add(cm);
              changed = true;
            }
          }
          if (changed && mounted) {
            setState(() {});
            GlobalLibrary.saveMatches();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _cloudSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.get('library_title'), style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF151B2B)),
      body: GlobalLibrary.matches.isEmpty 
        ? Center(child: Text(LanguageService.get('no_library_matches'), style: const TextStyle(color: Colors.white54, fontSize: 16)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: GlobalLibrary.matches.length,
            itemBuilder: (context, index) {
              var match = GlobalLibrary.matches[index];
              bool userWon = (match.winner == 'white' && match.userColor == PlayerColor.white) || (match.winner == 'black' && match.userColor == PlayerColor.black);
              bool userLost = (match.winner == 'white' && match.userColor == PlayerColor.black) || (match.winner == 'black' && match.userColor == PlayerColor.white);
              Color resultColor = Colors.grey;
              Color cardColor = const Color(0xFF151B2B);
              if (userWon) {
                resultColor = const Color(0xFF66BB6A);
                cardColor = resultColor.withValues(alpha: 0.12);
              } else if (userLost) {
                resultColor = const Color(0xFFEF5350);
                cardColor = resultColor.withValues(alpha: 0.12);
              }
              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: resultColor.withValues(alpha: 0.25))),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: resultColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.bookmark, color: resultColor),
                  ),
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (match.whiteTitle.isNotEmpty) buildTitleTag(match.whiteTitle),
                      Text(match.whiteName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text(' vs ', style: TextStyle(color: Colors.white54)),
                      if (match.blackTitle.isNotEmpty) buildTitleTag(match.blackTitle),
                      Text(match.blackName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  subtitle: Text('${match.platform} • ${LanguageService.get('mode')}: ${match.speed}', style: TextStyle(color: resultColor, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        GlobalLibrary.matches.removeAt(index);
                        GlobalLibrary.saveMatches();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.get('match_deleted'))));
                    },
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisPage(
                      matchData: {
                        'platform': match.platform,
                        'white': match.whiteName,
                        'black': match.blackName,
                        'whiteTitle': match.whiteTitle,
                        'blackTitle': match.blackTitle,
                        'whiteRating': match.whiteRating,
                        'blackRating': match.blackRating,
                        'pgn': match.pgn,
                        'speed': match.speed,
                        'moves': match.moves,
                        'winner': match.winner,
                      },
                      boardOrientation: match.userColor,
                      apiHeaders: const {},
                    ))).then((_) => setState((){})); 
                  },
                ),
              );
            },
          ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? initialUsername;
  const HomePage({super.key, this.initialUsername});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pgnController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); 
  bool _showSearchHistory = false;
  
  bool _isHeaderVisible = true; 
  String _selectedPlatform = 'Lichess'; 
  String _selectedTempo = 'all'; 
  
  bool _isUserDonor = false; // Yeni eklediğimiz değişken
  bool _isLoading = false; 
  bool _isMatchesLoading = false; 
  Map<String, dynamic>? _playerProfile; 
  List<dynamic> _recentMatches = []; 
  PlayerStyleProfile? _playerStyleProfile;
  String _errorMessage = ''; 
  
  int _loadedGamesCount = 30; 
  Timer? _debounce;
  List<String> _liveSuggestions = []; 
  
  final GlobalKey _styleAnalysisCardKey = GlobalKey();

  final Map<String, String> _apiHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty) {
      _usernameController.text = widget.initialUsername!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchPlayerStats();
      });
    }
    _searchFocusNode.addListener(() {
      setState(() {
        if (_searchFocusNode.hasFocus) {
          _isHeaderVisible = true;
          _showSearchHistory = _usernameController.text.trim().isNotEmpty || GlobalLibrary.searchHistory.isNotEmpty;
        } else {
          _showSearchHistory = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _usernameController.dispose();
    _pgnController.dispose();
    super.dispose();
  }

  void _resetHome() {
    setState(() {
      _isHeaderVisible = true;
      _playerProfile = null;
      _playerStyleProfile = null;
      _recentMatches = [];
      _errorMessage = '';
      _loadedGamesCount = 30; 
      _usernameController.clear();
      _searchFocusNode.unfocus();
      _showSearchHistory = false;
      _liveSuggestions = [];
    });
  }


  void _onSearchChanged(String value) {
    setState(() {
      _showSearchHistory = value.trim().isNotEmpty || GlobalLibrary.searchHistory.isNotEmpty;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().length >= 2 && _selectedPlatform == 'Lichess') {
      _debounce = Timer(const Duration(milliseconds: 350), () async {
        try {
          var res = await http.get(Uri.parse('https://lichess.org/api/player/autocomplete?term=${value.trim()}'));
          if (res.statusCode == 200) {
            List<dynamic> data = jsonDecode(res.body);
            if (mounted) {
              setState(() {
                _liveSuggestions = data.cast<String>();
              });
            }
          }
        } catch (e) {}
      });
    } else {
      if (mounted) {
        setState(() { _liveSuggestions = []; });
      }
    }
  }

  Future<void> fetchPlayerStats({bool loadMore = false}) async {
    String username = _usernameController.text.trim();
    if(username.isEmpty) { return; }

    _searchFocusNode.unfocus();

    if (loadMore) {
      _loadedGamesCount += 10;
      setState(() => _isMatchesLoading = true);
    } else {
      _loadedGamesCount = 30;
      setState(() {
        _isHeaderVisible = false;
        _isLoading = true;
        _playerProfile = null;
        _playerStyleProfile = null;
        _recentMatches = [];
        _selectedTempo = 'all';
        _errorMessage = '';
        _isUserDonor = false;
      });
    }

    await GlobalLibrary.saveSearch(username);

    // Veritabanından bağışçı durumunu arka planda kontrol et.
    bool isDonorCheck = await checkDonorStatus(username);

    if (!loadMore && mounted) {
      setState(() {
        _isUserDonor = isDonorCheck;
      });
    }

    try {
      if (_selectedPlatform == 'Lichess') {
        if (!loadMore) {
          var res = await http.get(Uri.parse('https://lichess.org/api/user/$username'), headers: _apiHeaders);
          if (res.statusCode == 200) {
            var data = jsonDecode(res.body);
            
            // Termo_x kontrolü
            String fetchedTitle = data['title'] ?? '';
            if (data['username'].toString().toLowerCase() == 'termo_x') {
              fetchedTitle = 'TermoGM';
            }
            
            _playerProfile = { 
              'username': data['username'], 
              'title': fetchedTitle,
              'rapid': data['perfs']?['rapid']?['rating'], 
              'blitz': data['perfs']?['blitz']?['rating'], 
              'bullet': data['perfs']?['bullet']?['rating'] 
            };
          } else {
            _errorMessage = res.statusCode == 429 ? 'Lichess hız sınırı uyguladı. Bekleyin.' : 'Lichess: Oyuncu bulunamadı.';
          }
        }
        if (_playerProfile != null) {
          _recentMatches = await _fetchLichessGames(username, _selectedTempo, _loadedGamesCount);
        }
      } else {
        if (!loadMore) {
          var profileRes = await http.get(Uri.parse('https://api.chess.com/pub/player/$username'), headers: _apiHeaders);
          var statsRes = await http.get(Uri.parse('https://api.chess.com/pub/player/$username/stats'), headers: _apiHeaders);
          if (profileRes.statusCode == 200 && statsRes.statusCode == 200) {
            var pData = jsonDecode(profileRes.body); var sData = jsonDecode(statsRes.body);
            _playerProfile = { 
              'username': pData['username'], 
              'title': pData['title'] ?? '',
              'rapid': sData['chess_rapid']?['last']?['rating'], 
              'blitz': sData['chess_blitz']?['last']?['rating'], 
              'bullet': sData['chess_bullet']?['last']?['rating'] 
            };
          } else {
            _errorMessage = 'Chess.com: Oyuncu bulunamadı.';
          }
        }
        if (_playerProfile != null) {
          _recentMatches = await _fetchChessComGames(username, _selectedTempo, _loadedGamesCount);
        }
      }

      if (_recentMatches.isNotEmpty) {
        int maxRating = 0;
        if (_playerProfile != null) {
          int r = _playerProfile!['rapid'] as int? ?? 0;
          int b = _playerProfile!['blitz'] as int? ?? 0;
          int bl = _playerProfile!['bullet'] as int? ?? 0;
          maxRating = [r, b, bl].reduce(max);
        }
        _playerStyleProfile = PlayerStyleAnalyzer.analyze(username, _recentMatches, maxRating);
      }

    } catch (e) { 
      _errorMessage = 'Bağlantı sağlanamadı.'; 
    }
    setState(() { _isLoading = false; _isMatchesLoading = false; });
  }

  bool _isPgnValid(String pgn) {
    if (pgn.trim().isEmpty) { return false; }
    return pgn.trim().split(RegExp(r'\s+')).where((t) => RegExp(r'^[a-h][1-8]|^[KQRBN]').hasMatch(t)).length >= 2;
  }

  Future<void> _showPgnInputDialog() async {
    _pgnController.clear();
    Color themeColor = _selectedPlatform == 'Chess.com' ? const Color(0xFF32804A) : const Color(0xFF5C6BC0);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF101A2B),
              title: Text(LanguageService.get('pgn_paste'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: themeColor.withValues(alpha: 0.6), blurRadius: 8, offset: const Offset(0, 0))])),
              content: SizedBox(
                width: double.maxFinite,
                child: TextField(
                  controller: _pgnController, maxLines: 10,
                  onChanged: (_) => setDialogState(() {}),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, shadows: [Shadow(color: themeColor.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 0))]),
                  decoration: InputDecoration(hintText: LanguageService.get('pgn_placeholder'), hintStyle: TextStyle(color: Colors.white38, shadows: [Shadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 0))]), filled: true, fillColor: const Color(0xFF151B2B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(LanguageService.get('cancel'), style: const TextStyle(color: Colors.white70, shadows: [Shadow(color: Colors.white10, blurRadius: 4, offset: Offset(0, 0))]))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _isPgnValid(_pgnController.text) ? themeColor : themeColor.withValues(alpha: 0.4), foregroundColor: Colors.white),
                  onPressed: _isPgnValid(_pgnController.text) ? () { Navigator.of(context).pop(); _analyzePgn(); } : null,
                  child: Text(LanguageService.get('analyze'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, shadows: _isPgnValid(_pgnController.text) ? [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 1))] : [])),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _extractPgnMetadata(String pgn) {
    String extractTag(String tag) {
      final regex = RegExp(r'\[' + tag + r'\s+"([^"]+)"\]');
      final match = regex.firstMatch(pgn);
      return match?.group(1)?.trim() ?? '';
    }

    String white = extractTag('White');
    String black = extractTag('Black');
    String whiteElo = extractTag('WhiteElo');
    String blackElo = extractTag('BlackElo');
    String result = extractTag('Result');
    String whiteTitle = extractTag('WhiteTitle');
    String blackTitle = extractTag('BlackTitle');

    String winner = 'draw';
    if (result == '1-0') { winner = 'white'; } else if (result == '0-1') { winner = 'black'; }

    return {
      'white': white.isNotEmpty ? white : 'Beyaz',
      'black': black.isNotEmpty ? black : 'Siyah',
      'whiteRating': int.tryParse(whiteElo) ?? 0,
      'blackRating': int.tryParse(blackElo) ?? 0,
      'whiteTitle': whiteTitle,
      'blackTitle': blackTitle,
      'winner': winner,
    };
  }

  void _analyzePgn() {
    String pgn = _pgnController.text.trim();
    if (pgn.isEmpty) { setState(() { _errorMessage = 'PGN boş olamaz.'; }); return; }
    Map<String, dynamic> meta = _extractPgnMetadata(pgn);

    var matchData = {
      'platform': 'PGN',
      'white': meta['white'], 'black': meta['black'],
      'whiteTitle': meta['whiteTitle'], 'blackTitle': meta['blackTitle'],
      'whiteRating': meta['whiteRating'], 'blackRating': meta['blackRating'],
      'winner': meta['winner'], 'speed': 'pgn', 'pgn': pgn, 'moves': '',
    };

    Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisPage(matchData: matchData, boardOrientation: PlayerColor.white, apiHeaders: _apiHeaders)));
  }

  Future<void> _updateTempoFilter(String targetTempo) async {
    String username = _usernameController.text.trim();
    if (username.isEmpty || _playerProfile == null) { return; }
    if (_selectedTempo == targetTempo) { targetTempo = 'all'; }
    setState(() { _isMatchesLoading = true; _selectedTempo = targetTempo; _recentMatches = []; _loadedGamesCount = 30; });
    try {
      if (_selectedPlatform == 'Lichess') { _recentMatches = await _fetchLichessGames(username, targetTempo, _loadedGamesCount); }
      else { _recentMatches = await _fetchChessComGames(username, targetTempo, _loadedGamesCount); }
    } catch (e) { _errorMessage = LanguageService.get('filter_error'); }
    setState(() { _isMatchesLoading = false; });
  }

  String _getChessComWinner(Map<String, dynamic> game) {
    if (game['white']?['result'] == 'win') { return 'white'; }
    if (game['black']?['result'] == 'win') { return 'black'; }
    return 'draw';
  }

  Future<List<dynamic>> _fetchLichessGames(String username, String tempo, int maxGames) async {
    List<dynamic> list = [];
    String urlStr = 'https://lichess.org/api/games/user/$username?max=$maxGames';
    if (tempo != 'all') { urlStr += '&perfType=$tempo'; } 
    var res = await http.get(Uri.parse(urlStr), headers: {'User-Agent': _apiHeaders['User-Agent']!, 'Accept': 'application/x-ndjson'});
    if (res.statusCode == 200) {
      for (var line in res.body.trim().split('\n')) {
        if (line.isNotEmpty) {
          var m = jsonDecode(line);
          String wName = m['players']?['white']?['user']?['name'] ?? 'Bilinmiyor';
          String bName = m['players']?['black']?['user']?['name'] ?? 'Bilinmiyor';
          String wTitle = m['players']?['white']?['user']?['title'] ?? '';
          String bTitle = m['players']?['black']?['user']?['title'] ?? '';
          
          // Termo_x kontrolü
          if (wName.toLowerCase() == 'termo_x') wTitle = 'TermoGM';
          if (bName.toLowerCase() == 'termo_x') bTitle = 'TermoGM';

          list.add({
            'platform': 'Lichess', 'white': wName, 'black': bName,
            'whiteTitle': wTitle, 'blackTitle': bTitle,
            'whiteRating': m['players']?['white']?['rating'] ?? 0, 
            'blackRating': m['players']?['black']?['rating'] ?? 0, 
            'winner': m['winner'] ?? 'draw', 'speed': m['speed']?.toString().toLowerCase() ?? 'Bilinmiyor', 
            'pgn': '', 'moves': m['moves'] ?? ''
          });
        }
      }
    }
    return list;
  }

  Future<List<dynamic>> _fetchChessComGames(String username, String tempo, int maxGames) async {
    List<dynamic> list = [];
    var res = await http.get(Uri.parse('https://api.chess.com/pub/player/$username/games/archives'), headers: _apiHeaders);
    if (res.statusCode == 200) {
      List<dynamic> archives = jsonDecode(res.body)['archives'] ?? [];
      for (String url in archives.reversed) {
        if (list.length >= maxGames) { break; } 
        var gRes = await http.get(Uri.parse(url), headers: _apiHeaders);
        if (gRes.statusCode == 200) {
          List<dynamic> games = jsonDecode(gRes.body)['games'] ?? [];
          for (var g in games.reversed) {
            if (list.length >= maxGames) { break; }
            String t = g['time_class']?.toString().toLowerCase() ?? 'bilinmiyor';
            if (tempo == 'all' || t == tempo) {
              String wName = g['white']['username'];
              String bName = g['black']['username'];
              String wTitle = (wName.toLowerCase() == username.toLowerCase()) ? (_playerProfile?['title'] ?? '') : '';
              String bTitle = (bName.toLowerCase() == username.toLowerCase()) ? (_playerProfile?['title'] ?? '') : '';

              list.add({
                'platform': 'Chess.com', 'white': wName, 'black': bName,
                'whiteTitle': wTitle, 'blackTitle': bTitle,
                'whiteRating': g['white']['rating'] ?? 0, 'blackRating': g['black']['rating'] ?? 0, 
                'winner': _getChessComWinner(g), 'speed': t, 'pgn': g['pgn'] ?? '', 'moves': '',
                'whiteAccuracy': g['accuracies']?['white'], 'blackAccuracy': g['accuracies']?['black']
              });
            }
          }
        }
      }
    }
    return list;
  }

  Future<void> _shareStyleAnalysisCard() async {
    if (_playerStyleProfile == null || _playerProfile == null) return;
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      RenderRepaintBoundary? boundary = _styleAnalysisCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Kart henüz ekranda çizilmedi.");

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception("Resim verisi alınamadı.");

      final bytes = byteData.buffer.asUint8List();

      String u = _playerProfile!['username']?.toString() ?? 'Oyuncu';
      String style = LanguageService.styleLabel(_playerStyleProfile!.mainStyle);
      int r = _playerProfile!['rapid'] as int? ?? 0;
      int b = _playerProfile!['blitz'] as int? ?? 0;
      int bl = _playerProfile!['bullet'] as int? ?? 0;
      int maxR = [r, b, bl].reduce(max);
      String ratingStr = maxR > 0 ? maxR.toString() : '-';

      final xFile = XFile.fromData(bytes, name: 'movelab_style.png', mimeType: 'image/png');
      await Share.shareXFiles([xFile], text: '♟️ MoveLab - ${LanguageService.get('share_style')}\n👤 ${LanguageService.get('player')}: $u (${LanguageService.get('rating')}: $ratingStr)\n🔥 ${LanguageService.get('style_tactical')}: $style\n\n📲 App: https://play.google.com/store/apps/details?id=com.movelab.app');
    } catch (e) {
      debugPrint("Share error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.get('share_error'))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPlayerStyleWidget(PlayerStyleProfile profile) {
    Color themeColor = _selectedPlatform == 'Chess.com' ? const Color(0xFF32804A) : const Color(0xFF5C6BC0);
    int r = _playerProfile!['rapid'] as int? ?? 0;
    int b = _playerProfile!['blitz'] as int? ?? 0;
    int bl = _playerProfile!['bullet'] as int? ?? 0;
    int maxR = [r, b, bl].reduce(max);
    String ratingStr = maxR > 0 ? maxR.toString() : '-';
    
    return RepaintBoundary(
      key: _styleAnalysisCardKey,
      child: Card(
        elevation: 8, color: const Color(0xFF151B2B), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: themeColor.withValues(alpha: 0.3), width: 1.5)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.insert_chart, color: themeColor), const SizedBox(width: 8), Text(LanguageService.get('analysis_title'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70))]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildUserTags((_playerProfile!['title'] ?? '').toString(), _isUserDonor),
                          Flexible(
                            child: Text(
                              _playerProfile!['username']?.toString() ?? LanguageService.get('player'), 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isUserDonor ? Colors.orangeAccent : Colors.white)
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Rating: $ratingStr', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), onPressed: _shareStyleAnalysisCard, tooltip: LanguageService.get('share_style'), padding: EdgeInsets.zero, constraints: const BoxConstraints())
              ]
            ),
            const Divider(height: 24, color: Colors.white12),
            Center(child: Column(children: [
              Text(profile.mainIcon, style: const TextStyle(fontSize: 48)), const SizedBox(height: 4),
              Text(LanguageService.styleLabel(profile.mainStyle), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor)), const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: profile.subStyles.map((sub) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: themeColor.withValues(alpha: 0.5))), child: Text(LanguageService.styleLabel(sub), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)))).toList()),
            ])),
            const SizedBox(height: 25),
            _buildStyleProgress(LanguageService.get('style_aggressive'), profile.aggressive, Colors.redAccent),
            _buildStyleProgress(LanguageService.get('style_defensive'), profile.defensive, Colors.blueAccent),
            _buildStyleProgress(LanguageService.get('style_tactical'), profile.tactical, Colors.amberAccent),
            _buildStyleProgress(LanguageService.get('style_positional'), profile.positional, Colors.green),
            _buildStyleProgress(LanguageService.get('style_risk'), profile.risk, Colors.orangeAccent),
            _buildStyleProgress(LanguageService.get('style_opening'), profile.opening, Colors.purpleAccent),
            const SizedBox(height: 15),
            const Center(child: Text('movelab.app', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)))
          ]),
        ),
      ),
    );
  }

  Widget _buildStyleProgress(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: value / 100, backgroundColor: Colors.white10, color: color, minHeight: 8))),
        SizedBox(width: 40, child: Text(' %$value', textAlign: TextAlign.right, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
      ]),
    );
  }

  Widget _buildEloColumn(String title, int? rating, String filterKey, Color themeColor) {
    bool isSelected = _selectedTempo == filterKey;
    return GestureDetector(
      onTap: () => _updateTempoFilter(filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? themeColor.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? themeColor : Colors.transparent, width: 1.5)),
        child: Column(children: [Text(title, style: TextStyle(fontSize: 14, color: isSelected ? themeColor : Colors.white54, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(rating != null ? rating.toString() : 'Yok', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70))]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _selectedPlatform == 'Chess.com' ? const Color(0xFF32804A) : const Color(0xFF5C6BC0);

    List<String> combinedSuggestions = [
      ...GlobalLibrary.searchHistory.where((name) => name.toLowerCase().contains(_usernameController.text.trim().toLowerCase())),
      ..._liveSuggestions.where((name) => !GlobalLibrary.searchHistory.any((h) => h.toLowerCase() == name.toLowerCase()))
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: LanguageService.get('back_home'), onPressed: _resetHome),
        title: const Text('MoveLab', style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: const Color(0xFF151B2B), centerTitle: true, elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: LanguageService.get('settings'),
            onPressed: () => showSettingsSheet(context, onChanged: () => setState(() {})),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic, alignment: Alignment.topCenter,
                child: _isHeaderVisible ? Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none, 
                      children: [
                        Container(
                          width: 100, 
                          height: 100, 
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: 0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/logoyazili.png',
                          height: 180, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.psychology, size: 70, color: themeColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), 
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ChoiceChip(label: const Text('Lichess'), selected: _selectedPlatform == 'Lichess', onSelected: (s) { setState(() { _selectedPlatform = 'Lichess'; _liveSuggestions = []; }); }, selectedColor: const Color(0xFF5C6BC0), backgroundColor: const Color(0xFF151B2B)),
                      const SizedBox(width: 15),
                      ChoiceChip(label: const Text('Chess.com'), selected: _selectedPlatform == 'Chess.com', onSelected: (s) { setState(() { _selectedPlatform = 'Chess.com'; _liveSuggestions = []; }); }, selectedColor: const Color(0xFF32804A), backgroundColor: const Color(0xFF151B2B)),
                    ]), const SizedBox(height: 12),
                  ],
                ) : const SizedBox(width: double.infinity, height: 0),
              ),
              
              TextField(
                focusNode: _searchFocusNode,
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                onTap: () {
                  setState(() {
                    _isHeaderVisible = true;
                    _showSearchHistory = _usernameController.text.trim().isNotEmpty || GlobalLibrary.searchHistory.isNotEmpty;
                  });
                },
                onChanged: _onSearchChanged, 
                onSubmitted: (_) => fetchPlayerStats(),
                decoration: InputDecoration(
                  hintText: '$_selectedPlatform ${LanguageService.get('player_search_placeholder')}', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor, width: 2)),
                  filled: true, fillColor: const Color(0xFF151B2B), 
                  prefixIcon: Icon(Icons.search, color: themeColor)
                ),
              ),
              
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showSearchHistory && combinedSuggestions.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101A2B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF24314D)),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            shrinkWrap: true,
                            itemCount: combinedSuggestions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                            itemBuilder: (context, index) {
                              final option = combinedSuggestions[index];
                              bool isHistory = GlobalLibrary.searchHistory.any((h) => h.toLowerCase() == option.toLowerCase());
                              
                              return ListTile(
                                dense: true,
                                leading: Icon(isHistory ? Icons.history : Icons.person_search, color: isHistory ? Colors.white54 : themeColor, size: 18),
                                title: Text(option, style: TextStyle(color: isHistory ? Colors.white : Colors.white, fontWeight: isHistory ? FontWeight.w500 : FontWeight.bold)),
                                onTap: () {
                                  _usernameController.text = option;
                                  setState(() => _showSearchHistory = false);
                                  fetchPlayerStats();
                                },
                              );
                            },
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              
              AnimatedSize(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic, alignment: Alignment.topCenter,
                child: _isHeaderVisible ? Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: fetchPlayerStats, child: Text(LanguageService.get('find_player'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: themeColor, backgroundColor: const Color(0xFF151B2B), side: BorderSide(color: themeColor), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _showPgnInputDialog, child: Text(LanguageService.get('analyze_with_pgn'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: themeColor)))),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: const Color(0xFF151B2B), side: const BorderSide(color: Colors.greenAccent), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.library_books, color: Colors.greenAccent), label: Text(LanguageService.get('library_saved_matches'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.greenAccent)), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryPage())); }, )),
                    const SizedBox(height: 8),
                    // --- YENİ EKLENEN BULMACALAR BUTONU ---
                  SizedBox(
                    width: double.infinity, 
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, 
                        backgroundColor: const Color(0xFF151B2B), 
                        side: const BorderSide(color: Colors.orangeAccent), 
                        padding: const EdgeInsets.symmetric(vertical: 14), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ), 
                      icon: const Icon(Icons.extension, color: Colors.orangeAccent), 
                      label: Text(
                        LanguageService.get('puzzles'), 
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orangeAccent)
                      ), 
                      onPressed: () { 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PuzzlesPage())); 
                      }, 
                    )
                  ),
                  const SizedBox(height: 8),
                  // ----------------------------------------
                  ],
                ) : const SizedBox(width: double.infinity, height: 0),
              ),

              if (_isLoading) Padding(padding: const EdgeInsets.only(top: 40.0), child: CircularProgressIndicator(color: themeColor)),
              if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              if (_playerProfile != null) ...[
                Card(
                  elevation: 8, color: const Color(0xFF151B2B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.person, size: 36, color: themeColor), const SizedBox(width: 10), 
                        // EĞER kişinin unvanı varsa VEYA kişi bağışçıysa etiketi çiz
                       buildUserTags((_playerProfile!['title'] ?? '').toString(), _isUserDonor),
                        Flexible(child: Text(_playerProfile!['username'] ?? 'Bilinmeyen', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      ]),
                      const Divider(height: 30, thickness: 1, color: Color(0xFF2A3650)),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildEloColumn('Rapid', _playerProfile!['rapid'], 'rapid', themeColor), _buildEloColumn('Blitz', _playerProfile!['blitz'], 'blitz', themeColor), _buildEloColumn('Bullet', _playerProfile!['bullet'], 'bullet', themeColor)]),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                if (_playerStyleProfile != null) _buildPlayerStyleWidget(_playerStyleProfile!),
                const SizedBox(height: 25),
                Align(alignment: Alignment.centerLeft, child: Text(_selectedTempo == 'all' ? LanguageService.get('recent_matches') : '${LanguageService.tempoLabel(_selectedTempo)} - ${LanguageService.get('recent_matches')}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor))),
                const SizedBox(height: 15),
                
                if (_recentMatches.isEmpty && !_isMatchesLoading) Text(LanguageService.get('no_match_data'), style: const TextStyle(color: Colors.white54))
                else ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _recentMatches.length,
                  itemBuilder: (context, index) {
                    var match = _recentMatches[index];
                    String sUser = _playerProfile!['username'].toString().toLowerCase();
                    String w = match['white'].toString().toLowerCase();
                    String b = match['black'].toString().toLowerCase();
                    bool uWon = (match['winner'] == 'white' && w == sUser) || (match['winner'] == 'black' && b == sUser);
                    bool uLost = (match['winner'] == 'white' && b == sUser) || (match['winner'] == 'black' && w == sUser);
                    Color rColor = const Color(0xFF151B2B); Color aColor = Colors.grey;
                    if (uWon) { rColor = const Color(0xFF66BB6A).withValues(alpha: 0.12); aColor = const Color(0xFF66BB6A); } 
                    else if (uLost) { rColor = const Color(0xFFEF5350).withValues(alpha: 0.12); aColor = const Color(0xFFEF5350); }
                    return Card(
                      color: rColor, margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: aColor.withValues(alpha: 0.2), width: 1)),
                      child: ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: aColor.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.sports_esports, color: Colors.white)),
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if ((match['whiteTitle'] ?? '').toString().isNotEmpty) buildTitleTag(match['whiteTitle']),
                            Text(match['white'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text(' vs ', style: TextStyle(color: Colors.white54)),
                            if ((match['blackTitle'] ?? '').toString().isNotEmpty) buildTitleTag(match['blackTitle']),
                            Text(match['black'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        subtitle: Text('${LanguageService.get('mode')}: ${match['speed']}', style: TextStyle(color: aColor, fontWeight: FontWeight.bold)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: aColor.withValues(alpha: 0.8)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisPage(matchData: match, boardOrientation: w == sUser ? PlayerColor.white : PlayerColor.black, apiHeaders: _apiHeaders))),
                      ),
                    );
                  },
                ),
                if (_recentMatches.isNotEmpty && !_isMatchesLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 12.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () => fetchPlayerStats(loadMore: true),
                      child: Text(LanguageService.get('load_more_games')),
                    ),
                  ),
                if (_isMatchesLoading) Padding(padding: const EdgeInsets.all(10), child: CircularProgressIndicator(color: themeColor))
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CustomArrowPainter extends CustomPainter {
  final String from;
  final String to;
  final PlayerColor orientation;
  final Color color;

  CustomArrowPainter({required this.from, required this.to, required this.orientation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (from.length < 2 || to.length < 2) return;
    double sqSize = size.width / 8;

    int fileFrom = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rankFrom = 8 - int.parse(from[1]);
    int fileTo = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rankTo = 8 - int.parse(to[1]);

    if (orientation == PlayerColor.black) {
      fileFrom = 7 - fileFrom; rankFrom = 7 - rankFrom;
      fileTo = 7 - fileTo; rankTo = 7 - rankTo;
    }

    Offset start = Offset(fileFrom * sqSize + sqSize / 2, rankFrom * sqSize + sqSize / 2);
    Offset end = Offset(fileTo * sqSize + sqSize / 2, rankTo * sqSize + sqSize / 2);

    Paint paint = Paint()
      ..color = color
      ..strokeWidth = sqSize * 0.22 
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; 

    double arrowSize = sqSize * 0.45;
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double distance = sqrt(dx * dx + dy * dy);
    double angle = atan2(dy, dx);
    
    // Okun baş kısmıyla çizginin daha düzgün çakışması için
    double pullBack = arrowSize * 0.75 + (paint.strokeWidth / 2);
    Offset lineEnd = end;
    if (distance > pullBack) {
      lineEnd = Offset(end.dx - pullBack * cos(angle), end.dy - pullBack * sin(angle));
      canvas.drawLine(start, lineEnd, paint);
    }

    _drawArrowHead(canvas, start, end, arrowSize, paint);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, double arrowSize, Paint paint) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double angle = atan2(dy, dx);
    
    Offset p1 = Offset(end.dx - arrowSize * cos(angle - pi / 6.5), end.dy - arrowSize * sin(angle - pi / 6.5));
    Offset p2 = Offset(end.dx - arrowSize * cos(angle + pi / 6.5), end.dy - arrowSize * sin(angle + pi / 6.5));
    
    Path path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.close();

    Paint headPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawPath(path, headPaint);
  }

  @override
  bool shouldRepaint(CustomArrowPainter oldDelegate) {
    return oldDelegate.from != from || oldDelegate.to != to || oldDelegate.orientation != orientation;
  }
}

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get('puzzle_username_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF151B2B),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: LanguageService.get('settings'),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Firestore'dan verileri score'a göre azalan şekilde çek (İlk 50 kişi)
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('score', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Veri çekilemedi: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }
          
          final users = snapshot.data?.docs ?? [];
          if (users.isEmpty) {
            return Center(child: Text(LanguageService.get('puzzle_no_solvers'), style: const TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var data = users[index].data() as Map<String, dynamic>;
              String name = data['username'] ?? users[index].id;
              String? title = data['title']; // Lichess title
              
              // Patron verisi eskiden string, yeni olarak bool kaydedildiği için güvenli kontrol:
              var pData = data['patron'];
              bool isPatron = false;
              if (pData is bool) isPatron = pData;
              else if (pData is String) isPatron = pData == 'true';
              
              int score = data['score'] ?? 0;
              
              // Termo_x için garanti easter egg
              if (name.toLowerCase() == 'termo_x') {
                title = 'TermoGM';
              }

              // İlk 3'e özel renkler
              Color rankColor = Colors.white54;
              if (index == 0) {
                rankColor = const Color(0xFFFFD700); // Altın
              } else if (index == 1) rankColor = const Color(0xFFC0C0C0); // Gümüş
              else if (index == 2) rankColor = const Color(0xFFCD7F32); // Bronz

              return Card(
                color: const Color(0xFF151B2B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: rankColor.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rankColor.withValues(alpha: 0.2),
                    child: Text('#${index + 1}', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildUserTags(title ?? '', isPatron),
                      Flexible(
                        child: Text(
                          name, 
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isPatron ? Colors.orangeAccent : Colors.white, fontWeight: FontWeight.bold)
                        )
                      ),
                    ],
                  ),
                  trailing: Text('$score ${LanguageService.get('puzzle_score_points')}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () {
                    if (name.toLowerCase() == 'misafir') return;
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => HomePage(initialUsername: name)), 
                      (route) => false
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 
class AnalysisPage extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final PlayerColor boardOrientation;
  final Map<String, String> apiHeaders;

  const AnalysisPage({super.key, required this.matchData, required this.boardOrientation, required this.apiHeaders});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late ChessBoardController controller;
  final ScrollController _pageScrollController = ScrollController(); 
  late PlayerColor _currentOrientation; 
  
  List<String> _allMoves = []; 
  List<String> _fenList = []; 
  int _currentMoveIndex = 0;

  final Map<int, double> _cachedValues = {}; 
  final Map<int, String> _cachedTexts = {};
  final Map<int, List<String>> _cachedSuggestions = {};
  final Map<int, List<double>> _alternativeMoveEvals = {}; 
  final Map<int, MoveAnalysis> _moveAnalyses = {};

  double _evaluationValue = 0.3; 
  String _evaluationText = "+0.3";
  List<String> _topEngineMoves = ['...', '...', '...'];

  bool _isAnalyzing = false;
  bool _analysisDone = false;
  bool _isDisposed = false; 
  bool _isSaved = false; 
  double _whiteAccuracy = 0.0;
  double _blackAccuracy = 0.0;
  double _analysisProgress = 0.0;

  Map<String, int> _whiteMoveStats = {'brilliant': 0, 'great': 0, 'best': 0, 'excellent': 0, 'good': 0, 'inaccuracy': 0, 'mistake': 0, 'blunder': 0};
  Map<String, int> _blackMoveStats = {'brilliant': 0, 'great': 0, 'best': 0, 'excellent': 0, 'good': 0, 'inaccuracy': 0, 'mistake': 0, 'blunder': 0};

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    _currentMoveIndex = 0; 
    _currentOrientation = widget.boardOrientation;
    
    _isSaved = GlobalLibrary.isSaved(widget.matchData['pgn'] ?? '', widget.matchData['moves'] ?? '');
    
    ChessEngineService().initEngine();
    _generateAllFens();
    
    _cachedValues[0] = 0.3;
    _cachedTexts[0] = "+0.3";
    _cachedSuggestions[0] = ['e2e4', 'd2d4', 'g1f3', 'c2c4', 'g2g3'];
    _alternativeMoveEvals[0] = [0.3, 0.3, 0.3, 0.3, 0.3];
    
    _loadBoardToCurrentIndex();
  }

  @override
  void dispose() {
    _isDisposed = true;
    ChessEngineService().stopContinuousAnalysis();
    _pageScrollController.dispose();
    super.dispose();
  }

  void _sharePgn() async {
    String pgn = widget.matchData['pgn'] ?? '';
    String moves = widget.matchData['moves'] ?? '';
    
    if (pgn.isEmpty && moves.isNotEmpty) {
      String white = widget.matchData['white'] ?? 'Beyaz';
      String black = widget.matchData['black'] ?? 'Siyah';
      String date = DateTime.now().toString().split(' ')[0].replaceAll('-', '.');
      pgn = '[Event "MoveLab Analiz"]\n[Site "MoveLab App"]\n[Date "$date"]\n[White "$white"]\n[Black "$black"]\n[Result "${widget.matchData['winner'] == 'white' ? '1-0' : widget.matchData['winner'] == 'black' ? '0-1' : '1/2-1/2'}"]\n\n';
      List<String> moveList = moves.trim().split(RegExp(r'\s+'));
      String formattedMoves = '';
      for (int i = 0; i < moveList.length; i++) {
        if (i % 2 == 0) formattedMoves += '${(i ~/ 2) + 1}. ';
        formattedMoves += '${moveList[i]} ';
      }
      pgn += formattedMoves.trim();
    }
    if (pgn.isNotEmpty) {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share('$pgn\n\n📲 App: https://play.google.com/store/apps/details?id=com.movelab.app', subject: 'MoveLab - ${LanguageService.get('share_pgn')}', sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null);
    }
  }

  void _toggleLibrary() {
    String pgn = widget.matchData['pgn'] ?? '';
    String moves = widget.matchData['moves'] ?? '';
    if (pgn.isEmpty && moves.isEmpty) return;

    if (_isSaved) {
      if (pgn.isNotEmpty) {
        GlobalLibrary.matches.removeWhere((m) => m.pgn == pgn);
      } else {
        GlobalLibrary.matches.removeWhere((m) => m.moves == moves);
      }
      setState(() { _isSaved = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.get('match_deleted')), backgroundColor: Colors.redAccent));
    } else {
      GlobalLibrary.matches.add(SavedMatch(
        title: '${widget.matchData['white']} vs ${widget.matchData['black']}',
        whiteName: widget.matchData['white'] ?? 'Beyaz', blackName: widget.matchData['black'] ?? 'Siyah',
        whiteTitle: widget.matchData['whiteTitle'] ?? '', blackTitle: widget.matchData['blackTitle'] ?? '',
        pgn: pgn, speed: widget.matchData['speed'] ?? 'PGN', moves: moves,
        winner: widget.matchData['winner'] ?? 'draw', userColor: widget.boardOrientation,
        whiteRating: widget.matchData['whiteRating'] ?? 0, blackRating: widget.matchData['blackRating'] ?? 0,
        platform: widget.matchData['platform'] ?? 'Bilinmiyor',
      ));
      setState(() { _isSaved = true; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.get('match_added')), backgroundColor: const Color(0xFF5C6BC0)));
    }
    GlobalLibrary.saveMatches();
  }


  void _generateAllFens() {
    _fenList = []; _allMoves = [];
    chess_engine.Chess chess = chess_engine.Chess();
    _fenList.add(chess.fen);

    String uciMoves = widget.matchData['moves'] ?? '';
    String pgn = widget.matchData['pgn'] ?? '';

    if (uciMoves.isNotEmpty) {
      for (String m in uciMoves.trim().split(RegExp(r'\s+'))) {
        if (m.isEmpty) continue; 
        bool success = false;
        if (m.length >= 4) {
          Map<String, dynamic> moveData = {"from": m.substring(0, 2), "to": m.substring(2, 4)};
          if (m.length > 4) moveData["promotion"] = m.substring(4, 5).toLowerCase(); 
          success = chess.move(moveData);
        }
        if (!success) success = chess.move(m); 
        if (success) { _fenList.add(chess.fen); _allMoves.add(m); }
      }
    } else {
      String cleaned = pgn.replaceAll('\n', ' ').replaceAll(RegExp(r'\[.*?\]|\{.*?\}|\([^)]*\)|(1-0|0-1|1/2-1/2|\*)|\d+\.+'), ' ');
      for (String san in cleaned.split(RegExp(r'\s+')).where((m) => m.isNotEmpty)) {
        if (chess.move(san)) { _fenList.add(chess.fen); _allMoves.add(san); }
      }
    }
  }

  void _startLiveEvaluationForCurrentMove() {
    int index = _currentMoveIndex;
    String fen = _fenList[index];

    if (fen == 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1') {
      if (mounted) {
        setState(() {
          _evaluationValue = 0.3; _evaluationText = "+0.3";
          _topEngineMoves = ['e2e4', 'd2d4', 'g1f3']; // Arayüzde sadece ilk 3 gösterilir
          _cachedValues[index] = 0.3; _cachedTexts[index] = "+0.3"; 
          _cachedSuggestions[index] = ['e2e4', 'd2d4', 'g1f3', 'c2c4', 'g2g3'];
        });
      }
      return; 
    }

    ChessEngineService().startContinuousAnalysis(fen, (updateData) {
      if (!mounted || _currentMoveIndex != index || _isAnalyzing) return;

      double rawEval = updateData['best_eval'] ?? 0.0;
      bool isMate = updateData['is_mate'] ?? false;
      List<String> suggs = List<String>.from(updateData['suggestions'] ?? ['', '', '', '', '']);

      String evalTxt = isMate || rawEval.abs() > 14.0 
          ? (rawEval > 0 ? '+M' : '-M') 
          : (rawEval > 0 ? '+${rawEval.toStringAsFixed(1)}' : rawEval.toStringAsFixed(1));

      for (int i = 0; i < 5; i++) { if (i >= suggs.length || suggs[i].isEmpty) suggs.add('-'); }

      setState(() {
        _evaluationValue = rawEval;
        _evaluationText = evalTxt;
        _topEngineMoves = suggs.take(3).toList();
        
        _cachedValues[index] = rawEval;
        _cachedTexts[index] = evalTxt;
        _cachedSuggestions[index] = suggs;
      });
    });
  }

  void _loadBoardToCurrentIndex() {
    if (_currentMoveIndex < _fenList.length) { 
      controller.loadFen(_fenList[_currentMoveIndex]); 
    }
    
    if (_cachedValues.containsKey(_currentMoveIndex)) {
      _evaluationValue = _cachedValues[_currentMoveIndex]!;
      _evaluationText = _cachedTexts[_currentMoveIndex]!;
      _topEngineMoves = _cachedSuggestions[_currentMoveIndex] ?? ['...', '...', '...'];
    } else {
      _evaluationText = LanguageService.get('analyzing');
      _topEngineMoves = ['...', '...', '...'];
    }

    setState(() {});
    if (!_isAnalyzing) { _startLiveEvaluationForCurrentMove(); }
  }

  void _playEngineMove(String moveStr) {
    if (moveStr == '-' || moveStr == '...' || moveStr.length < 4) return;
    chess_engine.Chess chess = chess_engine.Chess();
    chess.load(_fenList[_currentMoveIndex]);
    
    Map<String, dynamic> moveData = {"from": moveStr.substring(0, 2), "to": moveStr.substring(2, 4)};
    if (moveStr.length > 4) moveData["promotion"] = moveStr.substring(4, 5).toLowerCase();
    
    if (chess.move(moveData)) {
      setState(() {
        _fenList.removeRange(_currentMoveIndex + 1, _fenList.length);
        _allMoves.removeRange(_currentMoveIndex, _allMoves.length);
        _fenList.add(chess.fen);
        _allMoves.add(moveStr);
        _analysisDone = false; 
      });
      _goToMove(_currentMoveIndex + 1);
    }
  }

  List<String> _boardFiles() {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return _currentOrientation == PlayerColor.white ? files : files.reversed.toList();
  }

  List<String> _boardRanks() {
    return _currentOrientation == PlayerColor.white
        ? List<String>.generate(8, (index) => '${8 - index}')
        : List<String>.generate(8, (index) => '${index + 1}');
  }

Widget _buildCoordinateLabel(String text) {
    return SizedBox(
      width: 16, height: 16,
      child: Center(
        child: Text(
          text, 
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72), 
            fontSize: 9, 
            fontWeight: FontWeight.w600, 
            height: 1
          )
        ),
      ),
    );
  }

Widget _buildAnnotatedBoard() {
    final boardFiles = _boardFiles();
    final boardRanks = _boardRanks();
    
    bool shouldShowArrow = SoundService.showArrows && _topEngineMoves[0].length >= 4 && _topEngineMoves[0] != '...';
    String fromSquare = shouldShowArrow ? _topEngineMoves[0].substring(0, 2) : '';
    String toSquare = shouldShowArrow ? _topEngineMoves[0].substring(2, 4) : '';

    return ClipRect(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ChessBoard(
                  controller: controller,
                  boardColor: BoardColor.green,
                  boardOrientation: _currentOrientation,
                ),
              ),
            ),
            if (shouldShowArrow)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12.0), 
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CustomArrowPainter(
                        from: fromSquare,
                        to: toSquare,
                        orientation: _currentOrientation,
                        color: const Color(0xFF3F6CFF).withValues(alpha: 0.8), 
                      ),
                    ),
                  ),
                ),
              ),
            // BEYAZ HARFLER (ALT KISIM)
            Positioned(
              left: 12, right: 12, bottom: 0,
              child: SizedBox(
                height: 14,
                child: Row(children: boardFiles.map((e) => Expanded(child: Center(child: _buildCoordinateLabel(e)))).toList()),
              ),
            ),
            // BEYAZ SAYILAR (SOL KISIM)
            Positioned(
              top: 12, bottom: 12, left: 0,
              child: SizedBox(
                width: 14,
                child: Column(children: boardRanks.map((e) => Expanded(child: Center(child: _buildCoordinateLabel(e)))).toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToMove(int index) {
    if (index < 0 || index >= _fenList.length) { return; }
    
    if (index > 0 && index - 1 < _allMoves.length) {
      bool isCapture = _allMoves[index - 1].contains('x');
      SoundService.playMoveSound(isCapture);
    } else if (index == 0) {
      SoundService.playMoveSound(false);
    }

    setState(() { _currentMoveIndex = index; });
    _loadBoardToCurrentIndex();
  }

  Future<void> _runInlineAnalysis() async {
    if (_isAnalyzing) return;

    ChessEngineService().stopContinuousAnalysis();
    setState(() { _isAnalyzing = true; _analysisDone = false; _analysisProgress = 0.0; });

    try {
      List<int> missingIndices = [];
      for (int i = 0; i < _fenList.length; i++) {
        if (!_cachedValues.containsKey(i)) missingIndices.add(i);
      }

      for (int i = 0; i < missingIndices.length; i++) {
        if (!mounted || _isDisposed) break;
        int index = missingIndices[i];

        try { await _fetchSingleEvalToCache(index, depth: 20, maxTimeMs: 600, force: true); } 
        catch (e) { debugPrint("Motor bir hamleyi atladı: $e"); }

        if (mounted) setState(() { _analysisProgress = (i + 1) / (missingIndices.isEmpty ? 1 : missingIndices.length); });
      }

      _fillAllMissingEvaluations();
      _computeAccuracyAndCategories();

      if (mounted) setState(() { _analysisDone = true; });
    } catch (e) {
      debugPrint("Kritik Analiz Hatası: $e");
    } finally {
      if (mounted) {
        setState(() { _isAnalyzing = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageScrollController.hasClients) {
            _pageScrollController.animateTo(_pageScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
          }
        });
        _startLiveEvaluationForCurrentMove();
      }
    }
  }

  Future<void> _fetchSingleEvalToCache(int index, {int depth = 20, int maxTimeMs = 600, bool force = false}) async {
    if (index >= _fenList.length || (!force && _cachedValues.containsKey(index))) { return; }
    
    if (_fenList[index] == 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1') {
      _cachedValues[index] = 0.3; _cachedTexts[index] = "+0.3"; 
      _cachedSuggestions[index] = ['e2e4', 'd2d4', 'g1f3', 'c2c4', 'g2g3']; 
      _alternativeMoveEvals[index] = [0.3, 0.3, 0.3, 0.3, 0.3];
      if (_currentMoveIndex == index && mounted) setState(() { _evaluationValue = 0.3; _evaluationText = "+0.3"; _topEngineMoves = _cachedSuggestions[index]!.take(3).toList(); });
      return;
    }

    chess_engine.Chess chessCheck = chess_engine.Chess();
    chessCheck.load(_fenList[index]);
    
    if (chessCheck.in_checkmate) {
      bool isWhiteTurn = _fenList[index].split(' ')[1] == 'w';
      double val = isWhiteTurn ? -15.0 : 15.0; 
      _cachedValues[index] = val; _cachedTexts[index] = isWhiteTurn ? "-M" : "+M";
      _cachedSuggestions[index] = ['#', '#', '#', '#', '#']; _alternativeMoveEvals[index] = [val, val, val, val, val];
      if (_currentMoveIndex == index && mounted) setState(() { _evaluationValue = val; _evaluationText = _cachedTexts[index]!; _topEngineMoves = ['#', '#', '#']; });
      return;
    } else if (chessCheck.in_draw || chessCheck.in_stalemate || chessCheck.in_threefold_repetition || chessCheck.insufficient_material) {
      _cachedValues[index] = 0.0; _cachedTexts[index] = "0.0";
      _cachedSuggestions[index] = ['=', '=', '=', '=', '=']; _alternativeMoveEvals[index] = [0.0, 0.0, 0.0, 0.0, 0.0];
      if (_currentMoveIndex == index && mounted) setState(() { _evaluationValue = 0.0; _evaluationText = "0.0"; _topEngineMoves = ['=', '=', '=']; });
      return;
    }

    var engineData = await ChessEngineService().evaluateFen(_fenList[index], depth: depth, maxTimeMs: maxTimeMs);
    
    double val = engineData['best_eval'] ?? 0.0;
    bool isMate = engineData['is_mate'] ?? false;
    _alternativeMoveEvals[index] = engineData['alternatives'] ?? <double>[0.0, 0.0, 0.0, 0.0, 0.0];

    List<String> suggs = List<String>.from(engineData['suggestions'] ?? ['', '', '', '', '']);
    for (int i = 0; i < 5; i++) { if (i >= suggs.length || suggs[i].isEmpty) suggs.add('-'); }
    String txt = isMate || val.abs() > 14.0 ? (val > 0 ? '+M' : '-M') : (val > 0 ? '+${val.toStringAsFixed(1)}' : val.toStringAsFixed(1));
    
    _cachedValues[index] = val; _cachedTexts[index] = txt; _cachedSuggestions[index] = suggs;
    if (_currentMoveIndex == index && mounted) setState(() { _evaluationValue = val; _evaluationText = txt; _topEngineMoves = suggs.take(3).toList(); });
  }

  void _fillAllMissingEvaluations() {
    for (int i = 0; i < _fenList.length; i++) {
      if (!_cachedValues.containsKey(i)) _cachedValues[i] = 0.0;
      if (!_cachedTexts.containsKey(i)) _cachedTexts[i] = "0.0";
      if (!_cachedSuggestions.containsKey(i)) _cachedSuggestions[i] = ['...', '...', '...', '...', '...'];
      if (!_alternativeMoveEvals.containsKey(i)) _alternativeMoveEvals[i] = [0.0, 0.0, 0.0, 0.0, 0.0];
    }
  }

  void _computeAccuracyAndCategories() {
    _whiteMoveStats = {'brilliant': 0, 'great': 0, 'best': 0, 'excellent': 0, 'good': 0, 'inaccuracy': 0, 'mistake': 0, 'blunder': 0};
    _blackMoveStats = {'brilliant': 0, 'great': 0, 'best': 0, 'excellent': 0, 'good': 0, 'inaccuracy': 0, 'mistake': 0, 'blunder': 0};

    double whiteWeightedAccTotal = 0, blackWeightedAccTotal = 0, whiteWeightSum = 0, blackWeightSum = 0;

    for (int i = 0; i < _fenList.length - 1; i++) {
      double bestEval = _cachedValues[i]!.clamp(-15.0, 15.0);
      double playedEval = _cachedValues[i + 1]!.clamp(-15.0, 15.0);
      bool isWhiteMove = _fenList[i].split(' ')[1] == 'w';
      bool isBeforeMate = _cachedTexts[i]?.contains('M') ?? false;
      bool isAfterMate = _cachedTexts[i + 1]?.contains('M') ?? false;

      double accuracy = AccuracyCalculator.calculateMoveAccuracy(bestEval, playedEval, isWhiteMove, isBeforeMate, isAfterMate);
      
      int sacType = TacticalDetector.detectSacrificeType(i, _fenList, isWhiteMove, playedEval, bestEval);
      List<double> alts = _alternativeMoveEvals[i] ?? <double>[];
      bool isMateFound = _cachedTexts[i + 1]!.contains('M') || playedEval.abs() > 14.0;

      String qualityLabel = AdvancedClassifier.classifyMove(
        bestEval: bestEval, playedEval: playedEval, accuracy: accuracy, 
        alternatives: alts, isWhiteMove: isWhiteMove, isMateFound: isMateFound, sacrificeType: sacType
      );

      bool isBrill = qualityLabel == "Etkileyici Hamle";
      bool isGt = qualityLabel == "Harika Hamle";

      _moveAnalyses[i] = MoveAnalysis(bestEval: bestEval, playedEval: playedEval, accuracy: accuracy, qualityLabel: qualityLabel, isBrilliant: isBrill, isGreat: isGt);
      double weight = AnalysisPhaseWeight.getWeight(i);

      var targetStats = isWhiteMove ? _whiteMoveStats : _blackMoveStats;
      if (isWhiteMove) { whiteWeightedAccTotal += accuracy * weight; whiteWeightSum += weight; } 
      else { blackWeightedAccTotal += accuracy * weight; blackWeightSum += weight; }

      if (isBrill) {
        targetStats['brilliant'] = targetStats['brilliant']! + 1;
      } else if (isGt) targetStats['great'] = targetStats['great']! + 1;
      else if (qualityLabel == "En İyi Hamle") targetStats['best'] = targetStats['best']! + 1;
      else if (qualityLabel == "Mükemmel") targetStats['excellent'] = targetStats['excellent']! + 1;
      else if (qualityLabel == "İyi Hamle") targetStats['good'] = targetStats['good']! + 1;
      else if (qualityLabel == "Şüpheli Hamle") targetStats['inaccuracy'] = targetStats['inaccuracy']! + 1;
      else if (qualityLabel == "Kötü Hamle") targetStats['mistake'] = targetStats['mistake']! + 1;
      else targetStats['blunder'] = targetStats['blunder']! + 1;
    }
    _whiteAccuracy = whiteWeightSum > 0 ? whiteWeightedAccTotal / whiteWeightSum : 100.0;
    _blackAccuracy = blackWeightSum > 0 ? blackWeightedAccTotal / blackWeightSum : 100.0;
  }
  @override
  Widget build(BuildContext context) {
    double whitePercentage = 0.5 + (_evaluationValue / 10.0); 
    if (whitePercentage < 0.05) { whitePercentage = 0.05; }
    if (whitePercentage > 0.95) { whitePercentage = 0.95; }

    String whiteName = widget.matchData['white'] ?? LanguageService.get('player'); String blackName = widget.matchData['black'] ?? LanguageService.get('player');
    String whiteTitle = widget.matchData['whiteTitle'] ?? ''; String blackTitle = widget.matchData['blackTitle'] ?? '';
    int whiteRating = widget.matchData['whiteRating'] ?? 0; int blackRating = widget.matchData['blackRating'] ?? 0;
    
    String topName = _currentOrientation == PlayerColor.white ? blackName : whiteName;
    String topTitle = _currentOrientation == PlayerColor.white ? blackTitle : whiteTitle;
    String topRating = _currentOrientation == PlayerColor.white ? (blackRating > 0 ? blackRating.toString() : '?') : (whiteRating > 0 ? whiteRating.toString() : '?');

    String bottomName = _currentOrientation == PlayerColor.white ? whiteName : blackName;
    String bottomTitle = _currentOrientation == PlayerColor.white ? whiteTitle : blackTitle;
    String bottomRating = _currentOrientation == PlayerColor.white ? (whiteRating > 0 ? whiteRating.toString() : '?') : (blackRating > 0 ? blackRating.toString() : '?');

    Color whiteAccuracyColor = _whiteAccuracy < _blackAccuracy ? Colors.orangeAccent : Colors.greenAccent;
    Color blackAccuracyColor = _whiteAccuracy < _blackAccuracy ? Colors.greenAccent : Colors.orangeAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get('analysis_laboratory'), style: const TextStyle(fontSize: 14)), 
        backgroundColor: const Color(0xFF151B2B),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white70), tooltip: LanguageService.get('settings'), onPressed: () => showSettingsSheet(context, onChanged: () => setState(() {}))),
          IconButton(icon: const Icon(Icons.swap_vert, color: Colors.white70), tooltip: LanguageService.get('rotate_board'), onPressed: () { setState(() { _currentOrientation = _currentOrientation == PlayerColor.white ? PlayerColor.black : PlayerColor.white; }); }),
          IconButton(icon: const Icon(Icons.share, color: Colors.white70), tooltip: LanguageService.get('share_pgn'), onPressed: _sharePgn),
          IconButton(icon: AnimatedSwitcher(duration: const Duration(milliseconds: 300), transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child), child: Icon(_isSaved ? Icons.check_circle : Icons.library_add, key: ValueKey<bool>(_isSaved), color: _isSaved ? Colors.greenAccent : Colors.white)), tooltip: _isSaved ? LanguageService.get('remove_from_library') : LanguageService.get('save_to_library'), onPressed: _toggleLibrary),
        ],
      ),
      body: SingleChildScrollView(
        controller: _pageScrollController, 
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300), width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Icon(Icons.analytics, size: 20),
                  label: Text(_isAnalyzing ? '${LanguageService.get('analyzing')} %${(_analysisProgress * 100).toInt()}' : LanguageService.get('analyze_match'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: _isAnalyzing ? Colors.orange.shade700 : const Color(0xFF283593), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _isAnalyzing ? null : _runInlineAnalysis,
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14.0), child: Align(alignment: Alignment.centerLeft, child: Row(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)), child: Icon(Icons.person, color: Colors.grey[400], size: 16)), const SizedBox(width: 8), if(topTitle.isNotEmpty) buildTitleTag(topTitle), Text(topName, style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(width: 6), Text('($topRating)', style: TextStyle(color: Colors.grey[500], fontSize: 13))]))),
            const SizedBox(height: 6),
            
            Container(
              padding: const EdgeInsets.all(4.0), margin: const EdgeInsets.symmetric(horizontal: 10), 
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF1A237E)], begin: Alignment.topLeft, end: Alignment.bottomRight)), 
              child: _buildAnnotatedBoard()
            ),
            
            const SizedBox(height: 6),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14.0), child: Align(alignment: Alignment.centerLeft, child: Row(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.person, color: Colors.white, size: 16)), const SizedBox(width: 8), if(bottomTitle.isNotEmpty) buildTitleTag(bottomTitle), Text(bottomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(width: 6), Text('($bottomRating)', style: const TextStyle(color: Colors.white70, fontSize: 13))]))),
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 14, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF151B2B), borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(children: [AnimatedContainer(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, height: 14, width: constraints.maxWidth * whitePercentage, color: Colors.white)]),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 150), curve: Curves.easeOutQuint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white), child: Text("${LanguageService.get('analysis_engine')}: $_evaluationText")),
                      if (_analysisDone && _currentMoveIndex > 0 && _moveAnalyses.containsKey(_currentMoveIndex - 1))
                        Builder(
                          builder: (context) {
                            var analysis = _moveAnalyses[_currentMoveIndex - 1]!;
                            Color bgColor = Colors.grey; String icon = "";
                            if (analysis.isBrilliant) { bgColor = Colors.cyan; icon = " !!"; }
                            else if (analysis.isGreat) { bgColor = const Color(0xFF64FFDA); icon = " !"; }
                            else if (analysis.accuracy >= 99.2) { bgColor = Colors.green; }
                            else if (analysis.accuracy >= 88.0) { bgColor = const Color(0xFFAED581); }
                            else if (analysis.accuracy >= 65.0) { bgColor = Colors.amber; icon = " ?!"; }
                            else if (analysis.accuracy >= 40.0) { bgColor = Colors.orange; icon = " ?"; }
                            else { bgColor = Colors.red; icon = " ??"; }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: bgColor.withValues(alpha: 0.5))),
                              child: Text("${LanguageService.displayQualityLabel(analysis.qualityLabel)}$icon", style: TextStyle(color: bgColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            );
                          }
                        )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF111826), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFF1E2A46), width: 1.2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(color: _currentMoveIndex > 0 ? const Color(0xFF1F2D4B) : const Color(0xFF0D1422), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: _currentMoveIndex > 0 ? () => _goToMove(0) : null, child: Container(padding: const EdgeInsets.all(10), child: Icon(Icons.fast_rewind, size: 18, color: _currentMoveIndex > 0 ? const Color(0xFF8BD1FF) : const Color(0xFF4A5D7E))))),
                  const SizedBox(width: 4),
                  Material(color: _currentMoveIndex > 0 ? const Color(0xFF1F2D4B) : const Color(0xFF0D1422), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: _currentMoveIndex > 0 ? () => _goToMove(_currentMoveIndex - 1) : null, child: Container(padding: const EdgeInsets.all(10), child: Icon(Icons.arrow_back_ios_new, size: 18, color: _currentMoveIndex > 0 ? const Color(0xFF8BD1FF) : const Color(0xFF4A5D7E))))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF0B1422), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF1E2A46), width: 1)), child: Text("$_currentMoveIndex / ${_fenList.isNotEmpty ? _fenList.length - 1 : 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8BD1FF), fontSize: 12))),
                  const SizedBox(width: 4),
                  Material(color: _currentMoveIndex < _fenList.length - 1 ? const Color(0xFF1F2D4B) : const Color(0xFF0D1422), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: _currentMoveIndex < _fenList.length - 1 ? () => _goToMove(_currentMoveIndex + 1) : null, child: Container(padding: const EdgeInsets.all(10), child: Icon(Icons.arrow_forward_ios, size: 18, color: _currentMoveIndex < _fenList.length - 1 ? const Color(0xFF8BD1FF) : const Color(0xFF4A5D7E))))),
                  const SizedBox(width: 4),
                  Material(color: _currentMoveIndex < _fenList.length - 1 ? const Color(0xFF1F2D4B) : const Color(0xFF0D1422), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: _currentMoveIndex < _fenList.length - 1 ? () => _goToMove(_fenList.length - 1) : null, child: Container(padding: const EdgeInsets.all(10), child: Icon(Icons.fast_forward, size: 18, color: _currentMoveIndex < _fenList.length - 1 ? const Color(0xFF8BD1FF) : const Color(0xFF4A5D7E))))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _playEngineMove(_topEngineMoves[0]), borderRadius: BorderRadius.circular(14),
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF0B1422), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E2A46), width: 1)), child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFF1F2D4B), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text("1", style: TextStyle(color: Color(0xFF8BD1FF), fontWeight: FontWeight.bold, fontSize: 12)))), const SizedBox(width: 12), Expanded(child: Text(_topEngineMoves[0].isNotEmpty ? _topEngineMoves[0] : '-', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)))] )),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _playEngineMove(_topEngineMoves[1]), borderRadius: BorderRadius.circular(14),
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF0B1422), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E2A46), width: 1)), child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFF1F2D4B), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text("2", style: TextStyle(color: Color(0xFF8BD1FF), fontWeight: FontWeight.bold, fontSize: 12)))), const SizedBox(width: 12), Expanded(child: Text(_topEngineMoves[1].isNotEmpty ? _topEngineMoves[1] : '-', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)))] )),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _playEngineMove(_topEngineMoves[2]), borderRadius: BorderRadius.circular(14),
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF0B1422), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E2A46), width: 1)), child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFF1F2D4B), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text("3", style: TextStyle(color: Color(0xFF8BD1FF), fontWeight: FontWeight.bold, fontSize: 12)))), const SizedBox(width: 12), Expanded(child: Text(_topEngineMoves[2].isNotEmpty ? _topEngineMoves[2] : '-', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)))] )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            if (_analysisDone)
              AnimatedOpacity(
                opacity: _analysisDone ? 1.0 : 0.0, duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF151B2B), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF5C6BC0).withValues(alpha: 0.3))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Column(children: [Text(whiteName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: whiteAccuracyColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: whiteAccuracyColor.withValues(alpha: 0.4))), child: Text('%${_whiteAccuracy.toStringAsFixed(1)}', style: TextStyle(color: whiteAccuracyColor, fontWeight: FontWeight.bold, fontSize: 20)))] )),
                          Container(width: 1, height: 50, color: Colors.white12),
                          Expanded(child: Column(children: [Text(blackName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[300]), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: blackAccuracyColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: blackAccuracyColor.withValues(alpha: 0.4))), child: Text('%${_blackAccuracy.toStringAsFixed(1)}', style: TextStyle(color: blackAccuracyColor, fontWeight: FontWeight.bold, fontSize: 20)))] )),
                        ],
                      ),
                      const SizedBox(height: 25), Text(LanguageService.get('move_quality_distribution'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1)), const Divider(height: 20, color: Colors.white12),
                      
                      _buildStatRow(LanguageService.get('brilliant_move'), _whiteMoveStats['brilliant']!, _blackMoveStats['brilliant']!, Colors.cyanAccent, onTap: () => _goToCategoryMove('brilliant')),
                      _buildStatRow(LanguageService.get('great_move'), _whiteMoveStats['great']!, _blackMoveStats['great']!, const Color(0xFF64FFDA), onTap: () => _goToCategoryMove('great')),
                      _buildStatRow(LanguageService.get('best_move'), _whiteMoveStats['best']!, _blackMoveStats['best']!, Colors.greenAccent, onTap: () => _goToCategoryMove('best')),
                      _buildStatRow(LanguageService.get('excellent_move'), _whiteMoveStats['excellent']!, _blackMoveStats['excellent']!, Colors.lightGreen, onTap: () => _goToCategoryMove('excellent')),
                      _buildStatRow(LanguageService.get('good_move'), _whiteMoveStats['good']!, _blackMoveStats['good']!, const Color(0xFFAED581), onTap: () => _goToCategoryMove('good')),
                      _buildStatRow(LanguageService.get('inaccuracy_move'), _whiteMoveStats['inaccuracy']!, _blackMoveStats['inaccuracy']!, Colors.amberAccent, onTap: () => _goToCategoryMove('inaccuracy')),
                      _buildStatRow(LanguageService.get('mistake_move'), _whiteMoveStats['mistake']!, _blackMoveStats['mistake']!, Colors.orangeAccent, onTap: () => _goToCategoryMove('mistake')),
                      _buildStatRow(LanguageService.get('blunder_move'), _whiteMoveStats['blunder']!, _blackMoveStats['blunder']!, Colors.redAccent, onTap: () => _goToCategoryMove('blunder')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _goToCategoryMove(String category) {
    List<int> matches = [];
    _moveAnalyses.forEach((int index, MoveAnalysis analysis) {
      if (category == 'brilliant' && analysis.isBrilliant) { matches.add(index); }
      else if (category == 'great' && analysis.isGreat) { matches.add(index); }
      else if (category == 'best' && analysis.qualityLabel == 'En İyi Hamle') { matches.add(index); }
      else if (category == 'excellent' && analysis.qualityLabel == 'Mükemmel') { matches.add(index); }
      else if (category == 'good' && analysis.qualityLabel == 'İyi Hamle') { matches.add(index); }
      else if (category == 'inaccuracy' && analysis.qualityLabel == 'Şüpheli Hamle') { matches.add(index); }
      else if (category == 'mistake' && analysis.qualityLabel == 'Kötü Hamle') { matches.add(index); }
      else if (category == 'blunder' && analysis.qualityLabel == 'Çok Kötü Hamle') { matches.add(index); }
    });

    if (matches.isEmpty) { _showCategorySnackBar(category, false); return; }
    matches.sort();
    int currentBaseIndex = _currentMoveIndex - 1;
    int? nextMatch;
    for (var matchIndex in matches) {
      if (matchIndex > currentBaseIndex) { nextMatch = matchIndex; break; }
    }
    nextMatch ??= matches.first;
    int targetIndex = min(nextMatch + 1, _fenList.length - 1);
    String notation = "";
    if (nextMatch >= 0 && nextMatch < _allMoves.length) { notation = _allMoves[nextMatch]; }
    
    _goToMove(targetIndex);
    _showCategorySnackBar(category, true, notation: notation);
  }

  void _showCategorySnackBar(String category, bool found, {String? notation}) {
    String categoryLabel = category == 'brilliant' ? 'Etkileyici' : category == 'great' ? 'Harika' : category == 'best' ? 'En İyi' : category == 'excellent' ? 'Mükemmel' : category == 'good' ? 'İyi' : category == 'inaccuracy' ? 'Şüpheli' : category == 'mistake' ? 'Kötü' : 'Çok Kötü';
    String contentMessage = found ? '$categoryLabel hamleye gidildi.${notation != null && notation.isNotEmpty ? ' ($notation)' : ''}' : '$categoryLabel hamle bulunamadı.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(contentMessage), duration: const Duration(seconds: 2)));
  }

  Widget _buildStatRow(String label, int whiteCount, int blackCount, Color badgeColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(whiteCount.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            Container(width: 140, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor.withValues(alpha: 0.25))), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(child: Text(blackCount.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}