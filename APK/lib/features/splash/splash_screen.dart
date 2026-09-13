import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_assets.dart';
import '../../providers/location_provider.dart';
import '../../providers/weather_provider.dart';
import '../navigation/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particleController;

  int _statusIndex = 0;
  double _progressValue = 0.0;
  bool _navigated = false;

  final List<String> _statusMessages = [
    'Calibrating atmospheric sensors & GPS...',
    'Syncing global meteorological radar data...',
    'Synthesizing WeatherGPT AI intelligence...',
    'Ready!',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _startBootSequence();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _startBootSequence() async {
    // Stage 1
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _statusIndex = 0;
      _progressValue = 0.25;
    });

    // Start background weather & GPS fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locProvider = context.read<LocationProvider>();
      final weatherProvider = context.read<WeatherProvider>();
      weatherProvider.fetchWeather(location: locProvider.currentLocation);
    });

    // Stage 2
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _statusIndex = 1;
      _progressValue = 0.65;
    });

    // Stage 3
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _statusIndex = 2;
      _progressValue = 0.92;
    });

    // Final Stage
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _statusIndex = 3;
      _progressValue = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    _proceedToMain();
  }

  void _proceedToMain() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: GestureDetector(
        onTap: _proceedToMain, // Allow tap to skip
        child: Stack(
          children: [
            // 1. Deep Space Atmospheric Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF080D21),
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF090D1E),
                    ],
                    stops: [0.0, 0.35, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Animated Ambient Glowing Orbs
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulse = _pulseController.value;
                return Stack(
                  children: [
                    // Top Cyan Atmospheric Glow
                    Positioned(
                      top: -60 + (pulse * 20),
                      left: -40,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E5FF).withAlpha((35 + pulse * 25).round()),
                              const Color(0xFF00E5FF).withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Center-Right Purple Aurora Glow
                    Positioned(
                      top: size.height * 0.35,
                      right: -80 + (pulse * 25),
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF818CF8).withAlpha((30 + pulse * 25).round()),
                              const Color(0xFF6366F1).withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom Amber Sun Flare Glow
                    Positioned(
                      bottom: -50 - (pulse * 20),
                      left: size.width * 0.2,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFF59E0B).withAlpha((20 + pulse * 20).round()),
                              const Color(0xFFF59E0B).withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 3. Floating Weather & Star Particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _SplashParticlesPainter(
                    progress: _particleController.value,
                  ),
                );
              },
            ),

            // 4. Main Foreground Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 3),

                              // Central Creative 3D Weather + AI Core Emblem
                              _buildCentralEmblem(),

                              const SizedBox(height: 28),

                              // App Title & GPT Badge
                              _buildTitle(),

                              const SizedBox(height: 10),

                              // Tagline
                              Text(
                                AppAssets.appTagline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
                                  color: Colors.white.withAlpha(190),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 350.ms, duration: 600.ms)
                                  .slideY(begin: 0.15, end: 0),

                              const SizedBox(height: 18),

                              // Feature Pills Carousel / Tags
                              _buildFeatureBadges(),

                              const Spacer(flex: 3),

                              // AI Bootloader Status Ticker & Progress Bar
                              _buildBootloaderSection(),

                              const SizedBox(height: 14),

                              // Version & Skip hint
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'v${AppAssets.appVersion}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withAlpha(90),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '⚡ Powered by AI & Radar',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF38BDF8).withAlpha(180),
                                      ),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 600.ms),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralEmblem() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, _) {
        final pulse = _pulseController.value;
        final rot = _rotationController.value * 2 * math.pi;

        return SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glowing Radar Ripple Wave 1
              Container(
                width: 155 + (pulse * 15),
                height: 155 + (pulse * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withAlpha((30 * (1 - pulse)).round()),
                    width: 1.5,
                  ),
                ),
              ),

              // Outer Glowing Radar Ripple Wave 2
              Container(
                width: 135 + (pulse * 10),
                height: 135 + (pulse * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6366F1).withAlpha((50 * (1 - pulse)).round()),
                    width: 1.5,
                  ),
                ),
              ),

              // Rotating High-Tech Orbital Ring
              Transform.rotate(
                angle: rot,
                child: Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFF00E5FF).withAlpha(0),
                        const Color(0xFF38BDF8).withAlpha(140),
                        const Color(0xFF818CF8).withAlpha(220),
                        const Color(0xFF00E5FF).withAlpha(0),
                      ],
                      stops: const [0.0, 0.45, 0.85, 1.0],
                    ),
                  ),
                ),
              ),

              // Inner Frosted Glass Orb
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B).withAlpha(220),
                      const Color(0xFF0F172A).withAlpha(240),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withAlpha(50),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withAlpha((30 + pulse * 25).round()),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha((35 + pulse * 20).round()),
                      blurRadius: 36,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Golden Sun behind Cloud (Levitating)
                    Positioned(
                      top: 18 - (pulse * 3),
                      right: 20,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFFFDE047),
                              Color(0xFFF59E0B),
                              Color(0xFFEA580C),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withAlpha(160),
                              blurRadius: 14,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Front Translucent Cloud with 3D Depth
                    Positioned(
                      bottom: 22 + (pulse * 2),
                      child: Icon(
                        Icons.cloud_rounded,
                        size: 58,
                        color: Colors.white.withAlpha(245),
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(120),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          Shadow(
                            color: const Color(0xFF38BDF8).withAlpha(160),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),

                    // Sparkling AI Star
                    Positioned(
                      bottom: 20,
                      right: 22,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: const Color(0xFF38BDF8),
                        shadows: [
                          Shadow(
                            color: const Color(0xFF38BDF8).withAlpha(200),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .scale(
          duration: 900.ms,
          curve: Curves.easeOutBack,
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
        )
        .fadeIn(duration: 700.ms);
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Weather" Text with Gradient Shimmer
        const Text(
          'Weather',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 8),

        // Glowing "GPT" Frosted Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0284C7),
                Color(0xFF4F46E5),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF38BDF8).withAlpha(160),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withAlpha(120),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              const Text(
                'GPT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildFeatureBadges() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMiniBadge('Live Radar', Icons.radar_rounded),
          const SizedBox(width: 8),
          _buildMiniBadge('AI Forecast', Icons.psychology_rounded),
          const SizedBox(width: 8),
          _buildMiniBadge('Highway Routes', Icons.alt_route_rounded),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 450.ms, duration: 600.ms)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildMiniBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(210),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBootloaderSection() {
    final message = _statusMessages[_statusIndex.clamp(0, _statusMessages.length - 1)];

    return Column(
      children: [
        // Status Ticker Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  message,
                  key: ValueKey(message),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(_progressValue * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF38BDF8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Glowing Animated Gradient Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 5,
            width: double.infinity,
            color: Colors.white.withAlpha(20),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  widthFactor: _progressValue,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00E5FF),
                          Color(0xFF38BDF8),
                          Color(0xFF818CF8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withAlpha(180),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
  }
}

// Custom Painter for Floating Sparkles & Meteorological Dust
class _SplashParticlesPainter extends CustomPainter {
  final double progress;

  _SplashParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final particleCount = 28;
    final rand = math.Random(42);

    for (int i = 0; i < particleCount; i++) {
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final speed = 0.3 + (rand.nextDouble() * 0.7);
      final radius = 1.0 + (rand.nextDouble() * 2.2);

      // Float upward smoothly with wrapping
      final currentY = (baseY - (progress * speed * size.height)) % size.height;
      final driftX = baseX + (math.sin((progress * 2 * math.pi) + i) * 12);

      // Shimmering alpha
      final shimmer = (math.sin((progress * 4 * math.pi) + (i * 1.5)) + 1) / 2;
      final alpha = (35 + (shimmer * 130)).round().clamp(0, 255);

      final paint = Paint()
        ..color = (i % 3 == 0)
            ? const Color(0xFF00E5FF).withAlpha(alpha)
            : (i % 3 == 1)
                ? const Color(0xFF818CF8).withAlpha(alpha)
                : const Color(0xFFFDE047).withAlpha((alpha * 0.8).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8);

      canvas.drawCircle(Offset(driftX, currentY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
