import 'package:flutter/material.dart';
import 'client_shared.dart';

class ClientProject {
  final String id;
  final String name;
  final String type;
  final String location;
  final String lotSize;
  final String description;
  final String status;
  final String createdAt;
  final double progress;

  const ClientProject({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.lotSize,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.progress,
  });

  factory ClientProject.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    final rawProgress = double.tryParse(
      pick(['progress', 'progress_percent', 'percentage']),
    ) ??
        0;

    return ClientProject(
      id: pick(['id', 'project_id']),
      name: pick(['project_name', 'name', 'title']),
      type: pick(['project_type', 'type']),
      location: pick(['location', 'address']),
      lotSize: pick(['lot_size', 'lotSize', 'lot_area']),
      description: pick(['description', 'details']),
      status: pick(['status', 'project_status']),
      createdAt: pick(['created_at', 'date_created', 'created_date']),
      progress: rawProgress.clamp(0, 100).toDouble(),
    );
  }
}

class ProjectDetailsScreen extends StatelessWidget {
  final ClientProject project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextDark,
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
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kTextDark,
        title: const Text(
          'Project Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFDDECE7),
              ),
            ),
            child: Column(
              children: [
                _row('Project Name', project.name),
                _row('Project Type', project.type),
                _row('Location', project.location),
                _row('Lot Size', project.lotSize),
                _row('Description', project.description),
                _row('Status', project.status),
                _row('Created Date', project.createdAt),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: kTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${project.progress.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: kDarkGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: project.progress / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE3F0EB),
                    valueColor:
                    const AlwaysStoppedAnimation(kLightGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


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
