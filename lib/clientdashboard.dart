import 'package:flutter/material.dart';


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




  // COLORS




  static const Color darkGreen = Color(0xFF006B50);
  static const Color green = Color(0xFF087F5B);
  static const Color lightGreen = Color(0xFF63C47A);
  static const Color paleGreen = Color(0xFFEAF7F0);
  static const Color background = Color(0xFFF7FBF9);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);


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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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


          _emptyProjectCard(),


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
                  onTap: () {
                    setState(() {
                      selectedIndex = 3;
                    });
                  },
                ),
              ),
            ],
          ),


          const SizedBox(height: 25),


          _sectionTitle(
            'Project Status',
            action: null,
          ),


          const SizedBox(height: 10),


          _emptyStatusCard(),


          const SizedBox(height: 22),


          _sectionTitle(
            'Recent Activity',
            action: null,
          ),


          const SizedBox(height: 10),


          _emptyActivityCard(),
        ],
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




  // EMPTY PROJECT CARD




  Widget _emptyProjectCard() {
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
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Home Project',
                      style: TextStyle(
                        color: textGray,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'No Project Yet',
                      style: TextStyle(
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
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: const Text(
                  'No Project',
                  style: TextStyle(
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
                  'No location assigned',
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
                '0%',
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
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 7,
              backgroundColor: Color(0xFFE3F0EB),
              valueColor:
              AlwaysStoppedAnimation(lightGreen),
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
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




  // EMPTY ACTIVITY




  Widget _emptyActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
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
            Icons.history,
          ),


          const SizedBox(height: 12),


          const Text(
            'No Recent Activity',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),


          const SizedBox(height: 5),


          const Text(
            'Updates about your project will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGray,
              fontSize: 11,
            ),
          ),
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




  // PROJECTS PAGE




  Widget _projectsPage() {
    return SingleChildScrollView(
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
                selected: true,
              ),
              _filterChip(
                'Ongoing',
                selected: false,
              ),
              _filterChip(
                'Completed',
                selected: false,
              ),
            ],
          ),


          const SizedBox(height: 25),


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
                        borderRadius:
                        BorderRadius.circular(14),
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
          ),
        ],
      ),
    );
  }




  // FILES




  Widget _filesPage() {
    return SingleChildScrollView(
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


          Row(
            children: [
              _filterChip(
                'All',
                selected: true,
              ),
              _filterChip(
                'Plans',
                selected: false,
              ),
              _filterChip(
                'Permits',
                selected: false,
              ),
              _filterChip(
                'Others',
                selected: false,
              ),
            ],
          ),


          const SizedBox(height: 25),


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
          ),
        ],
      ),
    );
  }




  // ALERTS


  Widget _alertsPage() {
    return SingleChildScrollView(
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
                selected: true,
              ),
              _filterChip(
                'Project',
                selected: false,
              ),
              _filterChip(
                'System',
                selected: false,
              ),
            ],
          ),


          const SizedBox(height: 25),


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
          ),
        ],
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


              _fakeField(
                'Project Type',
                'Select project type',
              ),


              const SizedBox(height: 12),


              _fakeField(
                'Location',
                'Enter project location',
              ),


              const SizedBox(height: 12),


              _fakeField(
                'Lot Size',
                'Example: 120 sqm',
              ),


              const SizedBox(height: 20),


              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);


                    _showMessage(
                      'Project request form ready.',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Continue',
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




  // REQUEST REVISION




  void _requestRevision() {
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
            crossAxisAlignment:
            CrossAxisAlignment.start,
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


              _fakeField(
                'Select Area',
                'Choose area',
              ),


              const SizedBox(height: 12),


              Container(
                height: 120,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius:
                  BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFD5E8E1),
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Enter your revision details...',
                    style: TextStyle(
                      color: Color(0xFF9BB2AC),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),


              const SizedBox(height: 20),


              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);


                    _showMessage(
                      'Revision request form ready.',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Submit Request',
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
                      borderRadius:
                      BorderRadius.circular(14),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
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


        if (onBack == null)
          const SizedBox(width: 2),


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
      }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: selected
            ? darkGreen
            : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: selected
              ? darkGreen
              : const Color(0xFFDDECE7),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected
              ? Colors.white
              : textGray,
          fontSize: 11,
          fontWeight:
          selected
              ? FontWeight.bold
              : FontWeight.w500,
        ),
      ),
    );
  }


  Widget _fakeField(
      String label,
      String hint,
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
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
                  hint,
                  style: const TextStyle(
                    color: Color(0xFF9BB2AC),
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
          borderRadius:
          BorderRadius.circular(20),
        ),
      ),
    );
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}




// DESIGNS SCREEN


class DesignsScreen extends StatelessWidget {
  const DesignsScreen({super.key});


  static const Color darkGreen = Color(0xFF006B50);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);
  static const Color paleGreen = Color(0xFFEAF7F0);
  static const Color background = Color(0xFFF7FBF9);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,


      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text(
          'Designs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),


        child: Column(
          children: [
            // =========================================
            // FILTER CHIPS
            // =========================================


            Row(
              children: [
                _chip('All', true),
                _chip('Exterior', false),
                _chip('Interior', false),
              ],
            ),


            const SizedBox(height: 20),


            // =========================================
            // EXTERIOR DESIGN 1
            // =========================================


            _designCard(
              image: 'assets/exterior_1.png',
              title: 'Modern House Exterior',
              category: 'Exterior Design',
            ),


            const SizedBox(height: 16),


            // =========================================
            // EXTERIOR DESIGN 2
            // =========================================


            _designCard(
              image: 'assets/exterior_2.png',
              title: 'Contemporary House Exterior',
              category: 'Exterior Design',
            ),


            const SizedBox(height: 20),


            // =========================================
            // FLOOR PLAN
            // =========================================


            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FloorPlanScreen(),
                  ),
                );
              },


              borderRadius: BorderRadius.circular(18),


              child: Container(
                padding: const EdgeInsets.all(16),


                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),


                  border: Border.all(
                    color: const Color(0xFFDDECE7),
                  ),
                ),


                child: const Row(
                  children: [
                    Icon(
                      Icons.architecture,
                      color: darkGreen,
                    ),


                    SizedBox(width: 12),


                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,


                        children: [
                          Text(
                            'Floor Plan',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),


                          SizedBox(height: 3),


                          Text(
                            'View floor plan preview',
                            style: TextStyle(
                              color: textGray,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),


                    Icon(
                      Icons.chevron_right,
                      color: textGray,
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  // =========================================
  // FILTER CHIP
  // =========================================


  Widget _chip(
      String text,
      bool selected,
      ) {
    return Container(
      margin: const EdgeInsets.only(
        right: 8,
      ),


      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 9,
      ),


      decoration: BoxDecoration(
        color: selected
            ? darkGreen
            : Colors.white,


        borderRadius: BorderRadius.circular(30),


        border: Border.all(
          color: selected
              ? darkGreen
              : const Color(0xFFDDECE7),
        ),
      ),


      child: Text(
        text,


        style: TextStyle(
          color: selected
              ? Colors.white
              : textGray,


          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  // =========================================
  // DESIGN CARD
  // =========================================


  Widget _designCard({
    required String image,
    required String title,
    required String category,
  }) {
    return Container(
      width: double.infinity,


      decoration: BoxDecoration(
        color: Colors.white,


        borderRadius: BorderRadius.circular(20),


        border: Border.all(
          color: const Color(0xFFDDECE7),
        ),


        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),


      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,


        children: [
          // =====================================
          // DESIGN IMAGE
          // =====================================


          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),


            child: Image.asset(
              image,


              width: double.infinity,
              height: 210,


              fit: BoxFit.cover,


              errorBuilder: (
                  context,
                  error,
                  stackTrace,
                  ) {
                debugPrint(
                  'IMAGE ERROR: $image',
                );


                debugPrint(
                  'ERROR DETAILS: $error',
                );


                return Container(
                  width: double.infinity,
                  height: 210,


                  color: paleGreen,


                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,


                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: darkGreen,
                        size: 45,
                      ),


                      const SizedBox(height: 8),


                      const Text(
                        'Image not found',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),


                      const SizedBox(height: 4),


                      Text(
                        image,
                        style: const TextStyle(
                          color: textGray,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),


          // =====================================
          // DESIGN DETAILS
          // =====================================


          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16,
            ),


            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,


                    children: [
                      Text(
                        title,


                        style: const TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),


                      const SizedBox(height: 5),


                      Text(
                        category,


                        style: const TextStyle(
                          color: textGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),


                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),


                  decoration: BoxDecoration(
                    color: paleGreen,


                    borderRadius:
                    BorderRadius.circular(20),
                  ),


                  child: const Text(
                    'View',


                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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




// =========================================
// FLOOR PLAN SCREEN
// =========================================


class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});


  @override
  State<FloorPlanScreen> createState() =>
      _FloorPlanScreenState();
}


class _FloorPlanScreenState
    extends State<FloorPlanScreen> {


  bool firstFloor = true;


  static const Color darkGreen = Color(0xFF006B50);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);
  static const Color background = Color(0xFFF7FBF9);
  static const Color paleGreen = Color(0xFFEAF7F0);


  @override
  Widget build(BuildContext context) {
    final String imagePath = firstFloor
        ? 'assets/1st_Floor.png'
        : 'assets/2nd_Floor.png';


    return Scaffold(
      backgroundColor: background,


      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,


        title: const Text(
          'Floor Plan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          5,
          18,
          30,
        ),


        child: Column(
          children: [
            // =====================================
            // FLOOR BUTTONS
            // =====================================


            Row(
              children: [
                Expanded(
                  child: _floorButton(
                    '1st Floor',
                    firstFloor,
                        () {
                      setState(() {
                        firstFloor = true;
                      });
                    },
                  ),
                ),


                const SizedBox(width: 10),


                Expanded(
                  child: _floorButton(
                    '2nd Floor',
                    !firstFloor,
                        () {
                      setState(() {
                        firstFloor = false;
                      });
                    },
                  ),
                ),
              ],
            ),


            const SizedBox(height: 18),


            // =====================================
            // FLOOR PLAN IMAGE
            // =====================================


            Container(
              width: double.infinity,


              padding: const EdgeInsets.all(12),


              decoration: BoxDecoration(
                color: Colors.white,


                borderRadius:
                BorderRadius.circular(20),


                border: Border.all(
                  color: const Color(0xFFDDECE7),
                ),


                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withOpacity(0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),


              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(14),


                child: Image.asset(
                  imagePath,


                  width: double.infinity,


                  fit: BoxFit.contain,


                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return Container(
                      height: 350,


                      color: paleGreen,


                      child: Center(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,


                          children: [
                            const Icon(
                              Icons.broken_image_outlined,
                              color: darkGreen,
                              size: 50,
                            ),


                            const SizedBox(height: 10),


                            const Text(
                              'Floor plan image not found',
                              style: TextStyle(
                                color: textDark,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),


                            const SizedBox(height: 5),


                            Text(
                              imagePath,
                              textAlign:
                              TextAlign.center,


                              style: const TextStyle(
                                color: textGray,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),


            const SizedBox(height: 22),


            // =====================================
            // FEATURES TITLE
            // =====================================


            Align(
              alignment: Alignment.centerLeft,


              child: Text(
                firstFloor
                    ? '1st Floor Features'
                    : '2nd Floor Features',


                style: const TextStyle(
                  color: textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),


            const SizedBox(height: 12),


            // =====================================
            // FEATURES
            // =====================================


            _feature(
              '1',
              firstFloor
                  ? 'Living Area'
                  : 'Master Bedroom',
            ),


            _feature(
              '2',
              firstFloor
                  ? 'Dining Area'
                  : 'Walk-in Closet',
            ),


            _feature(
              '3',
              firstFloor
                  ? 'Kitchen'
                  : 'Master Bathroom',
            ),


            _feature(
              '4',
              firstFloor
                  ? 'Bedroom 1'
                  : 'Bedroom 2',
            ),


            _feature(
              '5',
              firstFloor
                  ? 'Bathroom'
                  : 'Bedroom 3',
            ),


            _feature(
              '6',
              firstFloor
                  ? 'Laundry Area'
                  : 'Common Bathroom',
            ),


            _feature(
              '7',
              firstFloor
                  ? 'Carport'
                  : 'Balcony',
            ),
          ],
        ),
      ),
    );
  }


  // =========================================
  // FLOOR BUTTON
  // =========================================


  Widget _floorButton(
      String title,
      bool selected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,


      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 180),


        height: 43,


        decoration: BoxDecoration(
          color: selected
              ? darkGreen
              : Colors.white,


          borderRadius:
          BorderRadius.circular(25),


          border: Border.all(
            color: selected
                ? darkGreen
                : const Color(0xFFDDECE7),
          ),
        ),


        child: Center(
          child: Text(
            title,


            style: TextStyle(
              color: selected
                  ? Colors.white
                  : textGray,


              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }


  // =========================================
  // FEATURE ITEM
  // =========================================


  Widget _feature(
      String number,
      String title,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),


      child: Container(
        width: double.infinity,


        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),


        decoration: BoxDecoration(
          color: Colors.white,


          borderRadius:
          BorderRadius.circular(14),


          border: Border.all(
            color: const Color(0xFFDDECE7),
          ),
        ),


        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,


              decoration: const BoxDecoration(
                color: darkGreen,
                shape: BoxShape.circle,
              ),


              child: Center(
                child: Text(
                  number,


                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),


            const SizedBox(width: 11),


            Expanded(
              child: Text(
                title,


                style: const TextStyle(
                  color: textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),


            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF9BC5B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

