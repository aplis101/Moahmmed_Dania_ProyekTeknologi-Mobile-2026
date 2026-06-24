import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqApiService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  
  static const String _apiKey = 'REPLACE_WITH_YOUR_GROQ_API_KEY';
  static const String _model = 'llama3-8b-8192';

  static Future<String> generateRecipes({
    required List<String> ingredients,
    String language = 'Indonesian',
  }) async {
    if (_apiKey == 'REPLACE_WITH_YOUR_GROQ_API_KEY') {
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
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String? ?? 'Gagal menghasilkan resep.';
      } else {
        return 'Error ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Gagal terhubung ke Groq API: $e';
    }
  }

  // Fallback mock response for offline testing or when API key is missing
  static String _getMockRecipeResponse(List<String> ingredients) {
    final list = ingredients.isEmpty ? 'Bayam & Telur' : ingredients.join(', ');
    return '''
✦ [Simulasi Resep Groq Llama3] ✦
Bahan yang Anda miliki: $list

Resep Rekomendasi: Tumis Campur Penyelamat Bumi
Waktu Masak: 15 menit | Porsi: 2 orang

Bahan-bahan:
- $list (bahan sisa kulkas Anda)
- Bawang putih & bawang merah iris
- Garam, lada, dan penyedap secukupnya
- 1 sdm minyak goreng

Cara Pembuatan:
1. Bersihkan dan potong semua bahan sisa Anda sesuai selera.
2. Panaskan minyak di wajan, tumis irisan bawang hingga harum.
3. Masukkan bahan-bahan keras terlebih dahulu (jika ada), aduk rata.
4. Masukkan bahan-bahan lunak, tambahkan garam, lada, dan penyedap.
5. Masak cepat dengan api sedang selama 5 menit hingga matang.
6. Angkat dan sajikan hangat! Anda baru saja mengurangi sampah makanan! 🌿
''';
  }
}
