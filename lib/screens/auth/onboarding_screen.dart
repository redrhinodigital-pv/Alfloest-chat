import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Connect Instantly',
      'subtitle': 'Fast, secure, and minimal communication via Google.',
      'icon': 'chat_bubble_outline_rounded',
    },
    {
      'title': 'Premium Violet Theme',
      'subtitle': 'Experience dark mode aesthetics crafted for modern eyes.',
      'icon': 'dark_mode_rounded',
    },
    {
      'title': 'Realtime Sync',
      'subtitle': 'Cross-platform sync everywhere. Start chatting now.',
      'icon': 'sync_rounded',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'chat_bubble_outline_rounded': return Icons.chat_bubble_outline_rounded;
      case 'dark_mode_rounded': return Icons.dark_mode_rounded;
      case 'sync_rounded': return Icons.sync_rounded;
      default: return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 10)
                            ]
                          ),
                          child: Icon(_getIconData(page['icon']!), size: 60, color: AppColors.primary),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1.copyWith(color: AppColors.textPrimary, fontSize: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['subtitle']!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),

            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: AppTextStyles.button.copyWith(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
