import 'package:flutter/material.dart';
import 'client_floor_plan.dart';
import 'client_shared.dart';

// ============================================================
// DESIGN IMAGES
// ============================================================

const List<Map<String, String>> kDesigns = [
  // =========================
  // EXTERIOR
  // =========================

  {
    'image': 'assets/exterior_1.png',
    'title': 'Modern House Exterior',
    'category': 'Exterior',
  },
  {
    'image': 'assets/exterior_2.png',
    'title': 'Contemporary House Exterior',
    'category': 'Exterior',
  },
  {
    'image': 'assets/exteriorr.png',
    'title': 'House Exterior 3',
    'category': 'Exterior',
  },
  {
    'image': 'assets/exteriorrr.png',
    'title': 'House Exterior 4',
    'category': 'Exterior',
  },

  // =========================
  // INTERIOR
  // =========================

  {
    'image': 'assets/interiorr.png',
    'title': 'Modern Living Room Interior',
    'category': 'Interior',
  },
  {
    'image': 'assets/interiorrr.png',
    'title': 'Modern Kitchen Interior',
    'category': 'Interior',
  },

  // =========================
  // FLOOR PLAN
  // =========================

  {
    'image': 'assets/1st_Floor.png',
    'title': '1st Floor Plan',
    'category': 'Floor Plan',
  },
  {
    'image': 'assets/1st_Floorr.png',
    'title': '1st Floor Plan (Alt)',
    'category': 'Floor Plan',
  },
  {
    'image': 'assets/2nd_Floor.png',
    'title': '2nd Floor Plan',
    'category': 'Floor Plan',
  },
  {
    'image': 'assets/2nd_Floorr.png',
    'title': '2nd Floor Plan (Alt)',
    'category': 'Floor Plan',
  },
];

// ============================================================
// DESIGNS SCREEN
// ============================================================

class DesignsScreen extends StatefulWidget {
  const DesignsScreen({super.key});

  @override
  State<DesignsScreen> createState() => _DesignsScreenState();
}

class _DesignsScreenState extends State<DesignsScreen> {
  String filter = 'All';

  // ==========================================================
  // IMAGE NOT FOUND
  // ==========================================================

  Widget _missingImage(String path, double height) {
    debugPrint('IMAGE NOT FOUND: $path');

    return Container(
      width: double.infinity,
      height: height,
      color: kPaleGreen,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: kDarkGreen,
            size: 45,
          ),
          const SizedBox(height: 8),
          const Text(
            'Image not found',
            style: TextStyle(
              color: kTextDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            path,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextGray,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VIEW IMAGE FULL SCREEN
  // ==========================================================

  void _viewImage(String path) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _missingImage(path, 300);
                  },
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final shown = kDesigns
        .where(
          (design) =>
      filter == 'All' || design['category'] == filter,
    )
        .toList();

    return Scaffold(
      backgroundColor: kBackground,

      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kTextDark,
        title: const Text(
          'Designs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [
            // ==================================================
            // FILTER CHIPS
            // ==================================================

            Align(
              alignment: Alignment.centerLeft,

              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: Row(
                  children: [
                    buildFilterChip(
                      'All',
                      selected: filter == 'All',
                      onTap: () {
                        setState(() {
                          filter = 'All';
                        });
                      },
                    ),

                    buildFilterChip(
                      'Exterior',
                      selected: filter == 'Exterior',
                      onTap: () {
                        setState(() {
                          filter = 'Exterior';
                        });
                      },
                    ),

                    buildFilterChip(
                      'Interior',
                      selected: filter == 'Interior',
                      onTap: () {
                        setState(() {
                          filter = 'Interior';
                        });
                      },
                    ),

                    buildFilterChip(
                      'Floor Plan',
                      selected: filter == 'Floor Plan',
                      onTap: () {
                        setState(() {
                          filter = 'Floor Plan';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // EMPTY STATE
            // ==================================================

            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'No designs yet for this category.',
                  style: TextStyle(
                    color: kTextGray,
                    fontSize: 12,
                  ),
                ),
              ),

            // ==================================================
            // DESIGN IMAGES
            // ==================================================

            for (final design in shown) ...[
              _designCard(
                image: design['image']!,
                title: design['title']!,
                category: '${design['category']} Design',
              ),

              const SizedBox(height: 16),
            ],

            const SizedBox(height: 4),

            // ==================================================
            // FLOOR PLAN BUTTON
            // ==================================================

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FloorPlanScreen(),
                  ),
                );
              },

              borderRadius: BorderRadius.circular(18),

              child: Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFDDECE7),
                  ),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.architecture,
                      color: kDarkGreen,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Floor Plan',
                            style: TextStyle(
                              color: kTextDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 3),

                          Text(
                            'View floor plan preview',
                            style: TextStyle(
                              color: kTextGray,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      color: kTextGray,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DESIGN CARD
  // ==========================================================

  Widget _designCard({
    required String image,
    required String title,
    required String category,
  }) {
    return GestureDetector(
      onTap: () {
        _viewImage(image);
      },

      child: Container(
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: const Color(0xFFDDECE7),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =================================================
            // ACTUAL IMAGE
            // =================================================

            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),

              child: Image.asset(
                image,

                width: double.infinity,
                height: 200,

                fit: BoxFit.cover,

                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return _missingImage(
                    image,
                    200,
                  );
                },
              ),
            ),

            // =================================================
            // DETAILS
            // =================================================

            Padding(
              padding: const EdgeInsets.all(14),

              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          title,

                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          category,

                          style: const TextStyle(
                            color: kTextGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // VIEW BUTTON


                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: kPaleGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Text(
                      'View',

                      style: TextStyle(
                        color: kDarkGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
  }
}
