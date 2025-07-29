import 'package:flutter/material.dart';
import '../models/note.dart';
import '../controllers/email_controller.dart';
import 'send_success_dialog.dart';

class NoteInputScreen extends StatefulWidget {
  const NoteInputScreen({super.key});
  @override
  State<NoteInputScreen> createState() => _NoteInputScreenState();
}

class _NoteInputScreenState extends State<NoteInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final EmailController _emailController = EmailController();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _handleSend() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    final success = await _emailController.sendNote(Note(content: content));
    setState(() => _sending = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SendSuccessDialog(
        success: success,
        onDone: () {
          _controller.clear();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80, top: 14, left: 10),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                autofocus: true,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                cursorColor: Colors.blueAccent,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Type your thoughts...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            if (_sending)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(18),
        child: ElevatedButton(
          onPressed: _sending ? null : _handleSend,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: _sending ? Colors.grey : Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SEND  ',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              Icon(Icons.send_outlined, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
