import 'package:flutter/material.dart';
import 'chatbot_topics.dart';

// ============================================================
// CIVIL ENGINEERING ASSISTANT
// ============================================================

class CivilEngineerChatbotScreen extends StatefulWidget {
  const CivilEngineerChatbotScreen({super.key});

  @override
  State<CivilEngineerChatbotScreen> createState() =>
      _CivilEngineerChatbotScreenState();
}

class _CivilEngineerChatbotScreenState
    extends State<CivilEngineerChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color darkGreen = Color(0xFF006B50);
  static const Color green = Color(0xFF087F5B);
  static const Color lightGreen = Color(0xFF63C47A);
  static const Color paleGreen = Color(0xFFEAF7F0);
  static const Color background = Color(0xFFF7FBF9);
  static const Color textDark = Color(0xFF173B33);
  static const Color textGray = Color(0xFF75908A);

  final List<Map<String, dynamic>> _messages = [
    {
      'from': 'bot',
      'text':
      'Hello! Im the Fix It In Plan Civil Engineering Assistant.\n\n'
          'I can help you understand general construction, materials, measurements, project requirements, and other civil engineering topics.\n\n'
          'What would you like to know?',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ask(String question) {
    _controller.text = question;
    _sendMessage();
  }

  void _sendMessage() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({'from': 'user', 'text': question});
      _messages.add({
        'from': 'bot',
        'text': chatbotAnswerFor(question),
      });
    });

    _controller.clear();
    _scrollToBottom();
  }

  
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: textDark,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: paleGreen,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.engineering_outlined,
                color: darkGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Civil Engineer Assistant',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Fix It In Plan',
                  style: TextStyle(
                    color: textGray,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              children: [
                _infoCard(),
                const SizedBox(height: 14),
                ..._messages.map(_messageBubble),
              ],
            ),
          ),
          _quickQuestions(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paleGreen,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD5E8E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: darkGreen, size: 21),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'For general engineering information only. Final structural designs, calculations, specifications, and approvals should come from the responsible licensed professional.',
              style: TextStyle(
                color: textDark,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final isUser = message['from'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? lightGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFFDDECE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'You' : 'Civil Engineering Assistant',
              style: TextStyle(
                color: isUser ? Colors.white : darkGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message['text'].toString(),
              style: TextStyle(
                color: isUser ? Colors.white : textDark,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickQuestions() {
    const questions = [
      'What is a foundation?',
      'What is rebar used for?',
      'What do I need for a building permit?',
      'How is construction cost estimated?',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: questions
              .map(
                (q) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                onPressed: () => _ask(q),
                backgroundColor: paleGreen,
                side: const BorderSide(color: Color(0xFFD5E8E1)),
                label: Text(
                  q,
                  style: const TextStyle(
                    color: darkGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE0ECE8)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 46,
                  maxHeight: 105,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD5E8E1)),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(color: textDark, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Ask a civil engineering question...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9BB2AC),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              height: 46,
              child: ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
