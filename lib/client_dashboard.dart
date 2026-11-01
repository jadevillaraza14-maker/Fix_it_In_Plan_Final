import 'dart:async';
import 'dart:convert';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'change_password.dart';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'client_designs.dart';
import 'api_service.dart';
import 'login.dart';
import 'client_projects.dart';
import 'chatbot.dart';
import  'map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'request_revision.dart';
import 'document_viewer.dart';
// ============================================================
// API SETTINGS
// ============================================================

const String _base = 'https://steed-husband-drier.ngrok-free.dev/Fix_it_In_Plans_Api';
const List<String> _stages = [
  'Request Submitted',
  'Assessment',
  'Planning',
  'Revision',
  'Finalized',
  'Completed',
];

Future<List<dynamic>> _get(String path, String key) async {
  try {
    final res = await http
        .get(Uri.parse('$_base/$path'))
        .timeout(const Duration(seconds: 10));
    final d = jsonDecode(res.body);
    if (d['success'] == true && d[key] is List) return d[key];
  } catch (e) {
    debugPrint('$path error: $e');
  }
  return [];
}

// Para sa projects: kapag pumalya ang connection, mag-throw
// (para lumabas ang "Unable to load project information." + Retry)
Future<List<dynamic>> _getStrict(String path, String key) async {
  final res = await http
      .get(Uri.parse('$_base/$path'))
      .timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }
  final d = jsonDecode(res.body);
  if (d is Map && d[key] is List) return d[key] as List;
  return [];
}

Future<Map> _post(String file, Map body) async {
  try {
    final res = await http
        .post(
      Uri.parse('$_base/$file'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 15));
    return jsonDecode(res.body) as Map;
  } catch (e) {
    return {'success': false, 'message': 'Error: $e'};
  }
}

String _pick(Map m, List<String> keys, [String d = '']) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return d;
}

int _stageIndex(Map p) {
  final s = _pick(p, ['status']).toLowerCase();
  return _stages.indexWhere((e) => s.contains(e.toLowerCase()));
}

double _progress(Map p) {
  final v = double.tryParse(_pick(p, ['progress', 'progress_percent']));
  if (v != null) return (v / 100).clamp(0.0, 1.0);
  final i = _stageIndex(p);
  return i < 0 ? 0 : (i + 1) / _stages.length;
}

bool _isCompleted(Map p) =>
    _pick(p, ['status']).toLowerCase().contains('complete');

class ClientDashboardScreen extends StatefulWidget {
  final int clientId;
  final String clientName;
  final String username;
  final String email;

  const ClientDashboardScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.username,
    required this.email,
  });

  @override
  State<ClientDashboardScreen> createState() =>
      _ClientDashboardScreenState();
}


class _ClientDashboardScreenState
    extends State<ClientDashboardScreen> {
  int selectedIndex = 0;

  // DATA
  List<dynamic> projects = [];
  List<dynamic> documents = [];
  List<dynamic> notifications = [];
  List<dynamic> revisions = [];
  bool loading = true;
  bool loadError = false;

  // FILTERS
  String projectFilter = 'All';
  String docFilter = 'All';
  String notifFilter = 'All';

  // COLORS

  static const Color darkGreen = Color(0xFF006B50);
  static const Color green = Color(0xFF087F5B);
  static const Color lightGreen = Color(0xFF63C47A);
  static const Color paleGreen = Color(0xFFEAF7F0);
  static const Color background = Color(0xFFF7FBF9);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll({bool showLoader = true}) async {
    if (mounted) {
      setState(() {
        if (showLoader) loading = true;
        loadError = false;
      });
    }

    // clientId ng NAKA-LOGIN na client (hindi hardcoded)
    final id = widget.clientId;

    List<dynamic> proj = [];
    bool failed = false;
    try {
      proj = await _getStrict('client_projects.php?client_id=$id', 'projects');
    } catch (e) {
      debugPrint('client_projects.php error: $e');
      failed = true;
    }

    final r = await Future.wait([
      _get('client_documents.php?client_id=$id', 'documents'),
      _get('client_notifications.php?client_id=$id', 'notifications'),
      _get('client_revisions.php?client_id=$id', 'revisions'),
    ]);
    if (!mounted) return;
    setState(() {
      if (failed) {
        loadError = true;
      } else {
        projects = proj;
      }
      documents = r[0];
      notifications = r[1];
      revisions = r[2];
      loading = false;
    });
  }

  Map? get activeProject {
    if (projects.isEmpty) return null;
    return projects.first as Map;
  }

  String get firstName {
    final name = widget.clientName.trim();

    if (name.isEmpty) {
      return 'Client';
    }

    return name.split(' ').first;
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientInboxScreen(
          clientId: widget.clientId,
          clientName: widget.clientName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: selectedIndex,
              children: [
                _homePage(),
                _projectsPage(),
                _filesPage(),
                _alertsPage(),
                _profilePage(),
              ],
            ),

            // Civil Engineering Assistant floating button
            Positioned(
              right: 16,
              bottom: 16,
              child: _chatbotFloatingButton(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNavigation(),
    );
  }

  Widget _chatbotFloatingButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CivilEngineerChatbotScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.engineering_outlined,
            color: Colors.white,
            size: 29,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _bottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE4EFEB),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
          loadAll(showLoader: false);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: darkGreen,
        unselectedItemColor: Color(0xFF8CA59E),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // HOME

  Widget _homePage() {
    final p = activeProject;
    return RefreshIndicator(
      onRefresh: () => loadAll(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          18,
          14,
          18,
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topHeader(),

            const SizedBox(height: 22),

            Text(
              'Hello, $firstName 👋',
              style: const TextStyle(
                color: textDark,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              "Here's your project overview.",
              style: TextStyle(
                color: textGray,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 18),

            _projectSection(p),

            const SizedBox(height: 22),

            const Text(
              'Quick Actions',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.image_outlined,
                    title: 'View Designs',
                    subtitle: 'Plans & Designs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DesignsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.description_outlined,
                    title: 'Documents',
                    subtitle: 'Files & Permits',
                    onTap: () {
                      setState(() {
                        selectedIndex = 2;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.edit_note,
                    title: 'Request Revision',
                    subtitle: 'Changes & Updates',
                    onTap: _requestRevision,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages',
                    subtitle: 'Contact Team',
                    onTap: _openMessages,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _featuredDesigns(),

            const SizedBox(height: 25),

            _sectionTitle(
              'Project Status',
              action: null,
            ),

            const SizedBox(height: 10),

            _statusSection(p),
          ],
        ),
      ),
    );
  }

  // HEADER

  Widget _topHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: paleGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.home_work_outlined,
            color: darkGreen,
            size: 23,
          ),
        ),

        const SizedBox(width: 10),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fix It In Plan',
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Client Portal',
                style: TextStyle(
                  color: textGray,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {
            setState(() {
              selectedIndex = 3;
            });
          },
          icon: const Icon(
            Icons.notifications_none,
            color: darkGreen,
          ),
        ),

        GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex = 4;
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: paleGreen,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD2E8DF),
              ),
            ),
            child: const Icon(
              Icons.person,
              color: darkGreen,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // PROJECT CARD (walang project = "No Project Yet")

  Widget _projectCardBody(Map? p) {
    final name = p == null
        ? 'No Project Yet'
        : _pick(p, ['project_name', 'title', 'project_type'], 'My Project');
    final status =
    p == null ? 'No Project' : _pick(p, ['status'], 'Ongoing');
    final loc = p == null ? '' : _pick(p, ['location']);
    final prog = p == null ? 0.0 : _progress(p);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCEDE7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 145,
            decoration: BoxDecoration(
              color: paleGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.home_work_outlined,
                color: Color(0xFF86BCAF),
                size: 65,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Home Project',
                      style: TextStyle(
                        color: textGray,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: paleGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: darkGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: textGray,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    loc.isEmpty ? 'No location assigned' : loc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (p != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                [
                  _pick(p, ['project_type', 'type']),
                  if (_pick(p, ['lot_size', 'lotSize', 'lot_area']).isNotEmpty)
                    'Lot: ${_pick(p, ['lot_size', 'lotSize', 'lot_area'])}',
                ].where((e) => e.isNotEmpty).join('  •  '),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Project Progress',
                  style: TextStyle(
                    color: textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(prog * 100).round()}%',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: prog,
              minHeight: 7,
              backgroundColor: const Color(0xFFE3F0EB),
              valueColor: const AlwaysStoppedAnimation(lightGreen),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MY HOME PROJECT (loading / error / empty / may project)
  // ============================================================

  Widget _projectSection(Map? p) {
    if (loading) return _loadingBox();
    if (loadError) return _errorBox();
    return _projectCard(p);
  }

  Widget _projectCard(Map? p) {
    final body = _projectCardBody(p);

    // Walang project -> may "Request a Project" button
    if (p == null) {
      return Column(
        children: [
          body,
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _requestProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Request a Project',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    // May project -> clickable, bubukas ang Project Details
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openProjectDetails(p),
      child: body,
    );
  }

  void _openProjectDetails(Map p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(
          project: p,
          progress: _progress(p),
          stages: _stages,
          currentStage: _stageIndex(p),
        ),
      ),
    );
  }

  Widget _loadingBox() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEDE7)),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEDE7)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: darkGreen, size: 34),
          const SizedBox(height: 10),
          const Text(
            'Unable to load project information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => loadAll(),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROJECT STATUS SECTION
  // ============================================================

  Widget _statusSection(Map? p) {
    if (loading) return _loadingBox();
    if (loadError) return _errorBox();
    if (p == null) return _emptyStatusCard();
    return _statusCard(p);
  }

  // ============================================================
  // FEATURED DESIGNS
  // ============================================================

  Widget _featuredDesigns() {
    const items = [
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
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Designs',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Explore our latest home design ideas',
          style: TextStyle(color: textGray, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _featuredCard(
              items[i]['image']!,
              items[i]['title']!,
              items[i]['category']!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _featuredCard(String image, String title, String category) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DesignsScreen(),
          ),
        );
      },
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCEDE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.asset(
                image,
                width: 230,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 230,
                  height: 130,
                  color: paleGreen,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: darkGreen,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          category,
                          style: const TextStyle(
                            color: textGray,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color: darkGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // QUICK ACTION

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDDECE7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: paleGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: darkGreen,
                size: 21,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textGray,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9BB5AE),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // SECTION TITLE

  Widget _sectionTitle(
      String title, {
        String? action,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (action != null)
          Text(
            action,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  // EMPTY STATUS

  Widget _emptyStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDECE7),
        ),
      ),
      child: Column(
        children: [
          _emptyIcon(
            Icons.timeline_outlined,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Project Status Yet',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your project status will appear here\n'
                'once a project is assigned.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGray,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // STATUS CARD

  Widget _statusCard(Map p) {
    final cur = _stageIndex(p);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDECE7),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _pick(p, ['status'], 'Ongoing'),
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(_progress(p) * 100).round()}%',
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress(p),
              minHeight: 7,
              backgroundColor: const Color(0xFFE3F0EB),
              valueColor: const AlwaysStoppedAnimation(lightGreen),
            ),
          ),
          const SizedBox(height: 10),
          _stageTrack(cur),
        ],
      ),
    );
  }

  Widget _emptyIcon(IconData icon) {
    return Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(
        color: paleGreen,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: darkGreen,
        size: 29,
      ),
    );
  }
  // CONNECTED CIRCLE STAGE TRACK

  Widget _stageTrack(int cur) {
    final step = cur < 0 ? 0 : cur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _stages.length; i++) ...[
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < step
                      ? darkGreen
                      : i == step
                      ? Colors.white
                      : const Color(0xFFEDF5F2),
                  border: Border.all(
                    color: i <= step
                        ? darkGreen
                        : const Color(0xFFBFDCCF),
                    width: 2,
                  ),
                ),
                child: i < step
                    ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
                    : Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: i == step
                        ? darkGreen
                        : const Color(0xFF9BC5B8),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  _stages[i],
                  style: TextStyle(
                    color: i <= step ? textDark : textGray,
                    fontSize: 13,
                    fontWeight: i == step
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (i != _stages.length - 1)
            Container(
              width: 2,
              height: 20,
              margin: const EdgeInsets.only(left: 13),
              color: i < step
                  ? darkGreen
                  : const Color(0xFFBFDCCF),
            ),
        ],
      ],
    );
  }
  // LIST ITEM (project / document / notification)

  Widget _listItem({
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
          border: Border.all(
            color: const Color(0xFFDDECE7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: paleGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: darkGreen, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textGray,
                        fontSize: 11,
                      ),
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
                  color: paleGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(
                    color: darkGreen,
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

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // PROJECTS PAGE

  Widget _projectsPage() {
    final shown = projects.where((p) {
      final m = p as Map;
      if (projectFilter == 'Ongoing') return !_isCompleted(m);
      if (projectFilter == 'Completed') return _isCompleted(m);
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => loadAll(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(
              'My Projects',
              onBack: null,
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                _filterChip(
                  'All',
                  selected: projectFilter == 'All',
                  onTap: () => setState(() => projectFilter = 'All'),
                ),
                _filterChip(
                  'Ongoing',
                  selected: projectFilter == 'Ongoing',
                  onTap: () => setState(() => projectFilter = 'Ongoing'),
                ),
                _filterChip(
                  'Completed',
                  selected: projectFilter == 'Completed',
                  onTap: () =>
                      setState(() => projectFilter = 'Completed'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (shown.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 35,
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
                    _emptyIcon(
                      Icons.home_work_outlined,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'No Projects Yet',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'You currently have no assigned\n'
                          'project.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textGray,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _requestProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Request a Project',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
                ...shown.map((p) {
                  final m = p as Map;
                  return _listItem(
                    icon: Icons.home_work_outlined,
                    title: _pick(
                        m, ['project_name', 'title', 'project_type'], 'Project'),
                    subtitle: _pick(m, ['location']),
                    trailing: _pick(m, ['status'], 'Ongoing'),
                    onTap: () => _showProjectDetail(m),
                  );
                }),
                const SizedBox(height: 6),
                _primaryButton('Request a Project', _requestProject),
                if (revisions.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _sectionTitle('My Revision Requests'),
                  const SizedBox(height: 10),
                  ...revisions.map((v) {
                    final m = v as Map;
                    return _listItem(
                      icon: fileIconFor(_pick(m, ['file_type'], 'doc')),
                      title: _pick(m, ['description'], 'Revision'),
                      subtitle: _pick(m, ['reason'], 'No reason given'),
                      trailing: _pick(m, ['status'], 'Pending'),
                      onTap: () => _showRevisionDetail(m),
                    );
                  }),
                ],
              ],
          ],
        ),
      ),
    );
  }
  void _showRevisionDetail(Map m) {
    final path = _pick(m, ['file_path']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              _sheetHandle(),

              const SizedBox(height: 14),

              if (path.isNotEmpty) ...[
                _primaryButton(
                  'View Attached File',
                      () => openDocumentFile(
                    context: context,
                    name: _pick(m, ['file_name'], 'Revision file'),
                    url: '$_base/$path',
                    ext: _pick(m, ['file_type']),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              _infoField(
                'Description',
                _pick(m, ['description'], '-'),
              ),
              _infoField(
                'Reason',
                _pick(m, ['reason'], '-'),
              ),
              _infoField(
                'Status',
                _pick(m, ['status'], 'Pending'),
              ),
              _infoField(
                'Admin remarks',
                _pick(m, ['engineer_remarks'], 'None yet'),
              ),
              _infoField(
                'Requested',
                _pick(m, ['created_at'], '-'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showProjectDetail(Map p) {
    final cur = _stageIndex(p);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              Text(
                _pick(p, ['project_name', 'title', 'project_type'],
                    'Project'),
                style: const TextStyle(
                  color: textDark,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _pick(p, ['location']),
                style: const TextStyle(
                  color: textGray,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              _stageTrack(cur),
            ],
          ),
        );
      },
    );
  }

  // FILES

  Widget _filesPage() {
    final shown = documents.where((d) {
      final cat = _pick(d as Map, ['category', 'type']).toLowerCase();
      if (docFilter == 'Plans') return cat.contains('plan');
      if (docFilter == 'Permits') return cat.contains('permit');
      if (docFilter == 'Others') {
        return !cat.contains('plan') && !cat.contains('permit');
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => loadAll(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(
              'Documents',
              onBack: null,
            ),

            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    'All',
                    selected: docFilter == 'All',
                    onTap: () => setState(() => docFilter = 'All'),
                  ),
                  _filterChip(
                    'Plans',
                    selected: docFilter == 'Plans',
                    onTap: () => setState(() => docFilter = 'Plans'),
                  ),
                  _filterChip(
                    'Permits',
                    selected: docFilter == 'Permits',
                    onTap: () => setState(() => docFilter = 'Permits'),
                  ),
                  _filterChip(
                    'Others',
                    selected: docFilter == 'Others',
                    onTap: () => setState(() => docFilter = 'Others'),
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
                    _emptyIcon(
                      Icons.folder_open_outlined,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'No Documents Yet',
                      style: TextStyle(
                        color: textDark,
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
                        color: textGray,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...shown.map((d) {
                final m = d as Map;
                return _listItem(
                  icon: _fileIcon(_pick(m, ['file_type'])),
                  title: _pick(m, ['title', 'file_name', 'name'], 'Document'),
                  subtitle: _pick(m, ['uploaded_at', 'category']),
                  trailing: _pick(m, ['category']),
                  onTap: () => _openDocument(m),
                );
              }),

    if (docFilter == 'All') ...[
    const SizedBox(height: 16),
    _primaryButton('Upload Document', _uploadDocument),
    ],
        ],
      ),
    )
    );
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf', 'jpg', 'jpeg', 'png',
        'doc', 'docx', 'xls', 'xlsx',
      ],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final f = result.files.single;

    if (f.path == null) {
      _showMessage('Could not read the selected file.');
      return;
    }

    if (!mounted) return;

    final cat = await _choose('Select Category', [
      'Plans',
      'Permits',
      'Others',
    ]);

    if (cat == null) return;

    _showMessage('Uploading...');

    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/upload_document.php'),
      )
        ..fields['client_id'] = '${widget.clientId}'
        ..fields['category'] = cat
        ..fields['title'] = f.name;

      final pid = activeProject?['id'];
      if (pid != null) req.fields['project_id'] = '$pid';

      req.files.add(await http.MultipartFile.fromPath('file', f.path!));

      final res = await http.Response.fromStream(await req.send());
      final d = jsonDecode(res.body);

      _showMessage(
        d['message']?.toString() ??
            (d['success'] == true ? 'Uploaded!' : 'Upload failed'),
      );
      loadAll(showLoader: false);
    } catch (e) {
      _showMessage('Upload error: $e');
    }
  }
  void _openDocument(Map m) {
    final path = _pick(m, ['file_path']);
    final name = _pick(m, ['file_name', 'title'], 'Document');
    final ext = _pick(m, ['file_type']).toLowerCase();

    if (path.isEmpty) {
      _showMessage('This file has no stored copy.');
      return;
    }

    final url = '$_base/$path';

    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ImageViewerScreen(
            title: name,
            url: url,
          ),
        ),
      );
      return;
    }

    launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).then((ok) {
      if (!ok && mounted) {
        _showMessage('No app on this phone can open a $ext file.');
      }
    });
  }

  IconData _fileIcon(String ext) {
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
  // ALERTS

  Widget _alertsPage() {
    final shown = notifFilter == 'All'
        ? notifications.toList()
        : <dynamic>[];
    return RefreshIndicator(
      onRefresh: () => loadAll(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(
              'Notifications',
              onBack: null,
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                _filterChip(
                  'All',
                  selected: notifFilter == 'All',
                  onTap: () => setState(() => notifFilter = 'All'),
                ),
              ],
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
                    _emptyIcon(
                      Icons.notifications_none,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'No Notifications',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'New project updates and messages\n'
                          'will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textGray,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...shown.map((n) {
                final m = n as Map;
                return _listItem(
                  icon: Icons.notifications_active_outlined,
                  title: _pick(m, ['title', 'message'], 'Notification'),
                  subtitle: _pick(m, ['message', 'created_at']),
                  trailing: _pick(m, ['type', 'category']),
                );
              }),
          ],
        ),
      ),
    );
  }

  // PROFILE

  Widget _profilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      child: Column(
        children: [
          _pageHeader(
            'Profile',
            onBack: null,
          ),

          const SizedBox(height: 25),

          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: paleGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: darkGreen,
              size: 55,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            widget.clientName,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            '@${widget.username}',
            style: const TextStyle(
              color: textGray,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            widget.email,
            style: const TextStyle(
              color: textGray,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 25),

          _profileOption(
            Icons.person_outline,
            'Personal Information',
            _personalInformation,
          ),


          _profileOption(
            Icons.lock_outline,
            'Change Password',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(
                    clientId: widget.clientId,
                  ),
                ),
              );
            },
          ),
          _profileOption(
            Icons.notifications_none,
            'Notification Settings',
            _openNotificationSettings,
          ),
          _profileOption(
            Icons.help_outline,
            'Help & Support',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CivilEngineerChatbotScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _profileOption(
            Icons.logout,
            'Logout',
                () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
            danger: true,
          ),
        ],
      ),
    );
  }
  Future<void> _openNotificationSettings() async {
    final loaded =
    await ApiService.getNotificationSettings(widget.clientId);

    if (loaded['success'] != true) {
      _showMessage(
        loaded['message']?.toString() ?? 'Could not load settings.',
      );
      return;
    }

    bool enabled =
        int.tryParse('${loaded['notif_enabled'] ?? 1}') == 1;

    await showDialog<void>(
      context: context,

      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Notification Settings'),

          content: SwitchListTile(
            contentPadding: EdgeInsets.zero,

            title: const Text('Push notifications'),
            subtitle: const Text(
              'Project updates and new messages',
            ),

            value: enabled,

            onChanged: (value) async {
              setDialogState(() => enabled = value);

              final res = await ApiService.saveNotificationSettings(
                clientId: widget.clientId,
                enabled: value,
              );

              _showMessage(
                res['success'] == true
                    ? value
                    ? 'Push notifications are on.'
                    : 'Push notifications are off.'
                    : res['message']?.toString() ??
                    'Could not save.',
              );
            },
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }





  Widget _profileOption(
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool danger = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFDDECE7),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: danger ? Colors.red : darkGreen,
          size: 21,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: danger ? Colors.red : textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF9CB5AE),
          size: 19,
        ),
      ),
    );
  }

  // ============================================================
// REQUEST PROJECT
// ============================================================
  void _requestRevision() {
    final project = activeProject;

    if (project == null || project['id'] == null) {
      _showMessage('Select a project first.');
      return;
    }

    showRequestRevisionSheet(
      context,
      clientId: widget.clientId,
      projectId: project['id'],
        onSubmitted: loadAll,
    );
  }
  void _requestProject() {
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

            // ==========================================================
            // SELECT LOCATION FROM MAP
            // ==========================================================

            Future<void> selectProjectLocation() async {
              final selectedLocation = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapScreen(),
                ),
              );

              if (selectedLocation != null) {
                setSheet(() {
                  locationC.text = selectedLocation.toString();

                });
              }
            }

            // ==========================================================
            // SUBMIT
            // ==========================================================

            Future<void> submit() async {
              if (type == null ||
                  locationC.text.trim().isEmpty) {
                _showMessage(
                  'Please select project type and location.',
                );
                return;
              }

              setSheet(() => sending = true);

              final d = await _post(
                'create_project_request.php',
                {
                  'client_id': widget.clientId,
                  'project_type': type,
                  'location': locationC.text.trim(),
                  'lot_size': lotC.text.trim(),
                  'preferred_service': '',
                  'description': '',
                  'target_timeline': '',
                },
              );

              if (d['success'] == true) {
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }

                _showMessage(
                  'Project request submitted!',
                );

                loadAll(showLoader: false);
              } else {
                if (sheetContext.mounted) {
                  setSheet(() => sending = false);
                }

                _showMessage(
                  d['message']?.toString() ??
                      'Failed to submit.',
                );
              }
            }

            // ==========================================================
            // REQUEST PROJECT UI
            // ==========================================================

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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(),

                    const Text(
                      'Request a Project',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Submit your project details to the team.',
                      style: TextStyle(
                        color: textGray,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // PROJECT TYPE
                    // ==================================================

                    _selectField(
                      'Project Type',
                      'Select project type',
                      type,
                          () async {
                        final v = await _choose(
                          'Project Type',
                          [
                            'House Design',
                            'Renovation',
                            'Interior Design',
                            'Building Permit',
                            'Structural Plan',
                            'Others',
                          ],
                        );

                        if (v != null) {
                          setSheet(() {
                            type = v;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // LOCATION
                    // TAP THIS TO OPEN MAP
                    // ==================================================

                    GestureDetector(
                      onTap: sending
                          ? null
                          : () async {
                        await selectProjectLocation();
                      },
                      child: AbsorbPointer(
                        child: _inputField(
                          'Location',
                          locationC.text.isEmpty
                              ? 'Tap to select project location'
                              : locationC.text,
                          locationC,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // LOT SIZE
                    // ==================================================

                    _inputField(
                      'Lot Size',
                      'Example: 120',
                      lotC,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // ==================================================
                    // CONTINUE
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                        sending ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(15),
                          ),
                        ),
                        child: sending
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Continue',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
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

  // REQUEST REVISION

  void _requestRevisionOld() {
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
                _showMessage('area details.');
                return;
              }
              setSheet(() => sending = true);

              final d = await _post('create_revision.php', {
                'client_id': widget.clientId,
                'project_id': activeProject?['id'],
                'area': area,
                'details': detailsC.text.trim(),
                'description': detailsC.text.trim(),
              });

              if (d['success'] == true) {
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                _showMessage('Revision request sent to admin.');
                loadAll(showLoader: false);
              } else {
                if (sheetContext.mounted) {
                  setSheet(() => sending = false);
                }
                _showMessage(
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
                    _sheetHandle(),

                    const Text(
                      'Request Revision',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Tell us what changes you want to make.',
                      style: TextStyle(
                        color: textGray,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _selectField(
                      'Select Area',
                      'Choose area',
                      area,
                          () async {
                        final v = await _choose('Select Area', [
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
                        color: background,
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
                          color: textDark,
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
                          backgroundColor: darkGreen,
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


  // PERSONAL INFORMATION

  void _personalInformation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),

              const Text(
                'Personal Information',
                style: TextStyle(
                  color: textDark,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _infoField(
                'Full Name',
                widget.clientName,
              ),

              _infoField(
                'Username',
                widget.username,
              ),

              _infoField(
                'Email Address',
                widget.email,
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoField(
      String label,
      String value,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFDDECE7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textGray,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // HELPERS

  Widget _pageHeader(
      String title, {
        VoidCallback? onBack,
      }) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
            ),
          ),
        if (onBack == null) const SizedBox(width: 2),
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
      String text, {
        required bool selected,
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? darkGreen : const Color(0xFFDDECE7),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : textGray,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      String label,
      String hint,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD5E8E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textDark,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9BB2AC),
                fontSize: 12,
              ),
              suffixText: label == 'Lot Size' ? 'sqm' : null,
              suffixStyle: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ],
      ),
    );
  }
  Widget _selectField(
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
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD5E8E1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: textDark,
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
                          : textDark,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: textGray,
                  size: 19,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _choose(String title, List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
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
                _sheetHandle(),
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
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
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                      ),
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

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 45,
        height: 5,
        margin: const EdgeInsets.only(
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFD7E6E1),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

class ClientInboxScreen extends StatefulWidget {
  final int clientId;
  final String clientName;

  const ClientInboxScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientInboxScreen> createState() => _ClientInboxScreenState();
}

class _ClientInboxScreenState extends State<ClientInboxScreen> {
  static const Color darkGreen = Color(0xFF006B50);
  static const Color background = Color(0xFFF7FBF9);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.getMessages(
        clientId: widget.clientId,
      );

      if (!mounted) return;

      setState(() {
        _messages = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openThread() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientMessagesScreen(
          clientId: widget.clientId,
          clientName: widget.clientName,
        ),
      ),
    );

    if (!mounted) return;
    _load();
  }

  String get _preview {
    if (_messages.isEmpty) return 'Say hello to the team';

    final last = _messages.last;
    final role = last['sender_role']?.toString().toLowerCase() ?? '';
    final who = role == 'client' ? 'You' : 'Admin';
    final text = last['message']?.toString() ?? '';

    if (text.isEmpty) return '$who: sent an attachment';
    return '$who: $text';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: textDark,
        titleSpacing: 16,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: darkGreen,
        ),
      )
          : ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          ListTile(
            onTap: _openThread,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: ClipOval(
              child: Image.asset(
                'assets/app_icon.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            title: const Text(
              'Admin',
              style: TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textGray,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// CLIENT MESSAGES / CHAT
// ============================================================

class ClientMessagesScreen extends StatefulWidget {
  final int clientId;
  final String clientName;

  const ClientMessagesScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientMessagesScreen> createState() =>
      _ClientMessagesScreenState();
}

class _ClientMessagesScreenState extends State<ClientMessagesScreen> {
  final TextEditingController _messageController =
  TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  final List<PlatformFile> _pendingFiles = [];
  Timer? _timer;
  static const Color darkGreen = Color(0xFF006B50);
  static const Color lightGreen = Color(0xFF63C47A);
  static const Color background = Color(0xFFF7FBF9);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Check for new messages every 5 seconds.
    _timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _loadMessages(showLoader: false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final result = await ApiService.getMessages(
        clientId: widget.clientId,
      );

      if (!mounted) return;

      setState(() {
        messages = result;
        loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  void _chatFeedback(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'zip',
        ],
      );

      if (result == null) return;

      setState(() {
        for (final file in result.files) {
          if (file.path == null) continue;

          final alreadyAdded = _pendingFiles.any(
                (p) => p.path == file.path,
          );

          if (!alreadyAdded) {
            _pendingFiles.add(file);
          }
        }
      });
    } catch (e) {
      _chatFeedback('Could not open the file picker. $e');
    }
  }

  void _removePendingFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    final paths = _pendingFiles
        .map((f) => f.path ?? '')
        .where((p) => p.isNotEmpty)
        .toList(growable: false);

    if ((text.isEmpty && paths.isEmpty) || sending) return;

    FocusScope.of(context).unfocus();

    setState(() {
      sending = true;
    });

    final result = await ApiService.sendChatMessage(
      clientId: widget.clientId,
      senderRole: 'client',
      message: text,
      filePaths: paths,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _messageController.clear();

      setState(() {
        _pendingFiles.clear();
      });

      await _loadMessages(showLoader: false);

      final problems = result['problems'];

      if (problems is List && problems.isNotEmpty) {
        _chatFeedback(problems.first.toString());
      }
    } else {
      _chatFeedback(
        result['message']?.toString() ?? 'Failed to send message.',
      );
    }

    if (mounted) {
      setState(() {
        sending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final text = value.toString();
    if (text.isEmpty) return '';

    try {
      final date = DateTime.parse(text).toLocal();
      final hour = date.hour == 0
          ? 12
          : date.hour > 12
          ? date.hour - 12
          : date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: textDark,
        titleSpacing: 12,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Contact Team',
              style: TextStyle(
                color: textGray,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
              child: CircularProgressIndicator(
                color: darkGreen,
              ),
            )
                : messages.isEmpty
                ? _emptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                18,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _messageBubble(messages[index]);
              },
            ),
          ),
          _messageInput(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: darkGreen,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No messages yet',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Send a message to contact the Fix It In Plan team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGray,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _attachmentUrl(String path) => '$_base/$path';

  bool _isImageType(String type) {
    const images = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    return images.contains(type.toLowerCase());
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  void _showFullImage(String url, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      cacheWidth: 1440,
                      errorBuilder: (context, error, stack) =>
                      const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showFileLink(String url, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            backgroundColor: const Color(0xFFF7FBF9),
            title: Text(
              name.isEmpty ? 'Attachment' : name,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF006B50),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _attachmentWidget({
    required String path,
    required String name,
    required String type,
    required bool isClient,
  }) {
    final url = _attachmentUrl(path);
    final textColor = isClient ? Colors.white : textDark;

    if (_isImageType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFullImage(url, name),
              child: SizedBox(
                width: 210,
                height: 150,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  cacheWidth: 640,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return Container(
                      width: 210,
                      height: 150,
                      alignment: Alignment.center,
                      color: const Color(0xFFEAF7F0),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) =>
                      Container(
                        width: 210,
                        height: 150,
                        alignment: Alignment.center,
                        color: const Color(0xFFEAF7F0),
                        child: const Text(
                          'Image not available',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isClient ? Colors.white24 : const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFileLink(url, name),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 22,
                  color: textColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Attachment' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '.${type.toUpperCase()}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final sender =
        message['sender_role']?.toString().toLowerCase() ?? '';
    final isClient = sender == 'client';
    final text = message['message']?.toString() ?? '';
    final time = _formatDate(message['created_at']);

    final path = message['attachment_path']?.toString() ?? '';
    final name = message['attachment_name']?.toString() ?? '';
    final type = message['attachment_type']?.toString() ?? '';

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery
            .of(context)
            .size
            .width * 0.70,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
      decoration: BoxDecoration(
        color: isClient ? lightGreen : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isClient ? 18 : 4),
          bottomRight: Radius.circular(isClient ? 4 : 18),
        ),
        border: isClient
            ? null
            : Border.all(
          color: const Color(0xFFDDECE7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isClient ? 'You' : 'Admin',
            style: TextStyle(
              color: isClient ? Colors.white : darkGreen,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (text.isNotEmpty)
            Text(
              text,
              style: TextStyle(
                color: isClient ? Colors.white : textDark,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          if (path.isNotEmpty) ...[
            if (text.isNotEmpty) const SizedBox(height: 8),
            _attachmentWidget(
              path: path,
              name: name,
              type: type,
              isClient: isClient,
            ),
          ],
          if (time.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(
                color: isClient
                    ? Colors.white.withOpacity(0.80)
                    : textGray,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
        isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isClient) ...[
            ClipOval(
              child: Image.asset(
                'assets/app_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
  Widget _pendingPreviewStrip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _pendingFiles.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final file = _pendingFiles[index];
            final path = file.path ?? '';
            final isImage = _isImageType(file.extension ?? '');

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD5E8E1),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isImage
                      ? Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    cacheWidth: 320,
                    errorBuilder: (context, error, stack) =>
                    const Center(
                      child: Icon(Icons.image_outlined),
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        size: 22,
                        color: Color(0xFF006B50),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        child: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF173B33),
                          ),
                        ),
                      ),
                      Text(
                        _formatBytes(file.size),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF75908A),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.cancel, size: 20),
                    onPressed: () => _removePendingFile(index),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  Widget _messageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE0ECE8),
            ),
          ),
        ),
        child: Column(
          children: [
            if (_pendingFiles.isNotEmpty) _pendingPreviewStrip(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: IconButton(
                    tooltip: 'Attach files',
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF006B50),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEAF7F0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: sending ? null : _pickFiles,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 46,
                      maxHeight: 110,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFD5E8E1),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9BB2AC),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: sending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      darkGreen.withOpacity(0.5),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: sending
                        ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.send_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _ImageViewerScreen extends StatelessWidget {
  final String title;
  final String url;

  const _ImageViewerScreen({
    required this.title,
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
          title,
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