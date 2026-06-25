import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqApiService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static Future<String> generateRecipes({
    required List<String> ingredients,
    String language = 'Indonesian',
  }) async {
    if (_apiKey.isEmpty) {
      return _getMockRecipeResponse(ingredients);
    }

    try {
      final ingredientsString = ingredients.join(', ');
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'Anda adalah Chef SisaPintar, asisten masak pintar berbasis SDG Goal 12 (Konsumsi & Produksi Bertanggung Jawab). Tugas Anda adalah membuat resep masakan sederhana, praktis, dan hemat energi/karbon berdasarkan bahan-bahan sisa kulkas yang diberikan pengguna. Format jawaban Anda dalam bahasa $language dengan struktur: 1. Nama Resep, 2. Waktu & Porsi, 3. Bahan-bahan, 4. Langkah Pembuatan.'
            },
            {
              'role': 'user',
              'content': 'Bahan sisa kulkas saya yang ingin dimasak: $ingredientsString.'
            }
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String;
      } else {
        String msg = 'Status ${response.statusCode}';
        try {
          final err = jsonDecode(response.body);
          if (err['error'] != null && err['error']['message'] != null) {
            msg = err['error']['message'];
          }
        } catch (_) {}
        return _getMockRecipeResponse(ingredients, errorMessage: 'Koneksi ke API gagal ($msg).');
      }
    } catch (e) {
      return _getMockRecipeResponse(ingredients, errorMessage: 'Terjadi kesalahan: $e');
    }
  }

  static String _getMockRecipeResponse(List<String> ingredients, {String? errorMessage}) {
    final ingredientList = ingredients.join(', ');
    return '''
🍳 **Resep Hemat Sisa Bahan: Tumis Serbaguna**

⏱ **Waktu & Porsi**: 15 menit | 2 porsi

🥗 **Bahan-bahan**:
- $ingredientList
- Garam & merica secukupnya
- Minyak goreng 2 sdm
- Bawang putih 2 siung

👨‍🍳 **Langkah Pembuatan**:
1. Panaskan minyak, tumis bawang putih hingga harum
2. Masukkan semua bahan sisa, tumis hingga matang
3. Tambahkan garam dan merica sesuai selera
4. Sajikan selagi hangat

🌱 *Dengan memanfaatkan sisa bahan, Anda berkontribusi pada SDG 12: Konsumsi Bertanggung Jawab!*

${errorMessage != null ? '⚠️ *Catatan Sistem: $errorMessage*' : '💡 *Catatan: Tambahkan GROQ_API_KEY di file .env untuk mendapatkan resep yang dipersonalisasi oleh AI.*'}
''';
  }
}
