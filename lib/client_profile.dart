import 'package:flutter/material.dart';

import 'client_shared.dart';
class ClientProfilePage extends StatelessWidget {
  final String clientName;
  final String username;
  final String email;
  final VoidCallback onPersonalInformation;
  final VoidCallback onLogout;

  const ClientProfilePage({
    super.key,
    required this.clientName,
    required this.username,
    required this.email,
    required this.onPersonalInformation,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      child: Column(
        children: [
          buildPageHeader('Profile', onBack: null),
          const SizedBox(height: 25),
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: kPaleGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: kDarkGreen,
              size: 55,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            clientName,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '@$username',
            style: const TextStyle(
              color: kTextGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            style: const TextStyle(
              color: kTextGray,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 25),
          _profileOption(
            Icons.person_outline,
            'Personal Information',
            onPersonalInformation,
          ),
          _profileOption(
            Icons.lock_outline,
            'Change Password',
                () {
              showMessage(context, 'Change Password');
            },
          ),
          _profileOption(
            Icons.notifications_none,
            'Notification Settings',
                () {
              showMessage(context, 'Notification Settings');
            },
          ),
          _profileOption(
            Icons.help_outline,
            'Help & Support',
                () {
              showMessage(context, 'Help & Support');
            },
          ),
          const SizedBox(height: 10),
          _profileOption(
            Icons.logout,
            'Logout',
            onLogout,
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
          color: danger ? Colors.red : kDarkGreen,
          size: 21,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: danger ? Colors.red : kTextDark,
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
}
