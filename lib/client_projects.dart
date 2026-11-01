import 'package:flutter/material.dart';

import 'client_shared.dart';

class ClientProjectsPage extends StatelessWidget {
  final List<dynamic> projects;
  final String filter;
  final bool loading;
  final ValueChanged<String> onFilterChange;
  final Future<void> Function({bool showLoader}) onRefresh;
  final VoidCallback onRequestProject;

  const ClientProjectsPage({
    super.key,
    required this.projects,
    required this.filter,
    required this.loading,
    required this.onFilterChange,
    required this.onRefresh,
    required this.onRequestProject,
  });

  @override
  Widget build(BuildContext context) {
    final shown = projects.where((p) {
      final m = p as Map;
      if (filter == 'Ongoing') return !isCompletedProject(m);
      if (filter == 'Completed') return isCompletedProject(m);
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
            buildPageHeader('My Projects', onBack: null),
            const SizedBox(height: 18),
            Row(
              children: [
                buildFilterChip(
                  'All',
                  selected: filter == 'All',
                  onTap: () => onFilterChange('All'),
                ),
                buildFilterChip(
                  'Ongoing',
                  selected: filter == 'Ongoing',
                  onTap: () => onFilterChange('Ongoing'),
                ),
                buildFilterChip(
                  'Completed',
                  selected: filter == 'Completed',
                  onTap: () => onFilterChange('Completed'),
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
                    buildEmptyIcon(Icons.home_work_outlined),
                    const SizedBox(height: 15),
                    const Text(
                      'No Projects Yet',
                      style: TextStyle(
                        color: kTextDark,
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
                        color: kTextGray,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onRequestProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkGreen,
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
                  return buildListItem(
                    icon: Icons.home_work_outlined,
                    title: pickValue(
                        m, ['project_name', 'title', 'project_type'], 'Project'),
                    subtitle: pickValue(m, ['location']),
                    trailing: pickValue(m, ['status'], 'Ongoing'),
                    onTap: () => _showProjectDetail(context, m),
                  );
                }),
                const SizedBox(height: 6),
                buildPrimaryButton('Request a Project', onRequestProject),
              ],
          ],
        ),
      ),
    );
  }
}

void _showProjectDetail(BuildContext context, Map p) {
  final cur = stageIndexOf(p);
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
            buildSheetHandle(),
            Text(
              pickValue(p, ['project_name', 'title', 'project_type'], 'Project'),
              style: const TextStyle(
                color: kTextDark,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pickValue(p, ['location']),
              style: const TextStyle(
                color: kTextGray,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(dashboardStages.length, (i) {
              final done = i <= cur;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? kDarkGreen : const Color(0xFF9BC5B8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dashboardStages[i],
                      style: TextStyle(
                        color: done ? kTextDark : kTextGray,
                        fontSize: 13,
                        fontWeight: done ? FontWeight.bold : FontWeight.w500,
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

// ============================================================
// PROJECT DETAILS SCREEN (bubukas kapag tinap ang My Home Project)
// ============================================================

class ProjectDetailsScreen extends StatelessWidget {
  final Map project;
  final double progress; // 0.0 - 1.0
  final List<String> stages;
  final int currentStage;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
    required this.progress,
    required this.stages,
    required this.currentStage,
  });

  static const Color _dark = Color(0xFF006B50);
  static const Color _light = Color(0xFF63C47A);
  static const Color _pale = Color(0xFFEAF7F0);
  static const Color _bg = Color(0xFFF7FBF9);
  static const Color _text = Color(0xFF173B33);
  static const Color _gray = Color(0xFF75908A);

  String _v(List<String> keys, [String d = '-']) {
    for (final k in keys) {
      final v = project[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return d;
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: _gray, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _text,
        title: const Text(
          'Project Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCEDE7)),
              ),
              child: Column(
                children: [
                  _row('Project Name',
                      _v(['project_name', 'title', 'project_type'])),
                  _row('Project Type', _v(['project_type', 'type'])),
                  _row('Location', _v(['location', 'address'])),
                  _row('Lot Size', _v(['lot_size', 'lotSize', 'lot_area'])),
                  _row('Description', _v(['description', 'details'])),
                  _row('Status', _v(['status'])),
                  _row('Created Date',
                      _v(['created_at', 'date_created', 'created_date'])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCEDE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Progress',
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: _dark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE3F0EB),
                      valueColor: const AlwaysStoppedAnimation(_light),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(stages.length, (i) {
                    final done = i <= currentStage;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: done ? _dark : const Color(0xFF9BC5B8),
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            stages[i],
                            style: TextStyle(
                              color: done ? _text : _gray,
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
            ),
          ],
        ),
      ),
    );
  }
}
