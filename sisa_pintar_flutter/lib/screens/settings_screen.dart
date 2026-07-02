import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../database/hive_db_helper.dart';
import '../services/localization_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = HiveDbHelper.getGroqApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveApiKey(String lang) {
    HiveDbHelper.saveGroqApiKey(_apiKeyController.text.trim());
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.get(lang, 'api_key_saved')),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmResetData(String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.get(lang, 'clear_db_confirm_title')),
        content: Text(LocalizationService.get(lang, 'clear_db_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.get(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await HiveDbHelper.clearAll();
              if (mounted) {
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.get(lang, 'clear_db_success')),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text(
              LocalizationService.get(lang, 'clear_db'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    final lang = settingsProvider.currentLanguage;
    final isDark = settingsProvider.isDarkMode;
    final hasKey = HiveDbHelper.getGroqApiKey().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService.get(lang, 'settings_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── LANGUAGE SETTING ───
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.globe, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          LocalizationService.get(lang, 'language_settings'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: lang,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ar', child: Text('🇸🇦 العربية (Arabic)')),
                        DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                        DropdownMenuItem(value: 'id', child: Text('🇮🇩 Bahasa Indonesia')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          settingsProvider.setLanguage(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── THEME SETTING ───
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                secondary: const Icon(LucideIcons.moon, color: Colors.green),
                title: Text(
                  LocalizationService.get(lang, 'dark_mode'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  LocalizationService.get(lang, 'dark_mode_desc'),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                value: isDark,
                activeThumbColor: Colors.green,
                onChanged: (_) => settingsProvider.toggleTheme(),
              ),
            ),
            const SizedBox(height: 12),

            // ─── API KEY SETTING ───
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.key, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocalizationService.get(lang, 'api_key_settings'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasKey ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            hasKey
                                ? LocalizationService.get(lang, 'api_key_active')
                                : LocalizationService.get(lang, 'api_key_inactive'),
                            style: TextStyle(
                              color: hasKey ? Colors.green.shade800 : Colors.orange.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocalizationService.get(lang, 'get_api_key_hint'),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'gsk_xxxxxxxxxxxxxxxxxxxx',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        prefixIcon: const Icon(LucideIcons.lock, size: 16),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _saveApiKey(lang),
                        icon: const Icon(LucideIcons.save, color: Colors.white, size: 16),
                        label: Text(
                          LocalizationService.get(lang, 'save_btn'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── ABOUT SECTION ───
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.info, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          LocalizationService.get(lang, 'about_title'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LocalizationService.get(lang, 'about_desc'),
                      style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── RESET SYSTEM BUTTON ───
            OutlinedButton.icon(
              onPressed: () => _confirmResetData(lang),
              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 16),
              label: Text(
                LocalizationService.get(lang, 'clear_db'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
