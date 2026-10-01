

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Palitan kung magbago ang IP ng PC
const String baseUrl = 'http://192.168.100.12/Fix_it_in_Plans_Api';

Future<List<dynamic>> fetchList(String file, String key) async {
try {
final res = await http
    .get(Uri.parse('$baseUrl/$file'))
    .timeout(const Duration(seconds: 10));
final data = jsonDecode(res.body);
if (data['success'] == true && data[key] is List) return data[key];
} catch (e) {
debugPrint('$file error: $e');
}
return [];
}

String pick(Map m, List<String> keys, [String d = '']) {
for (final k in keys) {
final v = m[k];
if (v != null && v.toString().isNotEmpty) return v.toString();
}
return d;
}

class DashboardScreen extends StatefulWidget {
const DashboardScreen({super.key});

@override
State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
final Color darkGreen = const Color(0xFF004437);
final Color lightGreen = const Color(0xFF63C47A);

int selectedIndex = 0;
bool loading = true;
String query = '';

List<dynamic> requests = [];
List<dynamic> clients = [];
List<dynamic> projects = [];
List<dynamic> documents = [];
List<dynamic> revisions = [];
List<dynamic> notifications = [];

@override
void initState() {
super.initState();
loadAll();
}

Future<void> loadAll() async {
setState(() => loading = true);
final r = await Future.wait([
fetchList('admin_project_requests.php', 'requests'),
fetchList('admin_clients.php', 'clients'),
fetchList('admin_projects.php', 'projects'),
fetchList('admin_documents.php', 'documents'),
fetchList('admin_revisions.php', 'revisions'),
fetchList('admin_notifications.php', 'notifications'),
]);
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

void _snack(String msg) {
ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> _updateStatus(Map r, String status) async {
final id = r['id'];
try {
final res = await http.post(
Uri.parse('$baseUrl/update_project_status.php'),
headers: {'Content-Type': 'application/json'},
body: jsonEncode({'id': id, 'request_id': id, 'status': status}),
);
final data = jsonDecode(res.body);
_snack(data['message']?.toString() ??
(data['success'] == true ? 'Updated' : 'Failed'));
loadAll();
} catch (e) {
_snack('Error: $e');
}
}

List<dynamic> _filter(List<dynamic> items) {
if (query.trim().isEmpty) return items;
final q = query.toLowerCase();
return items.where((i) {
if (i is! Map) return false;
return i.values.any((v) => v.toString().toLowerCase().contains(q));
}).toList();
}

// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF4F7F6),
body: SafeArea(
child: IndexedStack(
index: selectedIndex,
children: [
_homePage(),
_listPage('Clients', clients, ['name', 'full_name', 'username'],
['email', 'phone'], Icons.person_outline),
_listPage('Projects', projects,
['project_name', 'title', 'project_type'],
['location', 'status'], Icons.home_work_outlined),
_listPage('Files', documents,
['title', 'file_name', 'name'],
['created_at', 'type'], Icons.description_outlined),
_morePage(),
],
),
),
bottomNavigationBar: _bottomNav(),
);
}

// ============================================================
// HOME
// ============================================================

Widget _homePage() {
final shown = _filter(requests);
return RefreshIndicator(
onRefresh: loadAll,
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
child: Column(
children: [
_header(),
Padding(
padding: const EdgeInsets.fromLTRB(18, 20, 18, 25),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_title('Overview'),
const SizedBox(height: 13),
GridView.count(
crossAxisCount: 2,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
childAspectRatio: 1.25,
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
children: [
_statCard('Total Clients', clients.length,
Icons.people_outline, const Color(0xFF438D70),
() => setState(() => selectedIndex = 1)),
_statCard('Pending Requests', requests.length,
Icons.assignment_outlined, const Color(0xFFD79A35),
() => _scrollHint('pending')),
_statCard('Active Projects', projects.length,
Icons.home_work_outlined, const Color(0xFF4C82C1),
() => setState(() => selectedIndex = 2)),
_statCard('Pending Revisions', revisions.length,
Icons.edit_note_outlined, const Color(0xFF8B68AE),
() => _openList('Revisions', revisions,
['title', 'description', 'project_name'],
['status', 'created_at'],
Icons.edit_note_outlined)),
],
),
const SizedBox(height: 25),
_title('Recent Project Requests'),
const SizedBox(height: 10),
if (loading)
const Center(child: CircularProgressIndicator())
else if (shown.isEmpty)
_emptyCard('No project requests yet',
'Project requests from clients will appear here.')
else
...shown.map((r) => _requestCard(r as Map)),
],
),
),
],
),
),
);
}

void _scrollHint(String m) => _snack(m);

Widget _header() {
return Container(
width: double.infinity,
padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
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
color: Colors.white.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(15),
),
child: const Icon(Icons.home_outlined,
color: Colors.white, size: 29),
),
const SizedBox(width: 12),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Fix It In Plan',
style: TextStyle(
color: Colors.white,
fontSize: 19,
fontWeight: FontWeight.bold)),
Text('Admin Dashboard',
style: TextStyle(
color: Color(0xFFB8CBC6), fontSize: 12)),
],
),
),
InkWell(
borderRadius: BorderRadius.circular(13),
onTap: () => _openList('Notifications', notifications,
['title', 'message'], ['created_at'],
Icons.notifications_none),
child: Container(
width: 43,
height: 43,
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(13),
),
child: Badge(
isLabelVisible: notifications.isNotEmpty,
label: Text('${notifications.length}'),
child: const Icon(Icons.notifications_none,
color: Colors.white, size: 23),
),
),
),
],
),
const SizedBox(height: 25),
const Text('Welcome back,',
style: TextStyle(color: Color(0xFFB8CBC6), fontSize: 14)),
const Text('Administrator!',
style: TextStyle(
color: Colors.white,
fontSize: 27,
fontWeight: FontWeight.bold)),
const SizedBox(height: 18),
Container(
height: 48,
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(14),
),
child: TextField(
onChanged: (v) => setState(() => query = v),
style: const TextStyle(color: Colors.white, fontSize: 14),
decoration: const InputDecoration(
hintText: 'Search projects, clients...',
hintStyle:
TextStyle(color: Color(0xFF9CB5AE), fontSize: 13),
prefixIcon: Icon(Icons.search,
color: Color(0xFFD2DEDA), size: 21),
border: InputBorder.none,
contentPadding: EdgeInsets.symmetric(vertical: 14),
),
),
),
],
),
);
}

Widget _title(String t) => Text(t,
style: const TextStyle(
color: Color(0xFF173F36),
fontSize: 19,
fontWeight: FontWeight.bold));

Widget _statCard(String title, int value, IconData icon, Color color,
VoidCallback onTap) {
return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(17),
child: InkWell(
borderRadius: BorderRadius.circular(17),
onTap: onTap,
child: Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(17),
border: Border.all(color: const Color(0xFFE2EAE7)),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: color.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(11),
),
child: Icon(icon, color: color, size: 20),
),
const Spacer(),
Text('$value',
style: const TextStyle(
color: Color(0xFF173F36),
fontSize: 22,
fontWeight: FontWeight.bold)),
Text(title,
style: const TextStyle(
color: Color(0xFF71817C), fontSize: 11)),
],
),
),
),
);
}

Widget _emptyCard(String title, String message) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: const Color(0xFFE2EAE7)),
),
child: Column(
children: [
const Icon(Icons.inbox_outlined, color: Color(0xFF438D70), size: 30),
const SizedBox(height: 10),
Text(title,
textAlign: TextAlign.center,
style: const TextStyle(
color: Color(0xFF40534E),
fontSize: 13,
fontWeight: FontWeight.bold)),
const SizedBox(height: 5),
Text(message,
textAlign: TextAlign.center,
style: const TextStyle(color: Color(0xFF899792), fontSize: 11)),
],
),
);
}

// ============================================================
// REQUEST CARD + DETAIL
// ============================================================

Widget _requestCard(Map r) {
return Card(
color: Colors.white,
margin: const EdgeInsets.only(bottom: 10),
child: ListTile(
leading: const Icon(Icons.assignment_outlined),
title: Text(pick(r, ['project_type'], 'Project')),
subtitle: Text(
'${pick(r, ['client_name', 'name', 'username'])}  ${pick(r, ['location'])}'
    .trim()),
trailing: Text(pick(r, ['status'], 'pending'),
style: const TextStyle(fontSize: 11)),
onTap: () => _showRequest(r),
),
);
}

void _showRequest(Map r) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => Padding(
padding: const EdgeInsets.all(20),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(pick(r, ['project_type'], 'Project Request'),
style: const TextStyle(
fontSize: 20, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
_row('Client', pick(r, ['client_name', 'name', 'client_id'])),
_row('Location', pick(r, ['location'])),
_row('Lot size', pick(r, ['lot_size'])),
_row('Service', pick(r, ['preferred_service'])),
_row('Timeline', pick(r, ['target_timeline'])),
_row('Description', pick(r, ['description'])),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () {
Navigator.pop(context);
_updateStatus(r, 'rejected');
},
child: const Text('Reject'),
),
),
const SizedBox(width: 12),
Expanded(
child: ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: darkGreen,
foregroundColor: Colors.white),
onPressed: () {
Navigator.pop(context);
_updateStatus(r, 'approved');
},
child: const Text('Approve'),
),
),
],
),
],
),
),
);
}

Widget _row(String k, String v) {
if (v.isEmpty) return const SizedBox.shrink();
return Padding(
padding: const EdgeInsets.only(bottom: 6),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
SizedBox(
width: 90,
child: Text(k, style: const TextStyle(color: Colors.grey))),
Expanded(child: Text(v)),
],
),
);
}

// ============================================================
// GENERIC LIST PAGES
// ============================================================

Widget _listBody(List<dynamic> items, List<String> titleKeys,
List<String> subKeys, IconData icon) {
final shown = _filter(items);
return RefreshIndicator(
onRefresh: loadAll,
child: shown.isEmpty
? ListView(children: [
const SizedBox(height: 80),
Center(
child: Text(loading ? 'Loading...' : 'No data.')),
])
    : ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: shown.length,
itemBuilder: (_, i) {
final m = shown[i] as Map;
final sub = subKeys
    .map((k) => pick(m, [k]))
    .where((s) => s.isNotEmpty)
    .join(' • ');
return Card(
color: Colors.white,
child: ListTile(
leading: Icon(icon),
title: Text(pick(m, titleKeys, 'Item ${i + 1}')),
subtitle: Text(sub),
onTap: () => _showDetails(m),
),
);
},
),
);
}

void _showDetails(Map m) {
showModalBottomSheet(
context: context,
builder: (_) => ListView(
padding: const EdgeInsets.all(20),
shrinkWrap: true,
children: m.entries
    .map((e) => _row(e.key.toString(), '${e.value ?? ''}'))
    .toList(),
),
);
}

Widget _listPage(String title, List<dynamic> items, List<String> tk,
List<String> sk, IconData icon) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
child: Text('$title (${items.length})',
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: Color(0xFF173F36))),
),
Expanded(child: _listBody(items, tk, sk, icon)),
],
);
}

void _openList(String title, List<dynamic> items, List<String> tk,
List<String> sk, IconData icon) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => Scaffold(
appBar: AppBar(
title: Text(title),
backgroundColor: darkGreen,
foregroundColor: Colors.white),
body: _listBody(items, tk, sk, icon),
),
),
);
}

// ============================================================
// MORE
// ============================================================

Widget _morePage() {
return ListView(
padding: const EdgeInsets.all(16),
children: [
_title('More'),
const SizedBox(height: 12),
ListTile(
leading: const Icon(Icons.edit_note_outlined),
title: Text('Revisions (${revisions.length})'),
trailing: const Icon(Icons.chevron_right),
onTap: () => _openList('Revisions', revisions,
['title', 'description'], ['status', 'created_at'],
Icons.edit_note_outlined),
),
ListTile(
leading: const Icon(Icons.notifications_none),
title: Text('Notifications (${notifications.length})'),
trailing: const Icon(Icons.chevron_right),
onTap: () => _openList('Notifications', notifications,
['title', 'message'], ['created_at'],
Icons.notifications_none),
),
ListTile(
leading: const Icon(Icons.refresh),
title: const Text('Refresh data'),
onTap: loadAll,
),
ListTile(
leading: const Icon(Icons.logout, color: Colors.red),
title: const Text('Logout'),
onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
),
],
);
}

// ============================================================
// BOTTOM NAV
// ============================================================

Widget _bottomNav() {
return BottomNavigationBar(
currentIndex: selectedIndex,
onTap: (i) => setState(() => selectedIndex = i),
type: BottomNavigationBarType.fixed,
backgroundColor: Colors.white,
selectedItemColor: darkGreen,
unselectedItemColor: const Color(0xFF9AA7A3),
selectedFontSize: 10,
unselectedFontSize: 10,
items: const [
BottomNavigationBarItem(
icon: Icon(Icons.dashboard_outlined),
activeIcon: Icon(Icons.dashboard),
label: 'Home'),
BottomNavigationBarItem(
icon: Icon(Icons.people_outline),
activeIcon: Icon(Icons.people),
label: 'Clients'),
BottomNavigationBarItem(
icon: Icon(Icons.home_work_outlined),
activeIcon: Icon(Icons.home_work),
label: 'Projects'),
BottomNavigationBarItem(
icon: Icon(Icons.folder_outlined),
activeIcon: Icon(Icons.folder),
label: 'Files'),
BottomNavigationBarItem(
icon: Icon(Icons.more_horiz), label: 'More'),
],
);
}
}

