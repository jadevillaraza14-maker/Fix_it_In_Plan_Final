

import 'dart:convert';
import 'api_service.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'client_designs.dart';
import 'client_home.dart';
import 'client_projects.dart';

// API SETTINGS


const String _base = 'http://192.168.100.12/Fix_it_in_Plans_Api';

const List<String> _stages = [
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
  bool loading = true;
  bool projectLoading = true;
  bool projectError = false;

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
    if (showLoader && mounted) {
      setState(() {
        loading = true;
        projectLoading = true;
        projectError = false;
      });
    } else if (mounted) {
      setState(() {
        projectLoading = true;
        projectError = false;
      });
    }

    final id = widget.clientId;

    try {
      final projectData = await ApiService.getClientProjects(id);

      if (!mounted) return;

      setState(() {
        projects = projectData;
        projectLoading = false;
        projectError = false;
      });
    } catch (e) {
      debugPrint('client_projects.php error: $e');

      if (!mounted) return;

      setState(() {
        projects = [];
        projectLoading = false;
        projectError = true;
      });
    }

    try {
      final results = await Future.wait([
        _get('client_documents.php?client_id=$id', 'documents'),
        _get('client_notifications.php?client_id=$id', 'notifications'),
      ]);

      if (!mounted) return;

      setState(() {
        documents = results[0];
        notifications = results[1];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        documents = [];
        notifications = [];
        loading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: [
            _homePage(),
            _projectsPage(),
            _filesPage(),
            _alertsPage(),
            _profilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNavigation(),
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
    return ClientHomePage(
      firstName: firstName,
      project: activeProject,
      notifications: notifications,
      loading: projectLoading,
      projectError: projectError,
      onRefresh: loadAll,
      onNavigateTab: (index) {
        setState(() => selectedIndex = index);
      },
      onRequestRevision: _requestRevision,
      onRequestProject: _requestProject,
      onRetry: () => loadAll(showLoader: true),
      onProjectTap: _openProjectDetails,
    );
  }

  void _openProjectDetails(Map p) {
    final project = ClientProject.fromJson(
      Map<String, dynamic>.from(p),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(project: project),
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

  Widget _projectCard(Map? p) {
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
                Text(
                  loc.isEmpty ? 'No location assigned' : loc,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

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
        children: List.generate(_stages.length, (i) {
          final done = i <= cur;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(
                  done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: done ? darkGreen : const Color(0xFF9BC5B8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _stages[i],
                  style: TextStyle(
                    color: done ? textDark : textGray,
                    fontSize: 13,
                    fontWeight:
                    done ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
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
              ],
          ],
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
              ...List.generate(_stages.length, (i) {
                final done = i <= cur;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                        done ? darkGreen : const Color(0xFF9BC5B8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _stages[i],
                        style: TextStyle(
                          color: done ? textDark : textGray,
                          fontSize: 13,
                          fontWeight:
                          done ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
                  icon: Icons.insert_drive_file_outlined,
                  title: _pick(m, ['title', 'file_name', 'name'], 'Document'),
                  subtitle: _pick(m, ['created_at', 'uploaded_at']),
                  trailing: _pick(m, ['category', 'type']),
                );
              }),

            const SizedBox(height: 16),

            _primaryButton('Upload Document', _uploadDocument),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final cat = await _choose('Select Category', [
      'Plans',
      'Permits',
      'Others',
    ]);
    if (cat == null) return;

    final f = result.files.single;
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

  // ALERTS

  Widget _alertsPage() {
    final shown = notifications.where((n) {
      final t = _pick(n as Map, ['type', 'category']).toLowerCase();
      if (notifFilter == 'Project') return t.contains('project');
      if (notifFilter == 'System') return t.contains('system');
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
                _filterChip(
                  'Project',
                  selected: notifFilter == 'Project',
                  onTap: () => setState(() => notifFilter = 'Project'),
                ),
                _filterChip(
                  'System',
                  selected: notifFilter == 'System',
                  onTap: () => setState(() => notifFilter = 'System'),
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
              _showMessage('Change Password');
            },
          ),

          _profileOption(
            Icons.notifications_none,
            'Notification Settings',
                () {
              _showMessage('Notification Settings');
            },
          ),

          _profileOption(
            Icons.help_outline,
            'Help & Support',
                () {
              _showMessage('Help & Support');
            },
          ),

          const SizedBox(height: 10),

          _profileOption(
            Icons.logout,
            'Logout',
                () {
              Navigator.pop(context);
            },
            danger: true,
          ),
        ],
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

  // REQUEST PROJECT

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
            Future<void> submit() async {
              if (type == null || locationC.text.trim().isEmpty) {
                _showMessage(
                  'project type location.',
                );
                return;
              }
              setSheet(() => sending = true);

              final d = await _post('create_project_request.php', {
                'client_id': widget.clientId,
                'project_type': type,
                'location': locationC.text.trim(),
                'lot_size': lotC.text.trim(),
                'preferred_service': '',
                'description': '',
                'target_timeline': '',
              });

              if (d['success'] == true) {
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                _showMessage(
                  'Project request submitted!.',
                );
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

                    _selectField(
                      'Project Type',
                      'Select project type',
                      type,
                          () async {
                        final v = await _choose('Project Type', [
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

                    _inputField(
                      'Location',
                      'Enter project location',
                      locationC,
                    ),

                    const SizedBox(height: 12),

                    _inputField(
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

  // REQUEST REVISION

  void _requestRevision() {
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
      TextEditingController controller,
      ) {
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
