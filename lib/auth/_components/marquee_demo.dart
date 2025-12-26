import 'package:flutter/material.dart';

class Review {
  final String name;
  final String username;
  final String body;
  final String img;

  const Review({
    required this.name,
    required this.username,
    required this.body,
    required this.img,
  });
}

class MarqueeDemo extends StatefulWidget {
  const MarqueeDemo({super.key});

  @override
  State<MarqueeDemo> createState() => _MarqueeDemoState();
}

class _MarqueeDemoState extends State<MarqueeDemo> with TickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;

  final List<Review> reviews = [
    Review(
      name: "Loreal",
      username: "@loreal_fredz",
      body: "I love this platform offers so much of features to use.",
      img: "assets/a1.png",
    ),
    Review(
      name: "Genny",
      username: "@Genny-097",
      body: "Just found wonderful mentorship platform. thats amazing!",
      img: "assets/a2.png",
    ),
    Review(
      name: "John",
      username: "@john",
      body: "The platform is so easy to use. I love it.",
      img: "assets/a6.png",
    ),
    Review(
      name: "Jenny",
      username: "@jenny",
      body: "i just got internship by using this platform. I love it.",
      img: "assets/a3.png",
    ),
    Review(
      name: "Marta",
      username: "@marta",
      body: "alumni connect and mentor support, i used this while preparing for my competitive exams",
      img: "assets/a4.png",
    ),
    Review(
      name: "James",
      username: "@james",
      body: "clario is so easy to use, fun and amazing. i must recomened this platform",
      img: "assets/a5.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40), // Slower scrolling
    )..repeat();

    _controller.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _controller.value * _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SizedBox(
        height: 95,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: reviews.length * 4,
          itemBuilder: (context, index) {
            final review = reviews[index % reviews.length];
            return ReviewCard(review: review);
          },
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, // Reduced width for better fit
      margin: const EdgeInsets.symmetric(horizontal: 6), // Reduced margin
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x80F5F5F5), // gray-100/50
            Color(0x99FFFFFF), // white/60
            Color(0xFF90CAF9), // blue-200
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12, // Slightly smaller avatar
                backgroundImage: AssetImage(review.img),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        fontSize: 12, // Slightly smaller
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      review.username,
                      style: TextStyle(
                        fontSize: 10, // Slightly smaller
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              review.body,
              style: const TextStyle(
                fontSize: 12, // Slightly smaller but readable
                height: 1.3, // Better line height
                fontFamily: 'Raleway',
                color: Colors.black87,
              ),
              maxLines: 3, // Limit lines to ensure visibility
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}