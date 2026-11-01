import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================
// COLORS
// ============================================================

const Color kDarkGreen = Color(0xFF006B50);
const Color kGreen = Color(0xFF087F5B);
const Color kLightGreen = Color(0xFF63C47A);
const Color kPaleGreen = Color(0xFFEAF7F0);
const Color kBackground = Color(0xFFF7FBF9);
const Color kTextDark = Color(0xFF173B33);
const Color kTextGray = Color(0xFF75908A);

// ============================================================
// API
// ============================================================

// Palitan kung magbago ang IP ng PC
const String baseUrl = 'https://steed-husband-drier.ngrok-free.dev/Fix_it_In_Plans_Api';

const List<String> kStages = [
  'Assessment',
  'Planning',
  'Revision',
  'Finalized',
  'Completed',
];

Future<List<dynamic>> apiGet(String path, String key) async {
  try {
    final res = await http
        .get(Uri.parse('$baseUrl/$path'))
        .timeout(const Duration(seconds: 10));
    final d = jsonDecode(res.body);
    if (d['success'] == true && d[key] is List) return d[key];
  } catch (e) {
    debugPrint('$path error: $e');
  }
  return [];
}

Future<Map> apiPost(String file, Map body) async {
  try {
    final res = await http
        .post(
      Uri.parse('$baseUrl/$file'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 15));
    return jsonDecode(res.body) as Map;
  } catch (e) {
    return {'success': false, 'message': 'Error: $e'};
  }
}

String pickValue(Map m, List<String> keys, [String d = '']) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return d;
}

int stageIndexOf(Map p) {
  final s = pickValue(p, ['status']).toLowerCase();
  return kStages.indexWhere((e) => s.contains(e.toLowerCase()));
}

double progressOf(Map p) {
  final v = double.tryParse(pickValue(p, ['progress', 'progress_percent']));
  if (v != null) return (v / 100).clamp(0.0, 1.0);
  final i = stageIndexOf(p);
  return i < 0 ? 0 : (i + 1) / kStages.length;
}

bool isCompleted(Map p) =>
    pickValue(p, ['status']).toLowerCase().contains('complete');

// ============================================================
// UI HELPERS
// ============================================================

void showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Widget buildSheetHandle() {
  return Center(
    child: Container(
      width: 45,
      height: 5,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFD7E6E1),
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

Widget buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    ) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: kBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD5E8E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: kTextDark, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9BB2AC),
              fontSize: 12,
            ),
            border: InputBorder.none,
            isCollapsed: true,
          ),
        ),
      ],
    ),
  );
}

Widget buildSelectField(
    String label,
    String hint,
    String? value,
    VoidCallback onTap,
    ) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5E8E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    color: value == null
                        ? const Color(0xFF9BB2AC)
                        : kTextDark,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: kTextGray,
                size: 19,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<String?> chooseOption(
    BuildContext context,
    String title,
    List<String> options,
    ) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSheetHandle(),
              Text(
                title,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final o in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    o,
                    style: const TextStyle(color: kTextDark, fontSize: 14),
                  ),
                  onTap: () => Navigator.pop(sheetContext, o),
                ),
            ],
          ),
        ),
      );
    },
  );
}
// ============================================================
// MGA PANGALANG GINAGAMIT NG IBANG FILE
// ============================================================

const String apiBase = baseUrl;
const List<String> dashboardStages = kStages;

Widget buildEmptyIcon(IconData icon) {
  return Container(
    width: 62,
    height: 62,
    decoration: const BoxDecoration(
      color: kPaleGreen,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: kDarkGreen, size: 29),
  );
}

Widget buildPageHeader(String title, {VoidCallback? onBack}) {
  return Row(
    children: [
      if (onBack != null)
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
      if (onBack == null) const SizedBox(width: 2),
      Text(
        title,
        style: const TextStyle(
          color: kTextDark,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

Widget buildFilterChip(
    String text, {
      required bool selected,
      VoidCallback? onTap,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? kDarkGreen : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: selected ? kDarkGreen : const Color(0xFFDDECE7),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : kTextGray,
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    ),
  );
}

Widget buildListItem({
  required IconData icon,
  required String title,
  required String subtitle,
  String? trailing,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDECE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPaleGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kDarkGreen, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kTextGray, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null && trailing.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: kPaleGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trailing,
                style: const TextStyle(
                  color: kDarkGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget buildPrimaryButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kDarkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
bool isCompletedProject(Map p) => isCompleted(p);