import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

/// Service to fetch Indonesian Bible data using GetBible API
class BibleApiService {
  // Using GetBible.net - a free, reliable API specifically for Bible data
  // Supports multiple translations including Indonesian
  static const String _baseUrl = 'https://api.getbible.net/v2';
  static const String _translation = 'tb'; // TB = Terjemahan Baru (Indonesian)
  
  /// Fetch a specific chapter from the API
  /// Returns JSON with verses
  Future<Map<String, dynamic>?> fetchChapter(String bookCode, int chapter) async {
    try {
      // GetBible API format: /{translation}/{book}/{chapter}.json
      final url = '$_baseUrl/$_translation/$bookCode/$chapter.json';
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('API REQUEST: $url');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MyApp/1.0 (Flutter Bible Reader)',
        },
      ).timeout(const Duration(seconds: 20));

      print('RESPONSE: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✓ Successfully fetched $bookCode chapter $chapter');
        return data;
      } else if (response.statusCode == 404) {
        print('⚠ Book or chapter not found: $bookCode chapter $chapter');
        return null;
      } else {
        print('✗ API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      print('✗ Network error: $e');
      return null;
    } on TimeoutException catch (e) {
      print('✗ Request timeout: $e');
      return null;
    } catch (e) {
      print('✗ Error fetching Bible chapter: $e');
      return null;
    }
  }

  /// Parse the GetBible API response to extract verses
  List<Map<String, dynamic>> parseVerses(Map<String, dynamic> apiResponse, String bookName, int chapter) {
    final verses = <Map<String, dynamic>>[];
    
    try {
      print('Parsing GetBible API response for $bookName chapter $chapter');
      print('API Response keys: ${apiResponse.keys.toList()}');
      
      // GetBible API structure: {book_nr, book_name, chapter_nr, verses: {"1": {verse, text}, "2": {...}}}
      
      // Try to find verses in the response
      var versesData = apiResponse['verses'] as Map?;
      
      if (versesData != null && versesData.isNotEmpty) {
        print('Found ${versesData.length} verses in API response');
        
        versesData.forEach((key, value) {
          if (value is Map) {
            try {
              final verseNum = int.tryParse(key.toString()) ?? (value['verse'] as int?);
              final text = (value['text'] ?? value['verse_text'] ?? '') as String;
              
              if (text.isNotEmpty && verseNum != null && verseNum > 0) {
                verses.add({
                  'book': bookName,
                  'chapter': chapter,
                  'verse': verseNum,
                  'text': text.trim(),
                });
              }
            } catch (e) {
              print('Error parsing verse $key: $e');
            }
          }
        });
        
        // Sort by verse number
        verses.sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));
        print('✓ Successfully parsed ${verses.length} verses');
      } else {
        print('⚠ No verses found in API response');
        print('Response structure: $apiResponse');
      }
    } catch (e) {
      print('Error parsing verses: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    return verses;
  }

  /// Map Indonesian book names to GetBible API book numbers
  String getBookCode(String indonesianName) {
    // GetBible uses book numbers (1-66) or book names
    const bookCodes = {
      // Old Testament (1-39)
      'Kejadian': '1',
      'Keluaran': '2',
      'Imamat': '3',
      'Bilangan': '4',
      'Ulangan': '5',
      'Yosua': '6',
      'Hakim-hakim': '7',
      'Rut': '8',
      '1 Samuel': '9',
      '2 Samuel': '10',
      '1 Raja-raja': '11',
      '2 Raja-raja': '12',
      '1 Tawarikh': '13',
      '2 Tawarikh': '14',
      'Ezra': '15',
      'Nehemia': '16',
      'Ester': '17',
      'Ayub': '18',
      'Mazmur': '19',
      'Amsal': '20',
      'Pengkhotbah': '21',
      'Kidung Agung': '22',
      'Yesaya': '23',
      'Yeremia': '24',
      'Trenyina': '25',
      'Yehezkiel': '26',
      'Daniel': '27',
      'Hosea': '28',
      'Yoel': '29',
      'Amos': '30',
      'Obaja': '31',
      'Yunus': '32',
      'Mikha': '33',
      'Nahum': '34',
      'Habakuk': '35',
      'Zefanya': '36',
      'Hagai': '37',
      'Zakaria': '38',
      'Maleakhi': '39',
      
      // New Testament (40-66)
      'Matius': '40',
      'Markus': '41',
      'Lukas': '42',
      'Yohanes': '43',
      'Kisah Para Rasul': '44',
      'Roma': '45',
      '1 Korintus': '46',
      '2 Korintus': '47',
      'Galatia': '48',
      'Efesus': '49',
      'Filipi': '50',
      'Kolose': '51',
      '1 Tesalonika': '52',
      '2 Tesalonika': '53',
      '1 Timotius': '54',
      '2 Timotius': '55',
      'Titus': '56',
      'Filemon': '57',
      'Ibrani': '58',
      'Yakobus': '59',
      '1 Petrus': '60',
      '2 Petrus': '61',
      '1 Yohanes': '62',
      '2 Yohanes': '63',
      '3 Yohanes': '64',
      'Yudas': '65',
      'Wahyu': '66',
    };
    
    final code = bookCodes[indonesianName];
    if (code == null) {
      print('⚠ Unknown book: $indonesianName, using default');
      return '1'; // Default to Genesis
    }
    return code;
  }
}
