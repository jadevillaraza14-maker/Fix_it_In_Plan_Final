import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'login.dart';
import 'document_viewer.dart';

const List<String> _projectStages = [
  'Request Submitted',
  'Assessment',
  'Planning',
  'Revision',
  'Finalized',
  'Completed',
];

//
const String baseUrl =
'https://steed-husband-drier.ngrok-free.dev/Fix_it_In_Plans_Api';

Future<List<dynamic>> fetchList(
    String file,
    String key,
    ) async {
  try {
    final res = await http
        .get(
      Uri.parse('$baseUrl/$file'),
    )
        .timeout(
      const Duration(seconds: 10),
    );

    final data = jsonDecode(res.body);

    if (data['success'] == true &&
        data[key] is List) {
      return data[key];
    }
  } catch (e) {
    debugPrint('$file error: $e');
  }

  return [];
}

String pick(
    Map m,
    List<String> keys, [
      String d = '',
    ]) {
  for (final k in keys) {
    final v = m[k];

    if (v != null &&
        v.toString().isNotEmpty) {
      return v.toString();
    }
  }

  return d;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  final Color darkGreen =
  const Color(0xFF004437);

  final Color lightGreen =
  const Color(0xFF63C47A);

  int selectedIndex = 0;

  bool loading = true;

  String query = '';

  List<dynamic> requests = [];
  List<dynamic> clients = [];
  List<dynamic> projects = [];
  List<dynamic> documents = [];
  List<dynamic> revisions = [];
  List<dynamic> notifications = [];

  // ============================================================
  // MESSAGES
  // ============================================================

  List<Map<String, dynamic>> adminMessages = [];

  Timer? messageTimer;

  int get unreadMessageCount {
    return adminMessages.where((message) {
      final sender =
      message['sender_role']?.toString();

      final isRead =
      message['is_read']?.toString();

      return sender == 'client' &&
          isRead != '1' &&
          isRead != 'true';
    }).length;
  }

  @override
  void initState() {
    super.initState();

    loadAll();

    // Check new client messages every 5 seconds
    messageTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        loadAdminMessages(
          silent: true,
        );
      },
    );
  }

  @override
  void dispose() {
    messageTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<void> loadAll() async {
    setState(() => loading = true);

    final r = await Future.wait([
      fetchList(
        'admin_project_requests.php',
        'requests',
      ),
      fetchList(
        'admin_clients.php',
        'clients',
      ),
      fetchList(
        'admin_projects.php',
        'projects',
      ),
      fetchList(
        'admin_documents.php',
        'documents',
      ),
      fetchList(
        'admin_revisions.php',
        'revisions',
      ),
      fetchList(
        'admin_notifications.php',
        'notifications',
      ),
    ]);

    await loadAdminMessages(
      silent: true,
    );

    if (!mounted) return;

    setState(() {
      requests = r[0];
      clients = r[1];
      projects = r[2];
      documents = r[3];
      revisions = r[4];
      notifications = r[5];

      loading = false;
    });
  }

  // ============================================================
  // LOAD ADMIN MESSAGES
  // ============================================================

  Future<void> loadAdminMessages({
    bool silent = false,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '$baseUrl/admin_messages.php',
        ),
      )
          .timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        return;
      }

      final decoded =
      jsonDecode(response.body);

      if (decoded is Map &&
          decoded['success'] == false) {
        return;
      }

      dynamic list = [];

      if (decoded is Map) {
        list =
            decoded['messages'] ??
                decoded['data'] ??
                [];
      }

      if (list is! List) {
        return;
      }

      final result = list
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        adminMessages = result;
      });
    } catch (e) {
      if (!silent) {
        debugPrint(
          'Admin messages error: $e',
        );
      }
    }
  }

  // ============================================================
  // MARK MESSAGES READ
  // ============================================================

  Future<void> markMessagesRead() async {
    try {
      await http
          .post(
        Uri.parse(
          '$baseUrl/mark_messages_read.php',
        ),
      )
          .timeout(
        const Duration(seconds: 10),
      );

      await loadAdminMessages(
        silent: true,
      );
    } catch (e) {
      debugPrint(
        'Mark messages read error: $e',
      );
    }
  }

  // ============================================================
  // OPEN MESSAGES
  // ============================================================

  void openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminMessagesScreen(
          messages: adminMessages,
          onRead: () async {
            await markMessagesRead();
          },
        ),
      ),
    ).then((_) {
      loadAdminMessages(
        silent: true,
      );
    });
  }

  // ============================================================
  // SNACK
  // ============================================================

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(
      Map r,
      String status,
      ) async {
    final id = r['id'];

    try {
      final res = await http.post(
        Uri.parse(
          '$baseUrl/update_project_request.php',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'request_id': id,
          'status': status,
        }),
      );

      final data = jsonDecode(res.body);

      _snack(
        data['message']?.toString() ??
            (
                data['success'] == true
                    ? 'Updated'
                    : 'Failed'
            ),
      );

      if (data['success'] == true) {
        await loadAll();
      }

    } catch (e) {
      _snack(
        'Error: $e',
      );
    }
  }
  // ============================================================
  // FILTER
  // ============================================================

  List<dynamic> _filter(
      List<dynamic> items,
      ) {
    if (query.trim().isEmpty) {
      return items;
    }

    final q =
    query.toLowerCase();

    return items.where((i) {
      if (i is! Map) {
        return false;
      }

      return i.values.any(
            (v) => v
            .toString()
            .toLowerCase()
            .contains(q),
      );
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF4F7F6),

      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,

          children: [
            _homePage(),

            _listPage(
              'Clients',
              clients,
              [
                'name',
                'full_name',
                'username',
              ],
              [
                'email',
                'phone',
              ],
              Icons.person_outline,
            ),

            _listPage(
              'Projects',
              projects,
              [
                'project_name',
                'title',
                'project_type',
              ],
              [
                'location',
                'status',
              ],
              Icons.home_work_outlined,
            ),

            _listPage(
              'Files',
              documents,
              [
                'file_name',
              ],
              [
                'client_name',
                'category',
                'uploaded_at',
              ],
              Icons.description_outlined,
            ),

            _morePage(),
          ],
        ),
      ),

      bottomNavigationBar:
      _bottomNav(),
    );
  }
  List<dynamic> get _pending => requests.where(
        (r) =>
    pick(r as Map, ['status'], 'Pending').toLowerCase() ==
        'pending',
  ).toList();


  // ============================================================
  // HOME
  // ============================================================

  Widget _homePage() {
    final shown =
    _filter(requests);

    return RefreshIndicator(
      onRefresh: loadAll,

      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        child: Column(
          children: [
            _header(),

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                25,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  _title('Overview'),

                  const SizedBox(
                    height: 13,
                  ),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),

                    children: [
                      _statCard(
                        'Total Clients',
                        clients.length,
                        Icons.people_outline,
                        const Color(
                          0xFF438D70,
                        ),
                            () => setState(
                              () => selectedIndex = 1,
                        ),
                      ),

                      _statCard(
                        'Pending Requests',
                        _pending.length,
                        Icons.assignment_outlined,
                        const Color(
                          0xFFD79A35,
                        ),
                            () => _openList(
                          'Pending Requests',
                          _pending,
                          [
                            'project_type',
                            'description',
                          ],
                          [
                            'client_name',
                            'status',
                          ],
                          Icons.assignment_outlined,
                          onTapItem: _showRequest,
                        ),
                      ),

                      _statCard(
                        'Active Projects',
                        projects.length,
                        Icons.home_work_outlined,
                        const Color(
                          0xFF4C82C1,
                        ),
                            () => setState(
                              () => selectedIndex = 2,
                        ),
                      ),

                      _statCard(
                        'Pending Revisions',
                        revisions.length,
                        Icons.edit_note_outlined,
                        const Color(
                          0xFF8B68AE,
                        ),
                            () => _openList(
                          'Revisions',
                          revisions,
                          [
                            'title',
                            'description',
                            'project_name',
                          ],
                          [
                            'status',
                            'created_at',
                          ],
                          Icons.edit_note_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  _title(
                    query.trim().isEmpty
                        ? 'Recent Project Requests'
                        : 'Results for "${query.trim()}"',
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  if (loading)
                    const Center(
                      child:
                      CircularProgressIndicator(),
                    )
                  else if (shown.isEmpty)
                    _emptyCard(
                      query.trim().isEmpty
                          ? 'No project requests yet'
                          : 'No match for "${query.trim()}"',
                      query.trim().isEmpty
                          ? 'Project requests from clients will appear here.'
                          : 'Try the client name, location or project type.',
                    )
                  else
                    ...shown.map(
                          (r) => _requestCard(
                        r as Map,
                      ),
                    ),
                  const SizedBox(
                    height: 25,
                  ),

                  _title(
                    'Project Status',
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  if (projects.isEmpty)
                    _emptyCard(
                      'No projects yet',
                      'Accepted requests become projects here.',
                    )
                  else
                    ...projects.map(
                          (p) => _projectStatusCard(
                        p as Map,
                      ),
                    ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }



  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        24,
      ),

      decoration: BoxDecoration(
        color: darkGreen,

        borderRadius:
        const BorderRadius.only(
          bottomLeft:
          Radius.circular(28),
          bottomRight:
          Radius.circular(28),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),

                child: const Icon(
                  Icons.home_outlined,
                  color: Colors.white,
                  size: 29,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Fix It In Plan',
                      style:
                      TextStyle(
                        color:
                        Colors.white,
                        fontSize: 19,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    Text(
                      'Admin Dashboard',
                      style:
                      TextStyle(
                        color:
                        Color(
                          0xFFB8CBC6,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // NOTIFICATION BELL
              // =================================================

              InkWell(
                borderRadius:
                BorderRadius.circular(
                  13,
                ),

                onTap: () {
                  if (unreadMessageCount >
                      0) {
                    openMessages();
                  } else {
                    _openList(
                      'Notifications',
                      notifications,
                      [
                        'title',
                        'message',
                      ],
                      [
                        'created_at',
                      ],
                      Icons.notifications_none,
                    );
                  }
                },

                child: Container(
                  width: 43,
                  height: 43,

                  decoration:
                  BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),

                  child: Badge(
                    isLabelVisible:
                    unreadMessageCount >
                        0,

                    label: Text(
                      '$unreadMessageCount',
                    ),

                    child:
                    const Icon(
                      Icons.notifications_none,
                      color:
                      Colors.white,
                      size: 23,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 25,
          ),

          const Text(
            'Welcome back,',
            style: TextStyle(
              color:
              Color(0xFFB8CBC6),
              fontSize: 14,
            ),
          ),

          const Text(
            'Administrator!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Container(
            height: 48,

            decoration:
            BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),

            child: TextField(
              onChanged: (v) =>
                  setState(
                        () => query = v,
                  ),

              style:
              const TextStyle(
                color:
                Colors.white,
                fontSize: 14,
              ),

              decoration:
              const InputDecoration(
                hintText:
                'Search projects, clients...',

                hintStyle:
                TextStyle(
                  color:
                  Color(
                    0xFF9CB5AE,
                  ),
                  fontSize: 13,
                ),

                prefixIcon:
                Icon(
                  Icons.search,
                  color:
                  Color(
                    0xFFD2DEDA,
                  ),
                  size: 21,
                ),

                border:
                InputBorder.none,

                contentPadding:
                EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _title(String t) =>
      Text(
        t,
        style:
        const TextStyle(
          color:
          Color(0xFF173F36),
          fontSize: 19,
          fontWeight:
          FontWeight.bold,
        ),
      );

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(
      String title,
      int value,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(17),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(17),

        onTap: onTap,

        child: Container(
          padding:
          const EdgeInsets.all(14),

          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            border: Border.all(
              color:
              const Color(
                0xFFE2EAE7,
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Container(
                width: 36,
                height: 36,

                decoration:
                BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),

              const Spacer(),

              Text(
                '$value',
                style:
                const TextStyle(
                  color:
                  Color(0xFF173F36),
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              Text(
                title,
                style:
                const TextStyle(
                  color:
                  Color(0xFF71817C),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyCard(
      String title,
      String message,
      ) {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(24),

      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          const Color(
            0xFFE2EAE7,
          ),
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color:
            Color(0xFF438D70),
            size: 30,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              Color(0xFF40534E),
              fontSize: 13,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            message,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              Color(0xFF899792),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _requestCard(
      Map r,
      ) {
    return Card(
      color: Colors.white,

      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),

      child: ListTile(
        leading: const Icon(
          Icons.assignment_outlined,
        ),

        title: Text(
          pick(
            r,
            ['project_type'],
            'Project',
          ),
        ),

        subtitle: Text(
          '${pick(r, [
            'client_name',
            'name',
            'username',
          ])}  ${pick(r, ['location'])}'
              .trim(),
        ),

        trailing: Text(
          pick(
            r,
            ['status'],
            'pending',
          ),

          style:
          const TextStyle(
            fontSize: 11,
          ),
        ),

        onTap: () =>
            _showRequest(r),
      ),
    );
  }

  // ============================================================
  // REQUEST DETAIL
  // ============================================================

  void _showRequest(
      Map r,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (_) => Padding(
        padding:
        const EdgeInsets.all(20),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Text(
              pick(
                r,
                ['project_type'],
                'Project Request',
              ),

              style:
              const TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            _row(
              'Client',
              pick(
                r,
                [
                  'client_name',
                  'name',
                  'client_id',
                ],
              ),
            ),

            _row(
              'Location',
              pick(
                r,
                ['location'],
              ),
            ),

            _row(
              'Lot size',
              pick(
                r,
                ['lot_size'],
              ),
            ),

            _row(
              'Service',
              pick(
                r,
                [
                  'preferred_service',
                ],
              ),
            ),

            _row(
              'Timeline',
              pick(
                r,
                [
                  'target_timeline',
                ],
              ),
            ),

            _row(
              'Description',
              pick(
                r,
                ['description'],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Row(
              children: [
                Expanded(
                  child:
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );

                      _updateStatus(
                        r,
                        'rejected',
                      );
                    },

                    child:
                    const Text(
                      'Reject',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                  ElevatedButton(
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      darkGreen,
                      foregroundColor:
                      Colors.white,
                    ),

                    onPressed: () {
                      Navigator.pop(
                        context,
                      );

                      _updateStatus(
                        r,
                        'approved',
                      );
                    },

                    child:
                    const Text(
                      'Approve',
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
  // ============================================================
  // PROJECT STATUS TRACKER
  // ============================================================

  bool _savingStage = false;

  int _stageIndexOf(Map p) {
    final s = pick(p, ['status']).toLowerCase();

    return _projectStages.indexWhere(
          (e) => e.toLowerCase() == s,
    );
  }

  Widget _projectStatusCard(Map p) {
    final cur = _stageIndexOf(p);

    final stageName =
    cur < 0 ? 'Not started' : _projectStages[cur];

    return Card(
      color: Colors.white,

      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),

      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          12,
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 20,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    pick(
                      p,
                      [
                        'project_name',
                        'project_type',
                      ],
                      'Project',
                    ),

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  stageName,

                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              pick(p, ['client_name'], ''),

              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            _stageDots(p, cur),

            const SizedBox(
              height: 8,
            ),

            Text(
              _savingStage
                  ? 'Saving...'
                  : 'Tap a circle to mark that stage as done.',

              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageDots(Map p, int cur) {
    return Row(
      children: [
        for (int i = 0; i < _projectStages.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= cur
                    ? darkGreen
                    : Colors.grey.shade300,
              ),
            ),

          _stageDot(p, i, cur),
        ],
      ],
    );
  }

  Widget _stageDot(Map p, int i, int cur) {
    final done = i <= cur;

    return InkWell(
      onTap: _savingStage
          ? null
          : () => _setProjectStage(p, i),

      child: Tooltip(
        message: _projectStages[i],

        child: Container(
          width: 32,
          height: 32,

          alignment: Alignment.center,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            color: done
                ? darkGreen
                : Colors.white,

            border: Border.all(
              color: done
                  ? darkGreen
                  : Colors.grey.shade400,
              width: 2,
            ),
          ),

          child: done
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
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setProjectStage(
      Map p,
      int stageIndex,
      ) async {
    final projectId =
        int.tryParse('${p['id'] ?? ''}') ?? 0;

    if (projectId <= 0) {
      _snack('Project ID not found.');
      return;
    }

    setState(
          () => _savingStage = true,
    );

    final res = await ApiService.updateProjectStatus(
      projectId: projectId,
      status: _projectStages[stageIndex],
      progress:
      (((stageIndex + 1) / _projectStages.length) * 100)
          .round(),
    );

    if (!mounted) return;

    setState(
          () => _savingStage = false,
    );

    _snack(
      res['success'] == true
          ? '${_projectStages[stageIndex]} marked. Client notified: '
          '${res['notification_sent'] == true ? 'yes' : 'no'}.'
          : '${res['message'] ?? 'Update failed.'}',
    );

    if (res['success'] == true) loadAll();
  }

  Widget _row(
      String k,
      String v,
      ) {
    if (v.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 6,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 90,

            child: Text(
              k,

              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(v),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENERIC LIST
  // ============================================================

  Widget _listBody(
      List<dynamic> items,
      List<String> titleKeys,
      List<String> subKeys,
      IconData icon, {
        void Function(Map)? onTapItem,
      }) {
    final shown =
    _filter(items);

    return RefreshIndicator(
      onRefresh: loadAll,

      child: shown.isEmpty
          ? ListView(
        children: [
          const SizedBox(
            height: 80,
          ),

          Center(
            child: Text(
              loading
                  ? 'Loading...'
                  : 'No data.',
            ),
          ),
        ],
      )

          : ListView.builder(
        padding:
        const EdgeInsets.all(
          16,
        ),

        itemCount:
        shown.length,

        itemBuilder: (_, i) {
          final m =
          shown[i] as Map;

          final sub =
          subKeys
              .map(
                (k) =>
                pick(m, [k]),
          )
              .where(
                (s) =>
            s.isNotEmpty,
          )
              .join(' • ');

          return Card(
            color:
            Colors.white,

            child: ListTile(
              leading:
              Icon(icon),

              title: Text(
                pick(
                  m,
                  titleKeys,
                  'Item ${i + 1}',
                ),
              ),

              subtitle:
              Text(sub),
              onTap: () {
                if (onTapItem != null) {
                  onTapItem(m);
                } else if (m.containsKey('reason')) {
                  _showRevisionDetails(m);
                } else {
                  _showDetails(m);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetails(
      Map m,
      ) {
    final rows = m.entries
        .map(
          (e) => _row(
        e.key.toString(),
        '${e.value ?? ''}',
      ),
    )
        .toList();

    final path = pick(m, ['file_path']);

    if (path.isNotEmpty) {
      rows.insert(
        0,
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ElevatedButton.icon(
            onPressed: () => openDocumentFile(
              context: context,
              name: pick(m, ['file_name'], 'Document'),
              url: '$baseUrl/$path',
              ext: pick(m, ['file_type']),
            ),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('View File'),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding:
          const EdgeInsets.all(
            20,
          ),
          children: rows,
        ),
      ),
    );
  }
  void _showRevisionDetails(Map m) {
    final remarks = TextEditingController(
      text: pick(m, ['engineer_remarks']),
    );

    final path = pick(m, ['file_path']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Revision Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF173F36),
                ),
              ),
              const SizedBox(height: 14),
              _row('Client', pick(m, ['client_name'])),
              _row('Project', pick(m, ['project_name'])),
              _row('Description', pick(m, ['description'])),
              _row('Reason', pick(m, ['reason'])),
              _row('Status', pick(m, ['status'])),
              _row('Requested', pick(m, ['created_at'])),
              if (path.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ElevatedButton.icon(
                    onPressed: () => openDocumentFile(
                      context: context,
                      name: pick(m, ['file_name'], 'Revision file'),
                      url: '$baseUrl/$path',
                      ext: pick(m, ['file_type']),
                    ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View File'),
                  ),
                ),
              TextField(
                controller: remarks,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Engineer remarks',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _setRevisionStatus(
                          m,
                          'Rejected',
                          remarks.text.trim(),
                        );
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _setRevisionStatus(
                          m,
                          'Approved',
                          remarks.text.trim(),
                        );
                      },
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setRevisionStatus(
      Map m,
      String status,
      String remarks,
      ) async {
    final revisionId = int.tryParse('${m['id'] ?? ''}') ?? 0;

    if (revisionId <= 0) {
      _snack('Revision ID not found.');
      return;
    }

    final res = await ApiService.updateRevisionStatus(
      revisionId: revisionId,
      status: status,
      engineerRemarks: remarks,
    );

    if (!mounted) return;

    _snack(
      res['success'] == true
          ? '$status. Client notified: '
          '${res['notification_sent'] == true ? 'yes' : 'no'}.'
          : '${res['message'] ?? 'Update failed.'}',
    );

    if (res['success'] == true) loadAll();
  }
  Widget _listPage(
      String title,
      List<dynamic> items,
      List<String> tk,
      List<String> sk,
      IconData icon,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Padding(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            0,
          ),

          child: Text(
            '$title (${items.length})',

            style:
            const TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xFF173F36),
            ),
          ),
        ),

        Expanded(
          child: _listBody(
            items,
            tk,
            sk,
            icon,
          ),
        ),
      ],
    );
  }

  void _openList(
      String title,
      List<dynamic> items,
      List<String> tk,
      List<String> sk,
      IconData icon, {
        void Function(Map)? onTapItem,
      }) {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor:
            darkGreen,
            foregroundColor:
            Colors.white,
          ),

          body: _listBody(
            items,
            tk,
            sk,
            icon,
            onTapItem: onTapItem,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MORE
  // ============================================================

  Widget _morePage() {
    return ListView(
      padding:
      const EdgeInsets.all(16),

      children: [
        _title('More'),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // MESSAGES
        // ======================================================

        ListTile(
          leading: Stack(
            clipBehavior:
            Clip.none,

            children: [
              const Icon(
                Icons.chat_bubble_outline,
              ),

              if (unreadMessageCount >
                  0)
                Positioned(
                  right: -7,
                  top: -7,

                  child: Container(
                    padding:
                    const EdgeInsets.all(
                      4,
                    ),

                    constraints:
                    const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),

                    decoration:
                    const BoxDecoration(
                      color: Colors.red,
                      shape:
                      BoxShape.circle,
                    ),

                    child: Text(
                      unreadMessageCount >
                          99
                          ? '99+'
                          : '$unreadMessageCount',

                      textAlign:
                      TextAlign.center,

                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          title: const Text(
            'Messages',
          ),

          subtitle:
          unreadMessageCount >
              0
              ? Text(
            '$unreadMessageCount new message${unreadMessageCount == 1 ? '' : 's'}',
          )
              : const Text(
            'Client messages',
          ),

          trailing:
          const Icon(
            Icons.chevron_right,
          ),

          onTap: openMessages,
        ),

        const Divider(),

        ListTile(
          leading: const Icon(
            Icons.edit_note_outlined,
          ),

          title: Text(
            'Revisions (${revisions.length})',
          ),

          trailing:
          const Icon(
            Icons.chevron_right,
          ),

          onTap: () =>
              _openList(
                'Revisions',
                revisions,
                [
                  'title',
                  'description',
                ],
                [
                  'status',
                  'created_at',
                ],
                Icons.edit_note_outlined,
              ),
        ),

        ListTile(
          leading: const Icon(
            Icons.notifications_none,
          ),

          title: Text(
            'Notifications (${notifications.length})',
          ),

          trailing:
          const Icon(
            Icons.chevron_right,
          ),

          onTap: () =>
              _openList(
                'Notifications',
                notifications,
                [
                  'title',
                  'message',
                ],
                [
                  'created_at',
                ],
                Icons.notifications_none,
              ),
        ),
        ListTile(
          leading: const Icon(
            Icons.description_outlined,
          ),

          title: const Text(
            'Terms and Conditions',
          ),


          trailing: const Icon(
            Icons.chevron_right,
          ),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminTermsScreen(),
              ),
            );
          },
        ),

        const Divider(),




        ListTile(
          leading: const Icon(
            Icons.logout,
            color: Colors.red,
          ),

          title:
          const Text('Logout'),

          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
                  (route) => false,
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex:
      selectedIndex,

      onTap: (i) => setState(
            () => selectedIndex = i,
      ),

      type:
      BottomNavigationBarType
          .fixed,

      backgroundColor:
      Colors.white,

      selectedItemColor:
      darkGreen,

      unselectedItemColor:
      const Color(
        0xFF9AA7A3,
      ),

      selectedFontSize: 10,

      unselectedFontSize: 10,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.dashboard_outlined,
          ),
          activeIcon: Icon(
            Icons.dashboard,
          ),
          label: 'Home',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.people_outline,
          ),
          activeIcon: Icon(
            Icons.people,
          ),
          label: 'Clients',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.home_work_outlined,
          ),
          activeIcon: Icon(
            Icons.home_work,
          ),
          label: 'Projects',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.folder_outlined,
          ),
          activeIcon: Icon(
            Icons.folder,
          ),
          label: 'Files',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.more_horiz,
          ),
          label: 'More',
        ),
      ],
    );
  }
}

// ============================================================
// ADMIN MESSAGES SCREEN
// ============================================================

class AdminMessagesScreen
    extends StatefulWidget {
  final List<Map<String, dynamic>>
  messages;

  final Future<void> Function()
  onRead;

  const AdminMessagesScreen({
    super.key,
    required this.messages,
    required this.onRead,
  });

  @override
  State<AdminMessagesScreen>
  createState() =>
      _AdminMessagesScreenState();
}




class _AdminMessagesScreenState
    extends State<AdminMessagesScreen> {
  List<Map<String, dynamic>> messages = [];

  Timer? timer;

  final TextEditingController messageController =
  TextEditingController();

  final ScrollController scrollController =
  ScrollController();

  bool sending = false;

  int? selectedClientId;
  final List<PlatformFile> _pendingFiles = [];
  String selectedClientName = '';

  @override
  void initState() {
    super.initState();

    messages = List.from(widget.messages);


    widget.onRead();

    timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => loadMessages(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();

    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<void> loadMessages() async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '$baseUrl/admin_messages.php',
        ),
      )
          .timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body);

      dynamic list = [];

      if (decoded is Map) {
        list =
            decoded['messages'] ??
                decoded['data'] ??
                [];
      }

      if (list is! List) {
        return;
      }

      final result = list
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        messages = result;
      });

      if (selectedClientId != null) {
        final hasClientMessages = messages.any(
              (message) =>
          int.tryParse(
            message['client_id']?.toString() ?? '',
          ) ==
              selectedClientId,
        );

        if (!hasClientMessages) {
          setState(() {
            selectedClientId = null;
            selectedClientName = '';
          });
        }
      }
    } catch (e) {
      debugPrint(
        'Messages error: $e',
      );
    }
  }

  // ============================================================
  // SEND ADMIN MESSAGE
  // ============================================================

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty && _pendingFiles.isEmpty) {
      return;
    }

    if (selectedClientId == null) {
      _adminMsg('Select a client first.');
      return;
    }

    final paths = _pendingFiles
        .map((file) => file.path)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList();

    setState(() {
      sending = true;
    });

    final result = await ApiService.sendChatMessage(
      clientId: selectedClientId!,
      senderRole: 'admin',
      message: text,
      filePaths: paths,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      messageController.clear();

      setState(() {
        _pendingFiles.clear();
        sending = false;
      });

      await loadMessages();

      await Future.delayed(const Duration(milliseconds: 100));

      scrollToBottom();

      final problems = result['problems'];

      if (problems is List && problems.isNotEmpty) {
        _adminMsg('Skipped: ${problems.join(', ')}');
      }
    } else {
      setState(() {
        sending = false;
      });

      _adminMsg(
        result['message']?.toString() ?? 'Failed to send message.',
      );
    }
  }

  // ============================================================
  // CHAT ATTACHMENTS (ADMIN)
  // ============================================================

  void _adminMsg(String text) {
    if (!mounted) return;

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

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        for (final file in result.files) {
          final path = file.path;

          if (path != null && path.isNotEmpty) {
            _pendingFiles.add(file);
          }
        }
      });
    } catch (e) {
      _adminMsg('Could not open the file picker: $e');
    }
  }

  void _removePendingFile(int index) {
    if (index < 0 || index >= _pendingFiles.length) {
      return;
    }

    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  String _attachmentUrl(String path) => '$baseUrl/$path';

  bool _isImageType(String type) {
    const images = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

    return images.contains(type.toLowerCase());
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showFullImage(String url, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                  errorBuilder: (context, error, stack) => const Center(
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
      builder: (dialogContext) => AlertDialog(
        title: Text(name, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 420,
          child: SelectableText(
            url,
            style: const TextStyle(fontSize: 13),
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
    required bool isAdmin,
  }) {
    final url = _attachmentUrl(path);

    if (_isImageType(type)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _showFullImage(url, name),
          child: SizedBox(
            width: 200,
            height: 150,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              cacheWidth: 640,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return Container(
                  color: const Color(0xFFEAF7F0),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stack) => Container(
                color: const Color(0xFFEAF7F0),
                alignment: Alignment.center,
                child: const Text(
                  'Image not available',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showFileLink(url, name),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0x22FFFFFF) : const Color(0xFFEAF7F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 20,
              color: isAdmin ? Colors.white : const Color(0xFF006B50),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name.isEmpty ? 'file.$type' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isAdmin ? Colors.white : const Color(0xFF40534E),
                ),
              ),
            ),
          ],
        ),
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
                  border: Border.all(color: const Color(0xFFD5E8E1)),
                ),

                  clipBehavior: Clip.antiAlias,
                  child: isImage
                      ? Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    cacheWidth: 320,
                    errorBuilder: (context, error, stack) =>
                    const Center(child: Icon(Icons.image_outlined)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9),
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

  // ============================================================
  // SELECT CLIENT
  // ============================================================

  void selectClient(
      int clientId,
      String clientName,
      ) {
    setState(() {
      selectedClientId =
          clientId;

      selectedClientName =
          clientName;
    });

    Future.delayed(
      const Duration(
        milliseconds: 100,
      ),
      scrollToBottom,
    );
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void scrollToBottom() {
    if (!scrollController.hasClients) {
      return;
    }

    scrollController.animateTo(
      scrollController.position
          .maxScrollExtent,
      duration:
      const Duration(
        milliseconds: 250,
      ),
      curve:
      Curves.easeOut,
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  String time(
      dynamic value,
      ) {
    if (value == null) {
      return '';
    }

    final raw =
    value.toString();

    if (raw.length >= 16) {
      return raw.substring(
        11,
        16,
      );
    }

    return raw;
  }

  // ============================================================
  // CLIENT LIST
  // ============================================================

  List<Map<String, dynamic>>
  get clientList {
    final Map<int, Map<String, dynamic>>
    clients = {};

    for (final message in messages) {
      final id =
      int.tryParse(
        message['client_id']
            ?.toString() ??
            '',
      );

      if (id == null) {
        continue;
      }

      clients[id] = message;
    }

    return clients.values.toList();
  }

  // ============================================================
  // CLIENT MESSAGES
  // ============================================================

  List<Map<String, dynamic>>
  get selectedMessages {
    if (selectedClientId == null) {
      return [];
    }

    return messages.where(
          (message) {
        final id =
        int.tryParse(
          message['client_id']
              ?.toString() ??
              '',
        );

        return id ==
            selectedClientId;
      },
    ).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF4F7F6),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF004437),

        foregroundColor:
        Colors.white,

        title: Text(
          selectedClientId == null
              ? 'Messages'
              : selectedClientName,
        ),
        leading: selectedClientId == null
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              selectedClientId = null;
            });
          },
        ),
      ),
      body: Row(
        children: [

          // ======================================================
          // CHAT
          // ======================================================

          Expanded(
            child:
            selectedClientId ==
                null
                ? ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              itemCount: clientList.length,

              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 76,
                color: Color(0xFFEDF2F0),
              ),

              itemBuilder: (context, index) {
                final client = clientList[index];

                final id = int.tryParse(
                  client['client_id']?.toString() ?? '',
                );

                final name =
                    client['client_name']?.toString() ??
                        client['client_username']?.toString() ??
                        'Client';

                final initials = name
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((part) => part.isNotEmpty)
                    .take(2)
                    .map((part) => part[0].toUpperCase())
                    .join();

                const avatarColors = [
                  Color(0xFF006B50),
                  Color(0xFFD79A35),
                  Color(0xFF8B68AE),
                  Color(0xFF2F7EA1),
                ];

                final avatarColor =
                avatarColors[(id ?? 0) % avatarColors.length];

                final preview =
                    client['message']?.toString() ?? '';

                return ListTile(
                  onTap: id == null
                      ? null
                      : () => selectClient(id, name),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor,
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF173F36),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    preview.isEmpty
                        ? 'Sent an attachment'
                        : preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            )
                : Column(
              children: [
                // CHAT HEADER

                Container(
                  width:
                  double.infinity,

                  padding:
                  const EdgeInsets.all(
                    14,
                  ),

                  color:
                  Colors.white,

                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor:
                        Color(
                          0xFFEAF7F0,
                        ),

                        child:
                        Icon(
                          Icons.person,
                          color:
                          Color(
                            0xFF438D70,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                        Text(
                          selectedClientName,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(
                              0xFF173F36,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                // MESSAGES

                Expanded(
                  child:
                  selectedMessages
                      .isEmpty
                      ? const Center(
                    child:
                    Text(
                      'No messages yet.',
                      style:
                      TextStyle(
                        color:
                        Colors.grey,
                      ),
                    ),
                  )
                      : ListView.builder(
                    controller:
                    scrollController,

                    padding:
                    const EdgeInsets.all(
                      14,
                    ),

                    itemCount:
                    selectedMessages
                        .length,

                    itemBuilder:
                        (_, index) {
                      final message =
                      selectedMessages[
                      index];

                      final isAdmin =
                          message[
                          'sender_role']
                              ?.toString() ==
                              'admin';

                      final text =
                          message[
                          'message']
                              ?.toString() ??
                              '';

                      final attachmentPath =
                          message['attachment_path']?.toString() ?? '';

                      final attachmentName =
                          message['attachment_name']?.toString() ?? '';

                      final attachmentType =
                          message['attachment_type']?.toString() ?? '';

                      final hasAttachment = attachmentPath.isNotEmpty;

                      return Align(
                        alignment:
                        isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,

                        child:
                        Container(
                          constraints:
                          BoxConstraints(
                            maxWidth:
                            MediaQuery.of(
                              context,
                            ).size.width *
                                (hasAttachment ? 0.78 : 0.55),
                          ),

                          margin:
                          const EdgeInsets.only(
                            bottom:
                            8,
                          ),

                          padding:
                          const EdgeInsets.all(
                            12,
                          ),

                          decoration:
                          BoxDecoration(
                            color:
                            isAdmin
                                ? const Color(
                              0xFF63C47A,
                            )
                                : Colors.white,

                            borderRadius:
                            BorderRadius.circular(
                              15,
                            ),

                            border:
                            Border.all(
                              color:
                              isAdmin
                                  ? Colors.transparent
                                  : const Color(
                                0xFFE2EAE7,
                              ),
                            ),
                          ),

                          child:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [
                              if (hasAttachment)
                                _attachmentWidget(
                                  path: attachmentPath,
                                  name: attachmentName,
                                  type: attachmentType,
                                  isAdmin: isAdmin,
                                ),

                              if (hasAttachment && text.isNotEmpty)
                                const SizedBox(
                                  height:
                                  8,
                                ),

                              if (text.isNotEmpty)
                                Text(
                                  text,
                                style:
                                TextStyle(
                                  color:
                                  isAdmin
                                      ? Colors.white
                                      : const Color(
                                    0xFF40534E,
                                  ),
                                  fontSize:
                                  13,
                                ),
                              ),

                              const SizedBox(
                                height:
                                4,
                              ),

                              Text(
                                time(
                                  message[
                                  'created_at'],
                                ),
                                style:
                                TextStyle(
                                  color:
                                  isAdmin
                                      ? Colors.white70
                                      : Colors.grey,
                                  fontSize:
                                  9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ==================================================
                // REPLY BOX
                // ==================================================
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              color: Colors.white,

              child: Column(
                children: [
                  if (_pendingFiles.isNotEmpty) _pendingPreviewStrip(),

                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Attach files',
                        onPressed: sending ? null : _pickFiles,
                        icon: const Icon(
                          Icons.attach_file_rounded,
                          color: Color(0xFF004437),
                        ),
                      ),

                      Expanded(
                        child: TextField(
                          controller: messageController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Type a reply...',
                            filled: true,
                            fillColor: const Color(0xFFF4F7F6),
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      SizedBox(
                        width: 46,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: sending ? null : sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004437),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          child: sending
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.send, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
              ]
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN - TERMS AND CONDITIONS EDITOR
// ============================================================

class AdminTermsScreen extends StatefulWidget {
  const AdminTermsScreen({super.key});

  @override
  State<AdminTermsScreen> createState() => _AdminTermsScreenState();
}

class _AdminTermsScreenState extends State<AdminTermsScreen> {
  List<Map<String, dynamic>> clauses = [];

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final res = await http
          .get(
        Uri.parse('$baseUrl/client_terms.php'),
      )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      final list = data['clauses'] is List ? data['clauses'] as List : [];

      setState(() {
        clauses =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _msg('Cannot load terms. $e');
    }
  }

  Future<void> _post(Map<String, dynamic> body) async {
    setState(() => saving = true);

    try {
      final res = await http
          .post(
        Uri.parse('$baseUrl/admin_terms.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      if (data['success'] == true && data['clauses'] is List) {
        setState(() {
          clauses = (data['clauses'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }

      _msg(data['message']?.toString() ?? 'Saved.');
    } catch (e) {
      _msg('Cannot connect to server. $e');
    }

    setState(() => saving = false);
  }

  Future<Map<String, String>?> _showEditor({
    String title = '',
    String body = '',
  }) {
    final titleController = TextEditingController(text: title);
    final bodyController = TextEditingController(text: body);

    String error = '';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF7FBF9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title.isEmpty ? 'New Terms & Condition' : 'Edit clause'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 6,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                  ),
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final t = titleController.text.trim();
                final b = bodyController.text.trim();

                if (t.isEmpty || b.isEmpty) {
                  setDialogState(
                        () => error = 'Kailangan pareho ang title at details.',
                  );
                  return;
                }

                Navigator.pop(dialogContext, {'title': t, 'body': b});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add() async {
    final result = await _showEditor();
    if (result == null) return;

    await _post({
      'action': 'add',
      'title': result['title'],
      'body': result['body'],
    });
  }

  Future<void> _edit(Map<String, dynamic> clause) async {
    final result = await _showEditor(
      title: clause['title']?.toString() ?? '',
      body: clause['body']?.toString() ?? '',
    );
    if (result == null) return;

    await _post({
      'action': 'update',
      'id': clause['id'],
      'title': result['title'],
      'body': result['body'],
    });
  }

  Future<void> _delete(Map<String, dynamic> clause) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this clause?'),
        content: Text(
          'Clients will no longer see "${clause['title']}" when they sign up.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (yes != true) return;

    await _post({
      'action': 'delete',
      'id': clause['id'],
    });
  }

  Widget _clauseRow(int index, Map<String, dynamic> clause) {
    final isFirst = index == 0;
    final isLast = index == clauses.length - 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEAF7F0),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF004437),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    clause['title']?.toString() ?? '',
                    style: const TextStyle(
                      color: Color(0xFF004437),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 4, right: 8),
              child: Text(
                clause['body']?.toString() ?? '',
                style: const TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Move up',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: (isFirst || saving)
                      ? null
                      : () => _post({
                    'action': 'move',
                    'id': clause['id'],
                    'direction': 'up',
                  }),
                ),
                IconButton(
                  tooltip: 'Move down',
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: (isLast || saving)
                      ? null
                      : () => _post({
                    'action': 'move',
                    'id': clause['id'],
                    'direction': 'down',
                  }),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: saving ? null : () => _edit(clause),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: saving ? null : () => _delete(clause),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: const Color(0xFF004437),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (saving || loading) ? null : _add,
        backgroundColor: const Color(0xFF004437),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 90),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 10),

            ),
            if (clauses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Wala pang clause. Pindutin ang "Add clause".',
                  ),
                ),
              )
            else
              ...clauses.asMap().entries.map(
                    (e) => _clauseRow(e.key, e.value),
              ),
          ],
        ),
      ),
    );
  }
}
