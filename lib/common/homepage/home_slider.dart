import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_soc/utils/app_logger.dart';

// ---------------------------------------------------------
// UI Component: HomeSlider
// ---------------------------------------------------------
class HomeSlider extends StatefulWidget {
  const HomeSlider({super.key});

  @override
  State<HomeSlider> createState() => _HomeSliderState();
}

class _HomeSliderState extends State<HomeSlider> {
  List<dynamic> _cards = [];
  bool _isLoading = true;
  PageController? _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCardsData();
  }

  @override
  void dispose() {
    logger.d('HomeSliderState dispose triggered');
    _pageController?.dispose();
    super.dispose();
    logger.d('HomeSliderState dispose completed successfully');
  }

  // Backend: Load cards data from JSON asset
  Future<void> _loadCardsData() async {
    logger.i('_loadCardsData started');
    try {
      final jsonString = await rootBundle.loadString('lib/common/homepage/dummy_cards.json');
      final data = json.decode(jsonString);
      if (mounted) {
        setState(() {
          _cards = data;
          _isLoading = false;
          // Set initial page in the middle of a very large index for infinite looping
          final initialPage = 5000 - (5000 % _cards.length);
          _pageController = PageController(
            viewportFraction: 0.82,
            initialPage: initialPage,
          );
          _currentIndex = 0;
        });
      }
      logger.i('_loadCardsData completed successfully. Loaded ${_cards.length} cards.');
    } catch (e) {
      logger.e('Error during _loadCardsData: $e');
    }
  }

  // Helper: Get unique card gradient based on index
  LinearGradient _getCardGradient(int index) {
    switch (index % 5) {
      case 0:
        return const LinearGradient(
          colors: [Color(0xFFE26A6A), Color(0xFF852D2D)], // Coral/Red Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1:
        return const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF191654)], // Teal/Dark Blue Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Cyan/Electric Blue Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFFDA22FF), Color(0xFF9733EE)], // Violet/Purple Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 4:
        return const LinearGradient(
          colors: [Color(0xFF434343), Color(0xFF000000)], // Charcoal/Black Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF222A54), Color(0xFF151B3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final sliderHeight = screenHeight * 0.20;

    logger.d('HomeSlider build triggered. Height=$sliderHeight, Loading=$_isLoading');

    if (_isLoading) {
      return SizedBox(
        height: sliderHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            width: screenWidth * 0.82,
            margin: const EdgeInsets.only(right: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: sliderHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 10000,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % _cards.length;
              });
            },
            itemBuilder: (context, index) {
              final actualIndex = index % _cards.length;
              final card = _cards[actualIndex];
              final title = card['title'] ?? '';
              final message = card['message'] ?? '';
              final route = card['route'] ?? '';

              return AnimatedBuilder(
                animation: _pageController!,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController!.position.haveDimensions) {
                    value = _pageController!.page! - index;
                    // Scale from 0.90 (adjacent) to 1.0 (in focus)
                    value = (1.0 - (value.abs() * 0.08)).clamp(0.90, 1.0);
                  } else {
                    // Fallback before PageView measurements are calculated
                    final initialPage = 5000 - (5000 % _cards.length);
                    value = (index == initialPage) ? 1.0 : 0.90;
                  }

                  return Center(
                    child: SizedBox(
                      height: sliderHeight * value,
                      width: screenWidth * 0.82 * value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  clipBehavior: Clip.antiAlias, // Clip background overlay shapes
                  decoration: BoxDecoration(
                    gradient: _getCardGradient(actualIndex),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000), // Drop shadow
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative Shape 1: Translucent Circle
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x14FFFFFF), // White with 8% opacity
                          ),
                        ),
                      ),
                      // Decorative Shape 2: Translucent Circle
                      Positioned(
                        left: -20,
                        bottom: -40,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x0AFFFFFF), // White with 4% opacity
                          ),
                        ),
                      ),
                      // Card Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 12,
                                    color: Color(0xD9FFFFFF), // White with 85% opacity
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: InkWell(
                                onTap: () {
                                  logger.i('Check Now tapped for $title');
                                  Navigator.pushNamed(context, route);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33FFFFFF), // Translucent white (20% opacity)
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0x4DFFFFFF), // Translucent white border (30% opacity)
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Check Now",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cards.length, (dotIndex) {
            final isSelected = _currentIndex == dotIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 7,
              width: isSelected ? 18 : 7,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF222A54) : const Color(0xFFC4C4C4),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
