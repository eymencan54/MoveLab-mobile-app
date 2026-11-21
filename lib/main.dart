import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'master_archive_pages.dart';
import 'opening_trainer_page.dart';
import 'play_vs_bot_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'custom_chess_board/custom_chess_board.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:chess/chess.dart' as chess_engine;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockfish/stockfish.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'iap_service.dart';
import 'widgets/chess_silhouette_background.dart';
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
      String path = isCapture ? 'sounds/capture.mp3' : 'sounds/move-self.mp3';

      // Use a new player for each sound so they can overlap without cutting each other off
      AudioPlayer tempPlayer = AudioPlayer();
      await tempPlayer.play(AssetSource(path), volume: _volume);

      // Dispose the player after it finishes to free resources
      tempPlayer.onPlayerComplete.listen((_) {
        tempPlayer.dispose();
      });
    } catch (e) {
      debugPrint("Ses çalma hatası: $e");
    }
  }
}

class LanguageService {
  static String _currentLang = 'en'; // Varsayılan dil İngilizce
  static final ValueNotifier<String> localeNotifier =
      ValueNotifier<String>('en');

  static String get currentLang => _currentLang;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Hafızada kayıtlı dil varsa onu al, yoksa 'en' kullan
    _currentLang = prefs.getString('app_lang') ?? 'en';
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
    'play_vs_bot': {
      'tr': 'Botlarla Oyna',
      'en': 'Play with Bots'
    },
    'opening_trainer': {
      'tr': 'Açılış Stüdyosu',
      'en': 'Opening Studio'
    },
    'settings': {'tr': 'Ayarlar', 'en': 'Settings'},
    'board_color': {'tr': 'Tahta Rengi', 'en': 'Board Color'},
    'board_color_brown': {'tr': 'Kahverengi', 'en': 'Brown'},
    'board_color_green': {'tr': 'Yeşil', 'en': 'Green'},
    'board_color_blue': {'tr': 'Mavi', 'en': 'Blue'},
    'board_color_grey': {'tr': 'Gri', 'en': 'Grey'},
    'analysis_laboratory': {
      'tr': 'MoveLab Analiz Laboratuvarı',
      'en': 'MoveLab Analysis Lab'
    },
    'puzzle_congratulations': {
      'tr': 'Tebrikler! 🎉',
      'en': 'Congratulations! 🎉'
    },
    'puzzle_difficulty': {'tr': 'ZORLUK', 'en': 'DIFFICULTY'},
    'puzzle_diff_easy': {'tr': 'Kolay', 'en': 'Easy'},
    'puzzle_diff_medium': {'tr': 'Orta', 'en': 'Medium'},
    'puzzle_diff_hard': {'tr': 'Zor', 'en': 'Hard'},
    'puzzle_diff_elite': {'tr': 'Elit', 'en': 'Elite'},
    'puzzle_diff_select': {
      'tr': 'Zorluk Seviyesi Seç',
      'en': 'Select Difficulty Level'
    },
    'puzzle_diff_points': {'tr': 'Puan', 'en': 'Points'},
    'choose_username_title': {
      'tr': 'Kullanıcı Adı Seçin',
      'en': 'Choose Username'
    },
    'choose_username_desc': {
      'tr':
          'Google hesabınızla giriş yaptınız. Lütfen bulmacalarda kullanmak istediğiniz benzersiz bir isim girin.',
      'en':
          'You logged in with your Google account. Please enter a unique name you want to use in puzzles.'
    },
    'username_hint': {'tr': 'Kullanıcı Adı', 'en': 'Username'},
    'confirm': {'tr': 'Onayla', 'en': 'Confirm'},
    'username_taken_error': {
      'tr':
          'Bu isim Lichess, Chess.com veya MoveLab\'da kullanılıyor. Lütfen başka isim seçin.',
      'en':
          'This name is already used in Lichess, Chess.com or MoveLab. Please choose another name.'
    },
    'library_title': {'tr': 'MoveLab - Kütüphane', 'en': 'MoveLab - Library'},
    'piece_sounds': {'tr': 'Taş Sesleri', 'en': 'Piece Sounds'},
    'show_arrows': {
      'tr': 'En İyi Hamle Oklarını Göster',
      'en': 'Show Best Move Arrows'
    },
    'language': {'tr': 'Dil / Language', 'en': 'Language / Dil'},
    'turkish': {'tr': 'Türkçe', 'en': 'Turkish'},
    'english': {'tr': 'English', 'en': 'English'},
    'analyze_match': {'tr': 'Maçı Analiz Et', 'en': 'Analyze Match'},
    'library': {'tr': 'Kütüphane', 'en': 'Library'},
    'library_saved_matches': {
      'tr': 'Kütüphane',
      'en': 'Saved Matches'
    },
    'no_library_matches': {
      'tr': 'Henüz kütüphaneye maç eklenmemiş.',
      'en': 'No games have been added to the library yet.'
    },
    'match_deleted': {
      'tr': 'Maç kütüphaneden silindi.',
      'en': 'Game removed from library.'
    },
    'match_added': {
      'tr': 'Maç kütüphaneye eklendi!',
      'en': 'Game added to the library!'
    },
    'cancel': {'tr': 'İptal', 'en': 'Cancel'},
    'analyze': {'tr': 'Analiz Et', 'en': 'Analyze'},
    'pgn_paste': {'tr': 'PGN Yapıştır', 'en': 'Paste PGN'},
    'pgn_placeholder': {
      'tr': 'PGN metnini buraya yapıştırın...',
      'en': 'Paste the PGN text here...'
    },
    'pgn_empty': {'tr': 'PGN boş olamaz.', 'en': 'PGN cannot be empty.'},
    'connection_error': {
      'tr': 'Bağlantı sağlanamadı.',
      'en': 'Connection could not be established.'
    },
    'filter_error': {'tr': 'Filtreleme hatası.', 'en': 'Filtering error.'},
    'share_error': {
      'tr': 'Paylaşım sırasında bir hata oluştu.',
      'en': 'An error occurred while sharing.'
    },
    'analysis_share': {'tr': 'Analizi Paylaş', 'en': 'Share Analysis'},
    'back_home': {'tr': 'Ana Ekrana Dön', 'en': 'Back to Home'},
    'player_search_placeholder': {
      'tr': 'kullanıcı adı...',
      'en': 'username...'
    },
    'find_player': {'tr': 'Oyuncuyu Bul', 'en': 'Find Player'},
    'analyze_with_pgn': {'tr': 'PGN ile Analiz Et', 'en': 'Analyze with PGN'},
    'recent_matches': {'tr': 'Son Maçlar', 'en': 'Recent Games'},
    'all': {'tr': 'Tümü', 'en': 'All'},
    'no_match_data': {
      'tr': 'Maç verisi alınamadı.',
      'en': 'No game data could be retrieved.'
    },
    'load_more_games': {
      'tr': 'Önceki 10 Maçı Daha Getir',
      'en': 'Load 10 More Previous Games'
    },
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
    'move_quality_distribution': {
      'tr': 'HAMLE KALİTE DAĞILIMI',
      'en': 'MOVE QUALITY DISTRIBUTION'
    },
    'brilliant_move': {
      'tr': 'Etkileyici Hamle (!!)',
      'en': 'Impressive Move (!!)'
    },
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
    'remove_from_library': {
      'tr': 'Kütüphaneden Sil',
      'en': 'Remove from Library'
    },
    'analyzing': {'tr': 'Analiz Ediliyor...', 'en': 'Analyzing...'},
    'infinite': {'tr': 'Sonsuz', 'en': 'Infinite'},
    'engine_move': {'tr': 'Motor Analizi', 'en': 'Engine Analysis'},
    'best_move_nav': {'tr': 'En İyi', 'en': 'Best'},
    'excellent_nav': {'tr': 'Mükemmel', 'en': 'Excellent'},
    'good_nav': {'tr': 'İyi', 'en': 'Good'},
    'inaccuracy_nav': {'tr': 'Şüpheli', 'en': 'Inaccuracy'},
    'mistake_nav': {'tr': 'Kötü', 'en': 'Mistake'},
    'blunder_nav': {'tr': 'Çok Kötü', 'en': 'Blunder'},
    'puzzles': {'tr': 'Bulmacalar', 'en': 'Puzzles'},
    'master_archive': {'tr': 'Büyük Usta Arşivi', 'en': 'Grandmaster Archive'},
    'master_archive_desc': {
      'tr': 'Efsanevi büyük ustaların 5000+ maç arşivi',
      'en': 'Archive of 5000+ games from legendary grandmasters'
    },
    'no_pgn_files': {
      'tr': 'PGN dosyası bulunamadı',
      'en': 'No PGN files found'
    },
    'search_master': {'tr': 'Büyük usta ara...', 'en': 'Search grandmaster...'},
    'search_game': {
      'tr': 'Rakip, yıl veya açılış ara...',
      'en': 'Search opponent, year or ECO...'
    },
    'no_games_found': {
      'tr': 'Eşleşen oyun bulunamadı.',
      'en': 'No matching games found.'
    },
    'free_analyze': {'tr': 'Serbest Analiz', 'en': 'Free Analysis'},
    'white_player': {'tr': 'Beyaz Oyuncu', 'en': 'White Player'},
    'black_player': {'tr': 'Siyah Oyuncu', 'en': 'Black Player'},
    'result': {'tr': 'Sonuç', 'en': 'Result'},
    'elo': {'tr': 'Elo', 'en': 'Elo'},
    'engine_settings': {'tr': 'Motor Ayarları', 'en': 'Engine Settings'},
    'depth': {'tr': 'Derinlik', 'en': 'Depth'},
    'variants': {'tr': 'Varyantlar', 'en': 'Variants'},
    'three_variants': {'tr': '3 Varyant', 'en': '3 Variants'},
    'puzzle_leaderboard': {'tr': 'Sıralama', 'en': 'Leaderboard'},
    'puzzle_username_title': {'tr': 'Dünya Sıralaması', 'en': 'Global Ranking'},
    'puzzle_username_hint': {
      'tr': 'Sıralama için bir kullanıcı adı girin...',
      'en': 'Enter a username for the ranking...'
    },
    'puzzle_start': {'tr': 'Başla', 'en': 'Start'},
    'puzzle_player': {'tr': 'Oyuncu', 'en': 'Player'},
    'puzzle_turn_white': {'tr': 'HAMLE BEYAZDA', 'en': 'WHITE TO MOVE'},
    'puzzle_turn_black': {'tr': 'HAMLE SİYAHTA', 'en': 'BLACK TO MOVE'},
    'puzzle_hint': {'tr': 'İpucu:', 'en': 'Hint:'},
    'puzzle_wrong_move': {
      'tr': 'Yanlış hamle, tekrar dene!',
      'en': 'Wrong move, try again!'
    },
    'puzzle_solved': {'tr': 'Bulmaca Çözüldü!', 'en': 'Puzzle Solved!'},
    'puzzle_no_solvers': {
      'tr': 'Henüz kimse bulmaca çözmedi.',
      'en': 'No one has solved a puzzle yet.'
    },
    'get_hint': {'tr': 'İPUCU AL', 'en': 'GET HINT'},
    'puzzle_score_points': {'tr': 'Puan', 'en': 'Points'},
    'puzzle_find_best_white': {
      'tr': 'Beyaz için en iyi hamleyi bul',
      'en': 'Find the best move for White'
    },
    'puzzle_find_best_black': {
      'tr': 'Siyah için en iyi hamleyi bul',
      'en': 'Find the best move for Black'
    },
    'puzzle_next': {'tr': 'Sonraki Bulmaca', 'en': 'Next Puzzle'},
    'puzzle_skip': {'tr': 'Atla', 'en': 'Skip'},
    'puzzle_step': {'tr': 'Hamle', 'en': 'Move'},
    'puzzle_current_score': {'tr': 'Mevcut Puan', 'en': 'Current Score'},
    'puzzle_reward': {'tr': 'Ödül', 'en': 'Reward'},
    'puzzle_tactical_drill': {
      'tr': 'Taktik Çalışması',
      'en': 'Tactical Drill'
    },
    'puzzle_reviewing': {
      'tr': 'Geçmiş hamle inceleniyor',
      'en': 'Reviewing move history'
    },
    'library_sort_filter': {
      'tr': 'Sırala ve Filtrele',
      'en': 'Sort & Filter'
    },
    'library_newest_first': {
      'tr': 'Son eklenenden ilk eklenene',
      'en': 'Newest to Oldest'
    },
    'library_oldest_first': {
      'tr': 'İlk eklenenden son eklenene',
      'en': 'Oldest to Newest'
    },
    'library_only_chesscom': {
      'tr': 'Sadece Chess.com',
      'en': 'Chess.com Only'
    },
    'library_only_lichess': {'tr': 'Sadece Lichess', 'en': 'Lichess Only'},
    'library_pgn_matches': {'tr': 'PGN Maçları', 'en': 'PGN Matches'},
    'library_search_player': {'tr': 'Oyuncu Ara', 'en': 'Search Player'},
    'library_search_hint': {
      'tr': 'Oyuncu adı veya platform ara...',
      'en': 'Search player name or platform...'
    },
    'library_no_filter_match': {
      'tr': 'Seçilen kritere veya aramaya uygun maç bulunamadı.',
      'en': 'No matches found for the selected filter or search.'
    },
    'login_title': {'tr': 'Bulmacalara Giriş', 'en': 'Puzzle Login'},
    'login_lichess_desc': {
      'tr': 'Lichess hesabınıza güvenli bir şekilde şifrenizle giriş yapın:',
      'en': 'Securely log in with your Lichess account:'
    },
    'login_lichess_btn': {
      'tr': 'Lichess İle Giriş Yap',
      'en': 'Log In with Lichess'
    },
    'login_google_desc': {
      'tr': 'Google hesabınızla güvenli giriş yapın:',
      'en': 'Securely log in with your Google account:'
    },
    'login_google_btn': {
      'tr': 'Google İle Giriş Yap',
      'en': 'Log In with Google'
    },
    'login_guest_desc': {
      'tr': 'Veya misafir olarak bir isim girin:',
      'en': 'Or enter a name to continue as a guest:'
    },
    'login_guest_hint': {'tr': 'Misafir Kullanıcı Adı', 'en': 'Guest Username'},
    'login_guest_btn': {'tr': 'Misafir Girişi', 'en': 'Guest Login'},
    'login_failed': {'tr': 'Giriş başarısız oldu!', 'en': 'Login failed!'},
    'login_guest_taken': {
      'tr':
          'Bu isim Lichess, Chess.com veya MoveLab\'da kullanılıyor. Lütfen başka isim girin.',
      'en':
          'This name is taken on Lichess, Chess.com, or MoveLab. Please enter another name.'
    },
    'login_guest_conn_err': {
      'tr': 'Bağlantı hatası!',
      'en': 'Connection error!'
    },
    'settings_login': {'tr': 'Giriş Yap', 'en': 'Log In'},
    'settings_logout': {'tr': 'Çıkış Yap', 'en': 'Log Out'},
    'settings_delete_account': {'tr': 'Hesabı Sil', 'en': 'Delete Account'},
    'settings_delete_confirm_title': {
      'tr': 'Hesabı Sil',
      'en': 'Delete Account'
    },
    'settings_delete_confirm_desc': {
      'tr':
          'Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
      'en':
          'Are you sure you want to permanently delete your account and all data? This action cannot be undone.'
    },
    'settings_delete_confirm_yes': {'tr': 'Evet, Sil', 'en': 'Yes, Delete'},
    'settings_delete_confirm_no': {'tr': 'İptal', 'en': 'Cancel'},
    'settings_delete_success': {
      'tr': 'Hesabınız başarıyla silindi.',
      'en': 'Your account has been successfully deleted.'
    },
    'profile_title': {
      'tr': 'Oyuncu Profili & Analiz',
      'en': 'Player Profile & Analysis'
    },
    'profile_membership': {'tr': 'Üyelik Durumu', 'en': 'Membership Status'},
    'member_elite_title': {
      'tr': 'ELİTE Üye 👑 (VIP)',
      'en': 'ELITE Member 👑 (VIP)'
    },
    'member_std_title': {'tr': 'Standart Üye ♟️', 'en': 'Standard Member ♟️'},
    'member_elite_desc': {
      'tr':
          'Tüm yapay zeka botlarına, sınırsız motor derinliğine ve bulut özelliklerine tam erişiminiz aktiftir.',
      'en':
          'Full access to all AI bots, unlimited engine depth, and cloud features is active.'
    },
    'member_std_desc': {
      'tr':
          'Standart bulmaca ve temel analiz motoru aktiftir. Tüm kilitleri açmak için ELİTE aboneliğe yükseltin.',
      'en':
          'Standard puzzle and basic analysis engine are active. Upgrade to ELITE subscription to unlock all features.'
    },
    'profile_style_card': {
      'tr': 'Oyuncu Stili Analiz Kartı',
      'en': 'Player Style Analysis Card'
    },
    'profile_guest': {'tr': 'Misafir', 'en': 'Guest'},
    'profile_view': {
      'tr': 'Profili ve İstatistikleri Görüntüle',
      'en': 'View Profile and Statistics'
    },
    'free_analysis': {'tr': 'Serbest Analiz', 'en': 'Free Analysis'},
    'library_added': {'tr': 'Kütüphaneye Eklendi', 'en': 'Added to Library'},
    'match_saved': {
      'tr': 'Maç başarıyla kütüphaneye kaydedildi!',
      'en': 'Match successfully saved to library!'
    },
    'ok': {'tr': 'Tamam', 'en': 'OK'},
    'board_editor': {'tr': 'Tahta Düzenleyici', 'en': 'Board Editor'},
    'start_analysis': {'tr': 'Analize Başla', 'en': 'Start Analysis'},
    'apply_setup': {'tr': 'Kurulumu Uygula', 'en': 'Apply Setup'},
    'board_editor_tooltip': {
      'tr': 'Tahta Düzenleyici (Konum Kur)',
      'en': 'Board Editor (Setup Position)'
    },
    'piece_selection_hint': {
      'tr': 'Taş Seçimi (Kareye dokunarak koy/sil):',
      'en': 'Piece Selection (Tap square to place/remove):'
    },
    'white_label': {'tr': 'Beyaz:', 'en': 'White:'},
    'black_label': {'tr': 'Siyah:', 'en': 'Black:'},
    'turn_label': {'tr': 'Sıra:', 'en': 'Turn:'},
    'turn_white': {'tr': 'Beyaz', 'en': 'White'},
    'turn_black': {'tr': 'Siyah', 'en': 'Black'},
    'clear': {'tr': 'Temizle', 'en': 'Clear'},
    'initial_position': {'tr': 'Başlangıç', 'en': 'Initial'},
    'castling_rights': {'tr': 'Rok Hakları:', 'en': 'Castling Rights:'},
    'king_delete_error': {
      'tr': 'Şah silinemez, ancak başka bir kareye yerleştirilebilir.',
      'en': 'King cannot be deleted, but can be moved to another square.'
    },
    'missing_king_error': {
      'tr':
          'Geçersiz konum: Tahtada hem Beyaz hem de Siyah Şah (King) bulunmalıdır!',
      'en': 'Invalid position: Both White and Black King must be on the board!'
    },
    'next_branches': {'tr': 'Sonraki Dallar:', 'en': 'Next Branches:'},
    'syzygy_loading': {
      'tr': 'Syzygy 7-Taş Veritabanı Sorgulanıyor...',
      'en': 'Querying Syzygy 7-Piece Tablebase...'
    },
    'syzygy_title': {'tr': 'Syzygy 7-Taş:', 'en': 'Syzygy 7-Piece:'},
    'syzygy_win': {'tr': 'Kesin Kazanç (Win)', 'en': 'Decisive Win'},
    'syzygy_loss': {'tr': 'Kesin Kayıp (Loss)', 'en': 'Decisive Loss'},
    'syzygy_draw': {'tr': 'Kesin Berabere (Draw)', 'en': 'Decisive Draw'},
    'syzygy_perfect': {'tr': 'Kusursuz Oyun Sonu', 'en': 'Perfect Endgame'},
    'syzygy_short_win': {'tr': 'Kazanç', 'en': 'Win'},
    'syzygy_short_loss': {'tr': 'Kayıp', 'en': 'Loss'},
    'syzygy_short_draw': {'tr': 'Berabere', 'en': 'Draw'},
    'syzygy_mate': {'tr': 'Mat:', 'en': 'Mate:'},
    'syzygy_zero': {'tr': 'Sıfırlama:', 'en': 'Zeroing:'},
    'syzygy_moves': {'tr': 'hamle', 'en': 'moves'},
    'opening_loading': {
      'tr': 'Lichess Açılış Gezgini (Yükleniyor...)',
      'en': 'Lichess Opening Explorer (Loading...)'
    },
    'opening_not_found': {
      'tr': 'Özgün Konum / Usta Oyunlarında Yok',
      'en': 'Unique Position / Not in Master Games'
    },
    'opening_db': {'tr': 'Usta Veritabanı', 'en': 'Master Database'},
    'games_count': {'tr': 'oyun', 'en': 'games'},
    'toggle_explorer': {
      'tr': 'Açılış Gezginini Aç / Kapat',
      'en': 'Toggle Opening Explorer'
    },
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
      case 'Etkileyici Hamle':
        return 'Brilliant';
      case 'Harika':
      case 'Harika Hamle':
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

class NotationHelper {
  static String formatUciToSan(String uciMove, String startFen) {
    if (uciMove.isEmpty ||
        uciMove.length < 4 ||
        uciMove == '...' ||
        uciMove == '-' ||
        uciMove == '=' ||
        uciMove == '#') return uciMove;
    try {
      chess_engine.Chess chess = chess_engine.Chess();
      chess.load(startFen);
      String from = uciMove.substring(0, 2);
      String to = uciMove.substring(2, 4);
      String? promo =
          uciMove.length > 4 ? uciMove.substring(4, 5).toLowerCase() : null;
      var moves = chess.moves({'verbose': true});
      for (var m in moves) {
        if (m['from'] == from && m['to'] == to) {
          if (promo != null) {
            if (m['promotion'] == promo) return m['san'];
          } else {
            return m['san'];
          }
        }
      }
    } catch (_) {}
    return uciMove;
  }

  static String formatUciLineToSan(String uciLine, String startFen) {
    if (uciLine.isEmpty || uciLine == '...') return uciLine;
    try {
      chess_engine.Chess chess = chess_engine.Chess();
      chess.load(startFen);
      List<String> uciMoves = uciLine.trim().split(RegExp(r'\s+'));
      List<String> sanMoves = [];
      for (String uci in uciMoves) {
        if (uci.isEmpty || uci.length < 4) continue;
        String from = uci.substring(0, 2);
        String to = uci.substring(2, 4);
        String? promo =
            uci.length > 4 ? uci.substring(4, 5).toLowerCase() : null;
        var moves = chess.moves({'verbose': true});
        String san = uci;
        for (var m in moves) {
          if (m['from'] == from && m['to'] == to) {
            if (promo != null) {
              if (m['promotion'] == promo) {
                san = m['san'];
                break;
              }
            } else {
              san = m['san'];
              break;
            }
          }
        }
        sanMoves.add(san);
        Map<String, dynamic> moveData = {"from": from, "to": to};
        if (promo != null) moveData["promotion"] = promo;
        if (!chess.move(moveData)) {
          if (!chess.move(uci)) break;
        }
      }
      return sanMoves.join(' ');
    } catch (_) {
      return uciLine;
    }
  }
}

class NagHelper {
  static String getNagSymbol(String qualityLabel,
      {bool isBrilliant = false, bool isGreat = false}) {
    if (isBrilliant || qualityLabel == "Etkileyici Hamle") return "!!";
    if (isGreat || qualityLabel == "Harika Hamle") return "!";
    if (qualityLabel == "Şüpheli Hamle") return "?!";
    if (qualityLabel == "Kötü Hamle") return "?";
    if (qualityLabel == "Çok Kötü Hamle") return "??";
    return "";
  }

  static Color getNagColor(String symbol) {
    switch (symbol) {
      case "!!":
        return const Color(0xFF1BACA6);
      case "!":
        return const Color(0xFF5C8BB0);
      case "?!":
        return const Color(0xFFF7C045);
      case "?":
        return const Color(0xFFE58F2A);
      case "??":
        return const Color(0xFFCA3431);
      default:
        return Colors.transparent;
    }
  }
}

class SyzygyService {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};

  static bool isEligible(String fen) {
    try {
      String boardPart = fen.split(' ')[0];
      int pieces = boardPart.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      return pieces <= 7 && pieces > 0;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchTablebase(String fen) async {
    if (!isEligible(fen)) return null;
    String cleanFen = fen.trim();
    if (_cache.containsKey(cleanFen)) return _cache[cleanFen];
    if (_inFlight.containsKey(cleanFen)) return _inFlight[cleanFen]!;

    final future = _doFetch(cleanFen);
    _inFlight[cleanFen] = future;
    return future;
  }

  static Future<Map<String, dynamic>?> _doFetch(String cleanFen) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                'https://tablebase.lichess.ovh/standard?fen=${Uri.encodeComponent(cleanFen)}'),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cache[cleanFen] = data;
        _inFlight.remove(cleanFen);
        return data;
      }
    } catch (_) {}
    _inFlight.remove(cleanFen);
    return null;
  }
}

class OpeningExplorerService {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};

  static final Map<String, Map<String, dynamic>> _localOpenings = {
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR': {
      'opening': {'eco': 'A00', 'name': 'Standard Starting Position'},
      'moves': [
        {
          'san': 'e4',
          'uci': 'e2e4',
          'white': 650400,
          'draw': 885200,
          'black': 404890
        },
        {
          'san': 'd4',
          'uci': 'd2d4',
          'white': 476850,
          'draw': 635800,
          'black': 332350
        },
        {
          'san': 'Nf3',
          'uci': 'g1f3',
          'white': 116250,
          'draw': 168750,
          'black': 90000
        },
        {
          'san': 'c4',
          'uci': 'c2c4',
          'white': 68480,
          'draw': 96300,
          'black': 49220
        },
      ],
    },
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR': {
      'opening': {'eco': 'B00', 'name': "King's Pawn Opening"},
      'moves': [
        {
          'san': 'e5',
          'uci': 'e7e5',
          'white': 292500,
          'draw': 227500,
          'black': 130000
        },
        {
          'san': 'c5',
          'uci': 'c7c5',
          'white': 216000,
          'draw': 189000,
          'black': 135000
        },
        {
          'san': 'e6',
          'uci': 'e7e6',
          'white': 138600,
          'draw': 108900,
          'black': 82500
        },
        {
          'san': 'c6',
          'uci': 'c7c6',
          'white': 111800,
          'draw': 91000,
          'black': 57200
        },
      ],
    },
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR': {
      'opening': {'eco': 'C20', 'name': 'Open Game'},
      'moves': [
        {
          'san': 'Nf3',
          'uci': 'g1f3',
          'white': 172800,
          'draw': 115200,
          'black': 72000
        },
        {
          'san': 'Nc3',
          'uci': 'b1c3',
          'white': 54000,
          'draw': 36000,
          'black': 30000
        },
        {
          'san': 'Bc4',
          'uci': 'f1c4',
          'white': 43700,
          'draw': 28500,
          'black': 22800
        },
      ],
    },
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R': {
      'opening': {'eco': 'C40', 'name': "King's Knight Opening"},
      'moves': [
        {
          'san': 'Nc6',
          'uci': 'b8c6',
          'white': 144000,
          'draw': 112000,
          'black': 64000
        },
        {
          'san': 'Nf6',
          'uci': 'g8f6',
          'white': 50400,
          'draw': 45600,
          'black': 24000
        },
        {
          'san': 'd6',
          'uci': 'd7d6',
          'white': 43200,
          'draw': 27000,
          'black': 19800
        },
      ],
    },
    'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R': {
      'opening': {'eco': 'C44', 'name': 'Normal Variation'},
      'moves': [
        {
          'san': 'Bb5',
          'uci': 'f1b5',
          'white': 96600,
          'draw': 71400,
          'black': 42000
        },
        {
          'san': 'Bc4',
          'uci': 'f1c4',
          'white': 49500,
          'draw': 35200,
          'black': 25300
        },
        {
          'san': 'd4',
          'uci': 'd2d4',
          'white': 42300,
          'draw': 27000,
          'black': 20700
        },
      ],
    },
    'r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R': {
      'opening': {'eco': 'C60', 'name': 'Ruy Lopez'},
      'moves': [
        {
          'san': 'a6',
          'uci': 'a7a6',
          'white': 63000,
          'draw': 49000,
          'black': 28000
        },
        {
          'san': 'Nf6',
          'uci': 'g8f6',
          'white': 25800,
          'draw': 22200,
          'black': 12000
        },
        {
          'san': 'd6',
          'uci': 'd7d6',
          'white': 19200,
          'draw': 12000,
          'black': 8800
        },
      ],
    },
    'r1bqkbnr/1ppp1ppp/p1n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R': {
      'opening': {'eco': 'C68', 'name': 'Ruy Lopez: Morphy Defense'},
      'moves': [
        {
          'san': 'Ba4',
          'uci': 'b5a4',
          'white': 49500,
          'draw': 38500,
          'black': 22000
        },
        {
          'san': 'Bxc6',
          'uci': 'b5c6',
          'white': 14400,
          'draw': 9600,
          'black': 6000
        },
      ],
    },
    'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R': {
      'opening': {'eco': 'C50', 'name': 'Italian Game'},
      'moves': [
        {
          'san': 'Bc5',
          'uci': 'f8c5',
          'white': 37400,
          'draw': 30600,
          'black': 17000
        },
        {
          'san': 'Nf6',
          'uci': 'g8f6',
          'white': 31500,
          'draw': 23100,
          'black': 15400
        },
      ],
    },
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR': {
      'opening': {'eco': 'B20', 'name': 'Sicilian Defense'},
      'moves': [
        {
          'san': 'Nf3',
          'uci': 'g1f3',
          'white': 175500,
          'draw': 128700,
          'black': 85800
        },
        {
          'san': 'Nc3',
          'uci': 'b1c3',
          'white': 48400,
          'draw': 35200,
          'black': 26400
        },
        {
          'san': 'c3',
          'uci': 'c2c3',
          'white': 27950,
          'draw': 22750,
          'black': 14300
        },
      ],
    },
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R': {
      'opening': {'eco': 'B27', 'name': 'Sicilian Defense: Open'},
      'moves': [
        {
          'san': 'd6',
          'uci': 'd7d6',
          'white': 64897,
          'draw': 66751,
          'black': 53772
        },
        {
          'san': 'Nc6',
          'uci': 'b8c6',
          'white': 43438,
          'draw': 44680,
          'black': 35992
        },
        {
          'san': 'e6',
          'uci': 'e7e6',
          'white': 29642,
          'draw': 28819,
          'black': 23879
        },
      ],
    },
    'rnbqkbnr/pp1ppppp/2p5/8/4P3/8/PPPP1PPP/RNBQKBNR': {
      'opening': {'eco': 'B10', 'name': 'Caro-Kann Defense'},
      'moves': [
        {
          'san': 'd4',
          'uci': 'd2d4',
          'white': 96600,
          'draw': 71400,
          'black': 42000
        },
        {
          'san': 'Nc3',
          'uci': 'b1c3',
          'white': 36000,
          'draw': 26400,
          'black': 17600
        },
      ],
    },
    'rnbqkbnr/pppp1ppp/4p3/8/4P3/8/PPPP1PPP/RNBQKBNR': {
      'opening': {'eco': 'C00', 'name': 'French Defense'},
      'moves': [
        {
          'san': 'd4',
          'uci': 'd2d4',
          'white': 112800,
          'draw': 79200,
          'black': 48000
        },
        {
          'san': 'd3',
          'uci': 'd2d3',
          'white': 26400,
          'draw': 20400,
          'black': 13200
        },
      ],
    },
    'rnbqkbnr/pppp1ppp/4p3/8/3PP3/8/PPP2PPP/RNBQKBNR': {
      'opening': {'eco': 'C00', 'name': 'French Defense: Normal Variation'},
      'moves': [
        {
          'san': 'd5',
          'uci': 'd7d5',
          'white': 210500,
          'draw': 185000,
          'black': 142000
        },
        {
          'san': 'c5',
          'uci': 'c7c5',
          'white': 24000,
          'draw': 18000,
          'black': 12000
        },
      ],
    },
    'rnbqkbnr/ppp2ppp/4p3/3p4/3PP3/8/PPP2PPP/RNBQKBNR': {
      'opening': {'eco': 'C01', 'name': 'French Defense: Classical / Advance'},
      'moves': [
        {
          'san': 'Nc3',
          'uci': 'b1c3',
          'white': 85000,
          'draw': 72000,
          'black': 55000
        },
        {
          'san': 'Nd2',
          'uci': 'b1d2',
          'white': 68000,
          'draw': 54000,
          'black': 42000
        },
        {
          'san': 'e5',
          'uci': 'e4e5',
          'white': 55000,
          'draw': 41000,
          'black': 36000
        },
        {
          'san': 'exd5',
          'uci': 'e4d5',
          'white': 42000,
          'draw': 38000,
          'black': 29000
        },
      ],
    },
    'rnbqkbnr/pp2pppp/3p4/8/3pP3/5N2/PPP2PPP/RNBQKB1R': {
      'opening': {'eco': 'B50', 'name': 'Sicilian Defense: Open'},
      'moves': [
        {
          'san': 'Nxd4',
          'uci': 'f3d4',
          'white': 145000,
          'draw': 120000,
          'black': 98000
        },
        {
          'san': 'Qxd4',
          'uci': 'd1d4',
          'white': 12000,
          'draw': 9000,
          'black': 8500
        },
      ],
    },
    'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR': {
      'opening': {'eco': 'A40', 'name': "Queen's Pawn Game"},
      'moves': [
        {
          'san': 'Nf6',
          'uci': 'g8f6',
          'white': 144000,
          'draw': 112000,
          'black': 64000
        },
        {
          'san': 'd5',
          'uci': 'd7d5',
          'white': 119600,
          'draw': 88400,
          'black': 52000
        },
        {
          'san': 'e6',
          'uci': 'e7e6',
          'white': 39600,
          'draw': 30600,
          'black': 19800
        },
      ],
    },
    'rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR': {
      'opening': {'eco': 'D00', 'name': 'Closed Game'},
      'moves': [
        {
          'san': 'c4',
          'uci': 'c2c4',
          'white': 98700,
          'draw': 69300,
          'black': 42000
        },
        {
          'san': 'Nf3',
          'uci': 'g1f3',
          'white': 54000,
          'draw': 42000,
          'black': 24000
        },
        {
          'san': 'Bf4',
          'uci': 'c1f4',
          'white': 36800,
          'draw': 25600,
          'black': 17600
        },
      ],
    },
    'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR': {
      'opening': {'eco': 'D06', 'name': "Queen's Gambit"},
      'moves': [
        {
          'san': 'e6',
          'uci': 'e7e6',
          'white': 69000,
          'draw': 51000,
          'black': 30000
        },
        {
          'san': 'c6',
          'uci': 'c7c6',
          'white': 54000,
          'draw': 42000,
          'black': 24000
        },
        {
          'san': 'dxc4',
          'uci': 'd5c4',
          'white': 38400,
          'draw': 24000,
          'black': 17600
        },
      ],
    },
    'rnbqkbnr/ppp2ppp/4p3/3p4/2PP4/8/PP2PPPP/RNBQKBNR': {
      'opening': {'eco': 'D30', 'name': "Queen's Gambit Declined"},
      'moves': [
        {
          'san': 'Nc3',
          'uci': 'b1c3',
          'white': 41400,
          'draw': 30600,
          'black': 18000
        },
        {
          'san': 'Nf3',
          'uci': 'g1f3',
          'white': 27000,
          'draw': 21000,
          'black': 12000
        },
      ],
    },
    'rnbqkb1r/pppppppp/5n2/8/3P4/8/PPP1PPPP/RNBQKBNR': {
      'opening': {'eco': 'A45', 'name': 'Indian Defense'},
      'moves': [
        {
          'san': 'c4',
          'uci': 'c2c4',
          'white': 69000,
          'draw': 51000,
          'black': 30000
        },
        {
          'san': 'Nf3',
          'uci': 'g1f3',
          'white': 39600,
          'draw': 32400,
          'black': 18000
        },
      ],
    },
    'rnbqkb1r/pppppppp/5n2/8/2PP4/8/PP2PPPP/RNBQKBNR': {
      'opening': {'eco': 'A50', 'name': 'Indian Game'},
      'moves': [
        {
          'san': 'g6',
          'uci': 'g7g6',
          'white': 54000,
          'draw': 42000,
          'black': 24000
        },
        {
          'san': 'e6',
          'uci': 'e7e6',
          'white': 39600,
          'draw': 32400,
          'black': 18000
        },
        {
          'san': 'c5',
          'uci': 'c7c5',
          'white': 32900,
          'draw': 21700,
          'black': 15400
        },
      ],
    },
    'rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R': {
      'opening': {'eco': 'A04', 'name': 'Réti Opening'},
      'moves': [
        {
          'san': 'd5',
          'uci': 'd7d5',
          'white': 55200,
          'draw': 40800,
          'black': 24000
        },
        {
          'san': 'Nf6',
          'uci': 'g8f6',
          'white': 40500,
          'draw': 31500,
          'black': 18000
        },
        {
          'san': 'c5',
          'uci': 'c7c5',
          'white': 26400,
          'draw': 20400,
          'black': 13200
        },
      ],
    },
    'rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR': {
      'opening': {'eco': 'A10', 'name': 'English Opening'},
      'moves': [
        {
          'san': 'e5',
          'uci': 'e7e5',
          'white': 54000,
          'draw': 42000,
          'black': 24000
        },
        {
          'san': 'Nf6',
          'uci': 'g8f6',
          'white': 39600,
          'draw': 32400,
          'black': 18000
        },
        {
          'san': 'c5',
          'uci': 'c7c5',
          'white': 36800,
          'draw': 27200,
          'black': 16000
        },
      ],
    },
  };

  static String _getBoardPrefix(String fen) {
    final parts = fen.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : fen.trim();
  }

  static String _normalizeFenForLichess(String fen) {
    final parts = fen.trim().split(' ');
    if (parts.length >= 4 && parts[3] != '-') {
      parts[3] = '-';
    }
    return parts.join(' ');
  }

  static Future<Map<String, dynamic>?> fetchOpening(String fen) async {
    String cleanFen = fen.trim();
    if (_cache.containsKey(cleanFen)) return _cache[cleanFen];
    if (_inFlight.containsKey(cleanFen)) return _inFlight[cleanFen]!;

    String boardPrefix = _getBoardPrefix(cleanFen);
    final future = _doFetch(cleanFen, boardPrefix);
    _inFlight[cleanFen] = future;
    return future;
  }

  static Future<Map<String, dynamic>?> _doFetch(
      String cleanFen, String boardPrefix) async {
    String normalizedFen = _normalizeFenForLichess(cleanFen);
    if (_cache.containsKey(normalizedFen)) {
      final cachedData = _cache[normalizedFen]!;
      _cache[cleanFen] = cachedData;
      _inFlight.remove(cleanFen);
      return cachedData;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://explorer.lichess.ovh/lichess?variant=standard&fen=${Uri.encodeComponent(normalizedFen)}&moves=5'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MoveLabChessApp/1.0 (contact@movelab.app)'
        },
      ).timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cache[cleanFen] = data;
        _cache[normalizedFen] = data;
        _inFlight.remove(cleanFen);
        return data;
      }
    } catch (_) {}

    if (_localOpenings.containsKey(boardPrefix)) {
      final localData = _localOpenings[boardPrefix]!;
      _cache[cleanFen] = localData;
      _cache[normalizedFen] = localData;
      _inFlight.remove(cleanFen);
      return localData;
    }

    final fallback = {'opening': null, 'moves': []};
    _cache[cleanFen] = fallback;
    _cache[normalizedFen] = fallback;
    _inFlight.remove(cleanFen);
    return fallback;
  }
}

class LichessWidgets {
  static bool showOpeningExplorer = false;
  static bool isOpeningExplorerExpanded = true;

  static Widget buildSyzygyPanel(String fen, Function(String) onMoveTap) {
    if (!SyzygyService.isEligible(fen)) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: SyzygyService.fetchTablebase(fen),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.diamond_outlined,
                      color: Colors.cyanAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(LanguageService.get('syzygy_loading'),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            );
          }
          final data = snapshot.data ?? {};
          String cat = data['category'] ?? '';
          String wdl = cat == 'win'
              ? LanguageService.get('syzygy_win')
              : (cat == 'loss'
                  ? LanguageService.get('syzygy_loss')
                  : LanguageService.get('syzygy_draw'));
          Color wdlColor = cat == 'win'
              ? Colors.greenAccent
              : (cat == 'loss' ? Colors.redAccent : Colors.amberAccent);
          int? dtz = data['dtz'];
          int? dtm = data['dtm'];
          String distTxt = dtm != null
              ? "${LanguageService.get('syzygy_mate')} ${dtm.abs() ~/ 2} ${LanguageService.get('syzygy_moves')}"
              : (dtz != null
                  ? "${LanguageService.get('syzygy_zero')} ${dtz.abs()} ${LanguageService.get('syzygy_moves')}"
                  : "");

          final moves = data['moves'] as List<dynamic>? ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.diamond_outlined,
                        color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${LanguageService.get('syzygy_title')} $wdl ${distTxt.isNotEmpty ? '($distTxt)' : ''}",
                        style: TextStyle(
                            color: wdlColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(LanguageService.get('syzygy_perfect'),
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              if (moves.isNotEmpty) ...[
                const Divider(height: 1, color: Colors.white12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    children: moves.take(3).map((m) {
                      String uci = m['uci'] ?? '';
                      String mCat = m['category'] ?? '';
                      int? mDtz = m['dtz'];
                      Color mColor = mCat == 'win'
                          ? Colors.greenAccent
                          : (mCat == 'loss'
                              ? Colors.redAccent
                              : Colors.amberAccent);
                      String san = NotationHelper.formatUciToSan(uci, fen);
                      return InkWell(
                        onTap: () => onMoveTap(uci),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 40,
                                  child: Text(san,
                                      style: TextStyle(
                                          color: mColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              Text(
                                  mCat == 'win'
                                      ? LanguageService.get('syzygy_short_win')
                                      : (mCat == 'loss'
                                          ? LanguageService.get(
                                              'syzygy_short_loss')
                                          : LanguageService.get(
                                              'syzygy_short_draw')),
                                  style:
                                      TextStyle(color: mColor, fontSize: 11)),
                              const Spacer(),
                              if (mDtz != null)
                                Text("DTZ: ${mDtz.abs()}",
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 10)),
                              const SizedBox(width: 4),
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white30, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget buildOpeningExplorerPanel(
      String fen, Function(String) onMoveTap) {
    if (!showOpeningExplorer || SyzygyService.isEligible(fen))
      return const SizedBox.shrink();
    return OpeningExplorerWidget(fen: fen, onMoveTap: onMoveTap);
  }
}

class OpeningExplorerWidget extends StatefulWidget {
  final String fen;
  final Function(String) onMoveTap;
  const OpeningExplorerWidget(
      {super.key, required this.fen, required this.onMoveTap});

  @override
  State<OpeningExplorerWidget> createState() => _OpeningExplorerWidgetState();
}

class _OpeningExplorerWidgetState extends State<OpeningExplorerWidget> {
  @override
  Widget build(BuildContext context) {
    if (!LichessWidgets.showOpeningExplorer ||
        SyzygyService.isEligible(widget.fen)) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: OpeningExplorerService.fetchOpening(widget.fen),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(LanguageService.get('opening_loading'),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() {
                        LichessWidgets.showOpeningExplorer = false;
                      });
                    },
                    child: const Icon(Icons.close,
                        color: Colors.white38, size: 18),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data ?? {};
          final opening = data['opening'];
          final moves = data['moves'] as List<dynamic>? ?? [];
          String openingName = (opening != null && opening['name'] != null)
              ? "${opening['eco']}: ${opening['name']}"
              : LanguageService.get('opening_not_found');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    LichessWidgets.isOpeningExplorerExpanded =
                        !LichessWidgets.isOpeningExplorerExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.explore,
                          color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          openingName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(LanguageService.get('opening_db'),
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LichessWidgets.isOpeningExplorerExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          setState(() {
                            LichessWidgets.showOpeningExplorer = false;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.close,
                              color: Colors.white38, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (LichessWidgets.isOpeningExplorerExpanded &&
                  moves.isNotEmpty) ...[
                const Divider(height: 1, color: Colors.white12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    children: moves.take(3).map((m) {
                      int w = m['white'] ?? 0;
                      int d = m['draw'] ?? 0;
                      int b = m['black'] ?? 0;
                      int total = w + d + b;
                      String san = m['san'] ?? '';
                      String uci = m['uci'] ?? '';
                      if (total == 0) return const SizedBox.shrink();
                      int wPct = (w * 100 ~/ total);
                      int dPct = (d * 100 ~/ total);
                      int bPct = 100 - wPct - dPct;
                      if (wPct == 0 && dPct == 0 && bPct == 0) wPct = 100;
                      String formattedTotal = total >= 1000000
                          ? "${(total / 1000000).toStringAsFixed(1)}M"
                          : (total >= 1000
                              ? "${(total / 1000).toStringAsFixed(total >= 10000 ? 0 : 1)}K"
                              : "$total");
                      return InkWell(
                        onTap: () => widget.onMoveTap(uci),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 40,
                                  child: Text(san,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              Text(
                                  "$formattedTotal ${LanguageService.get('games_count')}",
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 10)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: SizedBox(
                                    height: 6,
                                    child: Row(
                                      children: [
                                        if (wPct > 0)
                                          Expanded(
                                              flex: wPct,
                                              child: Container(
                                                  color: Colors.white)),
                                        if (dPct > 0)
                                          Expanded(
                                              flex: dPct,
                                              child: Container(
                                                  color: Colors.grey[500])),
                                        if (bPct > 0)
                                          Expanded(
                                              flex: bPct,
                                              child: Container(
                                                  color: Colors.grey[800])),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text("%$wPct / %$dPct / %$bPct",
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 9.5)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> showEngineSettingsDialog(BuildContext context,
    {VoidCallback? onChanged}) async {
  showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151B2B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(LanguageService.get('engine_settings'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Depth
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                '${LanguageService.get('depth')}: ${ChessEngineService().stockfishDepth == 0 ? LanguageService.get('infinite') : ChessEngineService().stockfishDepth.toString()}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15))),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                constraints: const BoxConstraints(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                icon: const Icon(Icons.remove,
                                    color: Colors.white70),
                                onPressed: () {
                                  if (ChessEngineService().stockfishDepth > 0) {
                                    ChessEngineService().stockfishDepth--;
                                    ChessEngineService()._isMultiPvSet = false;
                                    setDialogState(() {});
                                    onChanged?.call();
                                  }
                                }),
                            IconButton(
                                constraints: const BoxConstraints(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                icon: const Icon(Icons.add,
                                    color: Colors.white70),
                                onPressed: () {
                                  if (ChessEngineService().stockfishDepth <
                                      30) {
                                    ChessEngineService().stockfishDepth++;
                                    ChessEngineService()._isMultiPvSet = false;
                                    setDialogState(() {});
                                    onChanged?.call();
                                  }
                                }),
                            IconButton(
                                constraints: const BoxConstraints(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                icon: Icon(Icons.all_inclusive,
                                    color:
                                        ChessEngineService().stockfishDepth == 0
                                            ? Colors.greenAccent
                                            : Colors.white70),
                                onPressed: () {
                                  ChessEngineService().stockfishDepth =
                                      ChessEngineService().stockfishDepth == 0
                                          ? 15
                                          : 0;
                                  ChessEngineService()._isMultiPvSet = false;
                                  setDialogState(() {});
                                  onChanged?.call();
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Variants
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                '${LanguageService.get('variants')}: ${ChessEngineService().stockfishMultiPv}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15))),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                constraints: const BoxConstraints(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                icon: const Icon(Icons.remove,
                                    color: Colors.white70),
                                onPressed: () {
                                  if (ChessEngineService().stockfishMultiPv >
                                      1) {
                                    ChessEngineService().stockfishMultiPv--;
                                    ChessEngineService()._isMultiPvSet = false;
                                    setDialogState(() {});
                                    onChanged?.call();
                                  }
                                }),
                            IconButton(
                                constraints: const BoxConstraints(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                icon: const Icon(Icons.add,
                                    color: Colors.white70),
                                onPressed: () {
                                  if (ChessEngineService().stockfishMultiPv <
                                      10) {
                                    ChessEngineService().stockfishMultiPv++;
                                    ChessEngineService()._isMultiPvSet = false;
                                    setDialogState(() {});
                                    onChanged?.call();
                                  }
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Threads
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.memory, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'Core (Threads): ${ChessEngineService().stockfishThreads}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15))),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                constraints: const BoxConstraints(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                icon: const Icon(Icons.remove,
                                    color: Colors.white70),
                                onPressed: () {
                                  if (ChessEngineService().stockfishThreads >
                                      1) {
                                    ChessEngineService().stockfishThreads--;
                                    ChessEngineService()._isMultiPvSet =
                                        false; // Trigger option reset
                                    setDialogState(() {});
                                    onChanged?.call();
                                  }
                                }),
                            IconButton(
                                constraints: const BoxConstraints(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                icon: const Icon(Icons.add,
                                    color: Colors.white70),
                                onPressed: () {
                                  if (ChessEngineService().stockfishThreads <
                                      8) {
                                    ChessEngineService().stockfishThreads++;
                                    ChessEngineService()._isMultiPvSet =
                                        false; // Trigger option reset
                                    setDialogState(() {});
                                    onChanged?.call();
                                  }
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LanguageService.get('ok'),
                    style: const TextStyle(color: Colors.blueAccent)),
              ),
            ],
          );
        });
      });
}

Future<void> showUserProfileDialog(
    BuildContext context, String username) async {
  final prefs = await SharedPreferences.getInstance();
  String? loggedInUser = prefs.getString('puzzle_username');
  bool isPatron = prefs.getBool('puzzle_user_patron') ?? false;
  String title = prefs.getString('puzzle_user_title') ?? '';
  try {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(username.toLowerCase())
        .get();
    if (doc.exists && doc.data() != null) {
      isPatron =
          (doc.data()!['patron'] == true || doc.data()!['patron'] == 'true');
      title = (doc.data()!['title'] ?? '').toString();
      if (isPatron) {
        await prefs.setBool('puzzle_user_patron', true);
      } else {
        await prefs.remove('puzzle_user_patron');
      }
      if (title.isNotEmpty) {
        await prefs.setString('puzzle_user_title', title);
      } else {
        await prefs.remove('puzzle_user_title');
      }
    }
  } catch (_) {}
  if (username.toLowerCase() == 'termo_x') {
    title = 'TermoGM';
  }

  String cleanName = username.trim().toLowerCase();
  bool isGuest = cleanName.isEmpty ||
      cleanName == 'misafir' ||
      cleanName == 'guest' ||
      cleanName == LanguageService.get('profile_guest').toLowerCase() ||
      prefs.getString('puzzle_username') == null;

  // 0 Saniye gecikme (anlık açılış) için önce önbelleği veya kütüphaneyi kontrol et
  List<Map<String, dynamic>> matchMaps = [];
  int fetchedMaxRating = 0;
  if (!isGuest && cleanName.isNotEmpty) {
    try {
      var res = await http
          .get(Uri.parse('https://lichess.org/api/user/$cleanName'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        int r = data['perfs']?['rapid']?['rating'] ?? 0;
        int b = data['perfs']?['blitz']?['rating'] ?? 0;
        int bl = data['perfs']?['bullet']?['rating'] ?? 0;
        fetchedMaxRating = [r, b, bl].reduce(max);
      } else {
        var cRes = await http
            .get(Uri.parse('https://api.chess.com/pub/player/$cleanName/stats'))
            .timeout(const Duration(seconds: 2));
        if (cRes.statusCode == 200) {
          var cData = jsonDecode(cRes.body);
          int r = cData['chess_rapid']?['last']?['rating'] ?? 0;
          int b = cData['chess_blitz']?['last']?['rating'] ?? 0;
          int bl = cData['chess_bullet']?['last']?['rating'] ?? 0;
          fetchedMaxRating = [r, b, bl].reduce(max);
        }
      }
    } catch (_) {}
  }

  int maxRating = fetchedMaxRating > 0 ? fetchedMaxRating : 1500;
  if (!isGuest &&
      PlayerStyleAnalyzer.onlineGamesCache.containsKey(cleanName) &&
      PlayerStyleAnalyzer.onlineGamesCache[cleanName]!.isNotEmpty) {
    matchMaps = PlayerStyleAnalyzer.onlineGamesCache[cleanName]!;
    if (fetchedMaxRating == 0) {
      for (var m in matchMaps) {
        String wN = (m['whiteName'] ??
                m['players']?['white']?['user']?['name'] ??
                m['white']?['username'] ??
                '')
            .toString();
        String bN = (m['blackName'] ??
                m['players']?['black']?['user']?['name'] ??
                m['black']?['username'] ??
                '')
            .toString();
        int wR = m['whiteRating'] as int? ?? 0;
        int bR = m['blackRating'] as int? ?? 0;
        if (wN.toLowerCase() == cleanName && wR > maxRating) maxRating = wR;
        if (bN.toLowerCase() == cleanName && bR > maxRating) maxRating = bR;
      }
    }
  } else {
    matchMaps = GlobalLibrary.matches.map((m) => m.toJson()).toList();
    if (fetchedMaxRating == 0) {
      for (var m in GlobalLibrary.matches) {
        if (m.whiteName.toLowerCase() == cleanName && m.whiteRating > maxRating)
          maxRating = m.whiteRating;
        if (m.blackName.toLowerCase() == cleanName && m.blackRating > maxRating)
          maxRating = m.blackRating;
      }
    }
  }
  bool isFetchingStyle = false;
  if (!isGuest &&
      (!PlayerStyleAnalyzer.onlineGamesCache.containsKey(cleanName) ||
          PlayerStyleAnalyzer.onlineGamesCache[cleanName]!.isEmpty)) {
    isFetchingStyle = true;
  }

  PlayerStyleProfile styleProfile =
      PlayerStyleAnalyzer.analyze(username, matchMaps, maxRating);
  Color themeColor =
      isPatron ? const Color(0xFFFFD700) : const Color(0xFF5C6BC0);
  final GlobalKey profileStyleCardKey = GlobalKey();

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // Eğer önbellekte henüz çevrimiçi maç yoksa arka planda sessizce çek ve dialog açıkken ekrandaki kartı %100 aynı olacak şekilde güncelle
          if (!isGuest &&
              (!PlayerStyleAnalyzer.onlineGamesCache.containsKey(cleanName) ||
                  PlayerStyleAnalyzer.onlineGamesCache[cleanName]!.isEmpty)) {
            PlayerStyleAnalyzer.fetchOnlineGamesForUser(username)
                .then((onlineGames) {
              if (onlineGames.isNotEmpty && dialogContext.mounted) {
                setDialogState(() {
                  isFetchingStyle = false;
                  matchMaps = onlineGames;
                  if (fetchedMaxRating > 0) {
                    maxRating = fetchedMaxRating;
                  } else {
                    maxRating = 1500;
                    for (var m in matchMaps) {
                      String wN = (m['whiteName'] ??
                              m['players']?['white']?['user']?['name'] ??
                              m['white']?['username'] ??
                              '')
                          .toString();
                      String bN = (m['blackName'] ??
                              m['players']?['black']?['user']?['name'] ??
                              m['black']?['username'] ??
                              '')
                          .toString();
                      int wR = m['whiteRating'] as int? ?? 0;
                      int bR = m['blackRating'] as int? ?? 0;
                      if (wN.toLowerCase() == cleanName && wR > maxRating)
                        maxRating = wR;
                      if (bN.toLowerCase() == cleanName && bR > maxRating)
                        maxRating = bR;
                    }
                  }
                  styleProfile = PlayerStyleAnalyzer.analyze(
                      username, matchMaps, maxRating);
                });
              } else if (dialogContext.mounted) {
                setDialogState(() {
                  isFetchingStyle = false;
                });
              }
            });
          }
          return Dialog(
            backgroundColor: const Color(0xFF151B2B),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: themeColor.withValues(alpha: 0.4), width: 1.5)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst Kısım / Başlık ve Kapat Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_circle,
                              color: themeColor, size: 24),
                          const SizedBox(width: 8),
                          Text(LanguageService.get('profile_title'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(dialogContext),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white12),

                  // Profil Avatarı & İsim
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: isPatron
                        ? const Color(0xFF261D00)
                        : Colors.blueAccent.withValues(alpha: 0.2),
                    child: isPatron
                        ? const Text('👑', style: TextStyle(fontSize: 34))
                        : (username.isNotEmpty &&
                                username != 'Misafir' &&
                                username !=
                                    LanguageService.get('profile_guest'))
                            ? Text(username[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))
                            : const Icon(Icons.person,
                                color: Colors.blueAccent, size: 38),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildUserTags(title, isPatron),
                      Flexible(
                        child: Text(
                          username,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isPatron
                                  ? const Color(0xFFFFD700)
                                  : Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. ÜYELİK KARTI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isPatron
                          ? const Color(0xFF261D00)
                          : const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isPatron
                              ? const Color(0xFFFFD700)
                              : Colors.white24,
                          width: 1),
                      boxShadow: isPatron
                          ? [
                              BoxShadow(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                isPatron
                                    ? Icons.workspace_premium
                                    : Icons.person_outline,
                                color: isPatron
                                    ? const Color(0xFFFFD700)
                                    : Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              LanguageService.get('profile_membership'),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPatron
                                      ? const Color(0xFFFFD700)
                                      : Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LanguageService.get(isPatron
                              ? 'member_elite_title'
                              : 'member_std_title'),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LanguageService.get(isPatron
                              ? 'member_elite_desc'
                              : 'member_std_desc'),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. OYUNCU STİLİ ANALİZ KARTI
                  if (!isGuest && isFetchingStyle) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Center(
                        child:
                            CircularProgressIndicator(color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (!isGuest &&
                      styleProfile.mainStyle != 'Dengeli') ...[
                    RepaintBoundary(
                      key: profileStyleCardKey,
                      child: ColoredBox(
                        color: const Color(0xFF0F172A),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2638),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.analytics_outlined,
                                          color: Colors.greenAccent, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        LanguageService.get(
                                            'profile_style_card'),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share,
                                        color: Colors.blueAccent),
                                    tooltip: LanguageService.get('share_style'),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      String? savedFilePath;
                                      try {
                                        await Future.delayed(
                                            const Duration(milliseconds: 300));
                                        RenderRepaintBoundary? boundary =
                                            profileStyleCardKey.currentContext
                                                    ?.findRenderObject()
                                                as RenderRepaintBoundary?;
                                        if (boundary == null) return;
                                        await Future.delayed(
                                            const Duration(milliseconds: 500));
                                        ui.Image image = await boundary.toImage(
                                            pixelRatio: 3.0);
                                        ByteData? byteData =
                                            await image.toByteData(
                                                format: ui.ImageByteFormat.png);
                                        if (byteData == null) {
                                          if (context.mounted)
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Share Error: Image generation failed')));
                                          return;
                                        }
                                        final bytes =
                                            byteData.buffer.asUint8List();
                                        String u = username;
                                        String style =
                                            LanguageService.styleLabel(
                                                styleProfile.mainStyle);
                                        String ratingStr = maxRating > 0
                                            ? maxRating.toString()
                                            : '-';
                                        bool isEn =
                                            LanguageService.currentLang == 'en';
                                        String shareText = isEn
                                            ? '♟️ Check out my chess profile and stats on MoveLab!\n👤 Player: $u\n📈 Rating: $ratingStr\n🎯 Play Style: $style\n\nDownload MoveLab now to get a detailed analysis of your own chess profile and play style:\n📲 https://play.google.com/store/apps/details?id=com.movelab.app'
                                            : '♟️ Satranç profilimi ve istatistiklerimi MoveLab\'de incele!\n👤 Oyuncu: $u\n📈 Rating: $ratingStr\n🎯 Oyun Stili: $style\n\nSen de kendi satranç profilini ve oyun stilini detaylıca analiz etmek için MoveLab\'i hemen indir:\n📲 https://play.google.com/store/apps/details?id=com.movelab.app';

                                        if (context.mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      LanguageService.get(
                                                          'preparing_share'))));

                                        try {
                                          const platform = MethodChannel(
                                              'com.movelab.app/share');
                                          await platform
                                              .invokeMethod('shareImage', {
                                            'bytes': bytes,
                                            'text': shareText,
                                          });
                                        } catch (e2, st2) {
                                          if (context.mounted)
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'NATIVE_PROFILE_SHARE_ERROR: $e2\n${st2.toString().split('\n').first}')));
                                        }
                                      } catch (e, st) {
                                        debugPrint("Profile share error: $e");
                                        if (context.mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'DART_PROFILE_SHARE_ERROR: $e\n${st.toString().split('\n').first}')));
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 0),
                              Row(
                                children: [
                                  buildUserTags(title, isPatron),
                                  Flexible(
                                    child: Text(
                                      username,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${LanguageService.get('rating')}: ${maxRating > 0 ? maxRating.toString() : '-'}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              Center(
                                child: Column(
                                  children: [
                                    Text(styleProfile.mainIcon,
                                        style: const TextStyle(fontSize: 40)),
                                    const SizedBox(height: 4),
                                    Text(
                                      LanguageService.styleLabel(
                                          styleProfile.mainStyle),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor),
                                    ),
                                    const SizedBox(height: 8),
                                    if (styleProfile.subStyles.isNotEmpty)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        alignment: WrapAlignment.center,
                                        children: styleProfile.subStyles
                                            .map((sub) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        themeColor.withValues(
                                                            alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: themeColor
                                                            .withValues(
                                                                alpha: 0.5)),
                                                  ),
                                                  child: Text(
                                                      LanguageService
                                                          .styleLabel(sub),
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white)),
                                                ))
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildProfileStyleBar(
                                  LanguageService.get('style_aggressive'),
                                  styleProfile.aggressive,
                                  Colors.redAccent),
                              _buildProfileStyleBar(
                                  LanguageService.get('style_defensive'),
                                  styleProfile.defensive,
                                  Colors.blueAccent),
                              _buildProfileStyleBar(
                                  LanguageService.get('style_tactical'),
                                  styleProfile.tactical,
                                  Colors.amberAccent),
                              _buildProfileStyleBar(
                                  LanguageService.get('style_positional'),
                                  styleProfile.positional,
                                  Colors.green),
                              _buildProfileStyleBar(
                                  LanguageService.get('style_risk'),
                                  styleProfile.risk,
                                  Colors.orangeAccent),
                              _buildProfileStyleBar(
                                  LanguageService.get('style_opening'),
                                  styleProfile.opening,
                                  Colors.purpleAccent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (!isGuest &&
                      styleProfile.mainStyle == 'Dengeli') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.amberAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.analytics_outlined,
                              color: Colors.amberAccent, size: 32),
                          const SizedBox(height: 10),
                          Text(
                            LanguageService.currentLang == 'tr'
                                ? 'Analiz Edilecek Maç Yok'
                                : 'No Matches to Analyze',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LanguageService.currentLang == 'tr'
                                ? 'Kütüphanenizde "$username" adına ait hiç maç bulunamadığı için oyun stili analizi oluşturulamadı. Maç oynayarak veya hesap maçlarınızı kütüphaneye ekleyerek stil kartınızı oluşturabilirsiniz.'
                                : 'No matches found in the library for "$username". Play matches or import your games to generate your player style analysis card.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline,
                              color: Colors.blueAccent, size: 32),
                          const SizedBox(height: 10),
                          Text(
                            LanguageService.currentLang == 'tr'
                                ? 'Oyuncu Kartı Kilitli'
                                : 'Player Card Locked',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LanguageService.currentLang == 'tr'
                                ? 'Oyuncu stili analiz kartınızı ve kişisel radar istatistiklerinizi görmek için lütfen giriş yapın veya kayıt olun.'
                                : 'Please log in or register with an account to view your personalized player style analysis card and stats.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.login),
                            label: Text(LanguageService.get('settings_login')),
                            onPressed: () async {
                              if (dialogContext.mounted)
                                Navigator.pop(dialogContext);
                              Map<String, String?>? inputData =
                                  await showGlobalLoginDialog(context);
                              if (inputData != null &&
                                  inputData['username'] != null) {
                                String newName = inputData['username']!.trim();
                                if (newName.toLowerCase() == 'termo_x')
                                  inputData['title'] = 'TermoGM';

                                await prefs.setString(
                                    'puzzle_username', newName);
                                if (inputData['title'] != null)
                                  await prefs.setString(
                                      'puzzle_user_title', inputData['title']!);
                                if (inputData['patron'] == 'true')
                                  await prefs.setBool(
                                      'puzzle_user_patron', true);

                                await GlobalLibrary.syncWithCloud(newName);

                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (c) => const HomePage()),
                                      (route) => false);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (loggedInUser != null &&
                      loggedInUser.toLowerCase() == cleanName) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.blueAccent),
                      label: Text(LanguageService.get('settings_logout'),
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                        } catch (_) {}
                        try {
                          await GoogleSignIn().signOut();
                        } catch (_) {}
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('puzzle_username');
                        await prefs.remove('puzzle_user_title');
                        await prefs.remove('puzzle_user_patron');
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => const HomePage()),
                              (route) => false);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.redAccent),
                      label: Text(
                          LanguageService.get('settings_delete_account'),
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        bool confirm = await showDialog(
                                context: dialogContext,
                                builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E2536),
                                      title: Text(
                                          LanguageService.get(
                                              'settings_delete_confirm_title'),
                                          style: const TextStyle(
                                              color: Colors.white)),
                                      content: Text(
                                          LanguageService.get(
                                              'settings_delete_confirm_desc'),
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(
                                              LanguageService.get(
                                                  'settings_delete_confirm_no'),
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(
                                              LanguageService.get(
                                                  'settings_delete_confirm_yes'),
                                              style: const TextStyle(
                                                  color: Colors.redAccent)),
                                        ),
                                      ],
                                    )) ??
                            false;

                        if (confirm) {
                          try {
                            if (cleanName.isNotEmpty) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(cleanName)
                                    .delete();
                              } catch (_) {}
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users_by_uid')
                                    .doc(user.uid)
                                    .delete();
                              } catch (_) {}

                              try {
                                await user.delete();
                              } catch (_) {}

                              try {
                                await GoogleSignIn().signOut();
                              } catch (_) {}
                            }

                            await prefs.remove('puzzle_username');
                            await prefs.remove('puzzle_user_title');
                            await prefs.remove('puzzle_user_patron');

                            // Ana sayfanın güncellenmesi için ufak bir hack:
                            // Settings kısmında onChanged callback'i vardı ama burada yok.
                            // Navigator ile ana sayfaya dönülebilir.
                            if (dialogContext.mounted) {
                              Navigator.pop(
                                  dialogContext); // Profil dialogunu kapat
                              // Uygulamanın yeniden başlamasını sağlamak için basitçe yönlendirme:
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => const HomePage()),
                                  (route) => false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(LanguageService.get(
                                          'settings_delete_success')),
                                      backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.redAccent));
                            }
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildProfileStyleBar(String label, int value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        SizedBox(
            width: 85,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white10,
              color: color,
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value%',
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class LifetimeEliteCard extends StatefulWidget {
  const LifetimeEliteCard({super.key});

  @override
  State<LifetimeEliteCard> createState() => _LifetimeEliteCardState();
}

class _LifetimeEliteCardState extends State<LifetimeEliteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String priceText = "";
    try {
      final product = IAPService()
          .products
          .firstWhere((p) => p.id == 'movelab_elite_lifetime');
      priceText = product.price;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(2), // border kalınlığı
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: SweepGradient(
                center: Alignment.center,
                startAngle: 0.0,
                endAngle: 3.141592653589793 * 2,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFF2B2000),
                  Color(0xFFFFD700),
                  Color(0xFF2B2000),
                  Color(0xFFFFD700),
                ],
                transform:
                    GradientRotation(_controller.value * 2 * 3.141592653589793),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2B2000), Color(0xFF1A1400)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text("💎 Lifetime Elite",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700))),
                      ),
                      if (priceText.isNotEmpty)
                        Text(priceText,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LanguageService.currentLang == 'en'
                        ? "Enjoy Lifetime Elite benefits with a one-time payment and provide permanent support for the development of the project."
                        : "Tek seferlik ödeme ile Ömür Boyu Elite avantajlarından yararlanın ve projenin gelişimine kalıcı destek sağlayın.",
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await IAPService().buyEliteLifetime();
                      },
                      child: Text(
                          LanguageService.currentLang == 'en'
                              ? "Get Lifetime Elite"
                              : "Ömür Boyu Elite Al",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> showSettingsSheet(BuildContext context,
    {VoidCallback? onChanged,
    VoidCallback? onPaste,
    VoidCallback? onResetBoard}) async {
  final prefs = await SharedPreferences.getInstance();
  String? currentUsername = prefs.getString('puzzle_username');

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF151B2B),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (modalContext) {
      return StatefulBuilder(
        builder: (modalContext, setModalState) {
          IAPService().onStatusChanged = () {
            if (modalContext.mounted) setModalState(() {});
          };
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () {
                          if (modalContext.mounted) Navigator.pop(modalContext);
                        },
                      ),
                      Text(LanguageService.get('settings'),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Yuvarlak Profil Kısmı
                  InkWell(
                    onTap: () {
                      if (modalContext.mounted) Navigator.pop(modalContext);
                      showUserProfileDialog(
                          context,
                          currentUsername ??
                              LanguageService.get('profile_guest'));
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                (prefs.getBool('puzzle_user_patron') ??
                                            false) ||
                                        (currentUsername?.toLowerCase() ==
                                            'termo_x')
                                    ? const Color(0xFF261D00)
                                    : Colors.blueAccent.withValues(alpha: 0.2),
                            child: (prefs.getBool('puzzle_user_patron') ??
                                        false) ||
                                    (currentUsername?.toLowerCase() ==
                                        'termo_x')
                                ? const Text('👑',
                                    style: TextStyle(fontSize: 22))
                                : (currentUsername != null &&
                                        currentUsername!.isNotEmpty &&
                                        currentUsername != 'Misafir')
                                    ? Text(currentUsername![0].toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))
                                    : const Icon(Icons.person,
                                        color: Colors.blueAccent, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    buildUserTags(
                                        prefs.getString('puzzle_user_title') ??
                                            '',
                                        prefs.getBool('puzzle_user_patron') ??
                                            false),
                                    Flexible(
                                      child: Text(
                                        currentUsername ??
                                            LanguageService.get(
                                                'profile_guest'),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  LanguageService.get('profile_view'),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- ELITE ABONELİK KARTI ---
                  if (currentUsername != null &&
                      (!IAPService().isElite ||
                          currentUsername?.toLowerCase() == 'termo_x'))
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none, // for shadows if any
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                            width: MediaQuery.of(modalContext).size.width * 0.85,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF2B2000), Color(0xFF1A1400)]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                    width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                            LanguageService.currentLang == 'en'
                                                ? "👑 Become an Elite! (Monthly)"
                                                : "👑 Elite Üye Ol! (Aylık)",
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFFD700))),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          try {
                                            final p = IAPService()
                                                .products
                                                .firstWhere((p) => p.id == 'elite');
                                            return Text(p.price,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white));
                                          } catch (_) {
                                            return const SizedBox();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    LanguageService.currentLang == 'en'
                                        ? "Get the ELITE badge next to your name and support this open-source project developed entirely by a student."
                                        : "İsminizin yanında ELİTE etiketi isteyenler için ve Öğrenci olarak tek başıma geliştirdiğim bu açık kaynak kodlu projeye destek sağlamak için katılabilirsiniz.",
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        height: 1.3),
                                  ),
                                  const SizedBox(height: 12),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFD700),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () async {
                                        await IAPService().buyElite();
                                      },
                                      child: Text(
                                          LanguageService.currentLang == 'en'
                                              ? "Support & Get Elite"
                                              : "Destek Ol & Elite'e Geç",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: MediaQuery.of(modalContext).size.width * 0.85,
                            child: const LifetimeEliteCard(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (currentUsername == null) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    ListTile(
                      leading: const Icon(Icons.login, color: Colors.blueAccent),
                      title: Text(LanguageService.get('settings_login'),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500)),
                      onTap: () async {
                        if (modalContext.mounted) Navigator.pop(modalContext);
                        Map<String, String?>? inputData =
                            await showGlobalLoginDialog(context);
                        if (inputData != null && inputData['username'] != null) {
                          String newName = inputData['username']!.trim();
                          if (newName.toLowerCase() == 'termo_x') {
                            inputData['title'] = 'TermoGM';
                          }

                          await prefs.setString('puzzle_username', newName);
                          if (inputData['title'] != null) {
                            await prefs.setString(
                                'puzzle_user_title', inputData['title']!);
                          }
                          if (inputData['patron'] == 'true') {
                            await prefs.setBool('puzzle_user_patron', true);
                          }

                          await GlobalLibrary.syncWithCloud(newName);
                          onChanged?.call();
                        }
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.settings_applications,
                        color: Colors.white70),
                    title: Text(LanguageService.get('engine_settings'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    onTap: () {
                      if (modalContext.mounted) Navigator.pop(modalContext);
                      showEngineSettingsDialog(context, onChanged: onChanged);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.white70),
                    title: Text(LanguageService.get('language'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<String>(
                      value: LanguageService.currentLang,
                      dropdownColor: const Color(0xFF151B2B),
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                            value: 'tr',
                            child: Text(LanguageService.get('turkish'),
                                style: const TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: 'en',
                            child: Text(LanguageService.get('english'),
                                style: const TextStyle(color: Colors.white))),
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
                  ListTile(
                    leading: const Icon(Icons.palette, color: Colors.white70),
                    title: Text(LanguageService.get('board_color'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<BoardColor>(
                      value: BoardThemeService.boardColor,
                      dropdownColor: const Color(0xFF151B2B),
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                            value: BoardColor.brown,
                            child: SizedBox(
                                width: 120,
                                child: Text(
                                    LanguageService.get('board_color_brown'),
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.right))),
                        DropdownMenuItem(
                            value: BoardColor.green,
                            child: SizedBox(
                                width: 120,
                                child: Text(
                                    LanguageService.get('board_color_green'),
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.right))),
                        DropdownMenuItem(
                            value: BoardColor.blue,
                            child: SizedBox(
                                width: 120,
                                child: Text(
                                    LanguageService.get('board_color_blue'),
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.right))),
                        DropdownMenuItem(
                            value: BoardColor.grey,
                            child: SizedBox(
                                width: 120,
                                child: Text(
                                    LanguageService.get('board_color_grey'),
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.right))),
                      ],
                      onChanged: (BoardColor? newValue) async {
                        if (newValue != null) {
                          await BoardThemeService.setBoardColor(newValue);
                          onChanged?.call();
                          setModalState(() {});
                        }
                      },
                    ),
                  ),
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.music_note, color: Colors.white70),
                    title: Text(LanguageService.get('piece_sounds'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    activeThumbColor: const Color(0xFF64FFDA),
                    value: !SoundService.isMuted,
                    onChanged: (val) {
                      SoundService.setMuted(!val);
                      setModalState(() {});
                      onChanged?.call();
                    },
                  ),
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.call_made, color: Colors.white70),
                    title: Text(LanguageService.get('show_arrows'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    activeThumbColor: const Color(0xFF64FFDA),
                    value: SoundService.showArrows,
                    onChanged: (val) {
                      SoundService.setShowArrows(val);
                      setModalState(() {});
                      onChanged?.call();
                    },
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.volume_down,
                            color: SoundService.isMuted
                                ? Colors.white24
                                : Colors.white70),
                        Expanded(
                            child: Slider(
                                value: SoundService.volume,
                                activeColor: const Color(0xFF64FFDA),
                                inactiveColor: Colors.white12,
                                onChanged: SoundService.isMuted
                                    ? null
                                    : (val) {
                                        SoundService.setVolume(val);
                                        setModalState(() {});
                                        onChanged?.call();
                                      })),
                        Icon(Icons.volume_up,
                            color: SoundService.isMuted
                                ? Colors.white24
                                : Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
  static double evalToWinPercent(double cp) =>
      50.0 + 50.0 * (2.0 / (1.0 + exp(-0.00368208 * cp)) - 1.0);
  static double cpFromEval(double eval, bool isMate) {
    if (isMate || eval.abs() > 14.0)
      return eval.isNegative
          ? -mateCentipawn.toDouble()
          : mateCentipawn.toDouble();
    return eval * 100.0;
  }

  static double calculateMoveAccuracy(double bestEval, double playedEval,
      bool isWhiteMove, bool isBeforeMate, bool isAfterMate) {
    double cpBest = cpFromEval(bestEval, isBeforeMate);
    double cpPlayed = cpFromEval(playedEval, isAfterMate);
    double bestWin = evalToWinPercent(cpBest);
    double playedWin = evalToWinPercent(cpPlayed);
    double winPercentLoss =
        isWhiteMove ? (bestWin - playedWin) : (playedWin - bestWin);
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
    } else if (topGap < 1.5)
      complexity += 3.0; // Orta karmaşık
    else
      complexity += 1.0; // Basit

    // Motorun bulduğu alternatiflerin ne kadarı birbirine yakın? (Taktiksel yoğunluk)
    int nearMoves =
        alternatives.where((e) => (alternatives[0] - e).abs() < 1.0).length;
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
    'p': 1,
    'n': 3,
    'b': 3,
    'r': 5,
    'q': 9,
    'k': 100
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
              } else if (san[0] == 'R')
                attackerVal = 5;
              else if (san[0] == 'Q')
                attackerVal = 9;
              else if (san[0] == 'K') attackerVal = 100;

              bool isProtected = false;
              chess.move(san);
              List<String> ourResponses = List<String>.from(chess.moves());
              for (String response in ourResponses) {
                if (response.contains('x')) {
                  String cleanResponse =
                      response.replaceAll('+', '').replaceAll('#', '');
                  if (cleanResponse.length >= 2) {
                    String ourTargetSq =
                        cleanResponse.substring(cleanResponse.length - 2);
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
                } else if (projectedNetLoss == 2)
                  currentSacType = 2;
                else
                  currentSacType = 1;

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
    bool isMate =
        bestEval.abs() > 14.0 || playedEval.abs() > 14.0 || isMateFound;
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
    if (!playerReceivesMate &&
        ((sacrificeType == 2 && nearBest) ||
            (sacrificeType == 1 && nearBest && complexity >= 3.0) ||
            (forcedMove && nearBest && !isMate && complexity >= 3.0))) {
      return "Harika Hamle";
    }

    // =====================================================
    // 3. BLUNDER / MISTAKE - STATE TRANSITION
    // =====================================================
    if (stateBefore == 'winning' &&
        (stateAfter == 'equal' ||
            stateAfter == 'losing' ||
            stateAfter == 'worse')) {
      return "Çok Kötü Hamle";
    }
    if (stateBefore == 'equal' && stateAfter == 'losing') {
      return "Çok Kötü Hamle";
    }
    if (stateBefore == 'better' &&
        (stateAfter == 'worse' || stateAfter == 'losing')) {
      return "Kötü Hamle";
    }

    // =====================================================
    // 4. STANDART DOĞRULUK YÜZDESİ
    // =====================================================
    if (playerDeliversMate || perfectMove || accuracy >= 99.0)
      return "En İyi Hamle";
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
    required this.bestEval,
    required this.playedEval,
    required this.accuracy,
    required this.qualityLabel,
    required this.isBrilliant,
    required this.isGreat,
  });
}

// =====================================================================
// 2. KÜTÜPHANE & HAFIZA
// =====================================================================

class SavedMatch {
  final String title,
      whiteName,
      blackName,
      whiteTitle,
      blackTitle,
      pgn,
      moves,
      speed,
      winner,
      platform;
  final PlayerColor userColor;
  final int whiteRating, blackRating;

  SavedMatch({
    required this.title,
    required this.pgn,
    required this.speed,
    this.whiteName = 'Beyaz',
    this.blackName = 'Siyah',
    this.whiteTitle = '',
    this.blackTitle = '',
    this.moves = '',
    this.winner = 'draw',
    this.userColor = PlayerColor.white,
    this.whiteRating = 0,
    this.blackRating = 0,
    this.platform = 'Bilinmiyor',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'whiteName': whiteName,
        'blackName': blackName,
        'whiteTitle': whiteTitle,
        'blackTitle': blackTitle,
        'pgn': pgn,
        'moves': moves,
        'speed': speed,
        'winner': winner,
        'userColor': userColor == PlayerColor.white ? 'w' : 'b',
        'whiteRating': whiteRating,
        'blackRating': blackRating,
        'platform': platform
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
      whiteName: wName,
      blackName: bName,
      whiteTitle: json['whiteTitle'] ?? '',
      blackTitle: json['blackTitle'] ?? '',
      pgn: json['pgn'] ?? '',
      moves: json['moves'] ?? '',
      speed: json['speed'] ?? '',
      winner: json['winner'] ?? 'draw',
      userColor:
          json['userColor'] == 'b' ? PlayerColor.black : PlayerColor.white,
      whiteRating: json['whiteRating'] ?? 0,
      blackRating: json['blackRating'] ?? 0,
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
    matches =
        matchesStr.map((e) => SavedMatch.fromJson(jsonDecode(e))).toList();
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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(username.toLowerCase())
            .set({'saved_matches': matchesStr}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud save failed: $e');
      }
    }
  }

  static Future<void> syncWithCloud(String username) async {
    if (username.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(username.toLowerCase())
          .get();
      if (doc.exists && doc.data() != null) {
        final prefs = await SharedPreferences.getInstance();
        bool isPatronCloud =
            (doc.data()!['patron'] == true || doc.data()!['patron'] == 'true');
        String titleCloud = (doc.data()!['title'] ?? '').toString();
        if (isPatronCloud) {
          await prefs.setBool('puzzle_user_patron', true);
        } else {
          await prefs.remove('puzzle_user_patron');
        }
        if (titleCloud.isNotEmpty) {
          await prefs.setString('puzzle_user_title', titleCloud);
        } else {
          await prefs.remove('puzzle_user_title');
        }

        if (doc.data()!.containsKey('saved_matches')) {
          List<dynamic> cloudMatchesRaw = doc.data()!['saved_matches'];
          List<SavedMatch> cloudMatches = cloudMatchesRaw
              .map((e) => SavedMatch.fromJson(jsonDecode(e.toString())))
              .toList();

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
      }
    } catch (e) {
      debugPrint('Cloud sync failed: $e');
    }
  }

  static Future<void> saveSearch(String username) async {
    if (username.trim().isEmpty) {
      return;
    }
    searchHistory
        .removeWhere((name) => name.toLowerCase() == username.toLowerCase());
    searchHistory.insert(0, username.trim());
    if (searchHistory.length > 15) {
      searchHistory = searchHistory.sublist(0, 15);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', searchHistory);
  }

  static bool isSaved(String pgn, String moves) {
    if (pgn.isEmpty && moves.isEmpty) {
      return false;
    }
    if (pgn.isNotEmpty) {
      return matches.any((m) => m.pgn == pgn);
    }
    return matches.any((m) => m.moves == moves);
  }
}

Widget buildUserTags(String title, bool isDonor) {
  List<Widget> tags = []; // Ekrana basılacak etiketleri bu listede toplayacağız

  // 1. EĞER UNVANI VARSA (GM, IM vs.) LİSTEYE EKLE
  if (title.trim().isNotEmpty) {
    bool isTermo = title == 'TermoGM';
    String displayTitle = isTermo ? 'GM' : title;
    Color bgColor = isTermo
        ? const Color(0xFFFFD700).withValues(alpha: 0.25)
        : Colors.grey.withValues(alpha: 0.6);
    Color textColor = isTermo ? const Color(0xFFFFD700) : Colors.white;
    Border? border = isTermo
        ? Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1)
        : null;

    tags.add(Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: border,
      ),
      child: Text(displayTitle.toUpperCase(),
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    ));
  }

  // 2. EĞER ABONEYSE (PATRON) ELİTE ETİKETİNİ LİSTEYE EKLE
  if (isDonor) {
    tags.add(Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(
            0xFF261D00), // Koyu lüks altın zemin taç emojisini belirginleştirir
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: const Text('ELİTE 👑',
          style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    ));
  }

  // Eğer listede hiçbir etiket yoksa boşluk döndür, varsa yan yana (Row) diz
  if (tags.isEmpty) return const SizedBox.shrink();
  return Row(mainAxisSize: MainAxisSize.min, children: tags);
}

Widget buildTitleTag(String title) {
  if (title.trim().isEmpty) {
    return const SizedBox.shrink();
  }

  bool isTermo = title == 'TermoGM';
  String displayTitle = isTermo ? 'GM' : title;
  Color bgColor = isTermo
      ? const Color(0xFFFFD700).withValues(alpha: 0.25)
      : Colors.grey.withValues(alpha: 0.6);
  Color textColor = isTermo ? const Color(0xFFFFD700) : Colors.white;
  Border? border = isTermo
      ? Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1)
      : null;

  return Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(4),
      border: border,
    ),
    child: Text(displayTitle.toUpperCase(),
        style: TextStyle(
            color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
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

  int stockfishDepth = 15;
  int stockfishMultiPv = 3;
  int stockfishThreads = 2;

  ChessEngineService._internal();

  void initEngine() {
    if (_stockfish != null) {
      return;
    }
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
    if (_stockfish == null) {
      throw Exception("Stockfish başlatılmadı.");
    }
    int timeout = 0;
    while (
        _stockfish!.state.value == StockfishState.starting && timeout < 100) {
      await Future.delayed(const Duration(milliseconds: 20));
      timeout++;
    }

    if (!_isMultiPvSet && _stockfish!.state.value == StockfishState.ready) {
      try {
        _stockfish!.stdin = 'setoption name Threads value 2';
        _stockfish!.stdin = 'setoption name Hash value 64';
        _stockfish!.stdin =
            'setoption name MultiPV value 8'; // PROFESYONEL DERİNLİK İÇİN 8 YAPINIZ (5 HIZLI VE İDEAL)
        _stockfish!.stdin = 'setoption name Ponder value false';
        _isMultiPvSet = true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  void _parseEngineOutput(String output) {
    try {
      if (output == 'readyok') {
        if (_readyCompleter != null && !_readyCompleter!.isCompleted)
          _readyCompleter!.complete();
        return;
      }

      if (output.startsWith('info depth') && !output.contains('currmove')) {
        int multipv = 1;
        final pvMatch = RegExp(r'multipv (\d+)').firstMatch(output);
        if (pvMatch != null) multipv = int.parse(pvMatch.group(1)!);

        final depthMatch = RegExp(r'depth (\d+)').firstMatch(output);
        if (depthMatch != null) {
          _currentEvalData['depth'] = int.tryParse(depthMatch.group(1)!) ?? 0;
        }

        double val = 0.0;
        bool isMate = false;
        final cpMatch = RegExp(r'score cp (-?\d+)').firstMatch(output);
        final mateMatch = RegExp(r'score mate (-?\d+)').firstMatch(output);

        if (cpMatch != null) {
          double rawVal = int.parse(cpMatch.group(1)!) / 100.0;
          val = _isWhiteToMove ? rawVal : -rawVal;
        } else if (mateMatch != null) {
          isMate = true;
          int mateIn = int.parse(mateMatch.group(1)!);
          double rawVal = mateIn > 0 ? 15.0 : -15.0;
          val = _isWhiteToMove ? rawVal : -rawVal;
        }

        String pvMoves =
            output.contains(' pv ') ? output.split(' pv ').last.trim() : '';
        String firstMove = pvMoves.isNotEmpty
            ? pvMoves
                .split(' ')
                .firstWhere((s) => s.isNotEmpty, orElse: () => '')
            : '';

        _currentEvalData['alternatives'] ??= <double>[0.0, 0.0, 0.0, 0.0, 0.0];
        _currentEvalData['suggestions'] ??= <String>['', '', '', '', ''];
        _currentEvalData['pv_lines'] ??= <String>['', '', '', '', ''];
        _currentEvalData['mates'] ??= <bool>[false, false, false, false, false];

        List<double> alts = _currentEvalData['alternatives'];
        List<String> suggs = _currentEvalData['suggestions'];
        List<String> pvs = _currentEvalData['pv_lines'];
        List<bool> mates = _currentEvalData['mates'];

        if (multipv >= 1 && multipv <= 5) {
          while (alts.length < multipv) {
            alts.add(0.0);
          }
          while (suggs.length < multipv) {
            suggs.add('');
          }
          while (pvs.length < multipv) {
            pvs.add('');
          }
          while (mates.length < multipv) {
            mates.add(false);
          }

          alts[multipv - 1] = val;
          suggs[multipv - 1] = firstMove;
          pvs[multipv - 1] = pvMoves;
          mates[multipv - 1] = isMate;
        }

        if (multipv == 1) {
          _currentEvalData['best_eval'] = val;
          _currentEvalData['is_mate'] = isMate;
        }
        if (_onContinuousUpdate != null)
          _onContinuousUpdate!(Map<String, dynamic>.from(_currentEvalData));
      }

      if (output.startsWith('bestmove')) {
        final bestMoveMatch = RegExp(r'bestmove (\S+)').firstMatch(output);
        if (bestMoveMatch != null)
          _currentEvalData['bestmove'] = bestMoveMatch.group(1);
        if (_evaluationCompleter != null &&
            !_evaluationCompleter!.isCompleted) {
          _evaluationCompleter!.complete(_currentEvalData);
          _evaluationCompleter = null;
        }
      }
    } catch (e) {
      debugPrint("Motor Parse Hatası: $e");
    }
  }

  Future<void> startContinuousAnalysis(
      String fen, Function(Map<String, dynamic>) onUpdate) async {
    _onContinuousUpdate = null;
    stopEngine();
    await _waitForReady();
    _readyCompleter = Completer<void>();
    if (_stockfish?.state.value == StockfishState.ready) {
      _stockfish!.stdin = 'isready';
      try {
        await _readyCompleter!.future
            .timeout(const Duration(milliseconds: 250));
      } catch (_) {}
    }
    _isWhiteToMove = fen.split(' ')[1] == 'w';
    _onContinuousUpdate = onUpdate;
    _currentEvalData = {
      'alternatives': <double>[0.0, 0.0, 0.0, 0.0, 0.0],
      'suggestions': <String>['', '', '', '', ''],
      'pv_lines': <String>['', '', '', '', ''],
      'mates': <bool>[false, false, false, false, false],
      'depth': 0
    };
    if (_stockfish?.state.value == StockfishState.ready) {
      if (!_isMultiPvSet) {
        _stockfish!.stdin = 'setoption name MultiPV value $stockfishMultiPv';
        _stockfish!.stdin = 'setoption name Threads value $stockfishThreads';
        _isMultiPvSet = true;
      }
      _stockfish!.stdin = 'position fen $fen';
      _stockfish!.stdin =
          stockfishDepth == 0 ? 'go infinite' : 'go depth $stockfishDepth';
    }
  }

  void stopContinuousAnalysis() {
    _onContinuousUpdate = null;
    stopEngine();
  }

  Future<Map<String, dynamic>> evaluateFen(String fen,
      {int depth = 20, int maxTimeMs = 1200, int? multiPvOverride, int? skillLevelOverride}) async {
    await _waitForReady();
    _onContinuousUpdate = null;
    if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted)
      _evaluationCompleter!.completeError("İptal edildi");
    _evaluationCompleter = null;
    stopEngine();
    _readyCompleter = Completer<void>();
    if (_stockfish?.state.value == StockfishState.ready) {
      _stockfish!.stdin = 'isready';
      try {
        await _readyCompleter!.future
            .timeout(const Duration(milliseconds: 250));
      } catch (_) {}
    }
    _isWhiteToMove = fen.split(' ')[1] == 'w';
    _currentEvalData = {
      'alternatives': <double>[0.0, 0.0, 0.0, 0.0, 0.0],
      'suggestions': <String>['', '', '', '', ''],
      'pv_lines': <String>['', '', '', '', ''],
      'mates': <bool>[false, false, false, false, false],
      'depth': 0
    };
    _evaluationCompleter = Completer<Map<String, dynamic>>();

    try {
      if (_stockfish?.state.value == StockfishState.ready) {
        int activeMultiPv = multiPvOverride ?? stockfishMultiPv;
        if (!_isMultiPvSet || multiPvOverride != null) {
          _stockfish!.stdin = 'setoption name MultiPV value $activeMultiPv';
          _stockfish!.stdin = 'setoption name Threads value $stockfishThreads';
          _isMultiPvSet = true;
        }
        if (skillLevelOverride != null) {
          _stockfish!.stdin = 'setoption name Skill Level value $skillLevelOverride';
        } else {
          _stockfish!.stdin = 'setoption name Skill Level value 20';
        }
        _stockfish!.stdin = 'position fen $fen';
        _stockfish!.stdin =
            depth == 0 ? 'go infinite' : 'go depth $depth';
        Timer(Duration(milliseconds: maxTimeMs), () {
          if (_evaluationCompleter != null &&
              !_evaluationCompleter!.isCompleted) stopEngine();
        });
      } else {
        _evaluationCompleter!.completeError("Motor hazır değil");
      }
    } catch (e) {
      if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted)
        _evaluationCompleter!.completeError(e);
    }
    return await _evaluationCompleter!.future
        .timeout(Duration(milliseconds: maxTimeMs + 2000), onTimeout: () {
      if (_evaluationCompleter != null && !_evaluationCompleter!.isCompleted)
        _evaluationCompleter!.completeError("Zaman Aşımı");
      return {};
    });
  }

  void dispose() {
    _outputSubscription?.cancel();
    stopEngine();
    try {
      if (_stockfish?.state.value == StockfishState.ready)
        _stockfish?.stdin = 'quit';
    } catch (_) {}
    _stockfish?.dispose();
    _stockfish = null;
    _isMultiPvSet = false;
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
    required this.aggressive,
    required this.defensive,
    required this.tactical,
    required this.positional,
    required this.opening,
    required this.risk,
    required this.mainStyle,
    required this.mainIcon,
    required this.subStyles,
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
  static int scale(double val, double minRaw, double maxRaw, double minOut,
      double maxOut, int rating) {
    // 1. Oyuncunun o stildeki ham başarısını (0.0 - 1.0 arası) hesapla
    double ratio = (val - minRaw) / (maxRaw - minRaw);
    ratio = ratio.clamp(0.0, 1.0);

    // 2. Dinamik Limitler
    double dynamicFloor = 5.0;
    double potentialCeiling = 99.0;

    if (rating > 0) {
      // 2000 ELO için en az ~50 taban olmalı ki kart zayıf görünmesin.
      dynamicFloor = (rating / 2500.0) * 45.0 + 15.0;
      dynamicFloor = dynamicFloor.clamp(25.0, 60.0);

      // Çıkabileceği maksimum tavan kapasitesi (2800 GM'ler için 99)
      potentialCeiling = (rating / 2800.0) * 75.0 + 25.0;
      potentialCeiling = potentialCeiling.clamp(45.0, 99.0);
    }

    // 3. Güçlü yönleri parlatmak için "Yetenek Sıçraması (Boost)"
    double boost = 0.0;
    if (ratio > 0.5) {
      // Eğer bu özellik oyuncunun güçlü yönüyse, ELO'ya bağlı makul bir sıçrama ekle
      boost = (ratio - 0.5) *
          2.0 *
          (rating / 2800.0) *
          20.0; // Maksimum 20 puan ekstra sıçrama
    }

    // 4. Temel puanı taban ve tavan arasında dağıt
    double baseScore =
        dynamicFloor + (ratio * (potentialCeiling - dynamicFloor));

    // 5. Sıçramayı (boost) ekle ve skoru sonlandır
    double finalScore = baseScore + boost;

    return finalScore.clamp(dynamicFloor, 99.0).toInt();
  }
}

class PlayerStyleAnalyzer {
  static final Map<String, List<Map<String, dynamic>>> onlineGamesCache = {};
  static final Set<String> _fetchingUsers = {};

  static Future<List<Map<String, dynamic>>> fetchOnlineGamesForUser(
      String username) async {
    List<Map<String, dynamic>> list = [];
    String u = username.trim();
    if (u.isEmpty || u.toLowerCase() == 'misafir' || u.toLowerCase() == 'guest')
      return list;
    if (onlineGamesCache.containsKey(u.toLowerCase()) &&
        onlineGamesCache[u.toLowerCase()]!.isNotEmpty) {
      return onlineGamesCache[u.toLowerCase()]!;
    }
    if (_fetchingUsers.contains(u.toLowerCase())) return list;
    _fetchingUsers.add(u.toLowerCase());
    try {
      String urlStr = 'https://lichess.org/api/games/user/$u?max=30';
      var res = await http.get(Uri.parse(urlStr), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/x-ndjson'
      }).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        for (var line in res.body.trim().split('\n')) {
          if (line.isNotEmpty) {
            var m = jsonDecode(line);
            String wName =
                m['players']?['white']?['user']?['name'] ?? 'Bilinmiyor';
            String bName =
                m['players']?['black']?['user']?['name'] ?? 'Bilinmiyor';
            list.add({
              'white': wName,
              'black': bName,
              'whiteName': wName,
              'blackName': bName,
              'winner': m['winner'] ?? 'draw',
              'pgn': '',
              'moves': m['moves'] ?? '',
              'whiteAccuracy': 0.0,
              'blackAccuracy': 0.0,
              'whiteRating': m['players']?['white']?['rating'] ?? 0,
              'blackRating': m['players']?['black']?['rating'] ?? 0,
            });
          }
        }
      }
    } catch (_) {}

    if (list.isEmpty) {
      try {
        var res = await http.get(
            Uri.parse('https://api.chess.com/pub/player/$u/games/archives'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/json'
            }).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          List<dynamic> archives = jsonDecode(res.body)['archives'] ?? [];
          for (String url in archives.reversed) {
            if (list.length >= 30) break;
            var gRes = await http.get(Uri.parse(url), headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/json'
            }).timeout(const Duration(seconds: 4));
            if (gRes.statusCode == 200) {
              List<dynamic> games = jsonDecode(gRes.body)['games'] ?? [];
              for (var g in games.reversed) {
                if (list.length >= 30) break;
                String wName = g['white']['username'];
                String bName = g['black']['username'];
                list.add({
                  'white': wName,
                  'black': bName,
                  'whiteName': wName,
                  'blackName': bName,
                  'winner': (g['white']['result'] == 'win')
                      ? 'white'
                      : ((g['black']['result'] == 'win') ? 'black' : 'draw'),
                  'pgn': g['pgn'] ?? '',
                  'moves': '',
                  'whiteAccuracy': g['accuracies']?['white'] ?? 0.0,
                  'blackAccuracy': g['accuracies']?['black'] ?? 0.0,
                  'whiteRating': g['white']['rating'] ?? 0,
                  'blackRating': g['black']['rating'] ?? 0,
                });
              }
            }
          }
        }
      } catch (_) {}
    }
    _fetchingUsers.remove(u.toLowerCase());
    if (list.isNotEmpty) {
      onlineGamesCache[u.toLowerCase()] = list;
    }
    return list;
  }

  static PlayerStyleProfile analyze(
      String username, List<dynamic> games, int rating) {
    List<dynamic> userGames = [];
    String u = username.trim().toLowerCase();
    for (var g in games) {
      String w =
          (g['white'] ?? g['whiteName'] ?? '').toString().trim().toLowerCase();
      String b =
          (g['black'] ?? g['blackName'] ?? '').toString().trim().toLowerCase();
      if (w == u || b == u) {
        userGames.add(g);
      }
    }
    if (userGames.isEmpty) {
      return PlayerStyleProfile(
          aggressive: 50,
          defensive: 50,
          tactical: 50,
          positional: 50,
          opening: 50,
          risk: 50,
          mainStyle: "Dengeli",
          mainIcon: "⚖️",
          subStyles: []);
    }

    int shortWins = 0, longGames = 0, gambits = 0, positionalOpenings = 0;
    double totalAccuracy = 0;
    int gamesWithAcc = 0;
    int totalChecks = 0, totalCaptures = 0, totalMoves = 0, wins = 0;

    for (var g in userGames) {
      bool isWhite =
          (g['white'] ?? g['whiteName'] ?? '').toString().toLowerCase() ==
              username.toLowerCase();
      bool isWin = g['winner'] == (isWhite ? 'white' : 'black');
      if (isWin) wins++;

      String pgn = g['pgn']?.toString().toLowerCase() ?? '';
      String moves = g['moves']?.toString().toLowerCase() ?? '';
      String fullText = '$pgn $moves';

      if (fullText.contains('gambit') ||
          fullText.contains('sicilian') ||
          fullText.contains('dutch') ||
          fullText.contains('vienna') ||
          fullText.contains('benoni') ||
          fullText.contains('evans') ||
          fullText.contains('morra')) gambits++;
      if (fullText.contains('caro-kann') ||
          fullText.contains('slav') ||
          fullText.contains('petroff') ||
          fullText.contains('london') ||
          fullText.contains('french') ||
          fullText.contains('berlin') ||
          fullText.contains('philidor')) {}
      if (fullText.contains('queen\'s gambit') ||
          fullText.contains('english') ||
          fullText.contains('catalan') ||
          fullText.contains('reti') ||
          fullText.contains('nimzo') ||
          fullText.contains('bogo') ||
          fullText.contains('pianissimo')) positionalOpenings++;

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

      double acc = isWhite
          ? (g['whiteAccuracy']?.toDouble() ?? 0.0)
          : (g['blackAccuracy']?.toDouble() ?? 0.0);
      if (acc > 0) {
        totalAccuracy += acc;
        gamesWithAcc++;
      } else {
        double guessedAcc = 75.0 + (min(20, (50 - moveCount).abs()) * 0.4);
        totalAccuracy +=
            isWin ? min(99.0, guessedAcc + 5.0) : max(40.0, guessedAcc - 10.0);
        gamesWithAcc++;
      }
    }

    int gc = userGames.length;
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

    double aggScore = (fAction * StyleConfig.aggActionWeight) +
        (fSpeed * StyleConfig.aggSpeedWeight) +
        (fShortWin * StyleConfig.aggShortWinWeight) +
        (fGambit * StyleConfig.aggGambitWeight);
    double defScore = (fEndgame * StyleConfig.defEndgameWeight) +
        ((1.0 - fAction) * StyleConfig.defPassiveWeight) +
        (fAcc * StyleConfig.defAccWeight);
    double tacScore = (fAction * StyleConfig.tacActionWeight) +
        (fAcc * StyleConfig.tacAccWeight) +
        (fShortWin * StyleConfig.tacShortWinWeight);
    double posScore = (fEndgame * StyleConfig.posEndgameWeight) +
        (fAcc * StyleConfig.posAccWeight) +
        ((1.0 - fAction) * StyleConfig.posPassiveWeight);
    double rskScore = (fChaos * StyleConfig.rskChaosWeight) +
        (fGambit * StyleConfig.rskGambitWeight) +
        (fShortWin * StyleConfig.rskShortWinWeight);

    double fPosOpening = positionalOpenings / gc;
    double opnScore = fAcc > 0.75
        ? ((fAcc * 0.5) + (fWin * 0.3) + (fPosOpening * 0.2))
        : (fAcc * 0.4);

    return _determineStyles(PlayerStyleProfile(
        aggressive: StyleNormalizer.scale(aggScore, 0.20, 0.75, 25, 99, rating),
        defensive: StyleNormalizer.scale(defScore, 0.30, 0.85, 20, 99, rating),
        tactical: StyleNormalizer.scale(tacScore, 0.30, 0.80, 30, 99, rating),
        positional: StyleNormalizer.scale(posScore, 0.35, 0.85, 30, 99, rating),
        opening: StyleNormalizer.scale(opnScore, 0.40, 0.90, 15, 99, rating),
        risk: StyleNormalizer.scale(rskScore, 0.10, 0.65, 15, 99, rating),
        mainStyle: '',
        mainIcon: '',
        subStyles: []));
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

    var sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String main = sorted[0].key;
    String icon = main.split(' ')[0];
    String styleName = main.substring(main.indexOf(' ') + 1);
    List<String> subs = [sorted[1].key, sorted[2].key];

    return PlayerStyleProfile(
        aggressive: p.aggressive,
        defensive: p.defensive,
        tactical: p.tactical,
        positional: p.positional,
        opening: p.opening,
        risk: p.risk,
        mainStyle: styleName,
        mainIcon: icon,
        subStyles: subs);
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
  IAPService().initialize(); // Initialize In-App Purchases
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Kullanıcı giriş yapmışsa son görülme tarihini güncelle
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'last_seen': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      print("Last seen update error: $e");
    }
  }

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
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ],
          debugShowCheckedModeBanner: false,
          title: 'MoveLab',
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
                brightness: Brightness.dark,
                seedColor: const Color(0xFF1A237E),
                primary: const Color(0xFF5C6BC0)),
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

    // Eğer belge varsa ve patron değeri true ise ELİTE etiketi verilir
    if (doc.exists) {
      var data = doc.data();
      if (data != null &&
          (data['patron'] == true || data['patron'] == 'true')) {
        return true;
      }
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

  const PuzzleDifficulty(
      this.minRating, this.maxRating, this.points, this.labelKey);
}

Future<String?> showGlobalUsernamePicker(BuildContext context) {
  TextEditingController controller = TextEditingController();
  bool isChecking = false;
  String? errorText;

  return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateLocal) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151B2B),
            title: Text(LanguageService.get('choose_username_title'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LanguageService.get('choose_username_desc'),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: LanguageService.get('username_hint'),
                    hintStyle: const TextStyle(color: Colors.white38),
                    errorText: errorText,
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isChecking
                    ? null
                    : () {
                        Navigator.pop(context, null);
                      },
                child: Text(LanguageService.get('cancel'),
                    style: const TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: isChecking
                    ? null
                    : () async {
                        String name = controller.text.trim();
                        if (name.isEmpty) return;
                        setStateLocal(() {
                          isChecking = true;
                          errorText = null;
                        });
                        try {
                          bool isTaken = false;
                          var doc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(name.toLowerCase())
                              .get();
                          if (doc.exists) isTaken = true;

                          if (!isTaken) {
                            final lichessRes = await http.get(Uri.parse(
                                'https://lichess.org/api/user/$name'));
                            if (lichessRes.statusCode == 200) isTaken = true;
                          }

                          if (!isTaken) {
                            final chesscomRes = await http.get(Uri.parse(
                                'https://api.chess.com/pub/player/$name'));
                            if (chesscomRes.statusCode == 200) isTaken = true;
                          }

                          if (isTaken) {
                            setStateLocal(() {
                              isChecking = false;
                              errorText =
                                  LanguageService.get('username_taken_error');
                            });
                          } else {
                            if (context.mounted) Navigator.pop(context, name);
                          }
                        } catch (e) {
                          setStateLocal(() {
                            isChecking = false;
                            errorText = LanguageService.get('connection_error');
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                child: isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(LanguageService.get('confirm'),
                        style: const TextStyle(color: Colors.white)),
              )
            ],
          );
        });
      });
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
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151B2B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(LanguageService.get('login_title'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LanguageService.get('login_lichess_desc'),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B313F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: isLichessLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Image.asset('assets/lichess_logo.png',
                            width: 26, height: 26, color: Colors.grey[400]),
                    label: Text(LanguageService.get('login_lichess_btn'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: isLichessLoading
                        ? null
                        : () async {
                            setStateDialog(() => isLichessLoading = true);
                            try {
                              // Lichess OAuth PKCE
                              final random = Random.secure();
                              final verifierValues = List<int>.generate(
                                  32, (i) => random.nextInt(256));
                              final codeVerifier =
                                  base64UrlEncode(verifierValues)
                                      .replaceAll('=', '');

                              final verifierBytes = utf8.encode(codeVerifier);
                              final challengeDigest =
                                  sha256.convert(verifierBytes);
                              final codeChallenge =
                                  base64UrlEncode(challengeDigest.bytes)
                                      .replaceAll('=', '');

                              const clientId = 'chess_analyzer_app';
                              const redirectUri =
                                  'com.chessanalyzer.app://callback';

                              final authUrl =
                                  Uri.https('lichess.org', '/oauth', {
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

                              final code =
                                  Uri.parse(result).queryParameters['code'];
                              if (code != null) {
                                final tokenRes = await http.post(
                                  Uri.parse('https://lichess.org/api/token'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'grant_type': 'authorization_code',
                                    'code': code,
                                    'code_verifier': codeVerifier,
                                    'redirect_uri': redirectUri,
                                    'client_id': clientId,
                                  }),
                                );

                                if (tokenRes.statusCode == 200) {
                                  final tokenData = jsonDecode(tokenRes.body);
                                  final accessToken = tokenData['access_token'];

                                  final profileRes = await http.get(
                                    Uri.parse(
                                        'https://lichess.org/api/account'),
                                    headers: {
                                      'Authorization': 'Bearer $accessToken'
                                    },
                                  );

                                  if (profileRes.statusCode == 200) {
                                    final profileData =
                                        jsonDecode(profileRes.body);
                                    String? lTitle = profileData['title'];
                                    String lichessName =
                                        profileData['username'].toString();

                                    var userDoc = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(lichessName.toLowerCase())
                                        .get();
                                    String patronStr = 'false';
                                    if (!userDoc.exists) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(lichessName.toLowerCase())
                                          .set({
                                        'username': lichessName,
                                        'score': 0,
                                        'patron': false,
                                        'title': lTitle,
                                      });
                                    } else {
                                      var pData = userDoc.data()?['patron'];
                                      if (pData is bool) {
                                        patronStr = pData ? 'true' : 'false';
                                      } else if (pData is String)
                                        patronStr = pData;

                                      if (userDoc.data()?['patron'] == null) {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(lichessName.toLowerCase())
                                            .set({
                                          'patron': false,
                                          'username': lichessName
                                        }, SetOptions(merge: true));
                                        patronStr = 'false';
                                      }
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context, <String, String?>{
                                        'username': lichessName,
                                        'title': lTitle,
                                        'patron': patronStr
                                      });
                                    }
                                    return;
                                  }
                                }
                              }
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        '${LanguageService.get('login_failed')} (Bilinmeyen Hata)')));
                            } catch (e) {
                              debugPrint("Lichess Auth Error: $e");
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Hata: ${e.toString()}'),
                                        duration: const Duration(seconds: 4)));
                            }
                            if (context.mounted)
                              setStateDialog(() => isLichessLoading = false);
                          },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Colors.white24),
                ),
                // GOOGLE GİRİŞİ
                Text(LanguageService.get('login_google_desc'),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B313F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: isGoogleLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Image.asset('assets/google_logo.png',
                            width: 19, height: 19, color: Colors.grey[400]),
                    label: Text(LanguageService.get('login_google_btn'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: isGoogleLoading
                        ? null
                        : () async {
                            setStateDialog(() => isGoogleLoading = true);
                            try {
                              final GoogleSignInAccount? googleUser =
                                  await GoogleSignIn().signIn();
                              if (googleUser == null) {
                                setStateDialog(() => isGoogleLoading = false);
                                return;
                              }

                              final GoogleSignInAuthentication googleAuth =
                                  await googleUser.authentication;
                              final AuthCredential credential =
                                  GoogleAuthProvider.credential(
                                accessToken: googleAuth.accessToken,
                                idToken: googleAuth.idToken,
                              );

                              final UserCredential userCredential =
                                  await FirebaseAuth.instance
                                      .signInWithCredential(credential);
                              final User? user = userCredential.user;

                              if (user != null) {
                                // Eymen'in hesabını otomatik olarak Termo_x yap
                                if (user.email == 'eymencanorman09@gmail.com') {
                                  await FirebaseFirestore.instance
                                      .collection('users_by_uid')
                                      .doc(user.uid)
                                      .set({'username': 'Termo_x'});
                                  var userDoc = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('termo_x')
                                      .get();
                                  if (!userDoc.exists) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc('termo_x')
                                        .set({
                                      'username': 'Termo_x',
                                      'score': 0,
                                      'patron': false,
                                      'title': 'TermoGM',
                                    });
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context, <String, String?>{
                                      'username': 'Termo_x',
                                      'title': 'TermoGM',
                                      'patron': 'false'
                                    });
                                  }
                                  return;
                                }

                                var uidDoc = await FirebaseFirestore.instance
                                    .collection('users_by_uid')
                                    .doc(user.uid)
                                    .get();
                                if (uidDoc.exists) {
                                  String savedUsername =
                                      uidDoc.data()!['username'];
                                  String? title;
                                  String patronStr = 'false';

                                  var userDoc = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(savedUsername.toLowerCase())
                                      .get();
                                  if (userDoc.exists) {
                                    title = userDoc.data()?['title'];
                                    var pData = userDoc.data()?['patron'];
                                    if (pData is bool) {
                                      patronStr = pData ? 'true' : 'false';
                                    } else if (pData is String)
                                      patronStr = pData;
                                  }

                                  if (savedUsername.toLowerCase() == 'termo_x')
                                    title = 'TermoGM';

                                  if (context.mounted) {
                                    Navigator.pop(context, <String, String?>{
                                      'username': savedUsername,
                                      'title': title,
                                      'patron': patronStr
                                    });
                                  }
                                  return;
                                } else {
                                  if (context.mounted) {
                                    String? chosenName =
                                        await showGlobalUsernamePicker(context);
                                    if (chosenName != null &&
                                        chosenName.trim().isNotEmpty) {
                                      await FirebaseFirestore.instance
                                          .collection('users_by_uid')
                                          .doc(user.uid)
                                          .set({'username': chosenName.trim()});

                                      // Kayıt olan kişinin ismini hemen 'users' koleksiyonuna da yaz ki misafirler bu ismi alamasın!
                                      var userDoc = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(chosenName.trim().toLowerCase())
                                          .get();
                                      if (!userDoc.exists) {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(
                                                chosenName.trim().toLowerCase())
                                            .set({
                                          'username': chosenName.trim(),
                                          'score': 0,
                                          'patron': false,
                                          'title': null,
                                        });
                                      }

                                      if (context.mounted) {
                                        Navigator.pop(
                                            context, <String, String?>{
                                          'username': chosenName.trim(),
                                          'title': null,
                                          'patron': 'false'
                                        });
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
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Google girişi başarısız: $e'),
                                        backgroundColor: Colors.redAccent));
                            }
                            if (context.mounted)
                              setStateDialog(() => isGoogleLoading = false);
                          },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Colors.white24),
                ),
                Text(LanguageService.get('login_guest_desc'),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: guestController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: LanguageService.get('login_guest_hint'),
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    errorText: guestErrorText,
                    filled: true,
                    fillColor: const Color(0xFF1E2638),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF4F46E5), width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.redAccent, width: 1.5)),
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
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: isGuestLoading
                        ? null
                        : () async {
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
                                  var doc = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(guestName.toLowerCase())
                                      .get();
                                  if (doc.exists) isTaken = true;

                                  // 2. Lichess Kontrolü
                                  if (!isTaken) {
                                    final lichessRes = await http.get(Uri.parse(
                                        'https://lichess.org/api/user/$guestName'));
                                    if (lichessRes.statusCode == 200)
                                      isTaken = true;
                                  }

                                  // 3. Chess.com Kontrolü
                                  if (!isTaken) {
                                    final chesscomRes = await http.get(Uri.parse(
                                        'https://api.chess.com/pub/player/$guestName'));
                                    if (chesscomRes.statusCode == 200)
                                      isTaken = true;
                                  }

                                  if (isTaken) {
                                    setStateDialog(() {
                                      guestErrorText = LanguageService.get(
                                          'login_guest_taken');
                                      isGuestLoading = false;
                                    });
                                    return;
                                  }
                                } catch (e) {
                                  setStateDialog(() {
                                    guestErrorText = LanguageService.get(
                                        'login_guest_conn_err');
                                    isGuestLoading = false;
                                  });
                                  return;
                                }
                              }

                              // Misafir olarak Termo_x girilirse yine Easter Egg çalışsın
                              if (guestName.toLowerCase() == 'termo_x') {
                                if (context.mounted)
                                  Navigator.pop(context, <String, String?>{
                                    'username': guestName,
                                    'title': 'TermoGM',
                                    'patron': 'false'
                                  });
                              } else {
                                // Veritabanına kaydet (Eğer yoksa)
                                var userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(guestName.toLowerCase())
                                    .get();
                                if (!userDoc.exists) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(guestName.toLowerCase())
                                      .set({
                                    'username': guestName,
                                    'score': 0,
                                    'patron': false,
                                  });
                                }
                                if (context.mounted)
                                  Navigator.pop(context, <String, String?>{
                                    'username': guestName,
                                    'title': null,
                                    'patron': 'false'
                                  });
                              }
                              if (context.mounted)
                                setStateDialog(() => isGuestLoading = false);
                            }
                          },
                    child: isGuestLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(LanguageService.get('login_guest_btn'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
          ),
        );
      });
    },
  );
}

class PuzzlesPage extends StatefulWidget {
  const PuzzlesPage({super.key});

  static void preloadPuzzles([PuzzleDifficulty diff = PuzzleDifficulty.hard]) {
    _PuzzlesPageState._fetchAndCachePuzzlesInBackground(diff);
  }

  @override
  State<PuzzlesPage> createState() => _PuzzlesPageState();
}

class _PuzzlesPageState extends State<PuzzlesPage> {
  static final Map<PuzzleDifficulty, List<dynamic>> _cachedApiPuzzles = {
    for (var d in PuzzleDifficulty.values) d: [],
  };
  static bool _isFetchingBackground = false;

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
  bool _hasFailedCurrentPuzzle =
      false; // Bulmacada hata yapılıp yapılmadığını izler
  PuzzleDifficulty currentDifficulty = PuzzleDifficulty.hard;
  String? _userTitle;
  bool _isPatron = false;
  bool _isOpponentMoving = false;
  List<String> _playedFens = [];
  int _viewIndex = 0;

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
        .listen((doc) async {
      if (doc.exists && mounted) {
        var data = doc.data();
        bool patronCloud =
            (data?['patron'] == true || data?['patron'] == 'true');
        String titleCloud = (data?['title'] ?? '').toString();

        final prefs = await SharedPreferences.getInstance();
        if (patronCloud) {
          await prefs.setBool('puzzle_user_patron', true);
        } else {
          await prefs.remove('puzzle_user_patron');
        }
        if (titleCloud.isNotEmpty) {
          await prefs.setString('puzzle_user_title', titleCloud);
        } else {
          await prefs.remove('puzzle_user_title');
        }

        if (mounted) {
          setState(() {
            _currentScore = data?['score'] ?? 0;
            _isPatron = patronCloud;
            if (titleCloud.isNotEmpty) {
              _userTitle = titleCloud;
            } else {
              _userTitle = null;
            }
            if (username.toLowerCase() == 'termo_x') {
              _userTitle = 'TermoGM';
              _isPatron = true;
            }
          });
        }
      }
    });
  }

  // 2. ZORLUK SEVİYESİNE GÖRE AYRILMIŞ YEREL BULMACA HAVUZU
  final List<Map<String, dynamic>> localPuzzlePool = [
    // --- EASY ---
    {
      "id": "arka_yatay_basit",
      "difficulty": "easy",
      "fen": "6k1/1p3ppp/8/8/8/8/1q3PPP/2R3K1 w - - 0 1",
      "solution": ["c1c8"] // Beyaz tek hamlede arka yataydan mat eder
    },
    {
      "id": "aptal_mati",
      "difficulty": "easy",
      "fen": "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2",
      "solution": ["d8h4"] // Aptal Matı
    },
    {
      "id": "coban_mati",
      "difficulty": "easy",
      "fen":
          "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 1",
      "solution": ["f3f7"] // Çoban Matı
    },
    {
      "id": "hizli_mat_siyah",
      "difficulty": "easy",
      "fen": "r1b1k2r/pppp1ppp/8/4P3/1nB1n2q/8/PPPP1PPP/RNBQK2R b KQkq - 1 8",
      "solution": ["h4f2"] // Siyah atın korumasıyla f2'den tek hamlede mat eder
    },
    {
      "id": "katal_taktigi_siyah",
      "difficulty": "easy",
      "fen": "6k1/5p1p/8/8/8/2n5/4QPPP/5RK1 b - - 0 1",
      "solution": ["c3e2"] // Siyah at ile şah çekerek veziri kazanır
    },
    {
      "id": "apolet_mati",
      "difficulty": "easy",
      "fen": "k7/p1R3p1/8/8/8/8/8/1Q5K w - - 0 1",
      "solution": ["b1b7"] // Apolet Matı
    },
    {
      "id": "merdiven_mati_basit",
      "difficulty": "easy",
      "fen": "k7/8/1K6/8/8/8/8/1R6 w - - 0 1",
      "solution": ["b1a1"] // Kale ve Şah yardımıyla temel mat
    },
    // --- MEDIUM ---
    {
      "id": "vezir_fedasi_arka_yatay",
      "difficulty": "medium",
      "fen": "1r4k1/p4ppp/8/3Q4/8/8/PPP2PPP/3R2K1 w - - 0 1",
      "solution": [
        "d5d8",
        "b8d8",
        "d1d8"
      ] // Vezir fedası ile zorunlu arka yatay matı
    },
    {
      "id": "vezir_saptirma_mati",
      "difficulty": "medium",
      "fen": "2r3k1/p4ppp/8/8/4Q3/8/1q3PPP/4R1K1 w - - 0 1",
      "solution": [
        "e4e8",
        "c8e8",
        "e1e8"
      ] // Kaleyi saptırmak için vezir fedası ve mat
    },
    // --- HARD & ELITE ---
    {
      "id": "opera_mati_hard",
      "difficulty": "hard",
      "fen": "4kb1r/p2n1ppp/4q3/4p1B1/4P3/1Q6/PPP2PPP/2KR4 w k - 1 16",
      "solution": [
        "b3b8",
        "d7b8",
        "d1d8"
      ] // Paul Morphy Opera Matı: Vezir fedası ve kale matı
    },
    {
      "id": "anastasia_mati",
      "difficulty": "hard",
      "fen": "r4r1k/pp2Nppp/8/7Q/8/R7/PPP2PP1/6K1 w - - 0 1",
      "solution": [
        "h5h7",
        "h8h7",
        "a3h3"
      ] // Klasik Anastasia Matı: Zorunlu vezir fedası ve kale matı
    },
    {
      "id": "smothered_short_hard",
      "difficulty": "hard",
      "fen": "r4r1k/6pp/7N/8/8/1Q6/6PP/6K1 w - - 0 1",
      "solution": [
        "b3g8",
        "f8g8",
        "h6f7"
      ] // Boğmaca Matı (Vezir fedalı)
    },
    {
      "id": "bogmaca_mati_elite",
      "difficulty": "elite",
      "fen": "r4rk1/5Npp/8/8/8/1Q6/6PP/6K1 w - - 0 1",
      "solution": [
        "f7h6",
        "g8h8",
        "b3g8",
        "f8g8",
        "h6f7"
      ] // 3 hamlelik klasik Philidor Boğmaca Matı (Çifte şah + Vezir fedası)
    },
  ];

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    _checkUsernameAndLoad();
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
    bool isPlayerTurn =
        (_boardOrientation == PlayerColor.white && isWhiteToMove) ||
            (_boardOrientation == PlayerColor.black && !isWhiteToMove);
    if (!isPlayerTurn || isSolved || isLoading)
      return; // Sıra bizde değilse işlem yapma

    final piece = controller.game.get(square);

    if (selectedSquare == null) {
      // Kendi taşımıza tıkladıysak onu seç ve hedefleri göster
      if (piece != null &&
          piece.color ==
              (isWhiteToMove
                  ? chess_engine.Color.WHITE
                  : chess_engine.Color.BLACK)) {
        setState(() {
          selectedSquare = square;
          final moves =
              controller.game.moves({"square": square, "verbose": true});
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
      } else if (piece != null &&
          piece.color ==
              (isWhiteToMove
                  ? chess_engine.Color.WHITE
                  : chess_engine.Color.BLACK)) {
        // Başka bir kendi taşımıza tıklandı, seçimi ona geçir
        setState(() {
          selectedSquare = square;
          final moves =
              controller.game.moves({"square": square, "verbose": true});
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
    if (savedDifficultyIndex != null &&
        savedDifficultyIndex >= 0 &&
        savedDifficultyIndex < PuzzleDifficulty.values.length) {
      currentDifficulty = PuzzleDifficulty.values[savedDifficultyIndex];
    }

    if (savedName == null || savedName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Map<String, String?>? inputData = await showGlobalLoginDialog(context);
        if (inputData != null &&
            inputData['username'] != null &&
            inputData['username']!.trim().isNotEmpty) {
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
          if (mounted) Navigator.pop(context);
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

  static final Set<String> _seenPuzzleIds = {};

  static PuzzleDifficulty _difficultyForRating(int rating) {
    if (rating < 1250) return PuzzleDifficulty.easy;
    if (rating < 1750) return PuzzleDifficulty.medium;
    if (rating < 2150) return PuzzleDifficulty.hard;
    return PuzzleDifficulty.elite;
  }

  /// HuggingFace üzerindeki resmi Lichess 4M+ bulmaca veri setinden
  /// tek istekte 100 gerçek, Stockfish onaylı bulmaca çeker ve
  /// ELO derecesine göre tüm zorluk havuzlarına dağıtır.
  static Future<bool> _fetchLichessDatasetBatch() async {
    final offset = Random().nextInt(3800000);
    final url =
        'https://datasets-server.huggingface.co/rows?dataset=Lichess/chess-puzzles&config=default&split=train&offset=$offset&length=100';

    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'MoveLabChessApp/1.0',
      },
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) return false;

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> rows = (data['rows'] as List<dynamic>?) ?? [];
    if (rows.isEmpty) return false;

    int addedCount = 0;
    for (final item in rows) {
      final row = (item as Map<String, dynamic>)['row'] as Map<String, dynamic>?;
      if (row == null) continue;

      final String id = (row['PuzzleId'] ?? '').toString();
      final String fen = (row['FEN'] ?? '').toString();
      final String movesStr = (row['Moves'] ?? '').toString().trim();
      final int? rating = row['Rating'] is int
          ? row['Rating'] as int
          : int.tryParse((row['Rating'] ?? '').toString());

      if (id.isEmpty ||
          fen.isEmpty ||
          movesStr.isEmpty ||
          rating == null ||
          _seenPuzzleIds.contains(id)) {
        continue;
      }

      final moveTokens =
          movesStr.split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
      if (moveTokens.length < 2) continue;

      final diff = _difficultyForRating(rating);
      final rawThemes = row['Themes'];
      final String themesStr = rawThemes is List
          ? rawThemes.map((e) => e.toString()).join(' ')
          : (rawThemes ?? '').toString();

      final bucket = _cachedApiPuzzles[diff]!;
      if (bucket.length < 60 &&
          !bucket.any((p) => p['PuzzleId']?.toString() == id)) {
        bucket.add({
          'PuzzleId': id,
          'Rating': rating,
          'Themes': themesStr,
          'FEN': fen,
          'Moves': movesStr,
        });
        addedCount++;
      }
    }

    for (final bucket in _cachedApiPuzzles.values) {
      bucket.shuffle();
    }

    return addedCount > 0;
  }

  static Future<void> _fetchAndCachePuzzlesInBackground(
      PuzzleDifficulty diff) async {
    if (_isFetchingBackground) return;
    _isFetchingBackground = true;
    try {
      await _fetchLichessDatasetBatch();
    } catch (_) {
      // Arka plan indirme hatası sessizce yoksayılır
    } finally {
      _isFetchingBackground = false;
    }
  }

  void _setupApiPuzzle(dynamic puzzle) {
    puzzleId = puzzle['PuzzleId'].toString();
    _seenPuzzleIds.add(puzzleId);
    puzzleRating = puzzle['Rating'] as int?;
    puzzleThemes = puzzle['Themes']?.toString();

    final String apiFen = puzzle['FEN'].toString();
    final List<String> apiMoves = (puzzle['Moves']?.toString() ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((m) => m.isNotEmpty)
        .toList();

    if (apiMoves.length < 2) {
      _loadRandomPuzzle();
      return;
    }

    final String opponentFirstMove = apiMoves.removeAt(0); // Rakibin hatalı hamlesi
    _validationChess.reset();
    _validationChess.load(apiFen);

    final String from = opponentFirstMove.substring(0, 2);
    final String to = opponentFirstMove.substring(2, 4);
    final bool isCapture = _validationChess.get(to) != null;

    final Map<String, dynamic> moveObj = {'from': from, 'to': to};
    if (opponentFirstMove.length > 4) {
      moveObj['promotion'] = opponentFirstMove.substring(4, 5);
    }
    _validationChess.move(moveObj);
    final String afterOpponentFen = _validationChess.fen;

    solutionMoves = apiMoves;
    currentMoveIndex = 0;

    final bool isWhiteTurn = _validationChess.turn == chess_engine.Color.WHITE;

    setState(() {
      isWhiteToMove = isWhiteTurn;
      _boardOrientation = isWhiteTurn ? PlayerColor.white : PlayerColor.black;
      _isOpponentMoving = true;
      _playedFens = [apiFen];
      _viewIndex = 0;
      controller.loadFen(apiFen);
      isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      if (opponentFirstMove.length > 4) {
        controller.makeMoveWithPromotion(
          from: from,
          to: to,
          pieceToPromoteTo: opponentFirstMove.substring(4, 5),
        );
      } else {
        controller.makeMove(from: from, to: to);
      }
      _playedFens.add(afterOpponentFen);
      _viewIndex = 1;
      SoundService.playMoveSound(isCapture);
      setState(() {
        _isOpponentMoving = false;
      });
    });
  }

  // 2. 4M+ Resmi Lichess Bulmaca Havuzundan zorluk seviyesine uygun sınırsız bulmaca çekme
  Future<void> _loadRandomPuzzle() async {
    setState(() => isLoading = true);

    // 1. Önce hafıza önbelleğine bak (Anında 0 ms yükleme)
    if (_cachedApiPuzzles[currentDifficulty] != null &&
        _cachedApiPuzzles[currentDifficulty]!.isNotEmpty) {
      final puzzle = _cachedApiPuzzles[currentDifficulty]!.removeLast();
      _setupApiPuzzle(puzzle);
      if (_cachedApiPuzzles[currentDifficulty]!.length < 6) {
        _fetchAndCachePuzzlesInBackground(currentDifficulty);
      }
      return;
    }

    // 2. Önbellek boşsa HuggingFace Lichess veri setinden 100'lük paket çek (maks 2 deneme)
    try {
      for (int attempt = 0; attempt < 2; attempt++) {
        await _fetchLichessDatasetBatch();
        if (_cachedApiPuzzles[currentDifficulty] != null &&
            _cachedApiPuzzles[currentDifficulty]!.isNotEmpty) {
          final puzzle = _cachedApiPuzzles[currentDifficulty]!.removeLast();
          _setupApiPuzzle(puzzle);
          if (_cachedApiPuzzles[currentDifficulty]!.length < 6) {
            _fetchAndCachePuzzlesInBackground(currentDifficulty);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Lichess Veri Seti Hatası (Çevrimdışı Havuza Düşülüyor): $e");
      _fetchAndCachePuzzlesInBackground(currentDifficulty);
    }

    // 3. API başarısız veya timeout olursa seçili zorluğa uygun yerel havuza düş (Fallback)
    try {
      puzzleRating = null;
      puzzleThemes = null;
      final random = Random();

      List<Map<String, dynamic>> filteredPool;
      switch (currentDifficulty) {
        case PuzzleDifficulty.easy:
          filteredPool = localPuzzlePool
              .where((p) => p['difficulty'] == 'easy')
              .toList();
          break;
        case PuzzleDifficulty.medium:
          filteredPool = localPuzzlePool
              .where((p) =>
                  p['difficulty'] == 'medium' || p['difficulty'] == 'hard')
              .toList();
          break;
        case PuzzleDifficulty.hard:
          filteredPool = localPuzzlePool
              .where((p) =>
                  p['difficulty'] == 'hard' || p['difficulty'] == 'elite')
              .toList();
          break;
        case PuzzleDifficulty.elite:
          filteredPool = localPuzzlePool
              .where((p) =>
                  p['difficulty'] == 'elite' || p['difficulty'] == 'hard')
              .toList();
          break;
      }
      if (filteredPool.isEmpty) filteredPool = localPuzzlePool;

      int randomIndex;
      // AYNI BULMACANIN ÜST ÜSTE 2 KERE GELMESİNİ ENGELLEYEN DÖNGÜ
      do {
        randomIndex = random.nextInt(filteredPool.length);
      } while (randomIndex == _lastPuzzleIndex && filteredPool.length > 1);

      _lastPuzzleIndex = randomIndex;
      final selectedPuzzle = filteredPool[randomIndex];

      puzzleId =
          "${selectedPuzzle['id']}_${DateTime.now().millisecondsSinceEpoch}";
      solutionMoves = List<String>.from(selectedPuzzle['solution']);
      currentMoveIndex = 0;

      _validationChess.reset();
      _validationChess.load(selectedPuzzle['fen']);

      bool isWhiteTurn = _validationChess.turn == chess_engine.Color.WHITE;

      setState(() {
        isWhiteToMove = isWhiteTurn;
        _boardOrientation = isWhiteTurn ? PlayerColor.white : PlayerColor.black;
        _isOpponentMoving = false;
        _playedFens = [_validationChess.fen];
        _viewIndex = 0;
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

    chess_engine.Chess userValidation = chess_engine.Chess();
    userValidation.load(controller.getFen());
    bool isUserMate = userValidation.in_checkmate;

    if (userFen == expectedFen || isUserMate) {
      // DOĞRU HAMLE!
      SoundService.playMoveSound(false);

      if (isUserMate) {
        _validationChess.load(controller.getFen());
      } else {
        _validationChess.load(tempValidation.fen);
      }

      _playedFens.add(_validationChess.fen);
      _viewIndex = _playedFens.length - 1;
      currentMoveIndex++;

      if (currentMoveIndex >= solutionMoves.length || isUserMate) {
        setState(() => isSolved = true);
        await _rewardUser();
        _showSuccessDialog();
      } else {
        Future.delayed(const Duration(milliseconds: 600), () async {
          if (!mounted) return;
          _makeEngineMove(solutionMoves[currentMoveIndex]);
          controller.loadFen(_validationChess.fen);
          _playedFens.add(_validationChess.fen);
          _viewIndex = _playedFens.length - 1;
          currentMoveIndex++;
          SoundService.playMoveSound(false);
          if (currentMoveIndex >= solutionMoves.length) {
            setState(() => isSolved = true);
            await _rewardUser();
            if (mounted) _showSuccessDialog();
          } else {
            setState(() {});
          }
        });
      }
    } else {
      // YANLIŞ HAMLE
      SoundService.playMoveSound(true);
      controller.loadFen(_validationChess.fen);

      if (!_hasFailedCurrentPuzzle) {
        _penalizeUser().then((penalty) {
          if (penalty > 0) {
            _showFloatingText(context, '-$penalty', Colors.redAccent);
          } else {
            _showFloatingText(context, '0', Colors.orangeAccent);
          }
        });
      } else {
        _showFloatingText(context, LanguageService.get('puzzle_wrong_move'),
            Colors.orangeAccent);
      }
    }
  }

  void _showFloatingText(BuildContext context, String text, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final size = MediaQuery.of(context).size;
    final bool isScoreDelta = text.startsWith('-') || text == '0';
    final Color semanticColor =
        isScoreDelta ? const Color(0xFFEF5350) : const Color(0xFFFFB74D);

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: size.height * 0.42,
          left: 24,
          right: 24,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1450),
              curve: Curves.easeOutCubic,
              onEnd: () {
                overlayEntry.remove();
              },
              builder: (context, value, child) {
                final double opacity = value < 0.65
                    ? 1.0
                    : (1.0 - ((value - 0.65) / 0.35)).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, -24 * value),
                  child: Opacity(
                    opacity: opacity,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151B2B).withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: semanticColor.withValues(alpha: 0.45),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isScoreDelta
                                    ? Icons.trending_down_rounded
                                    : Icons.close_rounded,
                                color: semanticColor,
                                size: isScoreDelta ? 20 : 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isScoreDelta ? 22 : 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: isScoreDelta ? 0.6 : 0.2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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

    // İpucu istenen taşı tahta üzerinde de vurgula
    setState(() {
      selectedSquare = from;
      final moves = controller.game.moves({"square": from, "verbose": true});
      legalDestinations = moves.map((m) => m["to"] as String).toList();
    });

    final bool isEn = LanguageService.currentLang == 'en';
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2236), Color(0xFF121827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.65),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amberAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.amberAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'TACTICAL HINT' : 'TAKTİK İPUCU',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEn
                          ? 'Play the highlighted move'
                          : 'Vurgulanan hamleyi oyna',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25304D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      from.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.amberAccent,
                      size: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Text(
                      to.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Puanı Firebase'e Yazma
  Future<void> _rewardUser() async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(username.toLowerCase());
      final doc = await userRef.get();

      List<dynamic> solved =
          doc.exists ? (doc.data()?['solved_puzzles'] ?? []) : [];

      if (!solved.contains(puzzleId)) {
        await userRef.set({
          'username': username,
          if (!_hasFailedCurrentPuzzle)
            'score': FieldValue.increment(currentDifficulty.points),
          'solved_puzzles': FieldValue.arrayUnion([puzzleId]),
          'last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Puan yazma hatası: $e");
    }
  }

  Future<int> _penalizeUser() async {
    if (username.isEmpty || username == 'Misafir') return 0;
    if (_hasFailedCurrentPuzzle)
      return 0; // Zaten hata yaptıysa bu bulmacada 2. kez puan düşme

    setState(() {
      _hasFailedCurrentPuzzle = true;
    });

    int penalty = currentDifficulty.points;
    if (_currentScore - penalty < 0) {
      penalty = _currentScore;
    }

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(username.toLowerCase());

      if (penalty > 0) {
        await userRef.set({
          'username': username,
          'score': FieldValue.increment(-penalty),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Ceza yazma hatası: $e");
    }

    return penalty;
  }

  void _showSuccessDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF101A2B),
              title: Text(LanguageService.get('puzzle_congratulations'),
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              content: Text(
                LanguageService.currentLang == 'en'
                    ? (_hasFailedCurrentPuzzle
                        ? 'Puzzle solved, but no points since you made a mistake.\nWould you like to try another?'
                        : 'You earned +${currentDifficulty.points} points!\nWould you like to solve another puzzle?')
                    : (_hasFailedCurrentPuzzle
                        ? 'Bulmaca çözüldü, ancak hata yaptığın için puan kazanamadın.\nSonraki bulmacaya geçmek ister misin?'
                        : '+${currentDifficulty.points} Puan Kazandın!\nSonraki bulmacaya geçmek ister misin?'),
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (mounted) Navigator.pop(context); // Dialogu kapat
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LeaderboardPage()));
                  },
                  child: Text(LanguageService.get('puzzle_leaderboard'),
                      style: const TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0)),
                  onPressed: () {
                    if (mounted) Navigator.pop(context); // Dialogu kapat
                    _loadNextPuzzle(); // YENİ BULMACAYA GEÇİŞ BAŞLATICI
                  },
                  child: Text(
                      LanguageService.currentLang == 'en'
                          ? 'Next Puzzle'
                          : 'Sonraki Bulmaca',
                      style: const TextStyle(color: Colors.white)),
                )
              ],
            ));
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
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(LanguageService.get('puzzle_diff_select'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                ...PuzzleDifficulty.values.map((diff) {
                  bool isSelected = currentDifficulty == diff;
                  return ListTile(
                    title: Text(
                      '${LanguageService.get(diff.labelKey)} (${diff.points} ${LanguageService.get('puzzle_diff_points')})',
                      style: TextStyle(
                          color:
                              isSelected ? Colors.cyanAccent : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.cyanAccent)
                        : null,
                    onTap: () async {
                      if (mounted) Navigator.pop(context);
                      if (currentDifficulty != diff) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(
                            'puzzle_difficulty_index', diff.index);
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
        });
  }

  @override
  Widget build(BuildContext context) {
    bool isReviewing =
        _playedFens.isNotEmpty && _viewIndex < _playedFens.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get('puzzles'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardPage())),
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C6BC0)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${LanguageService.get('puzzle_player')}: ',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              buildUserTags(_userTitle ?? '', _isPatron),
                              Flexible(
                                  child: Text(username,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: _isPatron
                                              ? Colors.orangeAccent
                                              : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13))),
                            ],
                          ),
                        ),
                        const SizedBox(
                            width: 8), // İki bölüm arasına hafif boşluk

                        // MODERN VE NEON SIRA GÖSTERGESİ (KÜÇÜLTÜLMÜŞ HALİ)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF101A2B), // Karanlık arka plan
                            borderRadius: BorderRadius.circular(
                                10), // Modern oval köşeler
                            border: Border.all(
                              color: isWhiteToMove
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.white12,
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
                                isWhiteToMove
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 14,
                                color: isWhiteToMove
                                    ? Colors.white
                                    : Colors.white38,
                                shadows: isWhiteToMove
                                    ? [
                                        const Shadow(
                                            color: Colors.white, blurRadius: 6)
                                      ]
                                    : [],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isWhiteToMove
                                    ? LanguageService.get('puzzle_turn_white')
                                    : LanguageService.get('puzzle_turn_black'),
                                style: TextStyle(
                                  color: isWhiteToMove
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1.2, // Daha sıkı harf aralığı
                                  shadows: isWhiteToMove
                                      ? [
                                          const Shadow(
                                              color: Colors.white54,
                                              blurRadius: 6)
                                        ]
                                      : [],
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
                          ClipRect(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  // Satranç Tahtası (İçte 12 birim boşluk bırakılarak oturtuldu)
                                  Positioned.fill(
                                    child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      return Listener(
                                        behavior: HitTestBehavior.translucent,
                                        onPointerUp: (event) {
                                          final squareSize =
                                              constraints.maxWidth / 8;
                                          final col = (event.localPosition.dx /
                                                  squareSize)
                                              .floor()
                                              .clamp(0, 7);
                                          final row = (event.localPosition.dy /
                                                  squareSize)
                                              .floor()
                                              .clamp(0, 7);

                                          int rank, file;
                                          if (_boardOrientation ==
                                              PlayerColor.white) {
                                            rank = 7 - row;
                                            file = col;
                                          } else {
                                            rank = row;
                                            file = 7 - col;
                                          }

                                          final fileChar = String.fromCharCode(
                                              'a'.codeUnitAt(0) + file);
                                          final rankChar =
                                              (rank + 1).toString();
                                          final square = '$fileChar$rankChar';

                                          if (!_isOpponentMoving &&
                                              !isReviewing) {
                                            _onSquareTapped(square);
                                          }
                                        },
                                        child: Stack(
                                          children: [
                                            // 1. ASIL SATRANÇ TAHTASI
                                            ChessBoard(
                                              controller: controller,
                                              boardColor:
                                                  BoardThemeService.boardColor,
                                              boardOrientation:
                                                  _boardOrientation,
                                              enableUserMoves: !_isOpponentMoving &&
                                                  !isReviewing, // Sürükle-bırak aktif değilse engelle
                                              onMove: _onMove,
                                            ),
                                            // 2. GÖRSEL KATMAN (Vurgular ve Noktalar)
                                            IgnorePointer(
                                              child: Column(
                                                children:
                                                    List.generate(8, (row) {
                                                  return Expanded(
                                                    child: Row(
                                                      children: List.generate(8,
                                                          (col) {
                                                        final index =
                                                            row * 8 + col;
                                                        final square =
                                                            indexToSquare(
                                                                index,
                                                                _boardOrientation ==
                                                                    PlayerColor
                                                                        .white);
                                                        final isSelected =
                                                            square ==
                                                                selectedSquare;
                                                        final isLegalMove =
                                                            legalDestinations
                                                                .contains(
                                                                    square);

                                                        final piece = controller
                                                            .game
                                                            .get(square);
                                                        final isCapture =
                                                            isLegalMove &&
                                                                piece != null;

                                                        Widget? highlightWidget;
                                                        if (isCapture) {
                                                          highlightWidget =
                                                              Center(
                                                            child: Container(
                                                              width: 32,
                                                              height: 32,
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                            alpha:
                                                                                0.3),
                                                                    width: 5),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          );
                                                        } else if (isLegalMove) {
                                                          highlightWidget =
                                                              Center(
                                                            child: Container(
                                                              width: 14,
                                                              height: 14,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                        alpha:
                                                                            0.3),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          );
                                                        }

                                                        return Expanded(
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isSelected
                                                                  ? Colors
                                                                      .yellow
                                                                      .withValues(
                                                                          alpha:
                                                                              0.4)
                                                                  : null,
                                                            ),
                                                            child:
                                                                highlightWidget,
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
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ALT KONTROL VE BİLGİ PANELİ
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. NAVİGASYON VE DURUM ÇUBUĞU
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151B2B),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.08)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Sol: Adım / Durum göstergesi
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSolved
                                                  ? Icons.check_circle_rounded
                                                  : (isReviewing
                                                      ? Icons.history_rounded
                                                      : Icons.bolt_rounded),
                                              size: 18,
                                              color: isSolved
                                                  ? Colors.greenAccent
                                                  : (isReviewing
                                                      ? Colors.amberAccent
                                                      : Colors.cyanAccent),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                isSolved
                                                    ? LanguageService.get(
                                                        'puzzle_solved')
                                                    : (isReviewing
                                                        ? LanguageService.get(
                                                            'puzzle_reviewing')
                                                        : '${LanguageService.get('puzzle_step')} ${((currentMoveIndex ~/ 2) + 1)} / ${((solutionMoves.length + 1) ~/ 2).clamp(1, 99)}'),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isSolved
                                                      ? Colors.greenAccent
                                                      : Colors.white
                                                          .withValues(
                                                              alpha: 0.9),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Orta: İleri / Geri Oklar
                                      if (_playedFens.isNotEmpty)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0E1422),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                icon: const Icon(
                                                    Icons.chevron_left_rounded,
                                                    size: 24),
                                                color: _viewIndex > 0
                                                    ? Colors.white
                                                    : Colors.white24,
                                                onPressed: _viewIndex > 0
                                                    ? () {
                                                        SoundService
                                                            .playMoveSound(
                                                                false);
                                                        setState(() {
                                                          _viewIndex--;
                                                          controller.loadFen(
                                                              _playedFens[
                                                                  _viewIndex]);
                                                        });
                                                      }
                                                    : null,
                                              ),
                                              Container(
                                                width: 1,
                                                height: 18,
                                                color: Colors.white12,
                                              ),
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                icon: const Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 24),
                                                color: _viewIndex <
                                                        _playedFens.length - 1
                                                    ? Colors.white
                                                    : Colors.white24,
                                                onPressed: _viewIndex <
                                                        _playedFens.length - 1
                                                    ? () {
                                                        SoundService
                                                            .playMoveSound(
                                                                false);
                                                        setState(() {
                                                          _viewIndex++;
                                                          controller.loadFen(
                                                              _playedFens[
                                                                  _viewIndex]);
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(width: 8),

                                      // Sağ: Atla / Sonraki Bulmaca kısayolu
                                      InkWell(
                                        onTap: _loadNextPuzzle,
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1F2A44),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isSolved
                                                    ? LanguageService.get(
                                                        'puzzle_next')
                                                    : LanguageService.get(
                                                        'puzzle_skip'),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              const Icon(
                                                  Icons.skip_next_rounded,
                                                  size: 16,
                                                  color: Colors.white70),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // 2. SKOR & ZORLUK KARTI
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (username.isNotEmpty &&
                                          username != 'Misafir')
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF151B2B),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFF5C6BC0)
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF5C6BC0)
                                                            .withValues(
                                                                alpha: 0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Icon(
                                                      Icons.stars_rounded,
                                                      color: Color(0xFF7986CB),
                                                      size: 20),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        LanguageService.get(
                                                            'puzzle_current_score'),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '$_currentScore',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (username.isNotEmpty &&
                                          username != 'Misafir')
                                        const SizedBox(width: 10),
                                      Expanded(
                                        child: InkWell(
                                          onTap: _showDifficultySelector,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF151B2B),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.cyanAccent
                                                    .withValues(alpha: 0.28),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.cyanAccent
                                                        .withValues(
                                                            alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Icon(
                                                      Icons.tune_rounded,
                                                      color: Colors.cyanAccent,
                                                      size: 20),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        LanguageService.get(
                                                            'puzzle_difficulty'),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${LanguageService.get(currentDifficulty.labelKey)} (+${currentDifficulty.points})',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
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

                                const SizedBox(height: 12),

                                // 3. BAĞLAMSAL YÖNLENDİRME / İPUCU / SONRAKİ BULMACA KARTI
                                if (isSolved)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF32804A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _loadNextPuzzle,
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded),
                                      label: Text(
                                        LanguageService.get('puzzle_next'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (_hasFailedCurrentPuzzle)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1F1C10),
                                        foregroundColor: Colors.amberAccent,
                                        side: BorderSide(
                                          color: Colors.amberAccent
                                              .withValues(alpha: 0.7),
                                          width: 1.3,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 13),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _showHint,
                                      icon: const Icon(
                                          Icons.lightbulb_outline_rounded,
                                          size: 20),
                                      label: Text(
                                        LanguageService.get('get_hint'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF131929),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isWhiteToMove
                                                ? Colors.white
                                                : const Color(0xFF262D3D),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white54,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            isWhiteToMove
                                                ? LanguageService.get(
                                                    'puzzle_find_best_white')
                                                : LanguageService.get(
                                                    'puzzle_find_best_black'),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.06),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            puzzleRating != null
                                                ? '$puzzleRating ELO'
                                                : LanguageService.get(
                                                    'puzzle_tactical_drill'),
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
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
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  StreamSubscription? _cloudSubscription;
  String _filterMode = 'newest';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  List<SavedMatch> _getDisplayedMatches() {
    List<SavedMatch> list = List.from(GlobalLibrary.matches);

    // Platform filtreleme
    if (_filterMode == 'chesscom') {
      list = list
          .where((m) => m.platform.toLowerCase().contains('chess.com'))
          .toList();
    } else if (_filterMode == 'lichess') {
      list = list
          .where((m) => m.platform.toLowerCase().contains('lichess'))
          .toList();
    } else if (_filterMode == 'pgn') {
      list = list
          .where((m) =>
              m.platform.toLowerCase().contains('pgn') ||
              (!m.platform.toLowerCase().contains('chess.com') &&
                  !m.platform.toLowerCase().contains('lichess')))
          .toList();
    }

    // Oyuncu veya başlık ara
    if (_showSearch && _searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.trim().toLowerCase();
      list = list
          .where((m) =>
              m.whiteName.toLowerCase().contains(q) ||
              m.blackName.toLowerCase().contains(q) ||
              m.title.toLowerCase().contains(q) ||
              m.platform.toLowerCase().contains(q))
          .toList();
    }

    // Sıralama (Varsayılan: Son eklenenden ilk eklenene)
    if (_filterMode == 'oldest') {
      // ilk eklenenden son eklenene (normal sıra)
    } else {
      // son eklenenden ilk eklenene (ters sıra)
      list = list.reversed.toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayedMatches = _getDisplayedMatches();
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get('library_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF151B2B),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.greenAccent),
            tooltip: LanguageService.get('library_sort_filter'),
            color: const Color(0xFF1E2536),
            onSelected: (val) {
              setState(() {
                if (val == 'search') {
                  _showSearch = !_showSearch;
                  if (!_showSearch) _searchController.clear();
                } else {
                  _filterMode = val;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(
                        _filterMode == 'newest'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _filterMode == 'newest'
                            ? Colors.greenAccent
                            : Colors.white70,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(LanguageService.get('library_newest_first'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(
                        _filterMode == 'oldest'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _filterMode == 'oldest'
                            ? Colors.greenAccent
                            : Colors.white70,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(LanguageService.get('library_oldest_first'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'chesscom',
                child: Row(
                  children: [
                    Icon(
                        _filterMode == 'chesscom'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _filterMode == 'chesscom'
                            ? Colors.greenAccent
                            : Colors.white70,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(LanguageService.get('library_only_chesscom'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lichess',
                child: Row(
                  children: [
                    Icon(
                        _filterMode == 'lichess'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _filterMode == 'lichess'
                            ? Colors.greenAccent
                            : Colors.white70,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(LanguageService.get('library_only_lichess'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pgn',
                child: Row(
                  children: [
                    Icon(
                        _filterMode == 'pgn'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _filterMode == 'pgn'
                            ? Colors.greenAccent
                            : Colors.white70,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(LanguageService.get('library_pgn_matches'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(_showSearch ? Icons.check_box : Icons.search,
                        color:
                            _showSearch ? Colors.greenAccent : Colors.white70,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(LanguageService.get('library_search_player'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1E2536),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: LanguageService.get('library_search_hint'),
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.greenAccent),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white54),
                                onPressed: () =>
                                    setState(() => _searchController.clear()))
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF151B2B),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => setState(() {
                      _showSearch = false;
                      _searchController.clear();
                    }),
                  ),
                ],
              ),
            ),
          Expanded(
            child: displayedMatches.isEmpty
                ? Center(
                    child: Text(
                      GlobalLibrary.matches.isEmpty
                          ? LanguageService.get('no_library_matches')
                          : LanguageService.get('library_no_filter_match'),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedMatches.length,
                    itemBuilder: (context, index) {
                      var match = displayedMatches[index];
                      bool userWon = (match.winner == 'white' &&
                              match.userColor == PlayerColor.white) ||
                          (match.winner == 'black' &&
                              match.userColor == PlayerColor.black);
                      bool userLost = (match.winner == 'white' &&
                              match.userColor == PlayerColor.black) ||
                          (match.winner == 'black' &&
                              match.userColor == PlayerColor.white);
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: resultColor.withValues(alpha: 0.25))),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: resultColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.bookmark, color: resultColor),
                          ),
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (match.whiteTitle.isNotEmpty)
                                buildTitleTag(match.whiteTitle),
                              Text(match.whiteName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const Text(' vs ',
                                  style: TextStyle(color: Colors.white54)),
                              if (match.blackTitle.isNotEmpty)
                                buildTitleTag(match.blackTitle),
                              Text(match.blackName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                          subtitle: Text(
                              '${match.platform} • ${LanguageService.get('mode')}: ${match.speed}',
                              style: TextStyle(
                                  color: resultColor,
                                  fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                GlobalLibrary.matches.removeWhere((m) =>
                                    identical(m, match) ||
                                    (m.pgn == match.pgn &&
                                        m.moves == match.moves));
                                GlobalLibrary.saveMatches();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(LanguageService.get(
                                          'match_deleted'))));
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AnalysisPage(
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
                                        ))).then((_) => setState(() {}));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
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
  DateTime? _lastBackPressTime;

  final GlobalKey _styleAnalysisCardKey = GlobalKey();

  final Map<String, String> _apiHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    PuzzlesPage
        .preloadPuzzles(); // Arka planda bulmaca havuzunu sessizce önbelleğe indir
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
          _showSearchHistory = _usernameController.text.trim().isNotEmpty ||
              GlobalLibrary.searchHistory.isNotEmpty;
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
      _showSearchHistory =
          value.trim().isNotEmpty || GlobalLibrary.searchHistory.isNotEmpty;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().length >= 2 && _selectedPlatform == 'Lichess') {
      _debounce = Timer(const Duration(milliseconds: 350), () async {
        try {
          var res = await http.get(Uri.parse(
              'https://lichess.org/api/player/autocomplete?term=${value.trim()}'));
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
        setState(() {
          _liveSuggestions = [];
        });
      }
    }
  }

  Future<void> fetchPlayerStats({bool loadMore = false}) async {
    String username = _usernameController.text.trim();
    if (username.isEmpty) {
      return;
    }

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
          var res = await http.get(
              Uri.parse('https://lichess.org/api/user/$username'),
              headers: _apiHeaders);
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
            _errorMessage = res.statusCode == 429
                ? 'Lichess hız sınırı uyguladı. Bekleyin.'
                : 'Lichess: Oyuncu bulunamadı.';
          }
        }
        if (_playerProfile != null) {
          _recentMatches = await _fetchLichessGames(
              username, _selectedTempo, _loadedGamesCount);
        }
      } else {
        if (!loadMore) {
          var profileRes = await http.get(
              Uri.parse('https://api.chess.com/pub/player/$username'),
              headers: _apiHeaders);
          var statsRes = await http.get(
              Uri.parse('https://api.chess.com/pub/player/$username/stats'),
              headers: _apiHeaders);
          if (profileRes.statusCode == 200 && statsRes.statusCode == 200) {
            var pData = jsonDecode(profileRes.body);
            var sData = jsonDecode(statsRes.body);
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
          _recentMatches = await _fetchChessComGames(
              username, _selectedTempo, _loadedGamesCount);
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
        _playerStyleProfile =
            PlayerStyleAnalyzer.analyze(username, _recentMatches, maxRating);
      }
    } catch (e) {
      _errorMessage = 'Bağlantı sağlanamadı.';
    }
    setState(() {
      _isLoading = false;
      _isMatchesLoading = false;
    });
  }

  bool _isPgnValid(String pgn) {
    if (pgn.trim().isEmpty) {
      return false;
    }
    return pgn
            .trim()
            .split(RegExp(r'\s+'))
            .where((t) => RegExp(r'^[a-h][1-8]|^[KQRBN]').hasMatch(t))
            .length >=
        2;
  }

  Future<void> _showPgnInputDialog() async {
    _pgnController.clear();
    Color themeColor = _selectedPlatform == 'Chess.com'
        ? const Color(0xFF32804A)
        : const Color(0xFF5C6BC0);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF101A2B),
              title: Text(LanguageService.get('pgn_paste'),
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            color: themeColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 0))
                      ])),
              content: SizedBox(
                width: double.maxFinite,
                child: TextField(
                  controller: _pgnController,
                  maxLines: 10,
                  onChanged: (_) => setDialogState(() {}),
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                            color: themeColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 0))
                      ]),
                  decoration: InputDecoration(
                      hintText: LanguageService.get('pgn_placeholder'),
                      hintStyle: TextStyle(color: Colors.white38, shadows: [
                        Shadow(
                            color: themeColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 0))
                      ]),
                      filled: true,
                      fillColor: const Color(0xFF151B2B),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(LanguageService.get('cancel'),
                        style: const TextStyle(color: Colors.white70, shadows: [
                          Shadow(
                              color: Colors.white10,
                              blurRadius: 4,
                              offset: Offset(0, 0))
                        ]))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _isPgnValid(_pgnController.text)
                          ? themeColor
                          : themeColor.withValues(alpha: 0.4),
                      foregroundColor: Colors.white),
                  onPressed: _isPgnValid(_pgnController.text)
                      ? () {
                          Navigator.of(context).pop();
                          _analyzePgn();
                        }
                      : null,
                  child: Text(LanguageService.get('analyze'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                          shadows: _isPgnValid(_pgnController.text)
                              ? [
                                  Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1))
                                ]
                              : [])),
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
    if (result == '1-0') {
      winner = 'white';
    } else if (result == '0-1') {
      winner = 'black';
    }

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
    if (pgn.isEmpty) {
      setState(() {
        _errorMessage = 'PGN boş olamaz.';
      });
      return;
    }
    Map<String, dynamic> meta = _extractPgnMetadata(pgn);

    var matchData = {
      'platform': 'PGN',
      'white': meta['white'],
      'black': meta['black'],
      'whiteTitle': meta['whiteTitle'],
      'blackTitle': meta['blackTitle'],
      'whiteRating': meta['whiteRating'],
      'blackRating': meta['blackRating'],
      'winner': meta['winner'],
      'speed': 'pgn',
      'pgn': pgn,
      'moves': '',
    };

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AnalysisPage(
                matchData: matchData,
                boardOrientation: PlayerColor.white,
                apiHeaders: _apiHeaders)));
  }

  Future<void> _updateTempoFilter(String targetTempo) async {
    String username = _usernameController.text.trim();
    if (username.isEmpty || _playerProfile == null) {
      return;
    }
    if (_selectedTempo == targetTempo) {
      targetTempo = 'all';
    }
    setState(() {
      _isMatchesLoading = true;
      _selectedTempo = targetTempo;
      _recentMatches = [];
      _loadedGamesCount = 30;
    });
    try {
      if (_selectedPlatform == 'Lichess') {
        _recentMatches =
            await _fetchLichessGames(username, targetTempo, _loadedGamesCount);
      } else {
        _recentMatches =
            await _fetchChessComGames(username, targetTempo, _loadedGamesCount);
      }
    } catch (e) {
      _errorMessage = LanguageService.get('filter_error');
    }
    setState(() {
      _isMatchesLoading = false;
    });
  }

  String _getChessComWinner(Map<String, dynamic> game) {
    if (game['white']?['result'] == 'win') {
      return 'white';
    }
    if (game['black']?['result'] == 'win') {
      return 'black';
    }
    return 'draw';
  }

  Future<List<dynamic>> _fetchLichessGames(
      String username, String tempo, int maxGames) async {
    List<dynamic> list = [];
    String urlStr =
        'https://lichess.org/api/games/user/$username?max=$maxGames';
    if (tempo != 'all') {
      urlStr += '&perfType=$tempo';
    }
    var res = await http.get(Uri.parse(urlStr), headers: {
      'User-Agent': _apiHeaders['User-Agent']!,
      'Accept': 'application/x-ndjson'
    });
    if (res.statusCode == 200) {
      for (var line in res.body.trim().split('\n')) {
        if (line.isNotEmpty) {
          var m = jsonDecode(line);
          String wName =
              m['players']?['white']?['user']?['name'] ?? 'Bilinmiyor';
          String bName =
              m['players']?['black']?['user']?['name'] ?? 'Bilinmiyor';
          String wTitle = m['players']?['white']?['user']?['title'] ?? '';
          String bTitle = m['players']?['black']?['user']?['title'] ?? '';

          // Termo_x kontrolü
          if (wName.toLowerCase() == 'termo_x') wTitle = 'TermoGM';
          if (bName.toLowerCase() == 'termo_x') bTitle = 'TermoGM';

          list.add({
            'platform': 'Lichess',
            'white': wName,
            'black': bName,
            'whiteTitle': wTitle,
            'blackTitle': bTitle,
            'whiteRating': m['players']?['white']?['rating'] ?? 0,
            'blackRating': m['players']?['black']?['rating'] ?? 0,
            'winner': m['winner'] ?? 'draw',
            'speed': m['speed']?.toString().toLowerCase() ?? 'Bilinmiyor',
            'pgn': '',
            'moves': m['moves'] ?? ''
          });
        }
      }
    }
    return list;
  }

  Future<List<dynamic>> _fetchChessComGames(
      String username, String tempo, int maxGames) async {
    List<dynamic> list = [];
    var res = await http.get(
        Uri.parse('https://api.chess.com/pub/player/$username/games/archives'),
        headers: _apiHeaders);
    if (res.statusCode == 200) {
      List<dynamic> archives = jsonDecode(res.body)['archives'] ?? [];
      for (String url in archives.reversed) {
        if (list.length >= maxGames) {
          break;
        }
        var gRes = await http.get(Uri.parse(url), headers: _apiHeaders);
        if (gRes.statusCode == 200) {
          List<dynamic> games = jsonDecode(gRes.body)['games'] ?? [];
          for (var g in games.reversed) {
            if (list.length >= maxGames) {
              break;
            }
            String t =
                g['time_class']?.toString().toLowerCase() ?? 'bilinmiyor';
            if (tempo == 'all' || t == tempo) {
              String wName = g['white']['username'];
              String bName = g['black']['username'];
              String wTitle = (wName.toLowerCase() == username.toLowerCase())
                  ? (_playerProfile?['title'] ?? '')
                  : '';
              String bTitle = (bName.toLowerCase() == username.toLowerCase())
                  ? (_playerProfile?['title'] ?? '')
                  : '';

              list.add({
                'platform': 'Chess.com',
                'white': wName,
                'black': bName,
                'whiteTitle': wTitle,
                'blackTitle': bTitle,
                'whiteRating': g['white']['rating'] ?? 0,
                'blackRating': g['black']['rating'] ?? 0,
                'winner': _getChessComWinner(g),
                'speed': t,
                'pgn': g['pgn'] ?? '',
                'moves': '',
                'whiteAccuracy': g['accuracies']?['white'],
                'blackAccuracy': g['accuracies']?['black']
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
    String? savedFilePath;
    String shareText = '';
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      RenderRepaintBoundary? boundary = _styleAnalysisCardKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Kart henüz ekranda çizilmedi.");

      // debugNeedsPaint causes LateInitializationError in release builds.
      // We already waited 300ms, wait a little bit more just in case.
      await Future.delayed(const Duration(milliseconds: 500));

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Share Error: Image generation failed (byteData is null)')));
        return;
      }

      final bytes = byteData.buffer.asUint8List();

      String u = _playerProfile!['username']?.toString() ?? 'Oyuncu';
      String style = LanguageService.styleLabel(_playerStyleProfile!.mainStyle);
      int r = _playerProfile!['rapid'] as int? ?? 0;
      int b = _playerProfile!['blitz'] as int? ?? 0;
      int bl = _playerProfile!['bullet'] as int? ?? 0;
      int maxR = [r, b, bl].reduce(max);
      String ratingStr = maxR > 0 ? maxR.toString() : '-';

      bool isEn = LanguageService.currentLang == 'en';
      shareText = isEn
          ? '♟️ Check out my chess play style analysis on MoveLab!\n👤 Player: $u\n🎯 Play Style: $style\n📈 Rating: $ratingStr\n\nDownload MoveLab now to get a detailed analysis of your own chess play style:\n📲 https://play.google.com/store/apps/details?id=com.movelab.app'
          : '♟️ Satranç oyun stili analizimi MoveLab\'de incele!\n👤 Oyuncu: $u\n🎯 Oyun Stili: $style\n📈 Rating: $ratingStr\n\nSen de kendi satranç oyun stilini detaylıca analiz etmek için MoveLab\'i hemen indir:\n📲 https://play.google.com/store/apps/details?id=com.movelab.app';

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LanguageService.get('preparing_share'))));

      try {
        const platform = MethodChannel('com.movelab.app/share');
        await platform.invokeMethod('shareImage', {
          'bytes': bytes,
          'text': shareText,
        });
      } catch (e2, st2) {
        if (mounted) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                  title: const Text('NATIVE_SHARE_ERROR'),
                  content: SingleChildScrollView(child: Text('$e2\n\n$st2'))));
        }
      }
    } catch (e, st) {
      debugPrint("Share error: $e");
      if (mounted) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text('DART_SHARE_ERROR'),
                content: SingleChildScrollView(child: Text('$e\n\n$st'))));
      }
    }
  }

  Widget _buildPlayerStyleWidget(PlayerStyleProfile profile) {
    Color themeColor = _selectedPlatform == 'Chess.com'
        ? const Color(0xFF32804A)
        : const Color(0xFF5C6BC0);
    String uName = _playerProfile?['username']?.toString() ?? 'Oyuncu';
    String uTitle = _playerProfile?['title']?.toString() ?? '';
    int maxR = 0;
    if (_playerProfile != null) {
      int r = _playerProfile!['rapid'] as int? ?? 0;
      int b = _playerProfile!['blitz'] as int? ?? 0;
      int bl = _playerProfile!['bullet'] as int? ?? 0;
      maxR = [r, b, bl].reduce(max);
    }

    if (profile.mainStyle == 'Dengeli') {
      String u = _playerProfile?['username']?.toString() ?? 'Oyuncu';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined,
                color: Colors.amberAccent, size: 32),
            const SizedBox(height: 10),
            Text(
              LanguageService.currentLang == 'tr'
                  ? 'Analiz Edilecek Maç Yok'
                  : 'No Matches to Analyze',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              LanguageService.currentLang == 'tr'
                  ? 'Kütüphanenizde "$u" adına ait hiç maç bulunamadığı için oyun stili analizi oluşturulamadı. Maç oynayarak veya hesap maçlarınızı kütüphaneye ekleyerek stil kartınızı oluşturabilirsiniz.'
                  : 'No matches found in the library for "$u". Play matches or import your games to generate your player style analysis card.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RepaintBoundary(
        key: _styleAnalysisCardKey,
        child: ColoredBox(
          color: const Color(0xFF0F172A),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2638),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insert_chart, color: themeColor, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          LanguageService.currentLang == 'tr'
                              ? 'OYUNCU STİLİ ANALİZİ'
                              : 'PLAY STYLE ANALYSIS',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blueAccent),
                      tooltip: LanguageService.get('share_style'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _shareStyleAnalysisCard,
                    ),
                  ],
                ),
                const SizedBox(height: 0),
                Row(
                  children: [
                    buildUserTags(uTitle, _isUserDonor),
                    Flexible(
                      child: Text(
                        uName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${LanguageService.get('rating')}: ${maxR > 0 ? maxR.toString() : '-'}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Text(profile.mainIcon,
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 4),
                      Text(
                        LanguageService.styleLabel(profile.mainStyle),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor),
                      ),
                      const SizedBox(height: 8),
                      if (profile.subStyles.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: profile.subStyles
                              .map((sub) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: themeColor.withValues(
                                              alpha: 0.5)),
                                    ),
                                    child: Text(LanguageService.styleLabel(sub),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileStyleBar(LanguageService.get('style_aggressive'),
                    profile.aggressive, Colors.redAccent),
                _buildProfileStyleBar(LanguageService.get('style_defensive'),
                    profile.defensive, Colors.blueAccent),
                _buildProfileStyleBar(LanguageService.get('style_tactical'),
                    profile.tactical, Colors.amberAccent),
                _buildProfileStyleBar(LanguageService.get('style_positional'),
                    profile.positional, Colors.green),
                _buildProfileStyleBar(LanguageService.get('style_risk'),
                    profile.risk, Colors.orangeAccent),
                _buildProfileStyleBar(LanguageService.get('style_opening'),
                    profile.opening, Colors.purpleAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEloColumn(
      String title, int? rating, String filterKey, Color themeColor) {
    bool isSelected = _selectedTempo == filterKey;
    return GestureDetector(
      onTap: () => _updateTempoFilter(filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: isSelected
                ? themeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? themeColor : Colors.transparent,
                width: 1.5)),
        child: Column(children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? themeColor : Colors.white54,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(rating != null ? rating.toString() : 'Yok',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.white70))
        ]),
      ),
    );
  }

  Widget _buildTexturedButton({
    required String label,
    IconData? icon,
    required Color color,
    required VoidCallback onPressed,
    bool isElevated = false,
    bool expandToFill = false,
    double verticalPadding = 12,
  }) {
    final borderRadius = BorderRadius.circular(12);

    if (expandToFill) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF151B2B).withValues(alpha: 0.92),
          borderRadius: borderRadius,
          border: Border.all(color: color.withValues(alpha: 0.85), width: 1.2),
          image: DecorationImage(
            image: const AssetImage('assets/button_texture.jpg'),
            fit: BoxFit.cover,
            opacity: 0.42,
            colorFilter: ColorFilter.mode(
              color,
              BlendMode.modulate,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            splashColor: color.withValues(alpha: 0.2),
            highlightColor: color.withValues(alpha: 0.1),
            onTap: onPressed,
            child: LayoutBuilder(
              builder: (context, btnConstraints) {
                final iconSize = (btnConstraints.maxHeight * 0.34).clamp(18.0, 26.0);
                final fontSize = (btnConstraints.maxHeight * 0.20).clamp(12.0, 14.5);
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: btnConstraints.maxWidth * 0.06,
                    vertical: btnConstraints.maxHeight * 0.08,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null)
                        Icon(icon, color: color, size: iconSize),
                      if (icon != null)
                        SizedBox(height: btnConstraints.maxHeight * 0.06),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B).withValues(alpha: 0.92),
        borderRadius: borderRadius,
        image: DecorationImage(
          image: const AssetImage('assets/button_texture.jpg'),
          fit: BoxFit.cover,
          opacity: 0.45,
          colorFilter: ColorFilter.mode(
            color,
            BlendMode.modulate, // Safely tints the gray pixels without breaking alpha
          ),
        ),
      ),
      child: isElevated
          ? ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
              ),
              icon: icon != null
                  ? Icon(icon, color: Colors.white)
                  : const SizedBox.shrink(),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: onPressed,
            )
          : OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                side: BorderSide(color: color),
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
              ),
              icon: icon != null ? Icon(icon, color: color) : const SizedBox.shrink(),
              label: Text(label,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              onPressed: onPressed,
            ),
    );
  }

  Widget _buildHomeActionGrid({
    required double gap,
    required bool expandRows,
  }) {
    final row1 = Row(
      children: [
        Expanded(
          child: _buildTexturedButton(
            label: LanguageService.get('library_saved_matches'),
            icon: Icons.library_books,
            color: const Color(0xFFE57373),
            expandToFill: expandRows,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LibraryPage())),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _buildTexturedButton(
            label: LanguageService.get('puzzles'),
            icon: Icons.extension,
            color: Colors.orangeAccent,
            expandToFill: expandRows,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PuzzlesPage())),
          ),
        ),
      ],
    );

    final row2 = Row(
      children: [
        Expanded(
          child: _buildTexturedButton(
            label: LanguageService.get('master_archive'),
            icon: Icons.workspace_premium,
            color: Colors.amberAccent,
            expandToFill: expandRows,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MastersListPage())),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _buildTexturedButton(
            label: LanguageService.get('opening_trainer'),
            icon: Icons.menu_book,
            color: const Color(0xFF81C784),
            expandToFill: expandRows,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OpeningTrainerPage())),
          ),
        ),
      ],
    );

    final row3 = Row(
      children: [
        Expanded(
          child: _buildTexturedButton(
            label: LanguageService.get('play_vs_bot'),
            icon: Icons.smart_toy,
            color: Colors.blueAccent,
            expandToFill: expandRows,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BotSelectionPage())),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _buildTexturedButton(
            label: LanguageService.get('free_analyze'),
            icon: Icons.analytics,
            color: Colors.purpleAccent,
            expandToFill: expandRows,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FreeAnalysisPage())),
          ),
        ),
      ],
    );

    if (expandRows) {
      return Column(
        children: [
          Expanded(child: row1),
          SizedBox(height: gap),
          Expanded(child: row2),
          SizedBox(height: gap),
          Expanded(child: row3),
        ],
      );
    }

    return Column(
      children: [
        IntrinsicHeight(child: row1),
        SizedBox(height: gap),
        IntrinsicHeight(child: row2),
        SizedBox(height: gap),
        IntrinsicHeight(child: row3),
      ],
    );
  }

  Widget _buildPrimaryActionRow({
    required Color themeColor,
    required double gap,
    required double vPad,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: vPad, horizontal: gap),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: fetchPlayerStats,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                LanguageService.get('find_player'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 2,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: themeColor,
              backgroundColor: const Color(0xFF151B2B).withValues(alpha: 0.92),
              side: BorderSide(color: themeColor),
              padding: EdgeInsets.symmetric(vertical: vPad, horizontal: gap),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showPgnInputDialog,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                LanguageService.get('analyze_with_pgn'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _selectedPlatform == 'Chess.com'
        ? const Color(0xFF32804A)
        : const Color(0xFF5C6BC0);

    List<String> combinedSuggestions = [
      ...GlobalLibrary.searchHistory.where((name) => name
          .toLowerCase()
          .contains(_usernameController.text.trim().toLowerCase())),
      ..._liveSuggestions.where((name) => !GlobalLibrary.searchHistory
          .any((h) => h.toLowerCase() == name.toLowerCase()))
    ];

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Eğer profil/maç ekranındaysa veya arama geçmişi açıksa önce ana menüye dön
        if (!_isHeaderVisible ||
            _playerProfile != null ||
            _isLoading ||
            _showSearchHistory ||
            _searchFocusNode.hasFocus) {
          _resetHome();
          return;
        }
        // Ana ekrandaysa 2 saniye içinde ikinci geri basışında çık
        final now = DateTime.now();
        if (_lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressTime = now;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService.currentLang == 'en'
                  ? 'Press back again to exit'
                  : 'Çıkmak için tekrar geri tuşuna basın',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF1E263A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ChessSilhouetteBackground(accentColor: themeColor),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportHeight = constraints.maxHeight;
                final viewportWidth = constraints.maxWidth;
                final hPad = viewportWidth * 0.05;
                final gap = (viewportHeight * 0.013).clamp(6.0, 14.0);
                final primaryBtnVPad =
                    (viewportHeight * 0.018).clamp(10.0, 16.0);

                final bool fitSingleScreen = _isHeaderVisible &&
                    _playerProfile == null &&
                    !_isLoading &&
                    _errorMessage.isEmpty &&
                    !_showSearchHistory &&
                    !keyboardOpen &&
                    viewportHeight >= 460;

                final Widget topBar = Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _isHeaderVisible
                        ? const SizedBox(width: 48)
                        : IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white70),
                            tooltip: LanguageService.get('back_home'),
                            onPressed: _resetHome,
                          ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      tooltip: LanguageService.get('settings'),
                      onPressed: () => showSettingsSheet(context,
                          onChanged: () => setState(() {})),
                    ),
                  ],
                );

                final Widget platformChips = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: const Text('Lichess'),
                      selected: _selectedPlatform == 'Lichess',
                      onSelected: (s) {
                        setState(() {
                          _selectedPlatform = 'Lichess';
                          _liveSuggestions = [];
                        });
                      },
                      selectedColor: const Color(0xFF5C6BC0),
                      backgroundColor:
                          const Color(0xFF151B2B).withValues(alpha: 0.92),
                    ),
                    SizedBox(width: viewportWidth * 0.04),
                    ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: const Text('Chess.com'),
                      selected: _selectedPlatform == 'Chess.com',
                      onSelected: (s) {
                        setState(() {
                          _selectedPlatform = 'Chess.com';
                          _liveSuggestions = [];
                        });
                      },
                      selectedColor: const Color(0xFF32804A),
                      backgroundColor:
                          const Color(0xFF151B2B).withValues(alpha: 0.92),
                    ),
                  ],
                );

                final Widget searchField = TextField(
                  focusNode: _searchFocusNode,
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  onTap: () {
                    setState(() {
                      _isHeaderVisible = true;
                      _showSearchHistory =
                          _usernameController.text.trim().isNotEmpty ||
                              GlobalLibrary.searchHistory.isNotEmpty;
                    });
                  },
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => fetchPlayerStats(),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: (viewportHeight * 0.017).clamp(10.0, 16.0),
                      horizontal: viewportWidth * 0.035,
                    ),
                    hintText:
                        '$_selectedPlatform ${LanguageService.get('player_search_placeholder')}',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor, width: 2)),
                    filled: true,
                    fillColor: const Color(0xFF151B2B).withValues(alpha: 0.92),
                    prefixIcon: Icon(Icons.search, color: themeColor),
                  ),
                );

                if (fitSingleScreen) {
                  return SizedBox(
                    height: viewportHeight,
                    width: viewportWidth,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        viewportHeight * 0.008,
                        hPad,
                        viewportHeight * 0.018,
                      ),
                      child: Column(
                        children: [
                          topBar,
                          Flexible(
                            flex: 24,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: viewportHeight * 0.006),
                                child: Image.asset(
                                  'assets/logoyazili.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      FittedBox(
                                    child: Icon(Icons.psychology,
                                        color: themeColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          platformChips,
                          SizedBox(height: gap),
                          searchField,
                          SizedBox(height: gap),
                          _buildPrimaryActionRow(
                            themeColor: themeColor,
                            gap: gap,
                            vPad: primaryBtnVPad,
                          ),
                          SizedBox(height: gap),
                          Expanded(
                            flex: 48,
                            child: _buildHomeActionGrid(
                              gap: gap,
                              expandRows: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      viewportHeight * 0.008,
                      hPad,
                      viewportHeight * 0.025,
                    ),
                    child: Column(
                      children: [
                        topBar,
                        AnimatedSize(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: _isHeaderVisible
                              ? Column(
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: viewportHeight * 0.22,
                                      ),
                                      child: Image.asset(
                                        'assets/logoyazili.png',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.psychology,
                                                    size: viewportHeight * 0.1,
                                                    color: themeColor),
                                      ),
                                    ),
                                    SizedBox(height: gap * 0.5),
                                    platformChips,
                                    SizedBox(height: gap),
                                  ],
                                )
                              : const SizedBox(
                                  width: double.infinity, height: 0),
                        ),
                        searchField,
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: _showSearchHistory &&
                                  combinedSuggestions.isNotEmpty
                              ? Container(
                                  margin: EdgeInsets.only(top: gap * 0.7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF101A2B)
                                        .withValues(alpha: 0.96),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0xFF24314D)),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxHeight: viewportHeight * 0.30),
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      shrinkWrap: true,
                                      itemCount: combinedSuggestions.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                              height: 1, color: Colors.white10),
                                      itemBuilder: (context, index) {
                                        final option =
                                            combinedSuggestions[index];
                                        bool isHistory = GlobalLibrary
                                            .searchHistory
                                            .any((h) =>
                                                h.toLowerCase() ==
                                                option.toLowerCase());

                                        return ListTile(
                                          dense: true,
                                          leading: Icon(
                                              isHistory
                                                  ? Icons.history
                                                  : Icons.person_search,
                                              color: isHistory
                                                  ? Colors.white54
                                                  : themeColor,
                                              size: 18),
                                          title: Text(option,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: isHistory
                                                      ? FontWeight.w500
                                                      : FontWeight.bold)),
                                          onTap: () {
                                            _usernameController.text = option;
                                            setState(() =>
                                                _showSearchHistory = false);
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
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _isHeaderVisible
                              ? Column(
                                  children: [
                                    SizedBox(height: gap),
                                    _buildPrimaryActionRow(
                                      themeColor: themeColor,
                                      gap: gap,
                                      vPad: primaryBtnVPad,
                                    ),
                                    SizedBox(height: gap),
                                    _buildHomeActionGrid(
                                      gap: gap,
                                      expandRows: false,
                                    ),
                                    SizedBox(height: gap),
                                  ],
                                )
                              : const SizedBox(
                                  width: double.infinity, height: 0),
                        ),
                        if (_isLoading)
                          Padding(
                              padding:
                                  EdgeInsets.only(top: viewportHeight * 0.05),
                              child: CircularProgressIndicator(
                                  color: themeColor)),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: gap),
                            child: Text(_errorMessage,
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        if (_playerProfile != null) ...[
                          Card(
                            elevation: 8,
                            color:
                                const Color(0xFF151B2B).withValues(alpha: 0.95),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person,
                                          size: 36, color: themeColor),
                                      const SizedBox(width: 10),
                                      buildUserTags(
                                          (_playerProfile!['title'] ?? '')
                                              .toString(),
                                          _isUserDonor),
                                      Flexible(
                                          child: Text(
                                              _playerProfile!['username'] ??
                                                  'Bilinmeyen',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ]),
                                const Divider(
                                    height: 30,
                                    thickness: 1,
                                    color: Color(0xFF2A3650)),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildEloColumn(
                                          'Rapid',
                                          _playerProfile!['rapid'],
                                          'rapid',
                                          themeColor),
                                      _buildEloColumn(
                                          'Blitz',
                                          _playerProfile!['blitz'],
                                          'blitz',
                                          themeColor),
                                      _buildEloColumn(
                                          'Bullet',
                                          _playerProfile!['bullet'],
                                          'bullet',
                                          themeColor)
                                    ]),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_playerStyleProfile != null)
                            _buildPlayerStyleWidget(_playerStyleProfile!),
                          const SizedBox(height: 25),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  _selectedTempo == 'all'
                                      ? LanguageService.get('recent_matches')
                                      : '${LanguageService.tempoLabel(_selectedTempo)} - ${LanguageService.get('recent_matches')}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor))),
                          const SizedBox(height: 15),
                          if (_recentMatches.isEmpty && !_isMatchesLoading)
                            Text(LanguageService.get('no_match_data'),
                                style: const TextStyle(color: Colors.white54))
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentMatches.length,
                              itemBuilder: (context, index) {
                                var match = _recentMatches[index];
                                String sUser = _playerProfile!['username']
                                    .toString()
                                    .toLowerCase();
                                String w =
                                    match['white'].toString().toLowerCase();
                                String b =
                                    match['black'].toString().toLowerCase();
                                bool uWon =
                                    (match['winner'] == 'white' && w == sUser) ||
                                        (match['winner'] == 'black' &&
                                            b == sUser);
                                bool uLost =
                                    (match['winner'] == 'white' && b == sUser) ||
                                        (match['winner'] == 'black' &&
                                            w == sUser);
                                Color rColor = const Color(0xFF151B2B);
                                Color aColor = Colors.grey;
                                if (uWon) {
                                  rColor = const Color(0xFF66BB6A)
                                      .withValues(alpha: 0.12);
                                  aColor = const Color(0xFF66BB6A);
                                } else if (uLost) {
                                  rColor = const Color(0xFFEF5350)
                                      .withValues(alpha: 0.12);
                                  aColor = const Color(0xFFEF5350);
                                }
                                return Card(
                                  color: rColor,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                          color: aColor.withValues(alpha: 0.2),
                                          width: 1)),
                                  child: ListTile(
                                    leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color:
                                                aColor.withValues(alpha: 0.35),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: const Icon(Icons.sports_esports,
                                            color: Colors.white)),
                                    title: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if ((match['whiteTitle'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          buildTitleTag(match['whiteTitle']),
                                        Text(match['white'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                        const Text(' vs ',
                                            style: TextStyle(
                                                color: Colors.white54)),
                                        if ((match['blackTitle'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          buildTitleTag(match['blackTitle']),
                                        Text(match['black'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ],
                                    ),
                                    subtitle: Text(
                                        '${LanguageService.get('mode')}: ${match['speed']}',
                                        style: TextStyle(
                                            color: aColor,
                                            fontWeight: FontWeight.bold)),
                                    trailing: Icon(Icons.arrow_forward_ios,
                                        size: 16,
                                        color: aColor.withValues(alpha: 0.8)),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => AnalysisPage(
                                                matchData: match,
                                                boardOrientation: w == sUser
                                                    ? PlayerColor.white
                                                    : PlayerColor.black,
                                                apiHeaders: _apiHeaders))),
                                  ),
                                );
                              },
                            ),
                          if (_recentMatches.isNotEmpty && !_isMatchesLoading)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 2.0, bottom: 12.0),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                        color:
                                            themeColor.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: () =>
                                    fetchPlayerStats(loadMore: true),
                                child: Text(
                                    LanguageService.get('load_more_games')),
                              ),
                            ),
                          if (_isMatchesLoading)
                            Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                    color: themeColor))
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

  CustomArrowPainter(
      {required this.from,
      required this.to,
      required this.orientation,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (from.length < 2 || to.length < 2) return;
    double sqSize = size.width / 8;

    int fileFrom = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rankFrom = 8 - int.parse(from[1]);
    int fileTo = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rankTo = 8 - int.parse(to[1]);

    if (orientation == PlayerColor.black) {
      fileFrom = 7 - fileFrom;
      rankFrom = 7 - rankFrom;
      fileTo = 7 - fileTo;
      rankTo = 7 - rankTo;
    }

    Offset start =
        Offset(fileFrom * sqSize + sqSize / 2, rankFrom * sqSize + sqSize / 2);
    Offset end =
        Offset(fileTo * sqSize + sqSize / 2, rankTo * sqSize + sqSize / 2);

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
      lineEnd = Offset(
          end.dx - pullBack * cos(angle), end.dy - pullBack * sin(angle));
      canvas.drawLine(start, lineEnd, paint);
    }

    _drawArrowHead(canvas, start, end, arrowSize, paint);
  }

  void _drawArrowHead(
      Canvas canvas, Offset start, Offset end, double arrowSize, Paint paint) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double angle = atan2(dy, dx);

    Offset p1 = Offset(end.dx - arrowSize * cos(angle - pi / 6.5),
        end.dy - arrowSize * sin(angle - pi / 6.5));
    Offset p2 = Offset(end.dx - arrowSize * cos(angle + pi / 6.5),
        end.dy - arrowSize * sin(angle + pi / 6.5));

    Path path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.close();

    Paint headPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, headPaint);
  }

  @override
  bool shouldRepaint(CustomArrowPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.orientation != orientation;
  }
}

class MultiArrowPainter extends CustomPainter {
  final List<String> moves;
  final PlayerColor orientation;

  MultiArrowPainter({required this.moves, required this.orientation});

  @override
  void paint(Canvas canvas, Size size) {
    if (moves.isEmpty) return;
    double sqSize = size.width / 8;

    final colors = [
      const Color(0xFF00E5FF).withValues(alpha: 0.85),
      const Color(0xFFFFAB00).withValues(alpha: 0.70),
      const Color(0xFF00E676).withValues(alpha: 0.55),
    ];
    final widths = [
      sqSize * 0.22,
      sqSize * 0.18,
      sqSize * 0.14,
    ];
    final headSizes = [
      sqSize * 0.45,
      sqSize * 0.38,
      sqSize * 0.32,
    ];

    for (int i = min(moves.length, 3) - 1; i >= 0; i--) {
      String uci = moves[i];
      if (uci.length < 4 || uci == '...') continue;
      String from = uci.substring(0, 2);
      String to = uci.substring(2, 4);

      int fileFrom = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int rankFrom = 8 - int.parse(from[1]);
      int fileTo = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int rankTo = 8 - int.parse(to[1]);

      if (orientation == PlayerColor.black) {
        fileFrom = 7 - fileFrom;
        rankFrom = 7 - rankFrom;
        fileTo = 7 - fileTo;
        rankTo = 7 - rankTo;
      }

      Offset start = Offset(
          fileFrom * sqSize + sqSize / 2, rankFrom * sqSize + sqSize / 2);
      Offset end =
          Offset(fileTo * sqSize + sqSize / 2, rankTo * sqSize + sqSize / 2);

      Paint paint = Paint()
        ..color = colors[i]
        ..strokeWidth = widths[i]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      double arrowSize = headSizes[i];
      double dx = end.dx - start.dx;
      double dy = end.dy - start.dy;
      double distance = sqrt(dx * dx + dy * dy);
      double angle = atan2(dy, dx);

      double pullBack = arrowSize * 0.75 + (paint.strokeWidth / 2);
      Offset lineEnd = end;
      if (distance > pullBack) {
        lineEnd = Offset(
            end.dx - pullBack * cos(angle), end.dy - pullBack * sin(angle));
        canvas.drawLine(start, lineEnd, paint);
      }

      _drawArrowHead(canvas, start, end, arrowSize, paint);
    }
  }

  void _drawArrowHead(
      Canvas canvas, Offset start, Offset end, double arrowSize, Paint paint) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double angle = atan2(dy, dx);

    Offset p1 = Offset(end.dx - arrowSize * cos(angle - pi / 6.5),
        end.dy - arrowSize * sin(angle - pi / 6.5));
    Offset p2 = Offset(end.dx - arrowSize * cos(angle + pi / 6.5),
        end.dy - arrowSize * sin(angle + pi / 6.5));

    Path path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.close();

    Paint headPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, headPaint);
  }

  @override
  bool shouldRepaint(MultiArrowPainter oldDelegate) {
    return oldDelegate.moves != moves || oldDelegate.orientation != orientation;
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _myUsername = '';

  @override
  void initState() {
    super.initState();
    _loadMyUsername();
  }

  Future<void> _loadMyUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('puzzle_username') ?? '';
    if (mounted) {
      setState(() => _myUsername = saved.trim());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageService.currentLang == 'en';
    final bool hasMyUser = _myUsername.isNotEmpty &&
        _myUsername.toLowerCase() != 'misafir' &&
        _myUsername.toLowerCase() != 'guest';

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get('puzzle_username_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF151B2B),
        actions: [
          if (hasMyUser)
            IconButton(
              icon: Icon(
                Icons.person_search_rounded,
                color: _searchQuery.toLowerCase() == _myUsername.toLowerCase()
                    ? Colors.cyanAccent
                    : Colors.white70,
              ),
              tooltip: isEn ? 'Find My Rank' : 'Sıramı Bul',
              onPressed: () {
                setState(() {
                  if (_searchQuery.toLowerCase() == _myUsername.toLowerCase()) {
                    _searchController.clear();
                    _searchQuery = '';
                  } else {
                    _searchController.text = _myUsername;
                    _searchQuery = _myUsername;
                  }
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: LanguageService.get('settings'),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            color: const Color(0xFF151B2B),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                isDense: true,
                hintText: isEn
                    ? 'Search username in ranking...'
                    : 'Sıralamada kullanıcı adı ara...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.orangeAccent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0E1422),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.orangeAccent, width: 1.4),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Firestore'dan verileri score'a göre azalan şekilde çek (Tüm liste)
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('score', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.orangeAccent));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Veri çekilemedi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent)));
                }

                final users = snapshot.data?.docs ?? [];
                if (users.isEmpty) {
                  return Center(
                      child: Text(LanguageService.get('puzzle_no_solvers'),
                          style: const TextStyle(color: Colors.white54)));
                }

                final List<Map<String, dynamic>> indexedUsers = [];
                final q = _searchQuery.toLowerCase();
                for (int i = 0; i < users.length; i++) {
                  final data = users[i].data() as Map<String, dynamic>;
                  final String name = (data['username'] ?? users[i].id).toString();
                  if (q.isEmpty || name.toLowerCase().contains(q)) {
                    indexedUsers.add({
                      'rank': i + 1,
                      'data': data,
                      'name': name,
                    });
                  }
                }

                if (indexedUsers.isEmpty) {
                  return Center(
                    child: Text(
                      isEn
                          ? 'No player found matching "$_searchQuery".'
                          : '"$_searchQuery" ile eşleşen oyuncu bulunamadı.',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: indexedUsers.length,
                  itemBuilder: (context, idx) {
                    final entry = indexedUsers[idx];
                    final int rank = entry['rank'] as int;
                    final data = entry['data'] as Map<String, dynamic>;
                    final String name = entry['name'] as String;
                    String? title = data['title']; // Lichess title

                    var pData = data['patron'];
                    bool isPatron = false;
                    if (pData is bool) {
                      isPatron = pData;
                    } else if (pData is String) {
                      isPatron = pData == 'true';
                    }

                    int score = data['score'] ?? 0;

                    if (name.toLowerCase() == 'termo_x') {
                      title = 'TermoGM';
                    }

                    final bool isMe = hasMyUser &&
                        name.toLowerCase() == _myUsername.toLowerCase();

                    Color rankColor = Colors.white54;
                    if (rank == 1) {
                      rankColor = const Color(0xFFFFD700); // Altın
                    } else if (rank == 2) {
                      rankColor = const Color(0xFFC0C0C0); // Gümüş
                    } else if (rank == 3) {
                      rankColor = const Color(0xFFCD7F32); // Bronz
                    }

                    return Card(
                      color: isMe
                          ? const Color(0xFF1B2540)
                          : const Color(0xFF151B2B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isMe
                              ? Colors.cyanAccent.withValues(alpha: 0.7)
                              : rankColor.withValues(alpha: 0.3),
                          width: isMe ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rankColor.withValues(alpha: 0.2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text('#$rank',
                                  style: TextStyle(
                                      color: rankColor,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildUserTags(title ?? '', isPatron),
                            Flexible(
                                child: Text(name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: isPatron
                                            ? Colors.orangeAccent
                                            : Colors.white,
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                        trailing: Text(
                            '$score ${LanguageService.get('puzzle_score_points')}',
                            style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        onTap: () {
                          if (name.toLowerCase() == 'misafir') return;
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      HomePage(initialUsername: name)),
                              (route) => false);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisPage extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final PlayerColor boardOrientation;
  final Map<String, String> apiHeaders;

  const AnalysisPage(
      {super.key,
      required this.matchData,
      required this.boardOrientation,
      required this.apiHeaders});

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
  List<String> _topEngineMoves = ['', '', ''];

  bool _isAnalyzing = false;
  bool _analysisDone = false;
  bool _isDisposed = false;
  bool _isSaved = false;
  double _whiteAccuracy = 0.0;
  double _blackAccuracy = 0.0;
  double _analysisProgress = 0.0;
  Timer? _engineDebounceTimer;

  Map<String, int> _whiteMoveStats = {
    'brilliant': 0,
    'great': 0,
    'best': 0,
    'excellent': 0,
    'good': 0,
    'inaccuracy': 0,
    'mistake': 0,
    'blunder': 0
  };
  Map<String, int> _blackMoveStats = {
    'brilliant': 0,
    'great': 0,
    'best': 0,
    'excellent': 0,
    'good': 0,
    'inaccuracy': 0,
    'mistake': 0,
    'blunder': 0
  };

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    _currentMoveIndex = 0;
    _currentOrientation = widget.boardOrientation;

    _isSaved = GlobalLibrary.isSaved(
        widget.matchData['pgn'] ?? '', widget.matchData['moves'] ?? '');

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
      String date =
          DateTime.now().toString().split(' ')[0].replaceAll('-', '.');
      pgn =
          '[Event "MoveLab Analiz"]\n[Site "MoveLab App"]\n[Date "$date"]\n[White "$white"]\n[Black "$black"]\n[Result "${widget.matchData['winner'] == 'white' ? '1-0' : widget.matchData['winner'] == 'black' ? '0-1' : '1/2-1/2'}"]\n\n';
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
      try {
        const platform = MethodChannel('com.movelab.app/share');
        await platform.invokeMethod('shareText', {
          'text':
              '$pgn\n\n📲 App: https://play.google.com/store/apps/details?id=com.movelab.app',
        });
      } catch (e) {
        debugPrint("PGN share error: $e");
      }
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
      setState(() {
        _isSaved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LanguageService.get('match_deleted')),
          backgroundColor: Colors.redAccent));
    } else {
      GlobalLibrary.matches.add(SavedMatch(
        title: '${widget.matchData['white']} vs ${widget.matchData['black']}',
        whiteName: widget.matchData['white'] ?? 'Beyaz',
        blackName: widget.matchData['black'] ?? 'Siyah',
        whiteTitle: widget.matchData['whiteTitle'] ?? '',
        blackTitle: widget.matchData['blackTitle'] ?? '',
        pgn: pgn,
        speed: widget.matchData['speed'] ?? 'PGN',
        moves: moves,
        winner: widget.matchData['winner'] ?? 'draw',
        userColor: widget.boardOrientation,
        whiteRating: widget.matchData['whiteRating'] ?? 0,
        blackRating: widget.matchData['blackRating'] ?? 0,
        platform: widget.matchData['platform'] ?? 'Bilinmiyor',
      ));
      setState(() {
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LanguageService.get('match_added')),
          backgroundColor: const Color(0xFF5C6BC0)));
    }
    GlobalLibrary.saveMatches();
  }

  void _generateAllFens() {
    _fenList = [];
    _allMoves = [];
    chess_engine.Chess chess = chess_engine.Chess();
    _fenList.add(chess.fen);

    String uciMoves = widget.matchData['moves'] ?? '';
    String pgn = widget.matchData['pgn'] ?? '';

    if (uciMoves.isNotEmpty) {
      for (String m in uciMoves.trim().split(RegExp(r'\s+'))) {
        if (m.isEmpty) continue;
        bool success = false;
        if (m.length >= 4) {
          Map<String, dynamic> moveData = {
            "from": m.substring(0, 2),
            "to": m.substring(2, 4)
          };
          if (m.length > 4)
            moveData["promotion"] = m.substring(4, 5).toLowerCase();
          success = chess.move(moveData);
        }
        if (!success) success = chess.move(m);
        if (success) {
          _fenList.add(chess.fen);
          _allMoves.add(m);
        }
      }
    } else {
      String cleaned = pgn.replaceAll('\n', ' ').replaceAll(
          RegExp(r'\[.*?\]|\{.*?\}|\([^)]*\)|(1-0|0-1|1/2-1/2|\*)|\d+\.+'),
          ' ');
      for (String san
          in cleaned.split(RegExp(r'\s+')).where((m) => m.isNotEmpty)) {
        if (chess.move(san)) {
          _fenList.add(chess.fen);
          _allMoves.add(san);
        }
      }
    }
  }

  void _startLiveEvaluationForCurrentMove() {
    int index = _currentMoveIndex;
    String fen = _fenList[index];

    if (fen == 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1') {
      if (mounted) {
        setState(() {
          _evaluationValue = 0.3;
          _evaluationText = "+0.3";
          _topEngineMoves = [
            'e2e4',
            'd2d4',
            'g1f3'
          ]; // Arayüzde sadece ilk 3 gösterilir
          _cachedValues[index] = 0.3;
          _cachedTexts[index] = "+0.3";
          _cachedSuggestions[index] = ['e2e4', 'd2d4', 'g1f3', 'c2c4', 'g2g3'];
        });
      }
      return;
    }

    ChessEngineService().startContinuousAnalysis(fen, (updateData) {
      if (!mounted || _currentMoveIndex != index || _isAnalyzing) return;

      double rawEval = updateData['best_eval'] ?? 0.0;
      bool isMate = updateData['is_mate'] ?? false;
      List<String> suggs =
          List<String>.from(updateData['suggestions'] ?? ['', '', '', '', '']);

      String evalTxt = isMate || rawEval.abs() > 14.0
          ? (rawEval > 0 ? '+M' : '-M')
          : (rawEval > 0
              ? '+${rawEval.toStringAsFixed(1)}'
              : rawEval.toStringAsFixed(1));

      for (int i = 0; i < 5; i++) {
        if (i >= suggs.length || suggs[i].isEmpty) suggs.add('-');
      }

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
      _topEngineMoves =
          _cachedSuggestions[_currentMoveIndex] ?? ['...', '...', '...'];
    } else {
      _evaluationText = LanguageService.get('analyzing');
      _topEngineMoves = ['...', '...', '...'];
    }

    setState(() {});

    if (!_isAnalyzing) {
      ChessEngineService().stopContinuousAnalysis();
      _engineDebounceTimer?.cancel();
      _engineDebounceTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          _startLiveEvaluationForCurrentMove();
        }
      });
    }
  }

  void _playEngineMove(String moveStr) {
    if (moveStr == '-' || moveStr == '...' || moveStr.length < 4) return;
    chess_engine.Chess chess = chess_engine.Chess();
    chess.load(_fenList[_currentMoveIndex]);

    Map<String, dynamic> moveData = {
      "from": moveStr.substring(0, 2),
      "to": moveStr.substring(2, 4)
    };
    if (moveStr.length > 4)
      moveData["promotion"] = moveStr.substring(4, 5).toLowerCase();

    if (chess.move(moveData)) {
      if (_currentMoveIndex + 1 < _fenList.length &&
          chess.fen == _fenList[_currentMoveIndex + 1]) {
        _goToMove(_currentMoveIndex + 1);
        return;
      }

      if (_currentMoveIndex + 1 < _fenList.length) {
        controller.loadFen(chess.fen);
        setState(() {
          _evaluationText = LanguageService.get('analyzing');
          _topEngineMoves = ['...', '...', '...'];
        });
        ChessEngineService().stopContinuousAnalysis();
        ChessEngineService().startContinuousAnalysis(chess.fen, (updateData) {
          if (!mounted || _isAnalyzing) return;
          double rawEval = updateData['best_eval'] ?? 0.0;
          bool isMate = updateData['is_mate'] ?? false;
          List<String> suggs = List<String>.from(
              updateData['suggestions'] ?? ['', '', '', '', '']);
          String evalTxt = isMate || rawEval.abs() > 14.0
              ? (rawEval > 0 ? '+M' : '-M')
              : (rawEval > 0
                  ? '+${rawEval.toStringAsFixed(1)}'
                  : rawEval.toStringAsFixed(1));
          for (int i = 0; i < 5; i++) {
            if (i >= suggs.length || suggs[i].isEmpty) suggs.add('-');
          }
          setState(() {
            _evaluationValue = rawEval;
            _evaluationText = evalTxt;
            _topEngineMoves = suggs.take(3).toList();
          });
        });
        return;
      }

      setState(() {
        _fenList.add(chess.fen);
        _allMoves.add(moveStr);
        _analysisDone = false;
      });
      _goToMove(_currentMoveIndex + 1);
    }
  }

  Widget _buildAnnotatedBoard() {
    bool shouldShowArrow = SoundService.showArrows &&
        _topEngineMoves[0].length >= 4 &&
        _topEngineMoves[0] != '...';
    String fromSquare =
        shouldShowArrow ? _topEngineMoves[0].substring(0, 2) : '';
    String toSquare = shouldShowArrow ? _topEngineMoves[0].substring(2, 4) : '';

    String? targetSquare;
    String? evalSymbol;
    Color? evalColor;

    if (_currentMoveIndex > 0 && _currentMoveIndex - 1 < _allMoves.length) {
      String san = _allMoves[_currentMoveIndex - 1];
      String fen = _fenList[_currentMoveIndex - 1];
      bool isWhite = fen.split(' ')[1] == 'w';

      String cleanSan = san.replaceAll(RegExp(r'[+#!\?]'), '');
      if (cleanSan == 'O-O') {
        targetSquare = isWhite ? 'g1' : 'g8';
      } else if (cleanSan == 'O-O-O') {
        targetSquare = isWhite ? 'c1' : 'c8';
      } else {
        final match = RegExp(r'[a-h][1-8]').allMatches(cleanSan);
        if (match.isNotEmpty) {
          targetSquare = match.last.group(0);
        }
      }

      var analysis = _moveAnalyses[_currentMoveIndex - 1];
      if (analysis != null) {
        evalSymbol = NagHelper.getNagSymbol(analysis.qualityLabel,
            isBrilliant: analysis.isBrilliant, isGreat: analysis.isGreat);
        if (evalSymbol.isNotEmpty) {
          evalColor = NagHelper.getNagColor(evalSymbol);
        } else {
          evalSymbol = null;
        }
      }
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ChessBoard(
              controller: controller,
              boardColor: BoardThemeService.boardColor,
              boardOrientation: _currentOrientation,
            ),
          ),
          if (shouldShowArrow)
            Positioned.fill(
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
          if (targetSquare != null && evalSymbol != null)
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final squareSize = constraints.maxWidth / 8;
                    int file = targetSquare!.codeUnitAt(0) - 'a'.codeUnitAt(0);
                    int rank = targetSquare.codeUnitAt(1) - '1'.codeUnitAt(0);

                    if (_currentOrientation == PlayerColor.white) {
                      rank = 7 - rank;
                    } else {
                      file = 7 - file;
                    }

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: file * squareSize + squareSize * 0.65,
                          top: rank * squareSize - squareSize * 0.15,
                          child: Container(
                            constraints: const BoxConstraints(
                                minWidth: 22, minHeight: 22),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                                color: evalColor,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]),
                            child: Text(
                              evalSymbol!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  height: 1.1),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToMove(int index) {
    if (index < 0 || index >= _fenList.length) {
      return;
    }

    if (index > 0 && index - 1 < _allMoves.length) {
      bool isCapture = _allMoves[index - 1].contains('x');
      SoundService.playMoveSound(isCapture);
    } else if (index == 0) {
      SoundService.playMoveSound(false);
    }

    setState(() {
      _currentMoveIndex = index;
    });
    _loadBoardToCurrentIndex();
  }

  Future<void> _runInlineAnalysis() async {
    if (_isAnalyzing) return;

    ChessEngineService().stopContinuousAnalysis();
    setState(() {
      _isAnalyzing = true;
      _analysisDone = false;
      _analysisProgress = 0.0;
    });

    try {
      List<int> missingIndices = [];
      for (int i = 0; i < _fenList.length; i++) {
        if (!_cachedValues.containsKey(i)) missingIndices.add(i);
      }

      for (int i = 0; i < missingIndices.length; i++) {
        if (!mounted || _isDisposed) break;
        int index = missingIndices[i];

        try {
          await _fetchSingleEvalToCache(index,
              depth: 20, maxTimeMs: 600, force: true);
        } catch (e) {
          debugPrint("Motor bir hamleyi atladı: $e");
        }

        if (mounted)
          setState(() {
            _analysisProgress =
                (i + 1) / (missingIndices.isEmpty ? 1 : missingIndices.length);
          });
      }

      _fillAllMissingEvaluations();
      _computeAccuracyAndCategories();

      if (mounted)
        setState(() {
          _analysisDone = true;
        });
    } catch (e) {
      debugPrint("Kritik Analiz Hatası: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageScrollController.hasClients) {
            _pageScrollController.animateTo(
                _pageScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic);
          }
        });
        _startLiveEvaluationForCurrentMove();
      }
    }
  }

  Future<void> _fetchSingleEvalToCache(int index,
      {int depth = 20, int maxTimeMs = 600, bool force = false}) async {
    if (index >= _fenList.length ||
        (!force && _cachedValues.containsKey(index))) {
      return;
    }

    if (_fenList[index] ==
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1') {
      _cachedValues[index] = 0.3;
      _cachedTexts[index] = "+0.3";
      _cachedSuggestions[index] = ['e2e4', 'd2d4', 'g1f3', 'c2c4', 'g2g3'];
      _alternativeMoveEvals[index] = [0.3, 0.3, 0.3, 0.3, 0.3];
      if (_currentMoveIndex == index && mounted)
        setState(() {
          _evaluationValue = 0.3;
          _evaluationText = "+0.3";
          _topEngineMoves = _cachedSuggestions[index]!.take(3).toList();
        });
      return;
    }

    chess_engine.Chess chessCheck = chess_engine.Chess();
    chessCheck.load(_fenList[index]);

    if (chessCheck.in_checkmate) {
      bool isWhiteTurn = _fenList[index].split(' ')[1] == 'w';
      double val = isWhiteTurn ? -15.0 : 15.0;
      _cachedValues[index] = val;
      _cachedTexts[index] = isWhiteTurn ? "-M" : "+M";
      _cachedSuggestions[index] = ['#', '#', '#', '#', '#'];
      _alternativeMoveEvals[index] = [val, val, val, val, val];
      if (_currentMoveIndex == index && mounted)
        setState(() {
          _evaluationValue = val;
          _evaluationText = _cachedTexts[index]!;
          _topEngineMoves = ['#', '#', '#'];
        });
      return;
    } else if (chessCheck.in_draw ||
        chessCheck.in_stalemate ||
        chessCheck.in_threefold_repetition ||
        chessCheck.insufficient_material) {
      _cachedValues[index] = 0.0;
      _cachedTexts[index] = "0.0";
      _cachedSuggestions[index] = ['=', '=', '=', '=', '='];
      _alternativeMoveEvals[index] = [0.0, 0.0, 0.0, 0.0, 0.0];
      if (_currentMoveIndex == index && mounted)
        setState(() {
          _evaluationValue = 0.0;
          _evaluationText = "0.0";
          _topEngineMoves = ['=', '=', '='];
        });
      return;
    }

    var engineData = await ChessEngineService()
        .evaluateFen(_fenList[index], depth: depth, maxTimeMs: maxTimeMs);

    double val = engineData['best_eval'] ?? 0.0;
    bool isMate = engineData['is_mate'] ?? false;
    _alternativeMoveEvals[index] =
        engineData['alternatives'] ?? <double>[0.0, 0.0, 0.0, 0.0, 0.0];

    List<String> suggs =
        List<String>.from(engineData['suggestions'] ?? ['', '', '', '', '']);
    for (int i = 0; i < 5; i++) {
      if (i >= suggs.length || suggs[i].isEmpty) suggs.add('-');
    }
    String txt = isMate || val.abs() > 14.0
        ? (val > 0 ? '+M' : '-M')
        : (val > 0 ? '+${val.toStringAsFixed(1)}' : val.toStringAsFixed(1));

    _cachedValues[index] = val;
    _cachedTexts[index] = txt;
    _cachedSuggestions[index] = suggs;
    if (_currentMoveIndex == index && mounted)
      setState(() {
        _evaluationValue = val;
        _evaluationText = txt;
        _topEngineMoves = suggs.take(3).toList();
      });
  }

  void _fillAllMissingEvaluations() {
    for (int i = 0; i < _fenList.length; i++) {
      if (!_cachedValues.containsKey(i)) _cachedValues[i] = 0.0;
      if (!_cachedTexts.containsKey(i)) _cachedTexts[i] = "0.0";
      if (!_cachedSuggestions.containsKey(i))
        _cachedSuggestions[i] = ['...', '...', '...', '...', '...'];
      if (!_alternativeMoveEvals.containsKey(i))
        _alternativeMoveEvals[i] = [0.0, 0.0, 0.0, 0.0, 0.0];
    }
  }

  void _computeAccuracyAndCategories() {
    _whiteMoveStats = {
      'brilliant': 0,
      'great': 0,
      'best': 0,
      'excellent': 0,
      'good': 0,
      'inaccuracy': 0,
      'mistake': 0,
      'blunder': 0
    };
    _blackMoveStats = {
      'brilliant': 0,
      'great': 0,
      'best': 0,
      'excellent': 0,
      'good': 0,
      'inaccuracy': 0,
      'mistake': 0,
      'blunder': 0
    };

    double whiteWeightedAccTotal = 0,
        blackWeightedAccTotal = 0,
        whiteWeightSum = 0,
        blackWeightSum = 0;

    for (int i = 0; i < _fenList.length - 1; i++) {
      double bestEval = _cachedValues[i]!.clamp(-15.0, 15.0);
      double playedEval = _cachedValues[i + 1]!.clamp(-15.0, 15.0);
      bool isWhiteMove = _fenList[i].split(' ')[1] == 'w';
      bool isBeforeMate = _cachedTexts[i]?.contains('M') ?? false;
      bool isAfterMate = _cachedTexts[i + 1]?.contains('M') ?? false;

      double accuracy = AccuracyCalculator.calculateMoveAccuracy(
          bestEval, playedEval, isWhiteMove, isBeforeMate, isAfterMate);

      int sacType = TacticalDetector.detectSacrificeType(
          i, _fenList, isWhiteMove, playedEval, bestEval);
      List<double> alts = _alternativeMoveEvals[i] ?? <double>[];
      bool isMateFound =
          _cachedTexts[i + 1]!.contains('M') || playedEval.abs() > 14.0;

      String qualityLabel = AdvancedClassifier.classifyMove(
          bestEval: bestEval,
          playedEval: playedEval,
          accuracy: accuracy,
          alternatives: alts,
          isWhiteMove: isWhiteMove,
          isMateFound: isMateFound,
          sacrificeType: sacType);

      bool isBrill = qualityLabel == "Etkileyici Hamle";
      bool isGt = qualityLabel == "Harika Hamle";

      _moveAnalyses[i] = MoveAnalysis(
          bestEval: bestEval,
          playedEval: playedEval,
          accuracy: accuracy,
          qualityLabel: qualityLabel,
          isBrilliant: isBrill,
          isGreat: isGt);
      double weight = AnalysisPhaseWeight.getWeight(i);

      var targetStats = isWhiteMove ? _whiteMoveStats : _blackMoveStats;
      if (isWhiteMove) {
        whiteWeightedAccTotal += accuracy * weight;
        whiteWeightSum += weight;
      } else {
        blackWeightedAccTotal += accuracy * weight;
        blackWeightSum += weight;
      }

      if (isBrill) {
        targetStats['brilliant'] = targetStats['brilliant']! + 1;
      } else if (isGt)
        targetStats['great'] = targetStats['great']! + 1;
      else if (qualityLabel == "En İyi Hamle")
        targetStats['best'] = targetStats['best']! + 1;
      else if (qualityLabel == "Mükemmel")
        targetStats['excellent'] = targetStats['excellent']! + 1;
      else if (qualityLabel == "İyi Hamle")
        targetStats['good'] = targetStats['good']! + 1;
      else if (qualityLabel == "Şüpheli Hamle")
        targetStats['inaccuracy'] = targetStats['inaccuracy']! + 1;
      else if (qualityLabel == "Kötü Hamle")
        targetStats['mistake'] = targetStats['mistake']! + 1;
      else
        targetStats['blunder'] = targetStats['blunder']! + 1;
    }
    _whiteAccuracy =
        whiteWeightSum > 0 ? whiteWeightedAccTotal / whiteWeightSum : 100.0;
    _blackAccuracy =
        blackWeightSum > 0 ? blackWeightedAccTotal / blackWeightSum : 100.0;
  }

  @override
  Widget build(BuildContext context) {
    double whitePercentage = 0.5 + (_evaluationValue / 10.0);
    if (whitePercentage < 0.05) {
      whitePercentage = 0.05;
    }
    if (whitePercentage > 0.95) {
      whitePercentage = 0.95;
    }

    String whiteName =
        widget.matchData['white'] ?? LanguageService.get('player');
    String blackName =
        widget.matchData['black'] ?? LanguageService.get('player');
    String whiteTitle = widget.matchData['whiteTitle'] ?? '';
    String blackTitle = widget.matchData['blackTitle'] ?? '';
    int whiteRating = widget.matchData['whiteRating'] ?? 0;
    int blackRating = widget.matchData['blackRating'] ?? 0;

    String topName =
        _currentOrientation == PlayerColor.white ? blackName : whiteName;
    String topTitle =
        _currentOrientation == PlayerColor.white ? blackTitle : whiteTitle;
    String topRating = _currentOrientation == PlayerColor.white
        ? (blackRating > 0 ? blackRating.toString() : '?')
        : (whiteRating > 0 ? whiteRating.toString() : '?');

    String bottomName =
        _currentOrientation == PlayerColor.white ? whiteName : blackName;
    String bottomTitle =
        _currentOrientation == PlayerColor.white ? whiteTitle : blackTitle;
    String bottomRating = _currentOrientation == PlayerColor.white
        ? (whiteRating > 0 ? whiteRating.toString() : '?')
        : (blackRating > 0 ? blackRating.toString() : '?');

    Color whiteAccuracyColor = _whiteAccuracy < _blackAccuracy
        ? Colors.orangeAccent
        : Colors.greenAccent;
    Color blackAccuracyColor = _whiteAccuracy < _blackAccuracy
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(LanguageService.get('analysis_laboratory'),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        backgroundColor: const Color(0xFF151B2B),
        actions: [
          IconButton(
            icon: Icon(Icons.explore,
                color: LichessWidgets.showOpeningExplorer
                    ? Colors.blueAccent
                    : Colors.white38),
            tooltip: LanguageService.get('toggle_explorer'),
            onPressed: () => setState(() {
              LichessWidgets.showOpeningExplorer =
                  !LichessWidgets.showOpeningExplorer;
            }),
          ),
          IconButton(
              icon: const Icon(Icons.swap_vert, color: Colors.white70),
              tooltip: LanguageService.get('rotate_board'),
              onPressed: () {
                setState(() {
                  _currentOrientation = _currentOrientation == PlayerColor.white
                      ? PlayerColor.black
                      : PlayerColor.white;
                });
              }),
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              tooltip: LanguageService.get('settings'),
              onPressed: () =>
                  showSettingsSheet(context, onChanged: () => setState(() {}))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1E2536),
            onSelected: (val) {
              if (val == 'share') {
                _sharePgn();
              } else if (val == 'save') _toggleLibrary();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(LanguageService.get('share_pgn'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(_isSaved ? Icons.check_circle : Icons.library_add,
                        color: _isSaved ? Colors.greenAccent : Colors.white70,
                        size: 20),
                    const SizedBox(width: 12),
                    Text(
                        _isSaved
                            ? LanguageService.get('remove_from_library')
                            : LanguageService.get('save_to_library'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
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
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.analytics, size: 20),
                  label: Text(
                      _isAnalyzing
                          ? '${LanguageService.get('analyzing')} %${(_analysisProgress * 100).toInt()}'
                          : LanguageService.get('analyze_match'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnalyzing
                          ? Colors.orange.shade700
                          : const Color(0xFF283593),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _isAnalyzing ? null : _runInlineAnalysis,
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4)),
                          child: Icon(Icons.person,
                              color: Colors.grey[400], size: 16)),
                      const SizedBox(width: 8),
                      if (topTitle.isNotEmpty) buildTitleTag(topTitle),
                      Text(topName,
                          style: TextStyle(
                              color: Colors.grey[300],
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('($topRating)',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13))
                    ]))),
            const SizedBox(height: 6),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildAnnotatedBoard()),
            const SizedBox(height: 6),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 16)),
                      const SizedBox(width: 8),
                      if (bottomTitle.isNotEmpty) buildTitleTag(bottomTitle),
                      Text(bottomName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('($bottomRating)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13))
                    ]))),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: const Color(0xFF151B2B),
                            borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(children: [
                            AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                height: 14,
                                width: constraints.maxWidth * whitePercentage,
                                color: Colors.white)
                          ]),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutQuint,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Colors.white),
                          child: Text(
                              "${LanguageService.get('analysis_engine')}: $_evaluationText")),
                      if (_analysisDone &&
                          _currentMoveIndex > 0 &&
                          _moveAnalyses.containsKey(_currentMoveIndex - 1))
                        Builder(builder: (context) {
                          var analysis = _moveAnalyses[_currentMoveIndex - 1]!;
                          String symbol = NagHelper.getNagSymbol(
                              analysis.qualityLabel,
                              isBrilliant: analysis.isBrilliant,
                              isGreat: analysis.isGreat);
                          Color bgColor;
                          if (symbol.isNotEmpty) {
                            bgColor = NagHelper.getNagColor(symbol);
                          } else if (analysis.accuracy >= 99.2) {
                            bgColor = Colors.green;
                          } else if (analysis.accuracy >= 88.0) {
                            bgColor = const Color(0xFFAED581);
                          } else {
                            bgColor = Colors.orange;
                          }
                          String icon = symbol.isNotEmpty ? " $symbol" : "";
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: bgColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: bgColor.withValues(alpha: 0.5))),
                            child: Text(
                                "${LanguageService.displayQualityLabel(analysis.qualityLabel)}$icon",
                                style: TextStyle(
                                    color: bgColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          );
                        })
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFF111826),
                  borderRadius: BorderRadius.circular(28),
                  border:
                      Border.all(color: const Color(0xFF1E2A46), width: 1.2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                      color: _currentMoveIndex > 0
                          ? const Color(0xFF1F2D4B)
                          : const Color(0xFF0D1422),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap:
                              _currentMoveIndex > 0 ? () => _goToMove(0) : null,
                          child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.fast_rewind,
                                  size: 18,
                                  color: _currentMoveIndex > 0
                                      ? const Color(0xFF8BD1FF)
                                      : const Color(0xFF4A5D7E))))),
                  const SizedBox(width: 4),
                  Material(
                      color: _currentMoveIndex > 0
                          ? const Color(0xFF1F2D4B)
                          : const Color(0xFF0D1422),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _currentMoveIndex > 0
                              ? () => _goToMove(_currentMoveIndex - 1)
                              : null,
                          child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.arrow_back_ios_new,
                                  size: 18,
                                  color: _currentMoveIndex > 0
                                      ? const Color(0xFF8BD1FF)
                                      : const Color(0xFF4A5D7E))))),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF0B1422),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: const Color(0xFF1E2A46), width: 1)),
                      child: Text(
                          "$_currentMoveIndex / ${_fenList.isNotEmpty ? _fenList.length - 1 : 0}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8BD1FF),
                              fontSize: 12))),
                  const SizedBox(width: 4),
                  Material(
                      color: _currentMoveIndex < _fenList.length - 1
                          ? const Color(0xFF1F2D4B)
                          : const Color(0xFF0D1422),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _currentMoveIndex < _fenList.length - 1
                              ? () => _goToMove(_currentMoveIndex + 1)
                              : null,
                          child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.arrow_forward_ios,
                                  size: 18,
                                  color: _currentMoveIndex < _fenList.length - 1
                                      ? const Color(0xFF8BD1FF)
                                      : const Color(0xFF4A5D7E))))),
                  const SizedBox(width: 4),
                  Material(
                      color: _currentMoveIndex < _fenList.length - 1
                          ? const Color(0xFF1F2D4B)
                          : const Color(0xFF0D1422),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _currentMoveIndex < _fenList.length - 1
                              ? () => _goToMove(_fenList.length - 1)
                              : null,
                          child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.fast_forward,
                                  size: 18,
                                  color: _currentMoveIndex < _fenList.length - 1
                                      ? const Color(0xFF8BD1FF)
                                      : const Color(0xFF4A5D7E))))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _playEngineMove(_topEngineMoves[0]),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0xFF0B1422),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF1E2A46), width: 1)),
                        child: Row(children: [
                          Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF1F2D4B),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Center(
                                  child: Text("1",
                                      style: TextStyle(
                                          color: Color(0xFF8BD1FF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  _topEngineMoves[0].isNotEmpty
                                      ? NotationHelper.formatUciToSan(
                                          _topEngineMoves[0],
                                          _fenList.isNotEmpty &&
                                                  _currentMoveIndex <
                                                      _fenList.length
                                              ? _fenList[_currentMoveIndex]
                                              : '')
                                      : '-',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)))
                        ])),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _playEngineMove(_topEngineMoves[1]),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0xFF0B1422),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF1E2A46), width: 1)),
                        child: Row(children: [
                          Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF1F2D4B),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Center(
                                  child: Text("2",
                                      style: TextStyle(
                                          color: Color(0xFF8BD1FF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  _topEngineMoves[1].isNotEmpty
                                      ? NotationHelper.formatUciToSan(
                                          _topEngineMoves[1],
                                          _fenList.isNotEmpty &&
                                                  _currentMoveIndex <
                                                      _fenList.length
                                              ? _fenList[_currentMoveIndex]
                                              : '')
                                      : '-',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)))
                        ])),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _playEngineMove(_topEngineMoves[2]),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0xFF0B1422),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF1E2A46), width: 1)),
                        child: Row(children: [
                          Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF1F2D4B),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Center(
                                  child: Text("3",
                                      style: TextStyle(
                                          color: Color(0xFF8BD1FF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  _topEngineMoves[2].isNotEmpty
                                      ? NotationHelper.formatUciToSan(
                                          _topEngineMoves[2],
                                          _fenList.isNotEmpty &&
                                                  _currentMoveIndex <
                                                      _fenList.length
                                              ? _fenList[_currentMoveIndex]
                                              : '')
                                      : '-',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)))
                        ])),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            if (_fenList.isNotEmpty && _currentMoveIndex < _fenList.length) ...[
              LichessWidgets.buildSyzygyPanel(
                  _fenList[_currentMoveIndex], _playEngineMove),
              LichessWidgets.buildOpeningExplorerPanel(
                  _fenList[_currentMoveIndex], _playEngineMove),
              const SizedBox(height: 15),
            ],
            if (_analysisDone)
              AnimatedOpacity(
                opacity: _analysisDone ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF151B2B),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color:
                              const Color(0xFF5C6BC0).withValues(alpha: 0.3))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Column(children: [
                            Text(whiteName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: whiteAccuracyColor.withValues(
                                        alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: whiteAccuracyColor.withValues(
                                            alpha: 0.4))),
                                child: Text(
                                    '%${_whiteAccuracy.toStringAsFixed(1)}',
                                    style: TextStyle(
                                        color: whiteAccuracyColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)))
                          ])),
                          Container(
                              width: 1, height: 50, color: Colors.white12),
                          Expanded(
                              child: Column(children: [
                            Text(blackName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.grey[300]),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: blackAccuracyColor.withValues(
                                        alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: blackAccuracyColor.withValues(
                                            alpha: 0.4))),
                                child: Text(
                                    '%${_blackAccuracy.toStringAsFixed(1)}',
                                    style: TextStyle(
                                        color: blackAccuracyColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)))
                          ])),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Text(LanguageService.get('move_quality_distribution'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
                              letterSpacing: 1)),
                      const Divider(height: 20, color: Colors.white12),
                      _buildStatRow(
                          LanguageService.get('brilliant_move'),
                          _whiteMoveStats['brilliant']!,
                          _blackMoveStats['brilliant']!,
                          Colors.cyanAccent,
                          onTap: () => _goToCategoryMove('brilliant')),
                      _buildStatRow(
                          LanguageService.get('great_move'),
                          _whiteMoveStats['great']!,
                          _blackMoveStats['great']!,
                          const Color(0xFF64FFDA),
                          onTap: () => _goToCategoryMove('great')),
                      _buildStatRow(
                          LanguageService.get('best_move'),
                          _whiteMoveStats['best']!,
                          _blackMoveStats['best']!,
                          Colors.greenAccent,
                          onTap: () => _goToCategoryMove('best')),
                      _buildStatRow(
                          LanguageService.get('excellent_move'),
                          _whiteMoveStats['excellent']!,
                          _blackMoveStats['excellent']!,
                          Colors.lightGreen,
                          onTap: () => _goToCategoryMove('excellent')),
                      _buildStatRow(
                          LanguageService.get('good_move'),
                          _whiteMoveStats['good']!,
                          _blackMoveStats['good']!,
                          const Color(0xFFAED581),
                          onTap: () => _goToCategoryMove('good')),
                      _buildStatRow(
                          LanguageService.get('inaccuracy_move'),
                          _whiteMoveStats['inaccuracy']!,
                          _blackMoveStats['inaccuracy']!,
                          Colors.amberAccent,
                          onTap: () => _goToCategoryMove('inaccuracy')),
                      _buildStatRow(
                          LanguageService.get('mistake_move'),
                          _whiteMoveStats['mistake']!,
                          _blackMoveStats['mistake']!,
                          Colors.orangeAccent,
                          onTap: () => _goToCategoryMove('mistake')),
                      _buildStatRow(
                          LanguageService.get('blunder_move'),
                          _whiteMoveStats['blunder']!,
                          _blackMoveStats['blunder']!,
                          Colors.redAccent,
                          onTap: () => _goToCategoryMove('blunder')),
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
      if (category == 'brilliant' && analysis.isBrilliant) {
        matches.add(index);
      } else if (category == 'great' && analysis.isGreat) {
        matches.add(index);
      } else if (category == 'best' &&
          analysis.qualityLabel == 'En İyi Hamle') {
        matches.add(index);
      } else if (category == 'excellent' &&
          analysis.qualityLabel == 'Mükemmel') {
        matches.add(index);
      } else if (category == 'good' && analysis.qualityLabel == 'İyi Hamle') {
        matches.add(index);
      } else if (category == 'inaccuracy' &&
          analysis.qualityLabel == 'Şüpheli Hamle') {
        matches.add(index);
      } else if (category == 'mistake' &&
          analysis.qualityLabel == 'Kötü Hamle') {
        matches.add(index);
      } else if (category == 'blunder' &&
          analysis.qualityLabel == 'Çok Kötü Hamle') {
        matches.add(index);
      }
    });

    if (matches.isEmpty) {
      _showCategorySnackBar(category, false);
      return;
    }
    matches.sort();
    int currentBaseIndex = _currentMoveIndex - 1;
    int? nextMatch;
    for (var matchIndex in matches) {
      if (matchIndex > currentBaseIndex) {
        nextMatch = matchIndex;
        break;
      }
    }
    nextMatch ??= matches.first;
    int targetIndex = min(nextMatch + 1, _fenList.length - 1);
    String notation = "";
    if (nextMatch >= 0 && nextMatch < _allMoves.length) {
      notation = _allMoves[nextMatch];
    }

    _goToMove(targetIndex);
    _showCategorySnackBar(category, true, notation: notation);
  }

  void _showCategorySnackBar(String category, bool found, {String? notation}) {
    String categoryLabel = category == 'brilliant'
        ? 'Etkileyici'
        : category == 'great'
            ? 'Harika'
            : category == 'best'
                ? 'En İyi'
                : category == 'excellent'
                    ? 'Mükemmel'
                    : category == 'good'
                        ? 'İyi'
                        : category == 'inaccuracy'
                            ? 'Şüpheli'
                            : category == 'mistake'
                                ? 'Kötü'
                                : 'Çok Kötü';
    String contentMessage = found
        ? '$categoryLabel hamleye gidildi.${notation != null && notation.isNotEmpty ? ' ($notation)' : ''}'
        : '$categoryLabel hamle bulunamadı.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(contentMessage), duration: const Duration(seconds: 2)));
  }

  Widget _buildStatRow(
      String label, int whiteCount, int blackCount, Color badgeColor,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(whiteCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14))),
            Container(
                width: 140,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: badgeColor.withValues(alpha: 0.25))),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))),
            Expanded(
                child: Text(blackCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class MoveNode {
  final String fen;
  final String san;
  final String uci;
  final MoveNode? parent;
  final List<MoveNode> children;
  String? nag;

  MoveNode({
    required this.fen,
    this.san = '',
    this.uci = '',
    this.parent,
    this.nag,
    List<MoveNode>? children,
  }) : children = children ?? [];

  List<MoveNode> getPathFromRoot() {
    List<MoveNode> path = [];
    MoveNode? curr = this;
    while (curr != null) {
      path.insert(0, curr);
      curr = curr.parent;
    }
    return path;
  }
}

class FreeAnalysisPage extends StatefulWidget {
  const FreeAnalysisPage({super.key});

  @override
  State<FreeAnalysisPage> createState() => _FreeAnalysisPageState();
}

class _FreeAnalysisPageState extends State<FreeAnalysisPage> {
  late ChessBoardController controller;
  final ScrollController _pageScrollController = ScrollController();
  PlayerColor _boardOrientation = PlayerColor.white;

  late MoveNode _rootNode;
  late MoveNode _currentNode;
  List<String> _fenList = [];
  List<String> _allMoves = [];
  int _currentMoveIndex = 0;

  double _evaluationValue = 0.3;
  String _evaluationText = "+0.3";
  List<String> _topEngineMoves = ['', '', ''];
  List<double> _multiPvEvals = [0.3, 0.2, 0.1];
  List<String> _multiPvLines = ['', '', ''];
  List<bool> _multiPvMates = [false, false, false];
  int _engineDepth = 0;
  Timer? _engineDebounceTimer;

  bool _isSetupMode = false;
  String _selectedSetupPiece = 'P';
  String _setupTurn = 'w';
  bool _setupCastlingK = true;
  bool _setupCastlingQ = true;
  bool _setupCastlingk = true;
  bool _setupCastlingq = true;

  String? _selectedSquare;
  List<String> _legalDestinations = [];

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    ChessEngineService().initEngine();
    controller.addListener(_onBoardChange);
    _initBoard();
  }

  void _playEngineMove(String uci) {
    if (uci.isEmpty || uci.length < 4 || uci == '...') return;
    String from = uci.substring(0, 2);
    String to = uci.substring(2, 4);
    if (uci.length == 5) {
      controller.makeMoveWithPromotion(
          from: from, to: to, pieceToPromoteTo: uci.substring(4, 5));
    } else {
      controller.makeMove(from: from, to: to);
    }
  }

  void _syncPathList() {
    final path = _currentNode.getPathFromRoot();
    _fenList = path.map((n) => n.fen).toList();
    _allMoves = path.where((n) => n.parent != null).map((n) => n.san).toList();
    _currentMoveIndex = path.length - 1;
  }

  void _goToNode(MoveNode node) {
    controller.removeListener(_onBoardChange);
    setState(() {
      _currentNode = node;
      _syncPathList();
      _selectedSquare = null;
      _legalDestinations.clear();
    });
    controller.loadFen(node.fen);
    _startEvaluation();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) controller.addListener(_onBoardChange);
    });
  }

  void _initBoard() {
    _rootNode = MoveNode(fen: controller.game.fen);
    _currentNode = _rootNode;
    _syncPathList();
    _startEvaluation();
  }

  void _toggleSetupMode() {
    setState(() {
      _isSetupMode = !_isSetupMode;
      if (_isSetupMode) {
        controller.removeListener(_onBoardChange);
        ChessEngineService().stopEngine();
        _selectedSquare = null;
        _legalDestinations.clear();

        List<String> parts = controller.game.fen.split(' ');
        if (parts.length > 1) _setupTurn = parts[1];
        if (parts.length > 2) {
          _setupCastlingK = parts[2].contains('K');
          _setupCastlingQ = parts[2].contains('Q');
          _setupCastlingk = parts[2].contains('k');
          _setupCastlingq = parts[2].contains('q');
        }
      } else {
        _applySetupAndStartAnalysis();
      }
    });
  }

  String _modifyFenSquare(String fen, String square, String pieceChar) {
    if ((pieceChar == 'P' || pieceChar == 'p') &&
        (square.endsWith('1') || square.endsWith('8'))) {
      return fen;
    }
    List<String> parts = fen.split(' ');
    String boardPart = parts[0];
    List<String> ranks = boardPart.split('/');

    List<List<String>> board = [];
    for (String r in ranks) {
      List<String> row = [];
      for (int i = 0; i < r.length; i++) {
        String c = r[i];
        if (int.tryParse(c) != null) {
          int emptyCount = int.parse(c);
          for (int e = 0; e < emptyCount; e++) {
            row.add('');
          }
        } else {
          row.add(c);
        }
      }
      board.add(row);
    }

    int fileIdx = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rankIdx = 8 - int.parse(square[1]);

    if (pieceChar == '_delete_') {
      if (board[rankIdx][fileIdx] == 'K' || board[rankIdx][fileIdx] == 'k') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(LanguageService.get('king_delete_error')),
              duration: const Duration(seconds: 1)),
        );
        return fen;
      }
      board[rankIdx][fileIdx] = '';
    } else if (board[rankIdx][fileIdx] == pieceChar) {
      if (pieceChar == 'K' || pieceChar == 'k') {
        return fen;
      }
      board[rankIdx][fileIdx] = '';
    } else {
      if (pieceChar == 'K' || pieceChar == 'k') {
        for (int r = 0; r < 8; r++) {
          for (int f = 0; f < 8; f++) {
            if (board[r][f] == pieceChar) board[r][f] = '';
          }
        }
      }
      board[rankIdx][fileIdx] = pieceChar;
    }

    if (board[7][4] != 'K' || board[7][7] != 'R') _setupCastlingK = false;
    if (board[7][4] != 'K' || board[7][0] != 'R') _setupCastlingQ = false;
    if (board[0][4] != 'k' || board[0][7] != 'r') _setupCastlingk = false;
    if (board[0][4] != 'k' || board[0][0] != 'r') _setupCastlingq = false;

    List<String> newRanks = [];
    for (List<String> row in board) {
      StringBuffer newRank = StringBuffer();
      int emptyCount = 0;
      for (String sq in row) {
        if (sq.isEmpty) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            newRank.write(emptyCount);
            emptyCount = 0;
          }
          newRank.write(sq);
        }
      }
      if (emptyCount > 0) newRank.write(emptyCount);
      newRanks.add(newRank.toString());
    }

    parts[0] = newRanks.join('/');
    return parts.join(' ');
  }

  void _updateAndApplySetupFen(
      {String? newBoardPart,
      String? newTurn,
      bool resetCastling = false,
      bool clearCastling = false}) {
    String currentFen = controller.game.fen;
    List<String> parts = currentFen.split(' ');

    String boardPart = newBoardPart ?? parts[0];
    if (newTurn != null) _setupTurn = newTurn;
    if (resetCastling) {
      _setupCastlingK = true;
      _setupCastlingQ = true;
      _setupCastlingk = true;
      _setupCastlingq = true;
    }
    if (clearCastling) {
      _setupCastlingK = false;
      _setupCastlingQ = false;
      _setupCastlingk = false;
      _setupCastlingq = false;
    }

    StringBuffer castling = StringBuffer();
    if (_setupCastlingK) castling.write('K');
    if (_setupCastlingQ) castling.write('Q');
    if (_setupCastlingk) castling.write('k');
    if (_setupCastlingq) castling.write('q');
    String castlingStr = castling.isEmpty ? '-' : castling.toString();

    String finalFen = '$boardPart $_setupTurn $castlingStr - 0 1';
    try {
      controller.loadFen(finalFen);
      setState(() {});
    } catch (e) {
      try {
        controller.loadFen('$boardPart w - - 0 1');
        setState(() {});
      } catch (_) {}
    }
  }

  void _applySetupAndStartAnalysis() {
    String currentFen = controller.game.fen;
    bool hasWhiteKing = currentFen.split(' ')[0].contains('K');
    bool hasBlackKing = currentFen.split(' ')[0].contains('k');
    if (!hasWhiteKing || !hasBlackKing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.get('missing_king_error')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSetupMode = false;
      _rootNode = MoveNode(fen: currentFen);
      _currentNode = _rootNode;
      _syncPathList();
      _startEvaluation();
      controller.addListener(_onBoardChange);
    });
  }

  Widget _buildSetupPalette() {
    // Tüm taşlar için dolgulu (solid) satranç sembolleri kullanıyoruz; böylece sistem fontu boş çizgili (outline) çizmeyip koyduğumuz rengi tam dolduruyor.
    const Map<String, String> whitePieces = {
      'K': '♚',
      'Q': '♛',
      'R': '♜',
      'B': '♝',
      'N': '♞',
      'P': '♟'
    };
    const Map<String, String> blackPieces = {
      'k': '♚',
      'q': '♛',
      'r': '♜',
      'b': '♝',
      'n': '♞',
      'p': '♟'
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.greenAccent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handyman,
                      color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(LanguageService.get('board_editor'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: Text(LanguageService.get('start_analysis'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _applySetupAndStartAnalysis,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(LanguageService.get('piece_selection_hint'),
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // BEYAZ TAŞLAR KUTUSU (Koyu lacivert/slate arka plan üzerine BEYAZ taşlar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Koyu lacivert zemin
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(LanguageService.get('white_label'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.start,
                    children: whitePieces.entries
                        .map((e) => _buildPieceChip(e.key, e.value, true))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // SİYAH TAŞLAR KUTUSU (Açık gümüş/slate arka plan üzerine SİYAH taşlar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0), // Açık gümüş zemin
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF475569), width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(LanguageService.get('black_label'),
                      style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.start,
                    children: [
                      ...blackPieces.entries
                          .map((e) => _buildPieceChip(e.key, e.value, false)),
                      _buildPieceChip('_delete_', '', false, isDelete: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LanguageService.get('turn_label'),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(LanguageService.get('turn_white')),
                    selected: _setupTurn == 'w',
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                        color:
                            _setupTurn == 'w' ? Colors.black : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    onSelected: (_) => _updateAndApplySetupFen(newTurn: 'w'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(LanguageService.get('turn_black')),
                    selected: _setupTurn == 'b',
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: const Color(0xFF1E293B),
                    side: _setupTurn == 'b'
                        ? const BorderSide(
                            color: Colors.greenAccent, width: 1.5)
                        : BorderSide.none,
                    labelStyle: TextStyle(
                        color:
                            _setupTurn == 'b' ? Colors.white : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    onSelected: (_) => _updateAndApplySetupFen(newTurn: 'b'),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: Text(LanguageService.get('clear'),
                        style: const TextStyle(fontSize: 11)),
                    onPressed: () => _updateAndApplySetupFen(
                        newBoardPart: '4k3/8/8/8/8/8/8/4K3',
                        clearCastling: true),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.lightBlueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: Text(LanguageService.get('initial_position'),
                        style: const TextStyle(fontSize: 11)),
                    onPressed: () => _updateAndApplySetupFen(
                        newBoardPart:
                            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
                        newTurn: 'w',
                        resetCastling: true),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text(LanguageService.get('castling_rights'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              _buildCastlingChip(
                  "O-O w",
                  _setupCastlingK,
                  (val) => setState(() {
                        _setupCastlingK = val;
                        _updateAndApplySetupFen();
                      })),
              const SizedBox(width: 4),
              _buildCastlingChip(
                  "O-O-O w",
                  _setupCastlingQ,
                  (val) => setState(() {
                        _setupCastlingQ = val;
                        _updateAndApplySetupFen();
                      })),
              const SizedBox(width: 4),
              _buildCastlingChip(
                  "O-O b",
                  _setupCastlingk,
                  (val) => setState(() {
                        _setupCastlingk = val;
                        _updateAndApplySetupFen();
                      })),
              const SizedBox(width: 4),
              _buildCastlingChip(
                  "O-O-O b",
                  _setupCastlingq,
                  (val) => setState(() {
                        _setupCastlingq = val;
                        _updateAndApplySetupFen();
                      })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieceChip(String pieceKey, String symbol, bool isWhite,
      {bool isDelete = false}) {
    bool isSelected = _selectedSetupPiece == pieceKey;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isDelete) {
      bgColor = isSelected ? Colors.red.shade700 : const Color(0xFFEF4444);
      borderColor = isSelected ? Colors.black : const Color(0xFF991B1B);
      textColor = Colors.white;
    } else if (isWhite) {
      // Lacivert kutu (1E293B) içindeki beyaz taş çipleri:
      bgColor = isSelected ? Colors.green.shade600 : const Color(0xFF334155);
      borderColor = isSelected ? Colors.white : const Color(0xFF94A3B8);
      textColor = Colors.white; // TAM BEYAZ TAŞ!
    } else {
      // Gümüş kutu (E2E8F0) içindeki siyah taş çipleri:
      bgColor = isSelected ? Colors.greenAccent : const Color(0xFF94A3B8);
      borderColor = isSelected ? Colors.black : const Color(0xFF475569);
      textColor = const Color(0xFF0F172A); // TAM SİYAH TAŞ!
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedSetupPiece = pieceKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: bgColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: isDelete
            ? Icon(Icons.delete_outline, color: textColor, size: 22)
            : Text(
                symbol,
                style: TextStyle(
                  fontSize: 24,
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildCastlingChip(
      String label, bool selected, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 10, color: selected ? Colors.black : Colors.white70)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.amberAccent,
      backgroundColor: const Color(0xFF1F2D4B),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  void dispose() {
    controller.removeListener(_onBoardChange);
    ChessEngineService().stopContinuousAnalysis();
    _pageScrollController.dispose();
    super.dispose();
  }

  void _onBoardChange() {
    if (_isSetupMode) return;
    if (_currentNode.fen == controller.game.fen) {
      return;
    }

    try {
      final existingChild = _currentNode.children.firstWhere(
        (child) => child.fen == controller.game.fen,
      );
      _currentNode = existingChild;
      _syncPathList();
      _selectedSquare = null;
      _legalDestinations.clear();
      _startEvaluation();
      return;
    } catch (_) {}

    var sans = controller.getSan();
    String lastMove = '?';
    if (sans.isNotEmpty && sans.last != null) {
      String lastPair = sans.last!.trim();
      List<String> parts = lastPair.split(RegExp(r'\s+'));
      lastMove = parts.last;
      bool isCapture = lastMove.contains('x');
      SoundService.playMoveSound(isCapture);
    } else {
      SoundService.playMoveSound(false);
    }

    MoveNode newNode =
        MoveNode(fen: controller.game.fen, san: lastMove, parent: _currentNode);
    _currentNode.children.add(newNode);
    _currentNode = newNode;
    _syncPathList();
    _selectedSquare = null;
    _legalDestinations.clear();
    _startEvaluation();
  }

  void _startEvaluation({bool silent = false}) {
    setState(() {
      _topEngineMoves = ['', '', ''];
      _multiPvLines = ['', '', ''];
      _multiPvEvals = [0.0, 0.0, 0.0];
      _multiPvMates = [false, false, false];
      _evaluationText = '...';
      _engineDepth = 0;
    });

    String currentFen = _fenList[_currentMoveIndex];
    if (currentFen ==
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1') {
      setState(() {
        _evaluationValue = 0.3;
        _evaluationText = "+0.3";
        _topEngineMoves = ['e2e4', 'd2d4', 'g1f3'];
        _multiPvEvals = [0.3, 0.2, 0.1];
        _multiPvLines = [
          'e2e4 e7e5 g1f3 b8c6 f1b5',
          'd2d4 d7d5 c2c4 e7e6 b1c3',
          'g1f3 d7d5 d2d4 g8f6 c4'
        ];
        _multiPvMates = [false, false, false];
        _engineDepth = 20;
      });
      return;
    }

    ChessEngineService().stopContinuousAnalysis();
    _engineDebounceTimer?.cancel();
    _engineDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ChessEngineService().startContinuousAnalysis(currentFen, (updateData) {
        if (!mounted ||
            _fenList.isEmpty ||
            _currentMoveIndex >= _fenList.length ||
            _fenList[_currentMoveIndex] != currentFen) return;
        double rawEval = updateData['best_eval'] ?? 0.0;
        bool isMate = updateData['is_mate'] ?? false;
        List<String> suggs = List<String>.from(
            updateData['suggestions'] ?? ['', '', '', '', '']);
        List<double> alts = List<double>.from(
            updateData['alternatives'] ?? [0.0, 0.0, 0.0, 0.0, 0.0]);
        List<String> pvs =
            List<String>.from(updateData['pv_lines'] ?? ['', '', '', '', '']);
        List<bool> mates = List<bool>.from(
            updateData['mates'] ?? [false, false, false, false, false]);
        int depth = updateData['depth'] ?? 0;

        String evalTxt = isMate || rawEval.abs() > 14.0
            ? (rawEval > 0 ? '+M' : '-M')
            : (rawEval > 0
                ? '+${rawEval.toStringAsFixed(1)}'
                : rawEval.toStringAsFixed(1));

        setState(() {
          _evaluationValue = rawEval;
          _evaluationText = evalTxt;
          _topEngineMoves = suggs.take(3).toList();
          _multiPvEvals = alts.take(3).toList();
          _multiPvLines = pvs.take(3).toList();
          _multiPvMates = mates.take(3).toList();
          _engineDepth = depth;
        });
      });
    });
  }

  void _goToMove(int index) {
    if (index < 0 || index >= _fenList.length) return;
    controller.removeListener(_onBoardChange);

    if (index > 0 && index - 1 < _allMoves.length) {
      bool isCapture = _allMoves[index - 1].contains('x');
      SoundService.playMoveSound(isCapture);
    } else if (index == 0) {
      SoundService.playMoveSound(false);
    }

    final path = _currentNode.getPathFromRoot();
    if (index < path.length) {
      _currentNode = path[index];
    }
    _syncPathList();
    _selectedSquare = null;
    _legalDestinations.clear();
    controller.loadFen(_fenList[index]);
    _startEvaluation();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) controller.addListener(_onBoardChange);
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

  Future<void> _showPromotionDialog(String from, String to) async {
    final isWhiteToMove = controller.game.fen.split(' ')[1] == 'w';
    final isTr = LanguageService.currentLang == 'tr';

    final piece = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151B2B),
          title: Text(isTr ? 'Terfi Seçimi' : 'Choose promotion',
              style: const TextStyle(color: Colors.white)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child:
                    isWhiteToMove ? WhiteQueen(size: 45) : BlackQueen(size: 45),
                onTap: () => Navigator.of(context).pop("q"),
              ),
              InkWell(
                child:
                    isWhiteToMove ? WhiteRook(size: 45) : BlackRook(size: 45),
                onTap: () => Navigator.of(context).pop("r"),
              ),
              InkWell(
                child: isWhiteToMove
                    ? WhiteBishop(size: 45)
                    : BlackBishop(size: 45),
                onTap: () => Navigator.of(context).pop("b"),
              ),
              InkWell(
                child: isWhiteToMove
                    ? WhiteKnight(size: 45)
                    : BlackKnight(size: 45),
                onTap: () => Navigator.of(context).pop("n"),
              ),
            ],
          ),
        );
      },
    );

    if (piece != null) {
      controller.makeMoveWithPromotion(
          from: from, to: to, pieceToPromoteTo: piece);
      setState(() {
        _selectedSquare = null;
        _legalDestinations.clear();
      });
    }
  }

  void _onFreeSquareTapped(String square) {
    if (_isSetupMode) {
      String currentFen = controller.game.fen;
      String newFen = _modifyFenSquare(currentFen, square, _selectedSetupPiece);
      _updateAndApplySetupFen(newBoardPart: newFen.split(' ')[0]);
      return;
    }
    final piece = controller.game.get(square);
    final isWhiteToMove = controller.game.fen.split(' ')[1] == 'w';

    if (_selectedSquare == null) {
      if (piece != null &&
          piece.color ==
              (isWhiteToMove
                  ? chess_engine.Color.WHITE
                  : chess_engine.Color.BLACK)) {
        setState(() {
          _selectedSquare = square;
          final moves =
              controller.game.moves({"square": square, "verbose": true});
          _legalDestinations = moves.map((m) => m["to"] as String).toList();
        });
      }
    } else {
      if (_legalDestinations.contains(square)) {
        final allMoves = controller.game
            .moves({"square": _selectedSquare!, "verbose": true});
        final moveList = allMoves.where((m) => m["to"] == square).toList();
        bool isPromotion = moveList.isNotEmpty &&
            ((moveList.first.containsKey("promotion") &&
                    moveList.first["promotion"] != null) ||
                (moveList.first.containsKey("flags") &&
                    (moveList.first["flags"] as String).contains("p")));

        if (isPromotion) {
          _showPromotionDialog(_selectedSquare!, square);
        } else {
          controller.makeMove(from: _selectedSquare!, to: square);
          setState(() {
            _selectedSquare = null;
            _legalDestinations.clear();
          });
        }
      } else if (piece != null &&
          piece.color ==
              (isWhiteToMove
                  ? chess_engine.Color.WHITE
                  : chess_engine.Color.BLACK)) {
        setState(() {
          _selectedSquare = square;
          final moves =
              controller.game.moves({"square": square, "verbose": true});
          _legalDestinations = moves.map((m) => m["to"] as String).toList();
        });
      } else {
        setState(() {
          _selectedSquare = null;
          _legalDestinations.clear();
        });
      }
    }
  }

  void _showPasteDialog() {
    TextEditingController textController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151B2B),
            title: Text(LanguageService.get('paste_pgn_fen'),
                style: const TextStyle(color: Colors.white)),
            content: TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: LanguageService.get('paste_pgn_fen_hint'),
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LanguageService.get('cancel'),
                    style: const TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                onPressed: () {
                  String input = textController.text.trim();
                  if (mounted) Navigator.pop(context);
                  if (input.isNotEmpty) {
                    _loadPgnOrFen(input);
                  }
                },
                child: Text(LanguageService.get('paste')),
              ),
            ],
          );
        });
  }

  void _shareFreePgn() async {
    String date = DateTime.now().toString().split(' ')[0].replaceAll('-', '.');
    String pgn =
        '[Event "MoveLab Analiz"]\n[Site "MoveLab App"]\n[Date "$date"]\n[White "Beyaz"]\n[Black "Siyah"]\n[Result "*"]\n\n';
    String formattedMoves = '';
    for (int i = 0; i < _allMoves.length; i++) {
      if (i % 2 == 0) formattedMoves += '${(i ~/ 2) + 1}. ';
      formattedMoves += '${_allMoves[i]} ';
    }
    pgn += formattedMoves.trim();
    final box = context.findRenderObject() as RenderBox?;
    try {
      const platform = MethodChannel('com.movelab.app/share');
      await platform.invokeMethod('shareText', {
        'text':
            '$pgn\n\n📲 App: https://play.google.com/store/apps/details?id=com.movelab.app',
      });
    } catch (e) {
      debugPrint("Free PGN share error: $e");
    }
  }

  void _showSaveToLibraryDialog() {
    final whiteCtrl = TextEditingController(text: 'Beyaz');
    final whiteEloCtrl = TextEditingController(text: '?');
    final blackCtrl = TextEditingController(text: 'Siyah');
    final blackEloCtrl = TextEditingController(text: '?');
    String result = '*';
    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2136),
              title: Text(LanguageService.get('save_to_library'),
                  style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                                controller: whiteCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    labelText:
                                        LanguageService.get('white_player'),
                                    labelStyle:
                                        const TextStyle(color: Colors.white54),
                                    enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.white24))))),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 60,
                            child: TextField(
                                controller: whiteEloCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    labelText: LanguageService.get('elo'),
                                    labelStyle:
                                        const TextStyle(color: Colors.white54),
                                    enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.white24))))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                                controller: blackCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    labelText:
                                        LanguageService.get('black_player'),
                                    labelStyle:
                                        const TextStyle(color: Colors.white54),
                                    enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.white24))))),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 60,
                            child: TextField(
                                controller: blackEloCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    labelText: LanguageService.get('elo'),
                                    labelStyle:
                                        const TextStyle(color: Colors.white54),
                                    enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.white24))))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: result,
                      dropdownColor: const Color(0xFF2A3146),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          labelText: LanguageService.get('result'),
                          labelStyle: const TextStyle(color: Colors.white54)),
                      items: ['1-0', '0-1', '1/2-1/2', '*'].map((String val) {
                        return DropdownMenuItem<String>(
                            value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() {
                            result = val;
                          });
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LanguageService.get('cancel'),
                      style: const TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    String formattedMoves = '';
                    for (int i = 0; i < _allMoves.length; i++) {
                      if (i % 2 == 0) formattedMoves += '${(i ~/ 2) + 1}. ';
                      formattedMoves += '${_allMoves[i]} ';
                    }
                    String pgnStr =
                        '[Event "MoveLab Analiz"]\n[White "${whiteCtrl.text}"]\n[WhiteElo "${whiteEloCtrl.text}"]\n[Black "${blackCtrl.text}"]\n[BlackElo "${blackEloCtrl.text}"]\n[Result "$result"]\n\n${formattedMoves.trim()}';
                    SavedMatch match = SavedMatch(
                        title: 'Custom Match',
                        whiteName: whiteCtrl.text,
                        blackName: blackCtrl.text,
                        winner: result == '1-0'
                            ? 'white'
                            : result == '0-1'
                                ? 'black'
                                : result == '1/2-1/2'
                                    ? 'draw'
                                    : 'unknown',
                        moves: formattedMoves.trim(),
                        pgn: pgnStr,
                        speed: 'Free Analysis',
                        whiteRating: int.tryParse(whiteEloCtrl.text) ?? 0,
                        blackRating: int.tryParse(blackEloCtrl.text) ?? 0);
                    GlobalLibrary.matches.add(match);
                    GlobalLibrary.saveMatches();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(LanguageService.get('saved_to_library')),
                        backgroundColor: Colors.greenAccent));
                  },
                  child: Text(LanguageService.get('save')),
                )
              ],
            );
          });
        });
  }

  void _loadPgnOrFen(String input) {
    try {
      controller.removeListener(_onBoardChange);
      if (input.contains('[Event') || input.contains('1.')) {
        // PGN
        chess_engine.Chess chess = chess_engine.Chess();
        chess.load_pgn(input);

        _fenList = [];
        _allMoves = [];

        // Unfortunately chess_engine doesn't expose FENs for all past moves directly from load_pgn
        // We will just load the final FEN and reset history for simplicity, OR we can parse it manually.
        // For robust PGN parsing, the user can just use Analyze with PGN from home.
        // Here we just load the final FEN:
        controller.loadFen(chess.fen);
      } else {
        // Try FEN
        controller.loadFen(input);
      }

      _rootNode = MoveNode(fen: controller.game.fen);
      _currentNode = _rootNode;
      _syncPathList();

      _startEvaluation();

      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) controller.addListener(_onBoardChange);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LanguageService.get('invalid_pgn_fen')),
          backgroundColor: Colors.redAccent));
      if (mounted) controller.addListener(_onBoardChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    double evalPercentage = 0.5;
    double capVal = _evaluationValue.clamp(-10.0, 10.0);
    if (capVal > 0) {
      evalPercentage = 0.5 + (capVal / 10.0) * 0.5;
    } else {
      evalPercentage = 0.5 - (capVal.abs() / 10.0) * 0.5;
    }
    bool isMateLocal = _evaluationText.contains('M');
    if (isMateLocal) {
      evalPercentage = _evaluationText.contains('+') ? 1.0 : 0.0;
    }

    bool shouldShowArrow = SoundService.showArrows &&
        _topEngineMoves.isNotEmpty &&
        _topEngineMoves[0].length >= 4 &&
        _topEngineMoves[0] != '...';

    return Scaffold(
      backgroundColor: const Color(0xFF0B101E),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(LanguageService.get('free_analysis'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        backgroundColor: const Color(0xFF151B2B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.explore,
                color: LichessWidgets.showOpeningExplorer
                    ? Colors.blueAccent
                    : Colors.white38),
            tooltip: LanguageService.get('toggle_explorer'),
            onPressed: () => setState(() {
              LichessWidgets.showOpeningExplorer =
                  !LichessWidgets.showOpeningExplorer;
            }),
          ),
          IconButton(
            icon: Icon(_isSetupMode ? Icons.check_circle : Icons.handyman,
                color: _isSetupMode ? Colors.greenAccent : Colors.white70),
            tooltip: _isSetupMode
                ? LanguageService.get('apply_setup')
                : LanguageService.get('board_editor_tooltip'),
            onPressed:
                _isSetupMode ? _applySetupAndStartAnalysis : _toggleSetupMode,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: LanguageService.get('settings'),
            onPressed: () => showSettingsSheet(
              context,
              onChanged: () {
                setState(() {});
                _startEvaluation(silent: true);
              },
              onPaste: _showPasteDialog,
              onResetBoard: () {
                controller.removeListener(_onBoardChange);
                controller.resetBoard();
                _initBoard();
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) controller.addListener(_onBoardChange);
                });
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1E2536),
            onSelected: (val) {
              if (val == 'rotate') {
                setState(() {
                  _boardOrientation = _boardOrientation == PlayerColor.white
                      ? PlayerColor.black
                      : PlayerColor.white;
                });
              } else if (val == 'share') {
                _shareFreePgn();
              } else if (val == 'save') {
                _showSaveToLibraryDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rotate',
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(LanguageService.get('rotate_board'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(LanguageService.get('share_pgn'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    const Icon(Icons.library_add,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(LanguageService.get('save_to_library'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _pageScrollController,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  if (_isSetupMode)
                    _buildSetupPalette()
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                height: 14,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF151B2B),
                                    borderRadius: BorderRadius.circular(8)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(children: [
                                    AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 350),
                                        curve: Curves.easeOutCubic,
                                        height: 14,
                                        width: constraints.maxWidth *
                                            evalPercentage,
                                        color: Colors.white)
                                  ]),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutQuint,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: Colors.white),
                              child: Text(
                                  "${LanguageService.get('analysis_engine')}: $_evaluationText")),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Top Engine Moves (Lichess Multi-PV Panel)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151B2B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.psychology,
                                        color: Colors.greenAccent, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Stockfish Engine (${_engineDepth > 0 ? 'D$_engineDepth' : '...'})",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                      LanguageService.get('three_variants'),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white12),
                          ...List.generate(3, (index) {
                            final line = _multiPvLines.length > index
                                ? _multiPvLines[index]
                                : '';
                            final eval = _multiPvEvals.length > index
                                ? _multiPvEvals[index]
                                : '';
                            final isMate = _multiPvMates.length > index
                                ? _multiPvMates[index]
                                : false;

                            if (line.isEmpty) {
                              if (index == 0) {
                                return Container(
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                        bottom:
                                            BorderSide(color: Colors.white10)),
                                  ),
                                  child: Text(LanguageService.get('analyzing'),
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic)),
                                );
                              }
                              return Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  border: index == 1
                                      ? const Border(
                                          bottom:
                                              BorderSide(color: Colors.white10))
                                      : null,
                                ),
                              );
                            }

                            final moves = line.split(' ');
                            final firstMove = moves.isNotEmpty ? moves[0] : '';
                            final currentFen = (_fenList.isNotEmpty &&
                                    _currentMoveIndex < _fenList.length)
                                ? _fenList[_currentMoveIndex]
                                : '';
                            final sanLine = NotationHelper.formatUciLineToSan(
                                line, currentFen);
                            final sanMoves = sanLine.split(' ');
                            final firstMoveSan =
                                sanMoves.isNotEmpty ? sanMoves[0] : '';
                            final remainingMovesSan = sanMoves.length > 1
                                ? sanMoves.sublist(1).take(5).join(' ')
                                : '';

                            return InkWell(
                              onTap: () => _playEngineMove(firstMove),
                              child: Container(
                                height: 38,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: index < 2
                                      ? const Border(
                                          bottom:
                                              BorderSide(color: Colors.white10))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1F2D4B),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: const TextStyle(
                                            color: Color(0xFF8BD1FF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "$firstMoveSan ",
                                              style: const TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                            TextSpan(
                                              text: remainingMovesSan,
                                              style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (eval.toString().isNotEmpty &&
                                        eval.toString() != '...') ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isMate
                                              ? Colors.amber
                                                  .withValues(alpha: 0.2)
                                              : const Color(0xFF1E293B),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          eval.toString(),
                                          style: TextStyle(
                                            color: isMate
                                                ? Colors.amber
                                                : const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    const Icon(Icons.play_arrow_rounded,
                                        color: Colors.white30, size: 20),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    if (_fenList.isNotEmpty &&
                        _currentMoveIndex < _fenList.length) ...[
                      LichessWidgets.buildSyzygyPanel(
                          _fenList[_currentMoveIndex], _playEngineMove),
                      LichessWidgets.buildOpeningExplorerPanel(
                          _fenList[_currentMoveIndex], _playEngineMove),
                    ],
                  ],
                  const SizedBox(height: 15),

                  // Chess Board
                  ClipRect(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              return Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerUp: (event) {
                                  final squareSize = constraints.maxWidth / 8;
                                  final col =
                                      (event.localPosition.dx / squareSize)
                                          .floor()
                                          .clamp(0, 7);
                                  final row =
                                      (event.localPosition.dy / squareSize)
                                          .floor()
                                          .clamp(0, 7);

                                  int rank, file;
                                  if (_boardOrientation == PlayerColor.white) {
                                    rank = 7 - row;
                                    file = col;
                                  } else {
                                    rank = row;
                                    file = 7 - col;
                                  }

                                  final fileChar = String.fromCharCode(
                                      'a'.codeUnitAt(0) + file);
                                  final rankChar = (rank + 1).toString();
                                  final square = '$fileChar$rankChar';

                                  _onFreeSquareTapped(square);
                                },
                                child: Stack(
                                  children: [
                                    ChessBoard(
                                      controller: controller,
                                      boardColor: BoardThemeService.boardColor,
                                      boardOrientation: _boardOrientation,
                                      enableUserMoves: !_isSetupMode,
                                    ),
                                    // Legal move hints overlay
                                    IgnorePointer(
                                      child: Column(
                                        children: List.generate(8, (row) {
                                          return Expanded(
                                            child: Row(
                                              children: List.generate(8, (col) {
                                                final index = row * 8 + col;
                                                final square = _indexToSquare(
                                                    index,
                                                    _boardOrientation ==
                                                        PlayerColor.white);
                                                final isSelected =
                                                    square == _selectedSquare;
                                                final isLegalMove =
                                                    _legalDestinations
                                                        .contains(square);

                                                final piece =
                                                    controller.game.get(square);
                                                final isCapture = isLegalMove &&
                                                    piece != null;

                                                Widget? highlightWidget;
                                                if (isCapture) {
                                                  highlightWidget = Center(
                                                    child: Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            width: 5),
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
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.3),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? Colors.yellow
                                                              .withValues(
                                                                  alpha: 0.4)
                                                          : null,
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
                            }),
                          ),
                          if (shouldShowArrow && !_isSetupMode)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: MultiArrowPainter(
                                    moves: _topEngineMoves.isNotEmpty &&
                                            _topEngineMoves[0].length >= 4 &&
                                            _topEngineMoves[0] != '...'
                                        ? [_topEngineMoves[0]]
                                        : [],
                                    orientation: _boardOrientation,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (!_isSetupMode) ...[
                    // Navigation Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.fast_rewind),
                          color: _currentMoveIndex > 0
                              ? Colors.white
                              : Colors.white30,
                          onPressed:
                              _currentMoveIndex > 0 ? () => _goToMove(0) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          color: _currentMoveIndex > 0
                              ? Colors.white
                              : Colors.white30,
                          onPressed: _currentMoveIndex > 0
                              ? () => _goToMove(_currentMoveIndex - 1)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          color: _currentMoveIndex < _fenList.length - 1
                              ? Colors.white
                              : Colors.white30,
                          onPressed: _currentMoveIndex < _fenList.length - 1
                              ? () => _goToMove(_currentMoveIndex + 1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.fast_forward),
                          color: _currentMoveIndex < _fenList.length - 1
                              ? Colors.white
                              : Colors.white30,
                          onPressed: _currentMoveIndex < _fenList.length - 1
                              ? () => _goToMove(_fenList.length - 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_currentNode.parent != null &&
                        _currentNode.parent!.children.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.alt_route,
                                size: 16, color: Colors.amberAccent),
                            const SizedBox(width: 8),
                            Text("${LanguageService.get('variants')}:",
                                style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _currentNode.parent!.children
                                      .map((sibling) {
                                    bool isCurrentBranch =
                                        sibling == _currentNode;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(sibling.san.isNotEmpty
                                            ? sibling.san
                                            : '...'),
                                        selected: isCurrentBranch,
                                        selectedColor: Colors.amberAccent
                                            .withValues(alpha: 0.3),
                                        backgroundColor:
                                            const Color(0xFF1F2D4B),
                                        labelStyle: TextStyle(
                                          color: isCurrentBranch
                                              ? Colors.amberAccent
                                              : Colors.white70,
                                          fontWeight: isCurrentBranch
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                        onSelected: (selected) {
                                          if (!isCurrentBranch) {
                                            _goToNode(sibling);
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_currentNode.children.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.fork_right,
                                size: 16, color: Colors.lightBlueAccent),
                            const SizedBox(width: 8),
                            Text(LanguageService.get('next_branches'),
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _currentNode.children.map((child) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ActionChip(
                                        label: Text(child.san.isNotEmpty
                                            ? child.san
                                            : '...'),
                                        backgroundColor:
                                            const Color(0xFF1F2D4B),
                                        labelStyle: const TextStyle(
                                            color: Colors.lightBlueAccent,
                                            fontSize: 12),
                                        onPressed: () => _goToNode(child),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Move List
                    if (_allMoves.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151B2B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 6,
                          children: List.generate(_allMoves.length, (index) {
                            bool isWhite = index % 2 == 0;
                            String moveNumber =
                                isWhite ? '${(index ~/ 2) + 1}. ' : '';
                            bool isCurrent = index == _currentMoveIndex - 1;

                            return GestureDetector(
                              onTap: () => _goToMove(index + 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.blueAccent.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$moveNumber${_allMoves[index].replaceAll(RegExp(r'^\d+\.+\s*'), '')}',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.blueAccent
                                        : Colors.white70,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
