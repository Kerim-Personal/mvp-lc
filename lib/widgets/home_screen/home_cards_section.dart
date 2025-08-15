// lib/widgets/home_screen/home_cards_section.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/home_screen/challenge_card.dart';
import 'package:lingua_chat/widgets/home_screen/level_assessment_card.dart';
import 'package:lingua_chat/widgets/home_screen/weekly_quiz_card.dart';
import 'package:lingua_chat/widgets/home_screen/vocabulary_treasure_card.dart';

class HomeCardsSection extends StatelessWidget {
  final PageController pageController;
  final double pageOffset;

  const HomeCardsSection({
    super.key,
    required this.pageController,
    required this.pageOffset,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [
      const ChallengeCard(),
      const WeeklyQuizCard(),
      const LevelAssessmentCard(),
      const VocabularyTreasureCard(),
    ];

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: pageController,
            itemBuilder: (context, index) {
              final cardIndex = index % cards.length;
              return _buildCardPageItem(
                index: index.toDouble(),
                child: cards[cardIndex],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildCardPageItem({required double index, required Widget child}) {
    Matrix4 matrix = Matrix4.identity();
    double scale;
    double gauss = 1 - (pageOffset - index).abs();

    scale = lerpDouble(0.8, 1.0, gauss) ?? 0.8;
    matrix.setEntry(3, 2, 0.001);
    matrix.rotateY((pageOffset - index) * -0.5);

    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: Transform.scale(
        scale: scale,
        child: child,
      ),
    );
  }

  Widget _buildPageIndicator() {
    const int pageCount = 4;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        bool isActive = (pageOffset.round() % pageCount == index);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: isActive ? 10.0 : 8.0,
          width: isActive ? 10.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive ? Colors.teal : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(5.0),
          ),
        );
      }),
    );
  }
}