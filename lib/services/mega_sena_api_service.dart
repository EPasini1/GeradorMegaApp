import 'dart:convert';
import 'package:http/http.dart' as http;

class MegaSenaResult {
  final int contest;
  final String date;
  final List<String> numbers;

  MegaSenaResult({
    required this.contest,
    required this.date,
    required this.numbers,
  });

  String get drawDate => date;
}

class MegaSenaApiService {
  static const String baseUrl = 'https://servicebus2.caixa.gov.br/portaldeloterias/api/megasena';
  
  // Get the latest contest number dynamically
  static Future<int?> getLatestContest() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['numero'];
      } else {
        print('Failed to get latest contest. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting the latest contest: $e');
      return null;
    }
  }
  
  // Get result for a specific contest number
  static Future<MegaSenaResult?> getResult(int contestNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$contestNumber'),
        headers: {'accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MegaSenaResult(
          contest: contestNumber,
          date: data['dataApuracao'],
          numbers: List<String>.from(data['listaDezenas']),
        );
      } else {
        print('Failed to get contest $contestNumber. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching contest $contestNumber: $e');
      return null;
    }
  }
  
  // Main logic to fetch the last N results
  static Future<List<MegaSenaResult>> getLastResults({int quantity = 30}) async {
    final results = <MegaSenaResult>[];
    final latestContest = await getLatestContest();
    
    if (latestContest == null) {
      return results;
    }
    
    for (int contest = latestContest; contest > latestContest - quantity; contest--) {
      final result = await getResult(contest);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
  
  // Convert string numbers to integers
  static List<int> convertNumbersToInt(List<String> stringNumbers) {
    return stringNumbers.map((number) => int.parse(number)).toList();
  }
}
