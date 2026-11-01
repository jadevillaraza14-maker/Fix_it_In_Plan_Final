import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

IconData fileIconFor(String ext) {
  switch (ext.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'jpg':
    case 'jpeg':
    case 'png':
      return Icons.image_outlined;
    case 'doc':
    case 'docx':
      return Icons.description_outlined;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

Future<void> openDocumentFile({
  required BuildContext context,
  required String name,
  required String url,
  required String ext,
}) async {
  if (const ['jpg', 'jpeg', 'png'].contains(ext.toLowerCase())) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          name: name,
          url: url,
        ),
      ),
    );
    return;
  }

  await _downloadThenOpen(
    context: context,
    name: name,
    url: url,
    ext: ext,
  );
}

Future<void> _downloadThenOpen({
  required BuildContext context,
  required String name,
  required String url,
  required String ext,
}) async {
  final nav = Navigator.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.all(22),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Preparing file...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String message = '';

  try {
    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception('the server answered ${res.statusCode}');
    }

    final dir = await getTemporaryDirectory();
    final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

    final file = File(
      '${dir.path}${Platform.pathSeparator}$safeName',
    );

    await file.writeAsBytes(res.bodyBytes, flush: true);

    if (nav.canPop()) nav.pop();

    final result = await OpenFilex.open(file.path);

    if (result.type != ResultType.done) {
      message = result.type == ResultType.noAppToOpen
          ? 'No app on this phone can open a $ext file.'
          : result.message;
    }
  } catch (e) {
    if (nav.canPop()) nav.pop();
    message = 'Could not open the file. $e';
  }

  if (message.isNotEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

class DocumentViewerScreen extends StatelessWidget {
  final String name;
  final String url;

  const DocumentViewerScreen({
    super.key,
    required this.name,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          name,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: InteractiveViewer(
        maxScale: 8,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stack) => const Center(
              child: Text(
                'Could not load image.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}