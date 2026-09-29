import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color darkGreen = const Color(0xFF004437);
  final Color lightGreen = const Color(0xFF63C47A);

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: SafeArea(
        child: _buildDashboard(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              24,
            ),
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.home_outlined,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fix It In Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              color: Color(0xFFB8CBC6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Color(0xFFB8CBC6),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Administrator!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                // SEARCH
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  child: const TextField(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search projects, clients...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CB5AE),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFFD2DEDA),
                        size: 21,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // BODY
          // ======================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              25,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(
                    color: Color(0xFF173F36),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 13),

                // ==================================================
                // ZERO STAT CARDS
                // ==================================================

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _statCard(
                      title: 'Total Clients',
                      value: '0',
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFF438D70),
                    ),
                    _statCard(
                      title: 'Pending Requests',
                      value: '0',
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFFD79A35),
                    ),
                    _statCard(
                      title: 'Active Projects',
                      value: '0',
                      icon: Icons.home_work_outlined,
                      iconColor: const Color(0xFF4C82C1),
                    ),
                    _statCard(
                      title: 'Pending Revisions',
                      value: '0',
                      icon: Icons.edit_note_outlined,
                      iconColor: const Color(0xFF8B68AE),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ==================================================
                // PROJECT REQUESTS
                // ==================================================

                _sectionHeader(
                  title: 'Recent Project Requests',
                ),

                const SizedBox(height: 10),

                _emptyCard(
                  icon: Icons.assignment_outlined,
                  title: 'No project requests yet',
                  message:
                  'Project requests from clients will appear here.',
                ),

                const SizedBox(height: 25),

                // ==================================================
                // ACTIVE PROJECTS
                // ==================================================

                _sectionHeader(
                  title: 'Active Projects',
                ),

                const SizedBox(height: 10),

                _emptyCard(
                  icon: Icons.home_work_outlined,
                  title: 'No active projects yet',
                  message:
                  'Active client projects will appear here.',
                ),

                const SizedBox(height: 25),

                // ==================================================
                // PENDING REVISIONS
                // ==================================================

                _sectionHeader(
                  title: 'Pending Revisions',
                ),

                const SizedBox(height: 10),

                _emptyCard(
                  icon: Icons.edit_note_outlined,
                  title: 'No pending revisions',
                  message:
                  'Client revision requests will appear here.',
                ),

                const SizedBox(height: 25),

                // ==================================================
                // PROJECT STATUS
                // ==================================================

                _sectionHeader(
                  title: 'Project Status',
                ),

                const SizedBox(height: 10),

                _projectStatusCard(),

                const SizedBox(height: 25),

                // ==================================================
                // RECENT ACTIVITY
                // ==================================================

                _sectionHeader(
                  title: 'Recent Activity',
                ),

                const SizedBox(height: 10),

                _emptyCard(
                  icon: Icons.history,
                  title: 'No recent activity',
                  message:
                  'System activities will appear here.',
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE2EAE7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF173F36),
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF71817C),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required String title,
  }) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF173F36),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2EAE7),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF438D70),
              size: 24,
            ),
          ),

          const SizedBox(height: 11),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF40534E),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF899792),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROJECT STATUS
  // ============================================================

  Widget _projectStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2EAE7),
        ),
      ),
      child: Column(
        children: [
          _statusItem(
            'Assessment',
            0,
            0,
          ),
          _statusItem(
            'Planning',
            0,
            0,
          ),
          _statusItem(
            'Revision',
            0,
            0,
          ),
          _statusItem(
            'Finalized',
            0,
            0,
          ),
          _statusItem(
            'Completed',
            0,
            0,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _statusItem(
      String title,
      int count,
      double progress, {
        bool isLast = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 17,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF40534E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '$count Projects',
                style: const TextStyle(
                  color: Color(0xFF899792),
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
              const Color(0xFFE7EFEC),
              valueColor:
              AlwaysStoppedAnimation<Color>(
                lightGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: darkGreen,
        unselectedItemColor: const Color(0xFF9AA7A3),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            activeIcon: Icon(Icons.home_work),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}