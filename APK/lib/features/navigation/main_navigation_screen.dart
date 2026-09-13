import 'dart:ui';
import 'package:flutter/material.dart';
import '../chatbot/chatbot_screen.dart';
import '../forecast/forecast_screen.dart';
import '../home/home_screen.dart';
import '../map/weather_map_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Home
          HomeScreen(
            onOpenChatbot: () => _onTabSelected(3),
            onOpenForecast: () => _onTabSelected(1),
          ),
          // 1: Forecast
          const ForecastScreen(),
          // 2: Weather Map
          WeatherMapScreen(
            onSwitchToHome: () => _onTabSelected(0),
          ),
          // 3: AI Chatbot
          const ChatbotScreen(),
          // 4: Profile & Settings
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildFloatingGlassNavBar(context),
    );
  }

  Widget _buildFloatingGlassNavBar(BuildContext context) {
    final isKeyboardOpen = View.of(context).viewInsets.bottom > 0 || MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.calendar_month_rounded, label: 'Forecast'),
      _NavItem(icon: Icons.map_rounded, label: 'Radar'),
      _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI Chat'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xC00C1D38)
                      : const Color(0xAA0F2B52),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withAlpha(50),
                    width: 1,
                  ),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = _currentIndex == index;

                  return GestureDetector(
                    onTap: () => _onTabSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 14 : 10,
                        vertical: 8,
                      ),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(80),
                                width: 1,
                              ),
                            )
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withAlpha(160),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
