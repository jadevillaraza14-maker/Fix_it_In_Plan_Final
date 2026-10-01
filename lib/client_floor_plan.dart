import 'package:flutter/material.dart';

// =========================================
// FLOOR PLAN SCREEN
// =========================================
class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  bool firstFloor = true;

  static const Color darkGreen = Color(0xFF006B50);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);
  static const Color background = Color(0xFFF7FBF9);
  static const Color paleGreen = Color(0xFFEAF7F0);

  @override
  Widget build(BuildContext context) {
    final List<String> imagePaths = firstFloor
        ? ['assets/1st_Floor.png', 'assets/1st_Floorr.png']
        : ['assets/2nd_Floor.png', 'assets/2nd_Floorr.png'];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text(
          'Floor Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 5, 18, 30),
        child: Column(
          children: [
            // FLOOR BUTTONS
            Row(
              children: [
                Expanded(
                  child: _floorButton('1st Floor', firstFloor, () {
                    setState(() => firstFloor = true);
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _floorButton('2nd Floor', !firstFloor, () {
                    setState(() => firstFloor = false);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // FLOOR PLAN IMAGES
            for (final p in imagePaths) ...[
              _planImage(p),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 8),

            // FEATURES TITLE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                firstFloor ? '1st Floor Features' : '2nd Floor Features',
                style: const TextStyle(
                  color: textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // FEATURES
            _feature('1', firstFloor ? 'Living Area' : 'Master Bedroom'),
            _feature('2', firstFloor ? 'Dining Area' : 'Walk-in Closet'),
            _feature('3', firstFloor ? 'Kitchen' : 'Master Bathroom'),
            _feature('4', firstFloor ? 'Bedroom 1' : 'Bedroom 2'),
            _feature('5', firstFloor ? 'Bathroom' : 'Bedroom 3'),
            _feature('6', firstFloor ? 'Laundry Area' : 'Common Bathroom'),
            _feature('7', firstFloor ? 'Carport' : 'Balcony'),
          ],
        ),
      ),
    );
  }

  // PLAN IMAGE
  Widget _planImage(String path) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDECE7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          path,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 350,
              color: paleGreen,
              child: Center(
                child: Text(
                  'Image not found\n$path',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGray, fontSize: 11),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // FLOOR BUTTON
  Widget _floorButton(String title, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 43,
        decoration: BoxDecoration(
          color: selected ? darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? darkGreen : const Color(0xFFDDECE7),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : textGray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // FEATURE ITEM
  Widget _feature(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDECE7)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: darkGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF9BC5B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
