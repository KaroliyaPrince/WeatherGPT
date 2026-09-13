import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Sharad Detroja';
  String _userBio = 'Meteorological AI Researcher';
  String _userEmail = 'sharaddetroja@gmail.com';
  String _userAvatar = '👨‍💻';

  static const List<String> _avatarPresets = ['👨‍💻', '🧑‍🌾', '🧑‍🔬', '⚡', '🌦️', '🚀'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('weathergpt_user_name') ?? 'Sharad Detroja';
      _userBio = prefs.getString('weathergpt_user_bio') ?? 'Meteorological AI Researcher';
      _userEmail = prefs.getString('weathergpt_user_email') ?? 'sharaddetroja@gmail.com';
      _userAvatar = prefs.getString('weathergpt_user_avatar') ?? '👨‍💻';
    });
  }

  Future<void> _saveProfile({
    required String name,
    required String bio,
    required String email,
    required String avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weathergpt_user_name', name);
    await prefs.setString('weathergpt_user_bio', bio);
    await prefs.setString('weathergpt_user_email', email);
    await prefs.setString('weathergpt_user_avatar', avatar);

    if (!mounted) return;
    setState(() {
      _userName = name;
      _userBio = bio;
      _userEmail = email;
      _userAvatar = avatar;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF0EA5E9),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _userName);
    final bioCtrl = TextEditingController(text: _userBio);
    final emailCtrl = TextEditingController(text: _userEmail);
    String selectedAvatar = _userAvatar;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Profile',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Avatar Picker
                      const Text('Choose Your Avatar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _avatarPresets.map((avatar) {
                            final isSelected = selectedAvatar == avatar;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => setModalState(() => selectedAvatar = avatar),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF0EA5E9).withAlpha(40)
                                        : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
                                      width: 2.2,
                                    ),
                                    boxShadow: isSelected
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x330EA5E9),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(avatar, style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Name input
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bio input
                      TextField(
                        controller: bioCtrl,
                        decoration: InputDecoration(
                          labelText: 'Role / Bio',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.work_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email input
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.mail_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final name = nameCtrl.text.trim().isEmpty ? _userName : nameCtrl.text.trim();
                          final bio = bioCtrl.text.trim().isEmpty ? _userBio : bioCtrl.text.trim();
                          final email = emailCtrl.text.trim().isEmpty ? _userEmail : emailCtrl.text.trim();

                          Navigator.pop(ctx);
                          _saveProfile(
                            name: name,
                            bio: bio,
                            email: email,
                            avatar: selectedAvatar,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      bioCtrl.dispose();
      emailCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final currentLoc = locationProvider.currentLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // 1. User Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withAlpha(20)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with edit badge
                    GestureDetector(
                      onTap: _showEditProfileSheet,
                      child: Stack(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withAlpha(80),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(_userAvatar, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0EA5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name & Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userBio,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 13, color: Color(0xFF0EA5E9)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  currentLoc.displayName,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _showEditProfileSheet,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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

          // Section 5: About & Status
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
                  subtitle: const Text('v2.0.0 Production (Smart India Hackathon)', style: TextStyle(fontSize: 12)),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981)),
                  title: Text('Live Backend Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(ApiConstants.baseUrl, style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.auto_awesome_rounded, color: Color(0xFF0EA5E9)),
                  title: Text('WeatherGPT AI Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(ApiConstants.aiBaseUrl, style: TextStyle(fontSize: 11, color: Colors.grey)),
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
