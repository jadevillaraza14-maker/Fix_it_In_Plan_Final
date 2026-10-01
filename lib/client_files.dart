import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'client_shared.dart';


class ClientFilesPage extends StatelessWidget {
  final List<dynamic> documents;
  final String filter;
  final bool loading;
  final ValueChanged<String> onFilterChange;
  final Future<void> Function({bool showLoader}) onRefresh;
  final int clientId;
  final Map? activeProject;

  const ClientFilesPage({
    super.key,
    required this.documents,
    required this.filter,
    required this.loading,
    required this.onFilterChange,
    required this.onRefresh,
    required this.clientId,
    required this.activeProject,
  });

  Future<void> _uploadDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;
    final cat = await chooseOption(context, 'Select Category', [
      'Plans',
      'Permits',
      'Others',
    ]);
    if (cat == null) return;
    final f = result.files.single;
    if (!context.mounted) return;
    showMessage(context, 'Uploading...');
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBase/upload_document.php'),
      )
        ..fields['client_id'] = '$clientId'
        ..fields['category'] = cat
        ..fields['title'] = f.name;
      final pid = activeProject?['id'];
      if (pid != null) req.fields['project_id'] = '$pid';
      req.files.add(await http.MultipartFile.fromPath('file', f.path!));
      final res = await http.Response.fromStream(await req.send());
      final d = jsonDecode(res.body);
      if (!context.mounted) return;
      showMessage(
        context,
        d['message']?.toString() ??
            (d['success'] == true ? 'Uploaded!' : 'Upload failed'),
      );
      onRefresh(showLoader: false);
    } catch (e) {
      if (!context.mounted) return;
      showMessage(context, 'Upload error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = documents.where((d) {
      final cat = pickValue(d as Map, ['category', 'type']).toLowerCase();
      if (filter == 'Plans') return cat.contains('plan');
      if (filter == 'Permits') return cat.contains('permit');
      if (filter == 'Others') {
        return !cat.contains('plan') && !cat.contains('permit');
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => onRefresh(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPageHeader('Documents', onBack: null),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildFilterChip(
                    'All',
                    selected: filter == 'All',
                    onTap: () => onFilterChange('All'),
                  ),
                  buildFilterChip(
                    'Plans',
                    selected: filter == 'Plans',
                    onTap: () => onFilterChange('Plans'),
                  ),
                  buildFilterChip(
                    'Permits',
                    selected: filter == 'Permits',
                    onTap: () => onFilterChange('Permits'),
                  ),
                  buildFilterChip(
                    'Others',
                    selected: filter == 'Others',
                    onTap: () => onFilterChange('Others'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (shown.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 45,
                  horizontal: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDDECE7),
                  ),
                ),
                child: Column(
                  children: [
                    buildEmptyIcon(Icons.folder_open_outlined),
                    const SizedBox(height: 15),
                    const Text(
                      'No Documents Yet',
                      style: TextStyle(
                        color: kTextDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Authorized project documents\n'
                          'will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kTextGray,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
                ...shown.map((d) {
                  final m = d as Map;
                  return buildListItem(
                    icon: Icons.insert_drive_file_outlined,
                    title: pickValue(m, ['title', 'file_name', 'name'], 'Document'),
                    subtitle: pickValue(m, ['created_at', 'uploaded_at']),
                    trailing: pickValue(m, ['category', 'type']),
                  );
                }),
                const SizedBox(height: 16),
                buildPrimaryButton(
                  'Upload Document',
                      () => _uploadDocument(context),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
