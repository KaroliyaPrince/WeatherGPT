import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          // Section 1: Units
          _buildSectionHeader('TEMPERATURE & UNITS'),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.thermostat_rounded, color: Color(0xFF0EA5E9)),
                  title: const Text('Fahrenheit (°F)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    settingsProvider.isFahrenheit ? 'Displaying °F' : 'Displaying Celsius (°C)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: settingsProvider.isFahrenheit,
                  onChanged: (val) => settingsProvider.setFahrenheit(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Appearance
          _buildSectionHeader('APPEARANCE'),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: const Icon(Icons.dark_mode_rounded, color: Color(0xFF818CF8)),
              title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Dark Theme (Permanent)', style: TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF818CF8).withAlpha(80)),
                ),
                child: const Text(
                  'Dark 🌙',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Section 3: Language
          _buildSectionHeader('AI & WEATHER LANGUAGE'),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Color(0xFF10B981)),
                  title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    settingsProvider.language == 'auto'
                        ? 'Auto Detect (Automatic NLU)'
                        : settingsProvider.language == 'gu'
                            ? 'ગુજરાતી (Gujarati)'
                            : settingsProvider.language == 'hi'
                                ? 'हिन्दी (Hindi)'
                                : 'English (UK/US)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settingsProvider.language,
                      items: const [
                        DropdownMenuItem(value: 'auto', child: Text('Auto Detect 🌐')),
                        DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
                        DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી 🇮🇳')),
                        DropdownMenuItem(value: 'hi', child: Text('हिन्दी 🇮🇳')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          settingsProvider.setLanguage(val);
                          weatherProvider.fetchWeather(
                            location: locationProvider.currentLocation,
                            language: val,
                            forceRefresh: true,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 4: Data & Cache Management
          _buildSectionHeader('DATA & CACHE'),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: Color(0xFF0EA5E9)),
                  title: const Text('Force Refresh Weather', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Fetch latest live data from Render backend', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    weatherProvider.refresh(
                      location: locationProvider.currentLocation,
                      language: settingsProvider.language,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refreshing weather data...')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                  title: const Text('Clear Search History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red)),
                  subtitle: const Text('Delete all saved recent searches', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    locationProvider.clearRecentSearches();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search history cleared.')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 5: About
          _buildSectionHeader('ABOUT WEATHERGPT'),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1)),
                  title: const Text('WeatherGPT Version', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('v2.0.0 Production Build', style: TextStyle(fontSize: 12)),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981)),
                  title: Text('Live Backend Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(ApiConstants.baseUrl, style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
