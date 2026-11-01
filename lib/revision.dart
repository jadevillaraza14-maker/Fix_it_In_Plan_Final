import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _revBase = 'https://steed-husband-drier.ngrok-free.dev/Fix_it_In_Plans_Api';

Future<Map> _revPost(String file, Map body) async {
  try {
    final res = await http
        .post(
      Uri.parse('$_revBase/$file'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 15));
    return jsonDecode(res.body) as Map;
  } catch (e) {
    return {'success': false, 'message': 'Error: $e'};
  }
}

void showRequestRevisionSheet(
    BuildContext context, {
      required int clientId,
      int? projectId,
      required VoidCallback onSubmitted,
    }) {
  const Color darkGreen = Color(0xFF006B50);
  const Color textDark = Color(0xFF173B33);
  const Color textGray = Color(0xFF75908A);
  const Color background = Color(0xFFF7FBF9);

  final detailsC = TextEditingController();
  String? area;
  bool sending = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> choose(String title, List<String> options) {
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
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7E6E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Text(title,
                    style: const TextStyle(
                        color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                    for (final o in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o, style: const TextStyle(color: textDark, fontSize: 14)),
                  onTap: () => Navigator.pop(sheetContext, o),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheet) {
          Future<void> submit() async {
            if (area == null || detailsC.text.trim().isEmpty) {
              showMessage('Piliin ang area at isulat ang details.');
              return;
            }
            setSheet(() => sending = true);
            final d = await _revPost('create_revision.php', {
              'client_id': clientId,
              'project_id': projectId,
              'area': area,
              'details': detailsC.text.trim(),
              'description': detailsC.text.trim(),
            });
            if (d['success'] == true) {
              if (sheetContext.mounted) Navigator.pop(sheetContext);
              showMessage('Revision request sent to admin.');
              onSubmitted();
            } else {
              if (sheetContext.mounted) setSheet(() => sending = false);
              showMessage(d['message']?.toString() ?? 'Failed to submit.');
            }
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7E6E1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const Text('Request Revision',
                      style: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('Tell us what changes you want to make.',
                      style: TextStyle(color: textGray, fontSize: 12)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final v = await choose('Select Area', [
                        'Exterior', 'Interior', 'Floor Plan', 'Materials', 'Budget', 'Others',
                      ]);
                      if (v != null) setSheet(() => area = v);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD5E8E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Area',
                              style: TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  area ?? 'Choose area',
                                  style: TextStyle(
                                      color: area == null ? const Color(0xFF9BB2AC) : textDark,
                                      fontSize: 12),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: textGray, size: 19),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFD5E8E1)),
                    ),
                    child: TextField(
                      controller: detailsC,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(color: textDark, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Enter your revision details...',
                        hintStyle: TextStyle(color: Color(0xFF9BB2AC), fontSize: 12),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: sending ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: sending
                          ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}