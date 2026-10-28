import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'custom_chess_board/custom_chess_board.dart';
import 'main.dart';

/// MasterGame modeli
class MasterGame {
  final String event;
  final String site;
  final String date;
  final String white;
  final String black;
  final String result;
  final String? whiteElo;
  final String? blackElo;
  final String? whiteTitle;
  final String? blackTitle;
  final String? eco;
  final String? round;
  final String rawPgn;

  MasterGame({
    required this.event,
    required this.site,
    required this.date,
    required this.white,
    required this.black,
    required this.result,
    this.whiteElo,
    this.blackElo,
    this.whiteTitle,
    this.blackTitle,
    this.eco,
    this.round,
    required this.rawPgn,
  });

  String get displayTitle => '$white vs $black';
}

/// Çoklu oyun içeren PGN metnini ayrı oyun bloklarına böler
List<String> splitPgnGames(String content) {
  final blocks = <String>[];
  final lines = content.split('\n');
  final current = StringBuffer();
  bool inGame = false;

  for (var line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[Event ') && inGame && current.isNotEmpty) {
      blocks.add(current.toString().trim());
      current.clear();
    }
    if (trimmed.isNotEmpty || inGame) {
      current.writeln(line);
      inGame = true;
    }
  }
  if (current.isNotEmpty && current.toString().trim().isNotEmpty) {
    blocks.add(current.toString().trim());
  }
  return blocks;
}

/// Tek bir PGN blokunu ayrıştırıp MasterGame nesnesi döndürür
MasterGame? parseOneGame(String block) {
  final lines = block.split('\n');
  final headers = <String, String>{};
  final moveLines = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('[')) {
      final headerMatch = RegExp(r'^\[(\w+)\s+"([^"]*)"\]').firstMatch(trimmed);
      if (headerMatch != null) {
        headers[headerMatch.group(1)!] = headerMatch.group(2)!;
      }
    } else {
      moveLines.add(trimmed);
    }
  }

  final white = headers['White'] ?? '';
  final black = headers['Black'] ?? '';
  if (white.isEmpty && black.isEmpty) return null;

  final moveText = moveLines.join(' ');
  if (moveText.trim().isEmpty) return null;

  return MasterGame(
    event: headers['Event'] ?? 'Master Game',
    site: headers['Site'] ?? '',
    date: headers['Date'] ?? '',
    white: white,
    black: black,
    result: headers['Result'] ?? '*',
    whiteElo: headers['WhiteElo'],
    blackElo: headers['BlackElo'],
    whiteTitle: headers['WhiteTitle'],
    blackTitle: headers['BlackTitle'],
    eco: headers['ECO'],
    round: headers['Round'],
    rawPgn: block,
  );
}

/// Dosya adından büyük usta ismini temizler
String masterNameFromFilename(String filename) {
  return filename.replaceAll('_selected.pgn', '').replaceAll('.pgn', '');
}

/// Dosya adından veya kısa isimden ustaların tam ismini döndürür
String getMasterFullName(String shortName) {
  return kMasterInfo[shortName]?['name'] ?? shortName;
}

/// Büyük ustalar hakkında zengin açıklama ve unvan verileri (Türkçe ve İngilizce)
const Map<String, Map<String, String>> kMasterInfo = {
  'Abdusattorov': {
    'name': 'Nodirbek Abdusattorov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Evrensel', 'style_en': 'Universal',
  },
  'Adams': {
    'name': 'Michael Adams',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Konumsal', 'style_en': 'Positional',
  },
  'Akobian': {
    'name': 'Varuzhan Akobian',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Katı', 'style_en': 'Solid',
  },
  'Akopian': {
    'name': 'Vladimir Akopian',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik', 'style_en': 'Tactical',
  },
  'Alburt': {
    'name': 'Lev Alburt',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Aktif', 'style_en': 'Active',
  },
  'Alekhine': {
    'name': 'Alexander Alekhine',
    'title_tr': '4. Dünya Şampiyonu', 'title_en': '4th World Champion',
    'era_tr': '1927-1946', 'era_en': '1927-1946',
    'style_tr': 'Dinamik', 'style_en': 'Dynamic',
  },
  'Alekseev': {
    'name': 'Evgeny Alekseev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Almasi': {
    'name': 'Zoltan Almasi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Anand': {
    'name': 'Viswanathan Anand',
    'title_tr': '15. Dünya Şampiyonu', 'title_en': '15th World Champion',
    'era_tr': '2007-2013', 'era_en': '2007-2013',
    'style_tr': 'Hızlı ve Evrensel', 'style_en': 'Fast & Universal',
  },
  'Anderssen': {
    'name': 'Adolf Anderssen',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Romantik Saldırgan', 'style_en': 'Romantic Attacker',
  },
  'Andersson': {
    'name': 'Ulf Andersson',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Profilaktik', 'style_en': 'Prophylactic',
  },
  'Andreikin': {
    'name': 'Dmitry Andreikin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Pragmatik', 'style_en': 'Pragmatic',
  },
  'Aronian': {
    'name': 'Levon Aronian',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yaratıcı Sezgisel', 'style_en': 'Creative Intuitive',
  },
  'Ashley': {
    'name': 'Maurice Ashley',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik', 'style_en': 'Tactical',
  },
  'Averbakh': {
    'name': 'Yuri Averbakh',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Oyun Sonu Dehası', 'style_en': 'Endgame Virtuoso',
  },
  'Azmaiparashvili': {
    'name': 'Zurab Azmaiparashvili',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Bacrot': {
    'name': 'Etienne Bacrot',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Bareev': {
    'name': 'Evgeny Bareev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'BecerraRivero': {
    'name': 'Julio Becerra Rivero',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Beliavsky': {
    'name': 'Alexander Beliavsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sert', 'style_en': 'Uncompromising',
  },
  'Benjamin': {
    'name': 'Joel Benjamin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Benko': {
    'name': 'Pal Benko',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Konumsal', 'style_en': 'Positional',
  },
  'Berliner': {
    'name': 'Hans Berliner',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yazışmalı Satranç', 'style_en': 'Correspondence',
  },
  'Bernstein': {
    'name': 'Ossip Bernstein',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Bird': {
    'name': 'Henry Bird',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Orijinal', 'style_en': 'Original',
  },
  'Bisguier': {
    'name': 'Arthur Bisguier',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Blackburne': {
    'name': 'Joseph Henry Blackburne',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Kara Ölüm (Taktik)', 'style_en': 'Black Death',
  },
  'Blatny': {
    'name': 'Pavel Blatny',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Bogoljubow': {
    'name': 'Efim Bogoljubow',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Kendine Güvenen', 'style_en': 'Confident',
  },
  'Boleslavsky': {
    'name': 'Isaac Boleslavsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Teorisyen', 'style_en': 'Theoretician',
  },
  'Bologan': {
    'name': 'Victor Bologan',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Botvinnik': {
    'name': 'Mikhail Botvinnik',
    'title_tr': '6. Dünya Şampiyonu', 'title_en': '6th World Champion',
    'era_tr': '1948-1963', 'era_en': '1948-1963',
    'style_tr': 'Bilimsel', 'style_en': 'Scientific',
  },
  'Breyer': {
    'name': 'Gyula Breyer',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Hipermodern', 'style_en': 'Hypermodern',
  },
  'Bronstein': {
    'name': 'David Bronstein',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yaratıcı', 'style_en': 'Creative',
  },
  'Browne': {
    'name': 'Walter Browne',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Savaşçı', 'style_en': 'Fighter',
  },
  'Bruzon': {
    'name': 'Lazaro Bruzon',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Bu': {
    'name': 'Bu Xiangzhi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Katı', 'style_en': 'Solid',
  },
  'Byrne': {
    'name': 'Robert Byrne',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Capablanca': {
    'name': 'José Raúl Capablanca',
    'title_tr': '3. Dünya Şampiyonu', 'title_en': '3rd World Champion',
    'era_tr': '1921-1927', 'era_en': '1921-1927',
    'style_tr': 'Oyun Sonu Makinesi', 'style_en': 'Endgame Machine',
  },
  'Carlsen': {
    'name': 'Magnus Carlsen',
    'title_tr': '16. Dünya Şampiyonu', 'title_en': '16th World Champion',
    'era_tr': '2013-2023', 'era_en': '2013-2023',
    'style_tr': 'Evrensel / Oyun Sonu', 'style_en': 'Universal / Endgame',
  },
  'Caruana': {
    'name': 'Fabiano Caruana',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '2014-Günümüz', 'era_en': '2014-Present',
    'style_tr': 'Derin Hazırlık', 'style_en': 'Deep Preparation',
  },
  'Chiburdanidze': {
    'name': 'Maia Chiburdanidze',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Konumsal', 'style_en': 'Positional',
  },
  'Chigorin': {
    'name': 'Mikhail Chigorin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Dinamik', 'style_en': 'Dynamic',
  },
  'Christiansen': {
    'name': 'Larry Christiansen',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Agresif', 'style_en': 'Aggressive',
  },
  'DeFirmian': {
    'name': 'Nick de Firmian',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Teorisyen', 'style_en': 'Theoretician',
  },
  'DeLaBourdonnais': {
    'name': 'Louis-Charles Mahé de La Bourdonnais',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Romantik', 'style_en': 'Romantic',
  },
  'Denker': {
    'name': 'Arnold Denker',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Ding': {
    'name': 'Ding Liren',
    'title_tr': '17. Dünya Şampiyonu', 'title_en': '17th World Champion',
    'era_tr': '2023-Günümüz', 'era_en': '2023-Present',
    'style_tr': 'Sağlam ve Hesaplayıcı', 'style_en': 'Solid & Calculating',
  },
  'DominguezPerez': {
    'name': 'Leinier Dominguez',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Katı', 'style_en': 'Solid',
  },
  'Dreev': {
    'name': 'Alexey Dreev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Duda': {
    'name': 'Jan-Krzysztof Duda',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Keskin Taktik', 'style_en': 'Sharp Tactical',
  },
  'Dzindzichashvili': {
    'name': 'Roman Dzindzichashvili',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Orijinal Açılışlar', 'style_en': 'Original Openings',
  },
  'Ehlvest': {
    'name': 'Jaan Ehlvest',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Eljanov': {
    'name': 'Pavel Eljanov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Hesaplayıcı', 'style_en': 'Calculator',
  },
  'Erigaisi': {
    'name': 'Arjun Erigaisi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yaratıcı', 'style_en': 'Creative',
  },
  'Euwe': {
    'name': 'Max Euwe',
    'title_tr': '5. Dünya Şampiyonu', 'title_en': '5th World Champion',
    'era_tr': '1935-1937', 'era_en': '1935-1937',
    'style_tr': 'Mantıksal', 'style_en': 'Logical',
  },
  'Evans': {
    'name': 'Larry Evans',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Fedorowicz': {
    'name': 'John Fedorowicz',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Fine': {
    'name': 'Reuben Fine',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Finegold': {
    'name': 'Ben Finegold',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Konumsal', 'style_en': 'Positional',
  },
  'Firouzja': {
    'name': 'Alireza Firouzja',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik', 'style_en': 'Tactical',
  },
  'Fischer': {
    'name': 'Bobby Fischer',
    'title_tr': '11. Dünya Şampiyonu', 'title_en': '11th World Champion',
    'era_tr': '1972-1975', 'era_en': '1972-1975',
    'style_tr': 'Kesinlik ve Üstünlük', 'style_en': 'Precision & Dominance',
  },
  'Fishbein': {
    'name': 'Alexander Fishbein',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Flohr': {
    'name': 'Salo Flohr',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Konumsal', 'style_en': 'Positional',
  },
  'Gaprindashvili': {
    'name': 'Nona Gaprindashvili',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Gashimov': {
    'name': 'Vugar Gashimov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Agresif', 'style_en': 'Aggressive',
  },
  'Gelfand': {
    'name': 'Boris Gelfand',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Klasik', 'style_en': 'Classical',
  },
  'Geller': {
    'name': 'Efim Geller',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan Teorisyen', 'style_en': 'Aggressive Theoretician',
  },
  'Georgiev': {
    'name': 'Kiril Georgiev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Giri': {
    'name': 'Anish Giri',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yenilmez', 'style_en': 'Solid',
  },
  'Gligoric': {
    'name': 'Svetozar Gligoric',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Goldin': {
    'name': 'Alexander Goldin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'GrandaZuniga': {
    'name': 'Julio Granda Zuniga',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sezgisel', 'style_en': 'Intuitive',
  },
  'Grischuk': {
    'name': 'Alexander Grischuk',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Zaman Sıkışması Uzmanı', 'style_en': 'Zeitnot Expert',
  },
  'Gukesh': {
    'name': 'Gukesh D',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Hesaplayıcı', 'style_en': 'Calculator',
  },
  'Gulko': {
    'name': 'Boris Gulko',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Gunsberg': {
    'name': 'Isidor Gunsberg',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'GurevichD': {
    'name': 'Dmitry Gurevich',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'GurevichM': {
    'name': 'Mikhail Gurevich',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Harikrishna': {
    'name': 'Pentala Harikrishna',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Hort': {
    'name': 'Vlastimil Hort',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Horwitz': {
    'name': 'Bernhard Horwitz',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Hou': {
    'name': 'Hou Yifan',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Evrensel', 'style_en': 'Universal',
  },
  'Huebner': {
    'name': 'Robert Huebner',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Ibragimov': {
    'name': 'Ildar Ibragimov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'IllescasCordoba': {
    'name': 'Miguel Illescas',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Inarkiev': {
    'name': 'Ernesto Inarkiev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Ivanchuk': {
    'name': 'Vasyl Ivanchuk',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Öngörülemez Deha', 'style_en': 'Unpredictable Genius',
  },
  'IvanovA': {
    'name': 'Alexander Ivanov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'IvanovI': {
    'name': 'Igor Ivanov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Ivkov': {
    'name': 'Borislav Ivkov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Jakovenko': {
    'name': 'Dmitry Jakovenko',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Katı', 'style_en': 'Solid',
  },
  'Janowski': {
    'name': 'Dawid Janowski',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Fillerin Aşığı', 'style_en': 'Bishop Lover',
  },
  'Jobava': {
    'name': 'Baadur Jobava',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yaratıcı', 'style_en': 'Creative',
  },
  'Jussupow': {
    'name': 'Artur Jussupow',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Kaidanov': {
    'name': 'Gregory Kaidanov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Kamsky': {
    'name': 'Gata Kamsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Dirençli', 'style_en': 'Resilient',
  },
  'Karjakin': {
    'name': 'Sergey Karjakin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Savunma Bakanı', 'style_en': 'Minister of Defense',
  },
  'Karpov': {
    'name': 'Anatoly Karpov',
    'title_tr': '12. Dünya Şampiyonu', 'title_en': '12th World Champion',
    'era_tr': '1975-1985', 'era_en': '1975-1985',
    'style_tr': 'Boa Yılanı', 'style_en': 'Boa Constrictor',
  },
  'Kasimdzhanov': {
    'name': 'Rustam Kasimdzhanov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Evrensel', 'style_en': 'Universal',
  },
  'Kasparov': {
    'name': 'Garry Kasparov',
    'title_tr': '13. Dünya Şampiyonu', 'title_en': '13th World Champion',
    'era_tr': '1985-2000', 'era_en': '1985-2000',
    'style_tr': 'Saldırgan Canavar', 'style_en': 'Attacking Monster',
  },
  'Kavalek': {
    'name': 'Lubomir Kavalek',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Keres': {
    'name': 'Paul Keres',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Keymer': {
    'name': 'Vincent Keymer',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Evrensel', 'style_en': 'Universal',
  },
  'Khalifman': {
    'name': 'Alexander Khalifman',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Katı', 'style_en': 'Solid',
  },
  'Kholmov': {
    'name': 'Ratmir Kholmov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Merkezi Savunma', 'style_en': 'Central Defender',
  },
  'Koneru': {
    'name': 'Humpy Koneru',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Korchnoi': {
    'name': 'Viktor Korchnoi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '1960-2010', 'era_en': '1960-2010',
    'style_tr': 'Korkunç Viktor', 'style_en': 'Viktor the Terrible',
  },
  'Korobov': {
    'name': 'Anton Korobov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Kosteniuk': {
    'name': 'Alexandra Kosteniuk',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik', 'style_en': 'Tactical',
  },
  'Kotov': {
    'name': 'Alexander Kotov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Kramnik': {
    'name': 'Vladimir Kramnik',
    'title_tr': '14. Dünya Şampiyonu', 'title_en': '14th World Champion',
    'era_tr': '2000-2007', 'era_en': '2000-2007',
    'style_tr': 'Derin Konumsal', 'style_en': 'Deep Positional',
  },
  'Krasenkow': {
    'name': 'Michal Krasenkow',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Krush': {
    'name': 'Irina Krush',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Kudrin': {
    'name': 'Sergey Kudrin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Lahno': {
    'name': 'Kateryna Lagno',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik', 'style_en': 'Tactical',
  },
  'Larsen': {
    'name': 'Bent Larsen',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Orijinal', 'style_en': 'Original',
  },
  'Lasker': {
    'name': 'Emanuel Lasker',
    'title_tr': '2. Dünya Şampiyonu', 'title_en': '2nd World Champion',
    'era_tr': '1894-1921', 'era_en': '1894-1921',
    'style_tr': 'Psikolojik', 'style_en': 'Psychological',
  },
  'Lautier': {
    'name': 'Joel Lautier',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Le': {
    'name': 'Le Quang Liem',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Hızlı', 'style_en': 'Fast',
  },
  'Leko': {
    'name': 'Peter Leko',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Katı', 'style_en': 'Solid',
  },
  'Levenfish': {
    'name': 'Grigory Levenfish',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Li': {
    'name': 'Li Chao',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Lilienthal': {
    'name': 'Andor Lilienthal',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Ljubojevic': {
    'name': 'Ljubomir Ljubojevic',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Dinamik', 'style_en': 'Dynamic',
  },
  'Lputian': {
    'name': 'Smbat Lputian',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'MacKenzie': {
    'name': 'George Henry Mackenzie',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Malakhov': {
    'name': 'Vladimir Malakhov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Mamedyarov': {
    'name': 'Shakhriyar Mamedyarov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Aşırı Agresif', 'style_en': 'Extremely Aggressive',
  },
  'Maroczy': {
    'name': 'Geza Maroczy',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Konumsal', 'style_en': 'Positional',
  },
  'Marshall': {
    'name': 'Frank Marshall',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan Taktik', 'style_en': 'Attacking Tactical',
  },
  'McDonnell': {
    'name': 'Alexander McDonnell',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Romantik', 'style_en': 'Romantic',
  },
  'McShane': {
    'name': 'Luke McShane',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Mecking': {
    'name': 'Henrique Mecking',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Mikenas': {
    'name': 'Vladas Mikenas',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Miles': {
    'name': 'Tony Miles',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yaratıcı', 'style_en': 'Creative',
  },
  'Milov': {
    'name': 'Vadim Milov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Morozevich': {
    'name': 'Alexander Morozevich',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sıra Dışı', 'style_en': 'Unorthodox',
  },
  'Morphy': {
    'name': 'Paul Morphy',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': "1850'ler", 'era_en': '1850s',
    'style_tr': 'Gelişim Ustası', 'style_en': 'Development Master',
  },
  'Motylev': {
    'name': 'Alexander Motylev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Movsesian': {
    'name': 'Sergei Movsesian',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Muzychuk': {
    'name': 'Mariya Muzychuk',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Najdorf': {
    'name': 'Miguel Najdorf',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Najer': {
    'name': 'Evgeniy Najer',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Nakamura': {
    'name': 'Hikaru Nakamura',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '2010-Günümüz', 'era_en': '2010-Present',
    'style_tr': 'Hızlı Taktik', 'style_en': 'Fast Tactical',
  },
  'Navara': {
    'name': 'David Navara',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Savaşçı', 'style_en': 'Fighter',
  },
  'Negi': {
    'name': 'Parimarjan Negi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Nepomniachtchi': {
    'name': 'Ian Nepomniachtchi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Hızlı ve Dinamik', 'style_en': 'Fast & Dynamic',
  },
  'Ni': {
    'name': 'Ni Hua',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Nielsen': {
    'name': 'Peter Heine Nielsen',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Nikolic': {
    'name': 'Predrag Nikolic',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Nimzowitsch': {
    'name': 'Aron Nimzowitsch',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Hipermodern', 'style_en': 'Hypermodern',
  },
  'Nisipeanu': {
    'name': 'Liviu-Dieter Nisipeanu',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Novikov': {
    'name': 'Igor Novikov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Nunn': {
    'name': 'John Nunn',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Olafsson': {
    'name': 'Fridrik Olafsson',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Oll': {
    'name': 'Lembit Oll',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Onischuk': {
    'name': 'Alexander Onischuk',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Pachman': {
    'name': 'Ludek Pachman',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Paehtz': {
    'name': 'Elisabeth Paehtz',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Panno': {
    'name': 'Oscar Panno',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Paulsen': {
    'name': 'Louis Paulsen',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Savunmacı', 'style_en': 'Defender',
  },
  'Petrosian': {
    'name': 'Tigran Petrosian',
    'title_tr': '9. Dünya Şampiyonu', 'title_en': '9th World Champion',
    'era_tr': '1963-1969', 'era_en': '1963-1969',
    'style_tr': 'Demir Savunma', 'style_en': 'Iron Defense',
  },
  'Philidor': {
    'name': 'Francois-Andre Danican Philidor',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Piyon Teorisyeni', 'style_en': 'Pawn Theorist',
  },
  'Pillsbury': {
    'name': 'Harry Nelson Pillsbury',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Pilnik': {
    'name': 'Herman Pilnik',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'PolgarJ': {
    'name': 'Judit Polgar',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '1990-2014', 'era_en': '1990-2014',
    'style_tr': 'Amansız Saldırgan', 'style_en': 'Relentless Attacker',
  },
  'PolgarS': {
    'name': 'Susan Polgar',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'PolgarZ': {
    'name': 'Sofia Polgar',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Polugaevsky': {
    'name': 'Lev Polugaevsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Açılış Uzmanı', 'style_en': 'Opening Expert',
  },
  'Ponomariov': {
    'name': 'Ruslan Ponomariov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Evrensel', 'style_en': 'Universal',
  },
  'Portisch': {
    'name': 'Lajos Portisch',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Macar Botvinnik', 'style_en': 'Hungarian Botvinnik',
  },
  'Praggnanandhaa': {
    'name': 'R. Praggnanandhaa',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Çok Yönlü', 'style_en': 'Versatile',
  },
  'Psakhis': {
    'name': 'Lev Psakhis',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Quinteros': {
    'name': 'Miguel Quinteros',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Radjabov': {
    'name': 'Teimour Radjabov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Rapport': {
    'name': 'Richard Rapport',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yaratıcı Dahi', 'style_en': 'Creative Genius',
  },
  'Reshevsky': {
    'name': 'Samuel Reshevsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Mücadeleci', 'style_en': 'Fighter',
  },
  'Reti': {
    'name': 'Richard Reti',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Hipermodern', 'style_en': 'Hypermodern',
  },
  'Ribli': {
    'name': 'Zoltan Ribli',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Rohde': {
    'name': 'Michael Rohde',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Rubinstein': {
    'name': 'Akiba Rubinstein',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Oyun Sonu Sanatçısı', 'style_en': 'Endgame Artist',
  },
  'Rublevsky': {
    'name': 'Sergei Rublevsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Saemisch': {
    'name': 'Friedrich Sämisch',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Sakaev': {
    'name': 'Konstantin Sakaev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Salov': {
    'name': 'Valery Salov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Sasikiran': {
    'name': 'Krishnan Sasikiran',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Schlechter': {
    'name': 'Carl Schlechter',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Seirawan': {
    'name': 'Yasser Seirawan',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Pozisyonel', 'style_en': 'Positional',
  },
  'Serper': {
    'name': 'Grigory Serper',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Shabalov': {
    'name': 'Alexander Shabalov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Shamkovich': {
    'name': 'Leonid Shamkovich',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Shirov': {
    'name': 'Alexei Shirov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Ateşli Taktik', 'style_en': 'Fire on Board',
  },
  'Short': {
    'name': 'Nigel Short',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Evrensel', 'style_en': 'Universal',
  },
  'Shulman': {
    'name': 'Yury Shulman',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Smirin': {
    'name': 'Ilya Smirin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Smyslov': {
    'name': 'Vassily Smyslov',
    'title_tr': '7. Dünya Şampiyonu', 'title_en': '7th World Champion',
    'era_tr': '1957-1958', 'era_en': '1957-1958',
    'style_tr': 'Uyumlu', 'style_en': 'Harmonious',
  },
  'So': {
    'name': 'Wesley So',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Aşırı Sağlam', 'style_en': 'Extremely Solid',
  },
  'Sokolov': {
    'name': 'Ivan Sokolov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Soltis': {
    'name': 'Andrew Soltis',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Spassky': {
    'name': 'Boris Spassky',
    'title_tr': '10. Dünya Şampiyonu', 'title_en': '10th World Champion',
    'era_tr': '1969-1972', 'era_en': '1969-1972',
    'style_tr': 'Evrensel Stratejist', 'style_en': 'Universal Strategist',
  },
  'Speelman': {
    'name': 'Jon Speelman',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Orijinal', 'style_en': 'Original',
  },
  'Spielmann': {
    'name': 'Rudolf Spielmann',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Stahlberg': {
    'name': 'Gideon Stahlberg',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Staunton': {
    'name': 'Howard Staunton',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'İngiliz Okulu', 'style_en': 'English School',
  },
  'Stefanova': {
    'name': 'Antoaneta Stefanova',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Stein': {
    'name': 'Leonid Stein',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Dinamik', 'style_en': 'Dynamic',
  },
  'Steinitz': {
    'name': 'Wilhelm Steinitz',
    'title_tr': '1. Dünya Şampiyonu', 'title_en': '1st World Champion',
    'era_tr': '1886-1894', 'era_en': '1886-1894',
    'style_tr': 'Klasik Teorisyen', 'style_en': 'Classical Theorist',
  },
  'Suetin': {
    'name': 'Alexey Suetin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'SultanKhan': {
    'name': 'Mir Sultan Khan',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Doğal Yetenek', 'style_en': 'Natural Talent',
  },
  'Sutovsky': {
    'name': 'Emil Sutovsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik', 'style_en': 'Tactical',
  },
  'Svidler': {
    'name': 'Peter Svidler',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Dinamik', 'style_en': 'Dynamic',
  },
  'Szabo': {
    'name': 'Laszlo Szabo',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Taimanov': {
    'name': 'Mark Taimanov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Tal': {
    'name': 'Mikhail Tal',
    'title_tr': '8. Dünya Şampiyonu', 'title_en': '8th World Champion',
    'era_tr': '1960-1961', 'era_en': '1960-1961',
    'style_tr': 'Feda Sihirbazı', 'style_en': 'Sacrifice Magician',
  },
  'Tarrasch': {
    'name': 'Siegbert Tarrasch',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Klasik Öğretmen', 'style_en': 'Classical Teacher',
  },
  'Tartakower': {
    'name': 'Savielly Tartakower',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Orijinal', 'style_en': 'Original',
  },
  'Teichmann': {
    'name': 'Richard Teichmann',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Timman': {
    'name': 'Jan Timman',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Yaratıcı', 'style_en': 'Creative',
  },
  'Tiviakov': {
    'name': 'Sergei Tiviakov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Katı', 'style_en': 'Solid',
  },
  'Tkachiev': {
    'name': 'Vladislav Tkachiev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Tomashevsky': {
    'name': 'Evgeny Tomashevsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Profesör', 'style_en': 'Professor',
  },
  'Topalov': {
    'name': 'Veselin Topalov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '2005-2006', 'era_en': '2005-2006',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'TorreRepetto': {
    'name': 'Carlos Torre Repetto',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Uhlmann': {
    'name': 'Wolfgang Uhlmann',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Fransız Savunması Uzmanı', 'style_en': 'French Expert',
  },
  'Unzicker': {
    'name': 'Wolfgang Unzicker',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Ushenina': {
    'name': 'Anna Ushenina',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'VachierLagrave': {
    'name': 'Maxime Vachier-Lagrave',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik ve Najdorf', 'style_en': 'Tactics & Najdorf',
  },
  'Vaganian': {
    'name': 'Rafael Vaganian',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sezgisel', 'style_en': 'Intuitive',
  },
  'VallejoPons': {
    'name': 'Francisco Vallejo Pons',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'VanWely': {
    'name': 'Loek van Wely',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik', 'style_en': 'Tactical',
  },
  'Vitiugov': {
    'name': 'Nikita Vitiugov',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Volokitin': {
    'name': 'Andrei Volokitin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Waitzkin': {
    'name': 'Josh Waitzkin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Wang': {
    'name': 'Wang Hao',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'WangH': {
    'name': 'Wang Hao',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Wei': {
    'name': 'Wei Yi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Taktik Dehası', 'style_en': 'Tactical Genius',
  },
  'Winawer': {
    'name': 'Szymon Winawer',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Wojtaszek': {
    'name': 'Radoslaw Wojtaszek',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Derin Hazırlık', 'style_en': 'Deep Prep',
  },
  'Wojtkiewicz': {
    'name': 'Aleksander Wojtkiewicz',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Wolff': {
    'name': 'Patrick Wolff',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Xie': {
    'name': 'Xie Jun',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Xu': {
    'name': 'Xu Yuhua',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Ye': {
    'name': 'Ye Jiangchuan',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Yermolinsky': {
    'name': 'Alex Yermolinsky',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Yu': {
    'name': 'Yu Yangyi',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Sağlam', 'style_en': 'Solid',
  },
  'Yudasin': {
    'name': 'Leonid Yudasin',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Zhu': {
    'name': 'Zhu Chen',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': '', 'style_en': '',
  },
  'Zukertort': {
    'name': 'Johannes Zukertort',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Saldırgan', 'style_en': 'Aggressive',
  },
  'Zvjaginsev': {
    'name': 'Vadim Zvjaginsev',
    'title_tr': 'Büyükusta', 'title_en': 'Grandmaster',
    'era_tr': '', 'era_en': '',
    'style_tr': 'Orijinal', 'style_en': 'Original',
  },
};

/// ECO kodundan (örn: C50, E62, C42) açılış adını döndürür (Türkçe/İngilizce çift dilli destekli)
String getEcoOpeningName(String? eco) {
  if (eco == null || eco.trim().isEmpty) return '';
  final code = eco.trim().toUpperCase();
  final isEn = LanguageService.currentLang == 'en';

  // 1) Tam 3 haneli eşleşme (Exact match)
  if (kEcoMap.containsKey(code)) {
    final info = kEcoMap[code]!;
    return isEn ? (info['en'] ?? '') : (info['tr'] ?? info['en'] ?? '');
  }

  // 2) 2 haneli önek eşleşmesi (Prefix match, örn: B9 -> Sicilian Najdorf, E6 -> King's Indian)
  if (code.length >= 2) {
    final prefix2 = code.substring(0, 2);
    if (kEcoPrefixMap.containsKey(prefix2)) {
      final info = kEcoPrefixMap[prefix2]!;
      return isEn ? (info['en'] ?? '') : (info['tr'] ?? info['en'] ?? '');
    }
  }

  // 3) 1 haneli önek eşleşmesi (Ana kategori: A, B, C, D, E)
  if (code.isNotEmpty) {
    final prefix1 = code.substring(0, 1);
    if (kEcoCategoryMap.containsKey(prefix1)) {
      final info = kEcoCategoryMap[prefix1]!;
      return isEn ? (info['en'] ?? '') : (info['tr'] ?? info['en'] ?? '');
    }
  }

  return '';
}

/// ECO kategorileri (A, B, C, D, E)
const Map<String, Map<String, String>> kEcoCategoryMap = {
  'A': {'tr': 'Kanat Açılışı', 'en': 'Flank Opening'},
  'B': {'tr': 'Yarı-Açık Oyun', 'en': 'Semi-Open Game'},
  'C': {'tr': 'Açık Oyun', 'en': 'Open Game'},
  'D': {'tr': 'Kapalı Oyun', 'en': 'Closed Game'},
  'E': {'tr': 'Hint Savunması', 'en': 'Indian Defense'},
};

/// 2 Haneli ECO önekleri (A0-E9)
const Map<String, Map<String, String>> kEcoPrefixMap = {
  'A0': {'tr': 'Standart / Nadir Açılış', 'en': 'Uncommon Opening'},
  'A1': {'tr': 'İngiliz Açılışı', 'en': 'English Opening'},
  'A2': {'tr': 'İngiliz Açılışı', 'en': 'English Opening'},
  'A3': {'tr': 'İngiliz Açılışı', 'en': 'English Opening'},
  'A4': {'tr': 'Vezir Piyonu Oyunu', 'en': "Queen's Pawn Game"},
  'A5': {'tr': 'Hint Savunması', 'en': 'Indian Defense'},
  'A6': {'tr': 'Benoni Savunması', 'en': 'Benoni Defense'},
  'A7': {'tr': 'Benoni Savunması', 'en': 'Benoni Defense'},
  'A8': {'tr': 'Hollanda Savunması', 'en': 'Dutch Defense'},
  'A9': {'tr': 'Hollanda Savunması', 'en': 'Dutch Defense'},
  'B0': {'tr': 'Alekhine / İskandinav / Pirc', 'en': 'Alekhine / Scandinavian / Pirc'},
  'B1': {'tr': 'Caro-Kann Savunması', 'en': 'Caro-Kann Defense'},
  'B2': {'tr': 'Sicilya Savunması', 'en': 'Sicilian Defense'},
  'B3': {'tr': 'Sicilya Savunması', 'en': 'Sicilian Defense'},
  'B4': {'tr': 'Sicilya Savunması', 'en': 'Sicilian Defense'},
  'B5': {'tr': 'Sicilya Savunması', 'en': 'Sicilian Defense'},
  'B6': {'tr': 'Sicilya Savunması', 'en': 'Sicilian Defense'},
  'B7': {'tr': 'Sicilya: Ejderha', 'en': 'Sicilian: Dragon'},
  'B8': {'tr': 'Sicilya Savunması', 'en': 'Sicilian Defense'},
  'B9': {'tr': 'Sicilya: Najdorf', 'en': 'Sicilian: Najdorf'},
  'C0': {'tr': 'Fransız Savunması', 'en': 'French Defense'},
  'C1': {'tr': 'Fransız Savunması', 'en': 'French Defense'},
  'C2': {'tr': 'Açık Oyun / Viyana / Fil Açılışı', 'en': 'Open Game / Vienna / Bishop\'s Opening'},
  'C3': {'tr': 'Şah Gambiti', 'en': 'King\'s Gambit'},
  'C4': {'tr': 'Petrov / İskoç / Dört At', 'en': 'Petrov / Scotch / Four Knights'},
  'C5': {'tr': 'İtalyan Açılışı / İki At', 'en': 'Italian Game / Two Knights'},
  'C6': {'tr': 'Ruy Lopez (İspanyol Açılışı)', 'en': 'Ruy Lopez'},
  'C7': {'tr': 'Ruy Lopez', 'en': 'Ruy Lopez'},
  'C8': {'tr': 'Ruy Lopez: Açık / Kapalı', 'en': 'Ruy Lopez: Open / Closed'},
  'C9': {'tr': 'Ruy Lopez: Ana Varyantlar', 'en': 'Ruy Lopez: Main Lines'},
  'D0': {'tr': 'Vezir Piyonu / London / Colle', 'en': 'Queen\'s Pawn / London / Colle'},
  'D1': {'tr': 'Slav Savunması', 'en': 'Slav Defense'},
  'D2': {'tr': 'Vezir Gambiti Kabul Edilen', 'en': 'Queen\'s Gambit Accepted'},
  'D3': {'tr': 'Vezir Gambiti Reddedilen', 'en': 'Queen\'s Gambit Declined'},
  'D4': {'tr': 'Yarı-Slav Savunması', 'en': 'Semi-Slav Defense'},
  'D5': {'tr': 'Vezir Gambiti Reddedilen', 'en': 'Queen\'s Gambit Declined'},
  'D6': {'tr': 'Vezir Gambiti Reddedilen', 'en': 'Queen\'s Gambit Declined'},
  'D7': {'tr': 'Neo-Grünfeld Savunması', 'en': 'Neo-Grünfeld Defense'},
  'D8': {'tr': 'Grünfeld Savunması', 'en': 'Grünfeld Defense'},
  'D9': {'tr': 'Grünfeld Savunması', 'en': 'Grünfeld Defense'},
  'E0': {'tr': 'Katalan Açılışı', 'en': 'Catalan Opening'},
  'E1': {'tr': 'Vezir Hint / Bogo-Hint Savunması', 'en': 'Queen\'s Indian / Bogo-Indian'},
  'E2': {'tr': 'Nimzo-Hint Savunması', 'en': 'Nimzo-Indian Defense'},
  'E3': {'tr': 'Nimzo-Hint Savunması', 'en': 'Nimzo-Indian Defense'},
  'E4': {'tr': 'Nimzo-Hint Savunması', 'en': 'Nimzo-Indian Defense'},
  'E5': {'tr': 'Nimzo-Hint Savunması', 'en': 'Nimzo-Indian Defense'},
  'E6': {'tr': 'Şah Hint Savunması', 'en': 'King\'s Indian Defense'},
  'E7': {'tr': 'Şah Hint Savunması', 'en': 'King\'s Indian Defense'},
  'E8': {'tr': 'Şah Hint Savunması', 'en': 'King\'s Indian Defense'},
  'E9': {'tr': 'Şah Hint Savunması: Ana Varyant', 'en': 'King\'s Indian Defense: Main Line'},
};

/// Popüler ve Yaygın Tam 3 Haneli ECO Kodları
const Map<String, Map<String, String>> kEcoMap = {
  // A serisi
  'A00': {'tr': 'Standart / Nadir Açılış', 'en': 'Uncommon Opening'},
  'A01': {'tr': 'Nimzo-Larsen Atağı', 'en': 'Nimzo-Larsen Attack'},
  'A02': {'tr': 'Bird Açılışı', 'en': 'Bird\'s Opening'},
  'A03': {'tr': 'Bird Açılışı', 'en': 'Bird\'s Opening'},
  'A04': {'tr': 'Réti Açılışı', 'en': 'Réti Opening'},
  'A05': {'tr': 'Réti Açılışı', 'en': 'Réti Opening'},
  'A06': {'tr': 'Réti Açılışı', 'en': 'Réti Opening'},
  'A07': {'tr': 'Şah Hint Atağı (KIA)', 'en': 'King\'s Indian Attack'},
  'A08': {'tr': 'Şah Hint Atağı (KIA)', 'en': 'King\'s Indian Attack'},
  'A09': {'tr': 'Réti Açılışı', 'en': 'Réti Opening'},
  'A10': {'tr': 'İngiliz Açılışı', 'en': 'English Opening'},
  'A13': {'tr': 'İngiliz Açılışı', 'en': 'English Opening'},
  'A15': {'tr': 'İngiliz Açılışı: Anglo-Hint', 'en': 'English: Anglo-Indian'},
  'A20': {'tr': 'İngiliz Açılışı: Şah İngiliz', 'en': 'English: King\'s English'},
  'A29': {'tr': 'İngiliz Açılışı: Dört At', 'en': 'English: Four Knights'},
  'A30': {'tr': 'İngiliz Açılışı: Simetrik', 'en': 'English: Symmetrical'},
  'A33': {'tr': 'İngiliz Açılışı: Simetrik', 'en': 'English: Symmetrical'},
  'A40': {'tr': 'Vezir Piyonu Oyunu', 'en': 'Queen\'s Pawn Game'},
  'A41': {'tr': 'Vezir Piyonu / Eski Hint', 'en': 'Queen\'s Pawn / Old Indian'},
  'A43': {'tr': 'Eski Benoni Savunması', 'en': 'Old Benoni Defense'},
  'A45': {'tr': 'Trompowsky / Hint Savunması', 'en': 'Trompowsky / Indian Defense'},
  'A46': {'tr': 'Vezir Piyonu / Torre Atağı', 'en': 'Queen\'s Pawn / Torre Attack'},
  'A48': {'tr': 'London Sistemi / Şah Hint', 'en': 'London System / King\'s Indian'},
  'A50': {'tr': 'Hint Savunması / Kraliçe Hint', 'en': 'Indian Game'},
  'A51': {'tr': 'Budapeşte Gambiti', 'en': 'Budapest Gambit'},
  'A52': {'tr': 'Budapeşte Gambiti', 'en': 'Budapest Gambit'},
  'A56': {'tr': 'Benoni Savunması', 'en': 'Benoni Defense'},
  'A57': {'tr': 'Benko Gambiti', 'en': 'Benko Gambit'},
  'A58': {'tr': 'Benko Gambiti Kabul Edilen', 'en': 'Benko Gambit Accepted'},
  'A60': {'tr': 'Modern Benoni', 'en': 'Modern Benoni Defense'},
  'A70': {'tr': 'Modern Benoni: Klasik', 'en': 'Modern Benoni: Classical'},
  'A80': {'tr': 'Hollanda Savunması', 'en': 'Dutch Defense'},
  'A85': {'tr': 'Hollanda Savunması', 'en': 'Dutch Defense'},
  'A88': {'tr': 'Hollanda Savunması: Leningrad', 'en': 'Dutch Defense: Leningrad'},
  'A90': {'tr': 'Hollanda Savunması', 'en': 'Dutch Defense'},

  // B serisi
  'B00': {'tr': 'Şah Piyonu / Nimzowitsch', 'en': 'King\'s Pawn / Nimzowitsch'},
  'B01': {'tr': 'İskandinav Savunması', 'en': 'Scandinavian Defense'},
  'B02': {'tr': 'Alekhine Savunması', 'en': 'Alekhine Defense'},
  'B03': {'tr': 'Alekhine Savunması', 'en': 'Alekhine Defense'},
  'B04': {'tr': 'Alekhine Savunması: Modern', 'en': 'Alekhine Defense: Modern'},
  'B06': {'tr': 'Modern Savunma', 'en': 'Modern Defense'},
  'B07': {'tr': 'Pirc Savunması', 'en': 'Pirc Defense'},
  'B08': {'tr': 'Pirc Savunması: Klasik', 'en': 'Pirc Defense: Classical'},
  'B09': {'tr': 'Pirc Savunması: Avusturya Atağı', 'en': 'Pirc Defense: Austrian Attack'},
  'B10': {'tr': 'Caro-Kann Savunması', 'en': 'Caro-Kann Defense'},
  'B12': {'tr': 'Caro-Kann: İlerleme Varyantı', 'en': 'Caro-Kann: Advance Variation'},
  'B13': {'tr': 'Caro-Kann: Değişim Varyantı', 'en': 'Caro-Kann: Exchange Variation'},
  'B15': {'tr': 'Caro-Kann: Ana Varyant', 'en': 'Caro-Kann: Main Line'},
  'B18': {'tr': 'Caro-Kann: Klasik Varyant', 'en': 'Caro-Kann: Classical Variation'},
  'B20': {'tr': 'Sicilya Savunması', 'en': 'Sicilian Defense'},
  'B21': {'tr': 'Sicilya: Smith-Morra / Grand Prix', 'en': 'Sicilian: Smith-Morra / Grand Prix'},
  'B22': {'tr': 'Sicilya: Alapin Varyantı', 'en': 'Sicilian: Alapin Variation'},
  'B23': {'tr': 'Sicilya: Kapalı Varyant', 'en': 'Sicilian: Closed Variation'},
  'B25': {'tr': 'Sicilya: Kapalı Varyant', 'en': 'Sicilian: Closed Variation'},
  'B27': {'tr': 'Sicilya: Açık Varyant', 'en': 'Sicilian: Open Variation'},
  'B30': {'tr': 'Sicilya: Rossolimo Varyantı', 'en': 'Sicilian: Rossolimo Variation'},
  'B31': {'tr': 'Sicilya: Rossolimo Varyantı', 'en': 'Sicilian: Rossolimo Variation'},
  'B33': {'tr': 'Sicilya: Sveshnikov / Pelikan', 'en': 'Sicilian: Sveshnikov Variation'},
  'B40': {'tr': 'Sicilya: Paulsen / Kan', 'en': 'Sicilian: Paulsen / Kan'},
  'B42': {'tr': 'Sicilya: Kan Varyantı', 'en': 'Sicilian: Kan Variation'},
  'B45': {'tr': 'Sicilya: Taimanov Varyantı', 'en': 'Sicilian: Taimanov Variation'},
  'B50': {'tr': 'Sicilya: Klasik / Moscow', 'en': 'Sicilian: Classical / Moscow'},
  'B51': {'tr': 'Sicilya: Moscow Varyantı', 'en': 'Sicilian: Moscow Variation'},
  'B52': {'tr': 'Sicilya: Moscow Varyantı', 'en': 'Sicilian: Moscow Variation'},
  'B60': {'tr': 'Sicilya: Richter-Rauzer', 'en': 'Sicilian: Richter-Rauzer'},
  'B70': {'tr': 'Sicilya: Ejderha Varyantı', 'en': 'Sicilian: Dragon Variation'},
  'B72': {'tr': 'Sicilya: Ejderha Varyantı', 'en': 'Sicilian: Dragon Variation'},
  'B75': {'tr': 'Sicilya: Ejderha (Yugoslav Atağı)', 'en': 'Sicilian: Dragon (Yugoslav Attack)'},
  'B80': {'tr': 'Sicilya: Scheveningen Varyantı', 'en': 'Sicilian: Scheveningen Variation'},
  'B85': {'tr': 'Sicilya: Scheveningen Varyantı', 'en': 'Sicilian: Scheveningen Variation'},
  'B90': {'tr': 'Sicilya: Najdorf Varyantı', 'en': 'Sicilian: Najdorf Variation'},
  'B92': {'tr': 'Sicilya: Najdorf (Opocensky)', 'en': 'Sicilian: Najdorf (Opocensky)'},
  'B95': {'tr': 'Sicilya: Najdorf Varyantı', 'en': 'Sicilian: Najdorf Variation'},
  'B97': {'tr': 'Sicilya: Najdorf (Zehirli Piyon)', 'en': 'Sicilian: Najdorf (Poisoned Pawn)'},
  'B99': {'tr': 'Sicilya: Najdorf Ana Varyant', 'en': 'Sicilian: Najdorf Main Line'},

  // C serisi
  'C00': {'tr': 'Fransız Savunması', 'en': 'French Defense'},
  'C01': {'tr': 'Fransız Savunması: Değişim', 'en': 'French: Exchange Variation'},
  'C02': {'tr': 'Fransız Savunması: İlerleme', 'en': 'French: Advance Variation'},
  'C03': {'tr': 'Fransız Savunması: Tarrasch', 'en': 'French: Tarrasch Variation'},
  'C05': {'tr': 'Fransız Savunması: Tarrasch', 'en': 'French: Tarrasch Variation'},
  'C10': {'tr': 'Fransız Savunması: Rubinstein', 'en': 'French: Rubinstein Variation'},
  'C11': {'tr': 'Fransız Savunması: Klasik / Steinitz', 'en': 'French: Classical / Steinitz'},
  'C15': {'tr': 'Fransız Savunması: Winawer', 'en': 'French: Winawer Variation'},
  'C18': {'tr': 'Fransız Savunması: Winawer Ana', 'en': 'French: Winawer Main Line'},
  'C20': {'tr': 'Açık Oyun / Şah Piyonu', 'en': 'Open Game / King\'s Pawn'},
  'C21': {'tr': 'Danimarka Gambiti / Merkez', 'en': 'Danish Gambit / Center Game'},
  'C23': {'tr': 'Fil Açılışı', 'en': 'Bishop\'s Opening'},
  'C24': {'tr': 'Fil Açılışı: Berlin Savunması', 'en': 'Bishop\'s Opening: Berlin'},
  'C25': {'tr': 'Viyana Oyunu', 'en': 'Vienna Game'},
  'C30': {'tr': 'Şah Gambiti', 'en': 'King\'s Gambit'},
  'C33': {'tr': 'Şah Gambiti Kabul Edilen', 'en': 'King\'s Gambit Accepted'},
  'C36': {'tr': 'Şah Gambiti Kabul Edilen: Modern', 'en': 'King\'s Gambit: Modern Defense'},
  'C40': {'tr': 'Letonya / Fil Piyon Oyunu', 'en': 'Latvian Gambit / King\'s Knight'},
  'C41': {'tr': 'Philidor Savunması', 'en': 'Philidor Defense'},
  'C42': {'tr': 'Petrov Savunması (Rus Oyunu)', 'en': 'Petrov\'s Defense (Russian Game)'},
  'C43': {'tr': 'Petrov Savunması: Modern Atak', 'en': 'Petrov\'s Defense: Modern Attack'},
  'C44': {'tr': 'İskoç / Ponziani Açılışı', 'en': 'Scotch Game / Ponziani'},
  'C45': {'tr': 'İskoç Oyunu', 'en': 'Scotch Game'},
  'C46': {'tr': 'Üç At Oyunu', 'en': 'Three Knights Game'},
  'C47': {'tr': 'Dört At Oyunu: İskoç Varyantı', 'en': 'Four Knights: Scotch Variation'},
  'C48': {'tr': 'Dört At Oyunu: İspanyol Varyantı', 'en': 'Four Knights: Spanish Variation'},
  'C50': {'tr': 'İtalyan Açılışı / Giuoco Piano', 'en': 'Italian Game / Giuoco Piano'},
  'C51': {'tr': 'Evans Gambiti', 'en': 'Evans Gambit'},
  'C52': {'tr': 'Evans Gambiti', 'en': 'Evans Gambit'},
  'C53': {'tr': 'İtalyan Açılışı (Giuoco Piano)', 'en': 'Italian Game (Giuoco Piano)'},
  'C54': {'tr': 'İtalyan Açılışı (Giuoco Piano)', 'en': 'Italian Game (Giuoco Piano)'},
  'C55': {'tr': 'İki At Savunması', 'en': 'Two Knights Defense'},
  'C56': {'tr': 'İki At Savunması', 'en': 'Two Knights Defense'},
  'C57': {'tr': 'İki At Savunması: Fried Liver', 'en': 'Two Knights: Fried Liver Attack'},
  'C60': {'tr': 'Ruy Lopez (İspanyol Açılışı)', 'en': 'Ruy Lopez (Spanish Opening)'},
  'C61': {'tr': 'Ruy Lopez: Bird Savunması', 'en': 'Ruy Lopez: Bird\'s Defense'},
  'C62': {'tr': 'Ruy Lopez: Eski Steinitz', 'en': 'Ruy Lopez: Old Steinitz'},
  'C63': {'tr': 'Ruy Lopez: Schliemann Gambiti', 'en': 'Ruy Lopez: Schliemann Defense'},
  'C65': {'tr': 'Ruy Lopez: Berlin Savunması', 'en': 'Ruy Lopez: Berlin Defense'},
  'C67': {'tr': 'Ruy Lopez: Berlin Savunması Ana', 'en': 'Ruy Lopez: Berlin Wall'},
  'C68': {'tr': 'Ruy Lopez: Değişim Varyantı', 'en': 'Ruy Lopez: Exchange Variation'},
  'C70': {'tr': 'Ruy Lopez', 'en': 'Ruy Lopez'},
  'C77': {'tr': 'Ruy Lopez: Morphy Savunması', 'en': 'Ruy Lopez: Morphy Defense'},
  'C78': {'tr': 'Ruy Lopez: Archangelsk / Möller', 'en': 'Ruy Lopez: Archangelsk / Möller'},
  'C80': {'tr': 'Ruy Lopez: Açık Varyant', 'en': 'Ruy Lopez: Open Variation'},
  'C84': {'tr': 'Ruy Lopez: Kapalı Varyant', 'en': 'Ruy Lopez: Closed Variation'},
  'C88': {'tr': 'Ruy Lopez: Kapalı Varyant', 'en': 'Ruy Lopez: Closed Variation'},
  'C89': {'tr': 'Ruy Lopez: Marshall Atağı', 'en': 'Ruy Lopez: Marshall Attack'},
  'C92': {'tr': 'Ruy Lopez: Zaitsev Varyantı', 'en': 'Ruy Lopez: Zaitsev Variation'},
  'C95': {'tr': 'Ruy Lopez: Breyer Varyantı', 'en': 'Ruy Lopez: Breyer Variation'},
  'C98': {'tr': 'Ruy Lopez: Chigorin Varyantı', 'en': 'Ruy Lopez: Chigorin Variation'},

  // D serisi
  'D00': {'tr': 'Vezir Piyonu / London Sistemi', 'en': 'Queen\'s Pawn / London System'},
  'D02': {'tr': 'Vezir Piyonu / London Sistemi', 'en': 'Queen\'s Pawn Game: London System'},
  'D03': {'tr': 'Torre Atağı (Tartakower)', 'en': 'Torre Attack'},
  'D04': {'tr': 'Colle Sistemi', 'en': 'Colle System'},
  'D05': {'tr': 'Colle Sistemi', 'en': 'Colle System'},
  'D06': {'tr': 'Vezir Gambiti', 'en': 'Queen\'s Gambit'},
  'D07': {'tr': 'Vezir Gambiti: Chigorin Savunması', 'en': 'Queen\'s Gambit: Chigorin Defense'},
  'D08': {'tr': 'Albin Karşı Gambiti', 'en': 'Albin Countergambit'},
  'D10': {'tr': 'Slav Savunması', 'en': 'Slav Defense'},
  'D11': {'tr': 'Slav Savunması: Modern', 'en': 'Slav Defense: Modern Line'},
  'D15': {'tr': 'Slav Savunması: Çek Varyantı', 'en': 'Slav Defense: Chebanenko'},
  'D17': {'tr': 'Slav Savunması: Alapin Varyantı', 'en': 'Slav Defense: Alapin'},
  'D20': {'tr': 'Vezir Gambiti Kabul Edilen (QGA)', 'en': 'Queen\'s Gambit Accepted'},
  'D27': {'tr': 'Vezir Gambiti Kabul Edilen Klasik', 'en': 'Queen\'s Gambit Accepted: Classical'},
  'D30': {'tr': 'Vezir Gambiti Reddedilen (QGD)', 'en': 'Queen\'s Gambit Declined'},
  'D31': {'tr': 'Vezir Gambiti Reddedilen (QGD)', 'en': 'Queen\'s Gambit Declined'},
  'D35': {'tr': 'Vezir Gambiti Reddedilen Değişim', 'en': 'QGD: Exchange Variation'},
  'D37': {'tr': 'Vezir Gambiti Reddedilen', 'en': 'Queen\'s Gambit Declined'},
  'D38': {'tr': 'QGD: Ragozin Savunması', 'en': 'QGD: Ragozin Defense'},
  'D43': {'tr': 'Yarı-Slav Savunması', 'en': 'Semi-Slav Defense'},
  'D44': {'tr': 'Yarı-Slav: Botvinnik / Anti-Meran', 'en': 'Semi-Slav: Botvinnik / Anti-Meran'},
  'D45': {'tr': 'Yarı-Slav: Meran Varyantı', 'en': 'Semi-Slav: Meran Variation'},
  'D50': {'tr': 'QGD: Klasik Varyant', 'en': 'QGD: Classical Variation'},
  'D52': {'tr': 'QGD: Cambridge Springs Savunması', 'en': 'QGD: Cambridge Springs Defense'},
  'D53': {'tr': 'QGD: Ortodoks Savunması', 'en': 'QGD: Orthodox Defense'},
  'D60': {'tr': 'QGD: Ortodoks Savunması', 'en': 'QGD: Orthodox Defense'},
  'D70': {'tr': 'Neo-Grünfeld Savunması', 'en': 'Neo-Grünfeld Defense'},
  'D80': {'tr': 'Grünfeld Savunması', 'en': 'Grünfeld Defense'},
  'D85': {'tr': 'Grünfeld Savunması: Değişim', 'en': 'Grünfeld Defense: Exchange'},
  'D86': {'tr': 'Grünfeld Savunması: Değişim Klasik', 'en': 'Grünfeld Defense: Exchange Classical'},
  'D90': {'tr': 'Grünfeld Savunması', 'en': 'Grünfeld Defense'},

  // E serisi
  'E00': {'tr': 'Vezir Piyonu / Katalan Açılışı', 'en': 'Queen\'s Pawn / Catalan Opening'},
  'E01': {'tr': 'Katalan Açılışı: Kapalı', 'en': 'Catalan Opening: Closed'},
  'E04': {'tr': 'Katalan Açılışı: Açık Varyant', 'en': 'Catalan Opening: Open'},
  'E05': {'tr': 'Katalan Açılışı: Açık Klasik', 'en': 'Catalan Opening: Open Classical'},
  'E06': {'tr': 'Katalan Açılışı: Kapalı Varyant', 'en': 'Catalan Opening: Closed'},
  'E10': {'tr': 'Blumenfeld Gambiti', 'en': 'Blumenfeld Gambit'},
  'E11': {'tr': 'Bogo-Hint Savunması', 'en': 'Bogo-Indian Defense'},
  'E12': {'tr': 'Vezir Hint Savunması (QID)', 'en': 'Queen\'s Indian Defense'},
  'E15': {'tr': 'Vezir Hint Savunması: Nimzowitsch', 'en': 'Queen\'s Indian: Nimzowitsch'},
  'E17': {'tr': 'Vezir Hint Savunması: Klasik', 'en': 'Queen\'s Indian: Classical'},
  'E20': {'tr': 'Nimzo-Hint Savunması', 'en': 'Nimzo-Indian Defense'},
  'E21': {'tr': 'Nimzo-Hint: Üç At Varyantı', 'en': 'Nimzo-Indian: Three Knights'},
  'E24': {'tr': 'Nimzo-Hint: Sämisch Varyantı', 'en': 'Nimzo-Indian: Sämisch Variation'},
  'E32': {'tr': 'Nimzo-Hint: Klasik Varyant', 'en': 'Nimzo-Indian: Classical Variation'},
  'E34': {'tr': 'Nimzo-Hint: Klasik Varyant', 'en': 'Nimzo-Indian: Classical Variation'},
  'E40': {'tr': 'Nimzo-Hint: Rubinstein Varyantı', 'en': 'Nimzo-Indian: Rubinstein Variation'},
  'E50': {'tr': 'Nimzo-Hint: Rubinstein Varyantı', 'en': 'Nimzo-Indian: Rubinstein Variation'},
  'E60': {'tr': 'Şah Hint Savunması (KID)', 'en': 'King\'s Indian Defense'},
  'E61': {'tr': 'Şah Hint Savunması', 'en': 'King\'s Indian Defense'},
  'E62': {'tr': 'Şah Hint: Fianchetto Varyantı', 'en': 'King\'s Indian: Fianchetto Variation'},
  'E63': {'tr': 'Şah Hint: Fianchetto Panno', 'en': 'King\'s Indian: Fianchetto Panno'},
  'E67': {'tr': 'Şah Hint: Fianchetto Klasik', 'en': 'King\'s Indian: Fianchetto Classical'},
  'E70': {'tr': 'Şah Hint Savunması', 'en': 'King\'s Indian Defense'},
  'E73': {'tr': 'Şah Hint: Averbakh Varyantı', 'en': 'King\'s Indian: Averbakh Variation'},
  'E80': {'tr': 'Şah Hint: Sämisch Varyantı', 'en': 'King\'s Indian: Sämisch Variation'},
  'E81': {'tr': 'Şah Hint: Sämisch Varyantı', 'en': 'King\'s Indian: Sämisch Variation'},
  'E90': {'tr': 'Şah Hint: Klasik Varyant', 'en': 'King\'s Indian: Classical Variation'},
  'E92': {'tr': 'Şah Hint: Klasik Varyant', 'en': 'King\'s Indian: Classical Variation'},
  'E97': {'tr': 'Şah Hint: Klasik Mar del Plata', 'en': 'King\'s Indian: Mar del Plata'},
  'E99': {'tr': 'Şah Hint: Klasik Ana Varyant', 'en': 'King\'s Indian: Classical Main Line'},
};

/// Büyük Ustalar Listesi Ekranı
class MastersListPage extends StatefulWidget {
  const MastersListPage({super.key});

  @override
  State<MastersListPage> createState() => _MastersListPageState();
}

class _MastersListPageState extends State<MastersListPage> {
  List<String> _allPaths = [];
  List<String> _filteredPaths = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMasterList();
    _searchController.addListener(_filterMasters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMasters() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredPaths = List.from(_allPaths);
      });
    } else {
      setState(() {
        _filteredPaths = _allPaths.where((path) {
          final name = masterNameFromFilename(path.split('/').last);
          final fullName = getMasterFullName(name).toLowerCase();
          final info = kMasterInfo[name] ?? {};
          final isEn = LanguageService.currentLang == 'en';
          final title = (info[isEn ? 'title_en' : 'title_tr'] ?? info['title'] ?? '').toLowerCase();
          final style = (info[isEn ? 'style_en' : 'style_tr'] ?? info['style'] ?? '').toLowerCase();
          return name.toLowerCase().contains(query) || fullName.contains(query) || title.contains(query) || style.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadMasterList() async {
    try {
      const knownMasters = [
        'Carlsen_selected.pgn',
        'Kasparov_selected.pgn',
        'Fischer_selected.pgn',
        'Tal_selected.pgn',
        'Alekhine_selected.pgn',
        'Capablanca_selected.pgn',
        'Karpov_selected.pgn',
        'Kramnik_selected.pgn',
        'Anand_selected.pgn',
        'Lasker_selected.pgn',
        'Steinitz_selected.pgn',
        'Spassky_selected.pgn',
        'Petrosian_selected.pgn',
        'Nakamura_selected.pgn',
        'Caruana_selected.pgn',
        'Ding_selected.pgn',
        'Giri_selected.pgn',
        'Nepomniachtchi_selected.pgn',
        'So_selected.pgn',
        'Karjakin_selected.pgn',
      ];
      final existing = <String>[];
      for (final name in knownMasters) {
        try {
          await rootBundle.load('assets/pgn_masters/$name');
          existing.add('assets/pgn_masters/$name');
        } catch (_) {
          // asset bulunamadıysa atla
        }
      }
      
      // TÜM OYUNCULARIN BULUT MAÇ ARŞİVİ
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Abdusattorov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Adams.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Akobian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Akopian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Alburt.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Alekhine.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Alekseev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Almasi.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Anand.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Anderssen.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Andersson.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Andreikin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Aronian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ashley.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Averbakh.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Azmaiparashvili.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bacrot.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bareev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/BecerraRivero.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Beliavsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Benjamin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Benko.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Berliner.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bernstein.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bird.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bisguier.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Blackburne.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Blatny.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bogoljubow.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Boleslavsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bologan.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Botvinnik.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Breyer.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bronstein.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Browne.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bruzon.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Bu.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Byrne.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Capablanca.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Carlsen.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Caruana.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Chiburdanidze.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Chigorin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Christiansen.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/DeFirmian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/DeLaBourdonnais.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Denker.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ding.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/DominguezPerez.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Dreev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Duda.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Dzindzichashvili.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ehlvest.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Eljanov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Erigaisi.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Euwe.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Evans.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Fedorowicz.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Fine.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Finegold.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Firouzja.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Fischer.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Fishbein.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Flohr.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Gaprindashvili.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Gashimov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Gelfand.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Geller.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Georgiev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Giri.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Gligoric.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Goldin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/GrandaZuniga.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Grischuk.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Gukesh.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Gulko.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Gunsberg.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/GurevichD.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/GurevichM.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Harikrishna.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Hort.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Horwitz.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Hou.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Huebner.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ibragimov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/IllescasCordoba.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Inarkiev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ivanchuk.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/IvanovA.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/IvanovI.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ivkov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Jakovenko.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Janowski.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Jobava.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Jussupow.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kaidanov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kamsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Karjakin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Karpov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kasimdzhanov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kasparov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kavalek.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Keres.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Keymer.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Khalifman.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kholmov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Koneru.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Korchnoi.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Korobov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kosteniuk.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kotov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kramnik.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Krasenkow.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Krush.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Kudrin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Lahno.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Larsen.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Lasker.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Lautier.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Le.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Leko.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Levenfish.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Li.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Lilienthal.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ljubojevic.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Lputian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/MacKenzie.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Malakhov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Mamedyarov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Maroczy.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Marshall.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/McDonnell.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/McShane.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Mecking.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Mikenas.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Miles.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Milov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Morozevich.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Morphy.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Motylev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Movsesian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Muzychuk.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Najdorf.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Najer.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Nakamura.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Navara.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Negi.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Nepomniachtchi.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ni.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Nielsen.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Nikolic.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Nimzowitsch.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Nisipeanu.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Novikov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Nunn.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Olafsson.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Oll.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Onischuk.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Pachman.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Paehtz.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Panno.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Paulsen.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Petrosian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Philidor.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Pillsbury.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Pilnik.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/PolgarJ.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/PolgarS.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/PolgarZ.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Polugaevsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ponomariov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Portisch.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Praggnanandhaa.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Psakhis.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Quinteros.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Radjabov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Rapport.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Reshevsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Reti.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ribli.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Rohde.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Rubinstein.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Rublevsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Saemisch.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Sakaev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Salov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Sasikiran.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Schlechter.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Seirawan.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Serper.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Shabalov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Shamkovich.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Shirov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Short.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Shulman.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Smirin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Smyslov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/So.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Sokolov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Soltis.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Spassky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Speelman.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Spielmann.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Stahlberg.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Staunton.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Stefanova.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Stein.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Steinitz.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Suetin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/SultanKhan.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Sutovsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Svidler.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Szabo.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Taimanov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Tal.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Tarrasch.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Tartakower.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Teichmann.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Timman.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Tiviakov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Tkachiev.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Tomashevsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Topalov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/TorreRepetto.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Uhlmann.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Unzicker.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ushenina.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/VachierLagrave.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Vaganian.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/VallejoPons.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/VanWely.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Vitiugov.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Volokitin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Waitzkin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Wang.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/WangH.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Wei.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Winawer.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Wojtaszek.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Wojtkiewicz.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Wolff.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Xie.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Xu.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Ye.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Yermolinsky.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Yu.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Yudasin.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Zhu.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Zukertort.pgn');
      existing.add('https://raw.githubusercontent.com/eymencanorman/chess-pgn-archive/main/Zvjaginsev.pgn');


      if (!mounted) return;
      setState(() {
        _allPaths = existing;
        _filteredPaths = existing;
        _loading = false;
        _error = existing.isEmpty ? LanguageService.get('no_pgn_files') : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.amberAccent;
    return Scaffold(
      backgroundColor: const Color(0xFF0F131E),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: themeColor, size: 24),
            const SizedBox(width: 8),
            Text(
              LanguageService.get('master_archive'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF151B2B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Banner & Arama Alanı
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF151B2B),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            LanguageService.get('master_archive_desc'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: LanguageService.get('search_master'),
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: themeColor),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFF0F131E),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: themeColor.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: themeColor, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _filteredPaths.isEmpty
                          ? Center(
                              child: Text(
                                LanguageService.get('no_games_found'),
                                style: const TextStyle(color: Colors.white54, fontSize: 15),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filteredPaths.length,
                              itemBuilder: (context, index) {
                                final path = _filteredPaths[index];
                                final name = masterNameFromFilename(path.split('/').last);
                                final fullName = getMasterFullName(name);
                                final info = kMasterInfo[name] ?? {};
                                final isEn = LanguageService.currentLang == 'en';
                                final title = info[isEn ? 'title_en' : 'title_tr'] ?? info['title'] ?? (isEn ? 'Grandmaster' : 'Büyük Usta');
                                final era = info[isEn ? 'era_en' : 'era_tr'] ?? info['era'] ?? '';
                                final style = info[isEn ? 'style_en' : 'style_tr'] ?? info['style'] ?? (isEn ? 'Classical' : 'Klasik');

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MasterGamesListPage(
                                              masterName: fullName,
                                              assetPath: path,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF151B2B),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: themeColor.withValues(alpha: 0.25)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 54,
                                              height: 54,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    themeColor.withValues(alpha: 0.2),
                                                    const Color(0xFF151B2B),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: themeColor.withValues(alpha: 0.5)),
                                              ),
                                              child: const Icon(
                                                Icons.emoji_events,
                                                color: themeColor,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          fullName,
                                                          style: const TextStyle(
                                                            fontSize: 17,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (era.isNotEmpty) ...[
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          '• $era',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.white54,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: themeColor.withValues(alpha: 0.9),
                                                    ),
                                                  ),
                                                  if (style.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.05),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        style,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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

/// Seçilen Büyük Ustanın Oyunlarını Listeleme Ekranı
class MasterGamesListPage extends StatefulWidget {
  final String masterName;
  final String assetPath;

  const MasterGamesListPage({
    super.key,
    required this.masterName,
    required this.assetPath,
  });

  @override
  State<MasterGamesListPage> createState() => _MasterGamesListPageState();
}

class _MasterGamesListPageState extends State<MasterGamesListPage> {
  List<MasterGame> _allGames = [];
  List<MasterGame> _filteredGames = [];
  bool _loading = true;
  String? _error;
  bool _isAscending = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGames();
    _searchController.addListener(_filterGames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sortGamesList(List<MasterGame> list) {
    list.sort((a, b) {
      final da = a.date.replaceAll('?', '0');
      final db = b.date.replaceAll('?', '0');
      return _isAscending ? da.compareTo(db) : db.compareTo(da);
    });
  }

  void _filterGames() {
    final query = _searchController.text.toLowerCase().trim();
    List<MasterGame> result = [];
    if (query.isEmpty) {
      result = List.from(_allGames);
    } else {
      result = _allGames.where((g) {
        final title = g.displayTitle.toLowerCase();
        final event = g.event.toLowerCase();
        final date = g.date.toLowerCase();
        final eco = (g.eco ?? '').toLowerCase();
        return title.contains(query) || event.contains(query) || date.contains(query) || eco.contains(query);
      }).toList();
    }
    
    _sortGamesList(result);
    setState(() {
      _filteredGames = result;
    });
  }

  Future<void> _loadGames() async {
    try {
      String content;
      if (widget.assetPath.startsWith('http')) {
        // BULUT YÖNTEMİ
        final filename = widget.assetPath.split('/').last;
        final dir = await getApplicationDocumentsDirectory();
        final localFile = File('${dir.path}/$filename');

        if (await localFile.exists()) {
          // Önceden indirilmişse, yerel dosyadan oku
          content = await localFile.readAsString();
        } else {
          // İndirilmemişse internetten çek ve yerel dosyaya kaydet
          final response = await http.get(Uri.parse(widget.assetPath));
          if (response.statusCode == 200) {
            content = response.body;
            await localFile.writeAsString(content);
          } else {
            throw Exception('İndirme başarısız (HTTP ${response.statusCode})');
          }
        }
      } else {
        // MEVCUT GÖMÜLÜ (ASSETS) YÖNTEMİ
        content = await rootBundle.loadString(widget.assetPath);
      }

      final blocks = splitPgnGames(content);
      final games = <MasterGame>[];
      for (final block in blocks) {
        final game = parseOneGame(block);
        if (game != null) games.add(game);
      }
      if (!mounted) return;
      _sortGamesList(games);
      setState(() {
        _allGames = games;
        _filteredGames = List.from(games);
        _loading = false;
        _error = games.isEmpty ? LanguageService.get('no_pgn_files') : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openGame(MasterGame game, int index) {
    Map<String, dynamic> matchData = {
      'id': 'master_${widget.masterName}_$index',
      'platform': 'PGN (${widget.masterName})',
      'title': '${game.white} vs ${game.black}',
      'white': game.white,
      'whiteTitle': game.whiteTitle != null && game.whiteTitle!.isNotEmpty ? game.whiteTitle! : 'GM',
      'whiteRating': int.tryParse(game.whiteElo ?? '') ?? 0,
      'black': game.black,
      'blackTitle': game.blackTitle != null && game.blackTitle!.isNotEmpty ? game.blackTitle! : 'GM',
      'blackRating': int.tryParse(game.blackElo ?? '') ?? 0,
      'winner': game.result == '1-0' ? 'white' : game.result == '0-1' ? 'black' : 'draw',
      'speed': game.eco != null && game.eco!.isNotEmpty ? 'ECO ${game.eco!}' : 'PGN',
      'pgn': game.rawPgn,
      'moves': '',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisPage(
          matchData: matchData,
          boardOrientation: PlayerColor.white,
          apiHeaders: const {},
        ),
      ),
    );
  }

  Color _getResultColor(String result) {
    if (result == '1-0') return Colors.greenAccent;
    if (result == '0-1') return Colors.redAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.amberAccent;
    return Scaffold(
      backgroundColor: const Color(0xFF0F131E),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.masterName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            if (!_loading && _error == null)
              Text(
                '${_filteredGames.length} ${LanguageService.get('games_count')}',
                style: const TextStyle(fontSize: 12, color: themeColor, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF151B2B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Arama Alanı
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF151B2B),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: LanguageService.get('search_game'),
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                                prefixIcon: const Icon(Icons.search, color: themeColor),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFF0F131E),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: themeColor.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: themeColor, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F131E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isAscending ? Icons.keyboard_double_arrow_up : Icons.keyboard_double_arrow_down,
                                color: themeColor,
                              ),
                              tooltip: LanguageService.currentLang == 'tr' ? 'Tarihe Göre Sırala' : 'Sort by Date',
                              onPressed: () {
                                setState(() {
                                  _isAscending = !_isAscending;
                                  _filterGames();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _filteredGames.isEmpty
                          ? Center(
                              child: Text(
                                LanguageService.get('no_games_found'),
                                style: const TextStyle(color: Colors.white54, fontSize: 15),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filteredGames.length,
                              itemBuilder: (context, index) {
                                final game = _filteredGames[index];
                                final resColor = _getResultColor(game.result);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _openGame(game, index),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF151B2B),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Üst Bilgi Satırı: ECO ve Tarih/Etkinlik
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      if (game.eco != null && game.eco!.isNotEmpty) ...[
                                                        Flexible(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: themeColor.withValues(alpha: 0.15),
                                                              borderRadius: BorderRadius.circular(4),
                                                              border: Border.all(color: themeColor.withValues(alpha: 0.5)),
                                                            ),
                                                            child: Text(
                                                              getEcoOpeningName(game.eco).isNotEmpty
                                                                  ? '${game.eco!} ${getEcoOpeningName(game.eco)}'
                                                                  : game.eco!,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                                color: themeColor,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                      ],
                                                      Text(
                                                        game.date.isNotEmpty ? game.date : 'Tarih Yok',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: resColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: resColor.withValues(alpha: 0.5)),
                                                  ),
                                                  child: Text(
                                                    game.result,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: resColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Beyaz vs Siyah
                                            Row(
                                              children: [
                                                const Icon(Icons.circle, size: 12, color: Colors.white),
                                                const SizedBox(width: 8),
                                                buildTitleTag(game.whiteTitle != null && game.whiteTitle!.isNotEmpty ? game.whiteTitle! : 'GM'),
                                                Expanded(
                                                  child: Text(
                                                    '${game.white} ${game.whiteElo != null && game.whiteElo!.isNotEmpty ? '(${game.whiteElo})' : ''}',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.circle, size: 12, color: Colors.white38),
                                                const SizedBox(width: 8),
                                                buildTitleTag(game.blackTitle != null && game.blackTitle!.isNotEmpty ? game.blackTitle! : 'GM'),
                                                Expanded(
                                                  child: Text(
                                                    '${game.black} ${game.blackElo != null && game.blackElo!.isNotEmpty ? '(${game.blackElo})' : ''}',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white70,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (game.event.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                game.event,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.white.withValues(alpha: 0.4),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
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
