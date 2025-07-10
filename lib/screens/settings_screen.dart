import 'package:flutter/material.dart';
import '../models/app_enums.dart';

class SettingsScreen extends StatelessWidget {
  final AppThemeMode themeMode;
  final void Function(AppThemeMode) onThemeChanged;
  final AppLanguage language;
  final void Function(AppLanguage) onLanguageChanged;
  
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(language == AppLanguage.zh ? '主題模式' : 'Theme Mode', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '淺色' : 'Light'),
            value: AppThemeMode.light,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '深色' : 'Dark'),
            value: AppThemeMode.dark,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '跟隨系統' : 'System'),
            value: AppThemeMode.system,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(language == AppLanguage.zh ? '賽博朋克' : 'Cyberpunk'),
            value: AppThemeMode.cyberpunk,
            groupValue: themeMode,
            onChanged: (mode) { if (mode != null) onThemeChanged(mode); },
          ),
          const SizedBox(height: 24),
          Text(language == AppLanguage.zh ? '語言' : 'Language', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          RadioListTile<AppLanguage>(
            title: const Text('繁體中文'),
            value: AppLanguage.zh,
            groupValue: language,
            onChanged: (lang) { if (lang != null) onLanguageChanged(lang); },
          ),
          RadioListTile<AppLanguage>(
            title: const Text('English'),
            value: AppLanguage.en,
            groupValue: language,
            onChanged: (lang) { if (lang != null) onLanguageChanged(lang); },
          ),
        ],
      ),
    );
  }
}