import 'package:flutter/material.dart';
import 'client_shared.dart';
void showRequestProjectSheet(
    BuildContext context, {
      required int clientId,
      required Future<void> Function({bool showLoader}) onSubmitted,
    }) {
  final locationC = TextEditingController();
  final lotC = TextEditingController();
  String? type;
  bool sending = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheet) {
          Future<void> submit() async {
            if (type == null || locationC.text.trim().isEmpty) {
              showMessage(
                context,
                'Piliin ang project type at ilagay ang location.',
              );
              return;
            }
            setSheet(() => sending = true);
            final d = await apiPost('create_project_request.php', {
              'client_id': clientId,
              'project_type': type,
              'location': locationC.text.trim(),
              'lot_size': lotC.text.trim(),
              'preferred_service': '',
              'description': '',
              'target_timeline': '',
            });
            if (d['success'] == true) {
              if (sheetContext.mounted) Navigator.pop(sheetContext);
              showMessage(
                context,
                'Project request submitted! Makikita na ito ng admin.',
              );
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
                    'Request a Project',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Submit your project details to the team.',
                    style: TextStyle(
                      color: kTextGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildSelectField(
                    'Project Type',
                    'Select project type',
                    type,
                        () async {
                      final v = await chooseOption(context, 'Project Type', [
                        'House Design',
                        'Renovation',
                        'Interior Design',
                        'Building Permit',
                        'Structural Plan',
                        'Others',
                      ]);
                      if (v != null) setSheet(() => type = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  buildInputField(
                    'Location',
                    'Enter project location',
                    locationC,
                  ),
                  const SizedBox(height: 12),
                  buildInputField(
                    'Lot Size',
                    'Example: 120 sqm',
                    lotC,
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
                        'Continue',
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
