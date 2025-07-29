// import 'package:flutter/material.dart';
// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';

// void main() {
//   runApp(const QuickNoteApp());
// }

// class QuickNoteApp extends StatelessWidget {
//   const QuickNoteApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Quick Note',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(fontFamily: 'sans-serif'),
//       home: const NoteInputScreen(),
//     );
//   }
// }

// class NoteInputScreen extends StatefulWidget {
//   const NoteInputScreen({super.key});

//   @override
//   State<NoteInputScreen> createState() => _NoteInputScreenState();
// }

// class _NoteInputScreenState extends State<NoteInputScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(_focusNode);
//     });
//   }

//   void _sendEmail() async {
//     const String username = 'ahmadtech116p@gmail.com'; // your email
//     const String appPassword = 'lvdbufychdowdupg'; // App password for Gmail

//     final message = Message()
//       ..from = Address(username, 'Quick Notes')
//       ..recipients.add(username) // sending to yourself
//       ..subject = 'Quick Note - ${DateTime.now()}'
//       ..text = _controller.text.trim();

//     final smtpServer = gmail(username, appPassword);

//     try {
//       await send(message, smtpServer);
//       _controller.clear();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Email sent successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       debugPrint('Send failed: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to send email.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Padding(
//         padding: const EdgeInsets.only(bottom: 60),
//         child: TextField(
//           controller: _controller,
//           focusNode: _focusNode,
//           maxLines: null,
//           autofocus: true,
//           style: const TextStyle(
//             fontSize: 18,
//             color: Colors.white,
//             fontFamily: 'sans-serif',
//           ),
//           cursorColor: Colors.blueAccent,
//           decoration: const InputDecoration(
//             contentPadding: EdgeInsets.all(16),
//             border: InputBorder.none,
//             hintText: 'Type your thoughts...',
//             hintStyle: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ),
//       bottomSheet: Container(
//         color: Colors.black,
//         padding: const EdgeInsets.all(12),
//         child: ElevatedButton(
//           onPressed: _sendEmail,
//           style: ElevatedButton.styleFrom(
//             minimumSize: const Size.fromHeight(48),
//             backgroundColor: Colors.blue,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text('SEND', style: TextStyle(fontSize: 18)),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'views/note_input_screen.dart';

void main() {
  runApp(const QuickNoteApp());
}

class QuickNoteApp extends StatelessWidget {
  const QuickNoteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif'),
      home: const NoteInputScreen(),
    );
  }
}
