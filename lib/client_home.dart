import 'package:flutter/material.dart';
import 'client_designs.dart';
import 'client_shared.dart';

const Color _darkGreen = Color(0xFF006B50);
const Color _green = Color(0xFF087F5B);
const Color _lightGreen = Color(0xFF63C47A);
const Color _paleGreen = Color(0xFFEAF7F0);
const Color _background = Color(0xFFF7FBF9);
const Color _textDark = Color(0xFF173B33);
const Color _textGray = Color(0xFF75908A);
const Color _border = Color(0xFFDCEBE5);

class ClientHomePage extends StatelessWidget {
  final String firstName;
  final Map? project;
  final List<dynamic> notifications;
  final bool loading;
  final bool projectError;
  final Future<void> Function({bool showLoader}) onRefresh;
  final void Function(int index) onNavigateTab;
  final VoidCallback onRequestRevision;
  final VoidCallback onRequestProject;
  final VoidCallback onRetry;
  final ValueChanged<Map> onProjectTap;

  const ClientHomePage({
    super.key,
    required this.firstName,
    required this.project,
    required this.notifications,
    required this.loading,
    required this.projectError,
    required this.onRefresh,
    required this.onNavigateTab,
    required this.onRequestRevision,
    required this.onRequestProject,
    required this.onRetry,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: RefreshIndicator(
        color: _darkGreen,
        backgroundColor: Colors.white,
        onRefresh: () => onRefresh(showLoader: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 22),
              Text(
                'Hello, ${firstName.trim().isEmpty ? 'Client' : firstName.trim()} 👋',
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Here's your project overview.",
                style: TextStyle(
                  color: _textGray,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('My Home Project'),
              const SizedBox(height: 10),
              if (projectError)
                _errorCard()
              else if (loading)
                _loadingProjectCard()
              else
                _projectCard(),
              const SizedBox(height: 24),
              _quickActions(context),
              const SizedBox(height: 26),
              _sectionTitle('Project Status'),
              const SizedBox(height: 10),
              if (projectError)
                _simpleCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Unable to load project status.',
                )
              else if (loading)
                _loadingStatusCard()
              else if (project == null)
                  _emptyStatusCard()
                else
                  _statusCard(project!),
              const SizedBox(height: 26),
              _featuredDesigns(context),
              const SizedBox(height: 26),
              _recentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: _paleGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: const Icon(
            Icons.home_work_rounded,
            color: _darkGreen,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fix It In Plan',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Client Portal',
                style: TextStyle(
                  color: _textGray,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _headerButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => onNavigateTab(3),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => onNavigateTab(4),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _paleGreen,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _darkGreen,
              size: 21,
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: _darkGreen, size: 21),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _textDark,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.1,
      ),
    );
  }

  BoxDecoration _cardDecoration({bool shadow = true}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: shadow
          ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ]
          : null,
    );
  }

  Widget _loadingProjectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          SizedBox(height: 12),
          CircularProgressIndicator(color: _darkGreen),
          SizedBox(height: 14),
          Text(
            'Loading project information...',
            style: TextStyle(
              color: _textGray,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: _paleGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              color: _darkGreen,
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Unable to load project information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Please check the connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGray, fontSize: 11),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: _darkGreen,
              side: const BorderSide(color: _darkGreen),
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

  Widget _projectCard() {
    if (project == null) {
      return _noProjectCard();
    }

    final p = project!;
    final name = pickValue(
      p,
      ['project_name', 'title', 'name'],
      'My Project',
    );
    final type = pickValue(p, ['project_type', 'type'], '-');
    final location = pickValue(
      p,
      ['location', 'address'],
      'No location assigned',
    );
    final status = pickValue(
      p,
      ['status', 'project_status'],
      'Request Submitted',
    );
    final progress = progressOf(p);

    return InkWell(
      onTap: () => onProjectTap(p),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MY HOME PROJECT',
                        style: TextStyle(
                          color: _green,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        type,
                        style: const TextStyle(
                          color: _textGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _statusPill(status),
              ],
            ),
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _paleGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: _darkGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            _progressHeader(progress),
            const SizedBox(height: 8),
            _progressBar(progress),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View project details',
                  style: TextStyle(
                    color: _darkGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _darkGreen,
                  size: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noProjectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 19),
            decoration: BoxDecoration(
              color: _paleGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: _green,
              size: 45,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'My Home Project',
            style: TextStyle(
              color: _textGray,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No Project Yet',
            style: TextStyle(
              color: _textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No location assigned',
            style: TextStyle(
              color: _textGray,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          _progressHeader(0),
          const SizedBox(height: 8),
          _progressBar(0),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRequestProject,
              icon: const Icon(Icons.add_home_outlined, size: 18),
              label: const Text('Request a Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _paleGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _darkGreen,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _progressHeader(double progress) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Project Progress',
            style: TextStyle(
              color: _textGray,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${(progress * 100).round()}%',
          style: const TextStyle(
            color: _darkGreen,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _progressBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: const Color(0xFFE3F0EB),
        valueColor: const AlwaysStoppedAnimation(_lightGreen),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quick Actions'),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 11),
            Expanded(
              child: _quickAction(
                icon: Icons.description_outlined,
                title: 'Documents',
                subtitle: 'Files & Permits',
                onTap: () => onNavigateTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _quickAction(
                icon: Icons.edit_note_rounded,
                title: 'Request Revision',
                subtitle: 'Changes & Updates',
                onTap: onRequestRevision,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _quickAction(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Messages',
                subtitle: 'Contact Team',
                onTap: () => onNavigateTab(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

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
        decoration: _cardDecoration(shadow: false),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: _paleGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _darkGreen, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textGray,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: _textGray,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: _paleGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timeline_outlined,
              color: _darkGreen,
              size: 25,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Project Status Yet',
            style: TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your project status will appear here\n'
                'once a project is assigned.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textGray,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: _cardDecoration(),
      child: const Center(
        child: CircularProgressIndicator(color: _darkGreen),
      ),
    );
  }

  Widget _simpleCard({
    required IconData icon,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: _darkGreen, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(Map p) {
    final status = pickValue(
      p,
      ['status', 'project_status'],
      'Request Submitted',
    );
    final progress = progressOf(p);
    const statuses = [
      'Request Submitted',
      'Assessment',
      'Planning',
      'Revision',
      'Finalized',
      'Completed',
    ];

    int current = statuses.indexWhere(
          (item) => status.toLowerCase().contains(item.toLowerCase()),
    );
    if (current < 0 && status.toLowerCase().contains('request')) {
      current = 0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Project Progress',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _darkGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _progressBar(progress),
          const SizedBox(height: 17),
          ...List.generate(statuses.length, (i) {
            final isCurrent = i == current;
            final isDone = current >= 0 && i < current;
            final isCompleted = current >= 0 && i <= current;

            return Padding(
              padding: EdgeInsets.only(
                bottom: i == statuses.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? _darkGreen
                          : isCompleted
                          ? _paleGreen
                          : const Color(0xFFF1F5F3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? _darkGreen
                            : isCompleted
                            ? const Color(0xFFBFE2D0)
                            : const Color(0xFFE1EBE7),
                      ),
                    ),
                    child: Icon(
                      isDone || isCurrent
                          ? Icons.check_rounded
                          : Icons.circle_outlined,
                      color: isCurrent
                          ? Colors.white
                          : isCompleted
                          ? _darkGreen
                          : _textGray,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statuses[i],
                      style: TextStyle(
                        color: isCurrent || isDone ? _textDark : _textGray,
                        fontSize: 12,
                        fontWeight: isCurrent || isDone
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _paleGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: _darkGreen,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _featuredDesigns(BuildContext context) {
    const designs = [
      (
      image: 'assets/exterior_1.png',
      title: 'Modern House',
      category: 'Exterior',
      ),
      (
      image: 'assets/exterior_2.png',
      title: 'Contemporary House',
      category: 'Exterior',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Featured Designs'),
        const SizedBox(height: 4),
        const Text(
          'Explore our latest home design ideas',
          style: TextStyle(
            color: _textGray,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 235,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: designs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final design = designs[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DesignsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 205,
                  padding: const EdgeInsets.all(10),
                  decoration: _cardDecoration(shadow: false),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          design.image,
                          width: double.infinity,
                          height: 125,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: double.infinity,
                            height: 125,
                            color: _paleGreen,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: _darkGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        design.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        design.category,
                        style: const TextStyle(
                          color: _textGray,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DesignsScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: _darkGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _recentActivity() {
    final shown = notifications.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Recent Activity'),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: _cardDecoration(),
            child: const Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: _green,
                  size: 28,
                ),
                SizedBox(height: 9),
                Text(
                  'No Recent Activity',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            decoration: _cardDecoration(),
            child: Column(
              children: List.generate(shown.length, (index) {
                final item = Map<String, dynamic>.from(
                  shown[index] as Map,
                );
                final title = _pickActivity(
                  item,
                  ['title', 'message'],
                  'Project Update',
                );
                final subtitle = _pickActivity(
                  item,
                  ['message', 'description', 'created_at', 'date'],
                  '',
                );
                final type = _pickActivity(
                  item,
                  ['type', 'category'],
                  'Update',
                );

                return Padding(
                  padding: EdgeInsets.only(
                    top: 10,
                    bottom: index == shown.length - 1 ? 10 : 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _paleGreen,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: _darkGreen,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textGray,
                                  fontSize: 10,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  String _pickActivity(
      Map<String, dynamic> item,
      List<String> keys,
      String fallback,
      ) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }
}
