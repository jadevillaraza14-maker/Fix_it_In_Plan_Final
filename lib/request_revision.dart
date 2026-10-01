import 'package:flutter/material.dart';

import 'client_shared.dart';

void showRequestRevisionSheet(
    BuildContext context, {
      required int clientId,
      required dynamic projectId,
      required Future<void> Function({bool showLoader}) onSubmitted,
    }) {
  final detailsC = TextEditingController();
  String? area;
  bool sending = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheet) {
          Future<void> submit() async {
            if (area == null || detailsC.text.trim().isEmpty) {
              showMessage(context, 'Piliin ang area at isulat ang details.');
              return;
            }
            setSheet(() => sending = true);
            final d = await apiPost('create_revision.php', {
              'client_id': clientId,
              'project_id': projectId,
              'area': area,
              'details': detailsC.text.trim(),
              'description': detailsC.text.trim(),
            });
            if (d['success'] == true) {
              if (sheetContext.mounted) Navigator.pop(sheetContext);
              showMessage(context, 'Revision request sent to admin.');
              onSubmitted(showLoader: false);
            } else {
              if (sheetContext.mounted) {
                setSheet(() => sending = false);
              }
              showMessage(
                context,
                d['message']?.toString() ?? 'Failed to submit.',
              );
            }
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSheetHandle(),
                  const Text(
                    'Request Revision',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tell us what changes you want to make.',
                    style: TextStyle(
                      color: kTextGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildSelectField(
                    'Select Area',
                    'Choose area',
                    area,
                        () async {
                      final v = await chooseOption(context, 'Select Area', [
                        'Exterior',
                        'Interior',
                        'Floor Plan',
                        'Materials',
                        'Budget',
                        'Others',
                      ]);
                      if (v != null) setSheet(() => area = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFD5E8E1),
                      ),
                    ),
                    child: TextField(
                      controller: detailsC,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter your revision details...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9BB2AC),
                          fontSize: 12,
                        ),
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
                        backgroundColor: kDarkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: sending
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
