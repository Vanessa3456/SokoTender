import 'package:flutter/material.dart';
import 'package:soko_tender/pages/auth.dart';
import 'package:soko_tender/pages/home_page.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int currentIndex = 0;
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // content for the 3 onboarding screens
  final List<OnboardingContent> contents = [
    OnboardingContent(
      title: 'Find Ready Buyers',
      description: "Connect directly with local schools",
      icon: Icons.storefront,
    ),
    OnboardingContent(
      title: 'Set Your Own Price',
      description:
          'Review what buyers need and submit your own bids. You decide how much your hard work is worth.',
      icon: Icons.gavel_rounded,
    ),
    OnboardingContent(
      title: 'Get Paid Instantly',
      description:
          'Receive your money securely and directly into your M-Pesa wallet as soon as the delivery is confirmed.',
      icon: Icons.phone_android,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // skip bottom at the top
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  _controller.jumpToPage(contents.length - 1);
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ),

          // swipeable pages
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: contents.length,
              onPageChanged: (int index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (_, i) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          contents[i].icon,
                          size: 100,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      Text(
                        contents[i].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        contents[i].description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // bottom: dots and button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // custom dot indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    contents.length,
                    (index) => buildDot(index, context),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),

                // get started button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentIndex == contents.length - 1) {
                        // TODO: Navigate to Login or Home Screen

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        );
                      } else {
                        // Go to the next slide
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      currentIndex == contents.length - 1
                          ? "GET STARTED"
                          : "NEXT",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to draw the little dots at the bottom
  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 10,
      width: currentIndex == index ? 25 : 10, // Active dot is wider
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentIndex == index
            ? const Color(0xFF2E7D32)
            : Colors.grey.shade300,
      ),
    );
  }
}

// Simple data class to hold the text and icons for the slides
class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}
