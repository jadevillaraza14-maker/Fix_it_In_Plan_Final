import 'package:flutter/material.dart';

import 'client_shared.dart';

class ClientAlertsPage extends StatelessWidget {
  final List<dynamic> notifications;
  final String filter;
  final bool loading;
  final ValueChanged<String> onFilterChange;
  final Future<void> Function({bool showLoader}) onRefresh;

  const ClientAlertsPage({
    super.key,
    required this.notifications,
    required this.filter,
    required this.loading,
    required this.onFilterChange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final shown = notifications.where((n) {
      final t = pickValue(n as Map, ['type', 'category']).toLowerCase();
      if (filter == 'Project') return t.contains('project');
      if (filter == 'System') return t.contains('system');
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
            buildPageHeader('Notifications', onBack: null),
            const SizedBox(height: 18),
            Row(
              children: [
                buildFilterChip(
                  'All',
                  selected: filter == 'All',
                  onTap: () => onFilterChange('All'),
                ),
                buildFilterChip(
                  'Project',
                  selected: filter == 'Project',
                  onTap: () => onFilterChange('Project'),
                ),
                buildFilterChip(
                  'System',
                  selected: filter == 'System',
                  onTap: () => onFilterChange('System'),
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
                    buildEmptyIcon(Icons.notifications_none),
                    const SizedBox(height: 15),
                    const Text(
                      'No Notifications',
                      style: TextStyle(
                        color: kTextDark,
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
                        color: kTextGray,
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
                return buildListItem(
                  icon: Icons.notifications_active_outlined,
                  title: pickValue(m, ['title', 'message'], 'Notification'),
                  subtitle: pickValue(m, ['message', 'created_at']),
                  trailing: pickValue(m, ['type', 'category']),
                );
              }),
          ],
        ),
      ),
    );
  }
}
