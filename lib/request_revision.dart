import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'client_shared.dart';

const List<String> kRevisionFileTypes = [
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'doc',
  'docx',
  'xls',
  'xlsx',
];

void showRequestRevisionSheet(
    BuildContext callerContext, {
      required int clientId,
      required dynamic projectId,
      required Future<void> Function({bool showLoader}) onSubmitted,
    }) {
  final descriptionC = TextEditingController();
  final reasonC = TextEditingController();

  PlatformFile? attachment;
  bool sending = false;

  showModalBottomSheet(
    context: callerContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheet) {
          Future<void> pickAttachment() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: kRevisionFileTypes,
              withData: false,
            );

            if (result == null || result.files.isEmpty) return;

            final file = result.files.single;

            if (file.path == null) {
              showMessage(
                callerContext,
                'Could not read the selected file.',
              );
              return;
            }

            if (file.size > 10 * 1024 * 1024) {
              showMessage(
                callerContext,
                '${(file.size / 1048576).toStringAsFixed(1)} MB is over the '
                    '10 MB limit.',
              );
              return;
            }

            setSheet(() => attachment = file);
          }

          Future<void> submit() async {
            if (descriptionC.text.trim().isEmpty ||
                reasonC.text.trim().isEmpty) {
              showMessage(
                callerContext,
                'Please fill in the description and reason.',
              );
              return;
            }

            setSheet(() => sending = true);

            final d = await _sendRevision(
              clientId: clientId,
              projectId: projectId,
              description: descriptionC.text.trim(),
              reason: reasonC.text.trim(),
              attachment: attachment,
            );

            if (d['success'] == true) {
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }

              showMessage(
                callerContext,
                'Revision request sent to admin.',
              );

              onSubmitted(showLoader: false);
            } else {
              if (sheetContext.mounted) {
                setSheet(() => sending = false);
              }

              showMessage(
                callerContext,
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
                    'Tell us what to change and why.',
                    style: TextStyle(
                      color: kTextGray,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 20),

                  buildInputField(
                    'Description',
                    'What should change in the design?',
                    descriptionC,
                  ),

                  const SizedBox(height: 12),

                  buildInputField(
                    'Reason',
                    'Why does it need to change?',
                    reasonC,
                  ),

                  const SizedBox(height: 12),

                  _RevisionAttachTile(
                    file: attachment,
                    onTap: pickAttachment,
                    onClear: () => setSheet(() => attachment = null),
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

Future<Map> _sendRevision({
  required int clientId,
  required dynamic projectId,
  required String description,
  required String reason,
  PlatformFile? attachment,
}) async {
  try {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/create_revision.php'),
    )
      ..fields['client_id'] = '$clientId'
      ..fields['project_id'] = '$projectId'
      ..fields['description'] = description
      ..fields['reason'] = reason;

    final path = attachment?.path;

    if (path != null) {
      req.files.add(
        await http.MultipartFile.fromPath('file', path),
      );
    }

    final res = await http.Response.fromStream(
      await req.send().timeout(const Duration(seconds: 60)),
    );

    return jsonDecode(res.body) as Map;
  } catch (e) {
    return {'success': false, 'message': 'Error: $e'};
  }
}

class _RevisionAttachTile extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _RevisionAttachTile({
    required this.file,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final selected = file;
    final hasFile = selected != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: hasFile ? kPaleGreen : kBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD5E8E1)),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.attach_file : Icons.add_circle_outline,
              size: 20,
              color: kDarkGreen,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? selected.name : 'Attach file (optional)',
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasFile
                        ? '${(selected.size / 1048576).toStringAsFixed(1)} MB '
                        '• tap to change'
                        : 'PDF, JPG, PNG, DOC, DOCX, XLS, XLSX • max 10 MB',
                    style: const TextStyle(
                      color: kTextGray,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: kTextGray,
                ),
              ),
          ],
        ),
      ),
    );
  }
}