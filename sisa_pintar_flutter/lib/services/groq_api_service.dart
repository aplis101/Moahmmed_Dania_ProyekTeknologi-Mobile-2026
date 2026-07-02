import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../database/hive_db_helper.dart';

class GroqApiService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  /// API key: priority → Hive settings → .env file
  static String get _apiKey {
    final fromHive = HiveDbHelper.getGroqApiKey();
    if (fromHive.isNotEmpty) return fromHive;
    return dotenv.env['GROQ_API_KEY'] ?? '';
  }

  static Future<String> generateRecipes({
    required List<String> ingredients,
    String language = 'Indonesian',
  }) async {
    if (_apiKey.isEmpty) {
      return _getMockRecipeResponse(ingredients);
    }

    try {
      final ingredientsString = ingredients.join(', ');

      // Build language-specific prompts
      final String systemPrompt;
      final String userMessage;

      if (language == 'Arabic') {
        systemPrompt =
            'أنت الشيف الذكي SisaPintar 👨‍🍳، مساعد طبخ ذكي قائم على هدف التنمية المستدامة رقم 12 (الاستهلاك والإنتاج المسؤول). '
            'مهمتك هي إنشاء وصفات بسيطة وعملية وموفرة للطاقة من بقايا مكونات الثلاجة. '
            'قدّم إجابتك باللغة العربية مع هيكل غني بالإيموجي:\n'
            '🍽️ اسم الوصفة\n'
            '⏱️ الوقت والحصص\n'
            '🥗 المكونات (مع إيموجي لكل مكون)\n'
            '👨‍🍳 خطوات التحضير (أرقام + إيموجي لكل خطوة)\n'
            '💡 نصائح وقيمة غذائية\n'
            '🌱 ملاحظة SDG';
        userMessage = 'مكونات ثلاجتي المتبقية التي أريد طبخها: $ingredientsString.';
      } else if (language == 'English') {
        systemPrompt =
            'You are Chef SisaPintar 👨‍🍳, a smart cooking assistant based on SDG Goal 12 (Responsible Consumption & Production). '
            'Your task is to create simple, practical, and energy-efficient recipes using leftover fridge ingredients provided by the user. '
            'Format your answer in English with an emoji-rich structure:\n'
            '🍽️ Recipe Name\n'
            '⏱️ Time & Servings\n'
            '🥗 Ingredients (use an emoji per ingredient)\n'
            '👨‍🍳 Cooking Steps (use numbers + emoji per step)\n'
            '💡 Tips & Nutrition\n'
            '🌱 SDG Note';
        userMessage = 'My leftover fridge ingredients I want to cook: $ingredientsString.';
      } else {
        // Indonesian (default)
        systemPrompt =
            'Anda adalah Chef SisaPintar 👨‍🍳, asisten masak pintar berbasis SDG Goal 12 (Konsumsi & Produksi Bertanggung Jawab). '
            'Tugas Anda adalah membuat resep masakan sederhana, praktis, dan hemat energi/karbon berdasarkan bahan-bahan sisa kulkas yang diberikan pengguna. '
            'Format jawaban Anda dalam Bahasa Indonesia dengan struktur yang kaya emoji:\n'
            '🍽️ Nama Resep\n'
            '⏱️ Waktu & Porsi\n'
            '🥗 Bahan-bahan (gunakan emoji per bahan)\n'
            '👨‍🍳 Langkah Pembuatan (gunakan angka + emoji per langkah)\n'
            '💡 Tips & Nutrisi\n'
            '🌱 Catatan SDG';
        userMessage = 'Bahan sisa kulkas saya yang ingin dimasak: $ingredientsString.';
      }

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
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userMessage,
            }
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

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
        return _getMockRecipeResponse(ingredients,
            errorMessage: 'Koneksi ke API gagal ($msg).');
      }
    } catch (e) {
      return _getMockRecipeResponse(ingredients,
          errorMessage: 'Terjadi kesalahan: $e');
    }
  }

  static String _getMockRecipeResponse(List<String> ingredients,
      {String? errorMessage}) {
    final ingredientList = ingredients.join(', ');
    return '''🍳 **Tumis Serbaguna Hemat Sisa Bahan**

⏱️ **Waktu & Porsi**: 15 menit | 2 porsi

🥗 **Bahan-bahan**:
🫙 $ingredientList
🧂 Garam & merica secukupnya
🫒 Minyak goreng 2 sdm
🧄 Bawang putih 2 siung
🌶️ Cabai merah (opsional)

👨‍🍳 **Langkah Pembuatan**:
1️⃣ Panaskan minyak di wajan, tumis bawang putih hingga harum keemasan 🔥
2️⃣ Masukkan bahan yang paling keras terlebih dahulu, aduk rata
3️⃣ Tambahkan sisa bahan, tumis hingga matang sempurna ✨
4️⃣ Bumbui dengan garam dan merica sesuai selera
5️⃣ Sajikan selagi hangat di piring saji 🍽️

💡 **Tips Chef**:
• Tambahkan kecap manis untuk rasa yang lebih kaya
• Bisa ditambah telur orak-arik untuk protein ekstra 🥚
• Sajikan bersama nasi putih atau roti

🌱 *Dengan memanfaatkan sisa bahan, Anda berkontribusi pada SDG 12: Konsumsi Bertanggung Jawab! Setiap gram yang diselamatkan = bumi yang lebih hijau* 🌍

${errorMessage != null ? '⚠️ *Catatan Sistem: $errorMessage*' : '💡 *Catatan: Masukkan GROQ_API_KEY di Pengaturan untuk mendapatkan resep AI yang dipersonalisasi!*'}''';
  }
}
