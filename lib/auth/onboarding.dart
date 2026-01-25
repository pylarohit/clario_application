import 'package:flutter/material.dart';
import '_components/onboarding_card.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 700),
            padding: EdgeInsets.all(16),
            child: OnBoardingCard(),
          ),
        ),
      ),
    );
  }
}
