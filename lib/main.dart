import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue,
          selectionHandleColor: Colors.blue,
          selectionColor: Colors.blue.withOpacity(0.4),
        ),
      ),
      color: Colors.blue,
      title: 'QuickMail',
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  SharedPreferences? prefs;
  String? toEmail, fromEmail, apiKey;
  List<PlatformFile> attachments = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPrefs();
    _handleInitialShare();
    _showKeyboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showKeyboard();
    }
  }

  void _showKeyboard() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      toEmail = prefs?.getString('toEmail') ?? '';
      fromEmail = prefs?.getString('fromEmail') ?? '';
      apiKey = prefs?.getString('apiKey') ?? '';
    });
  }

  Future<void> _savePrefs() async {
    await prefs?.setString('toEmail', toEmail ?? '');
    await prefs?.setString('fromEmail', fromEmail ?? '');
    await prefs?.setString('apiKey', apiKey ?? '');
  }

  void _handleInitialShare() async {
    if (!Platform.isAndroid) return;

    try {
      const methodChannel = MethodChannel('flutter/sharedIntent');
      final result = await methodChannel.invokeMethod<Map>('getSharedContent');

      if (result == null) {
        return;
      }

      String? sharedText = result['text'];
      String? sharedSubject = result['subject'];
      List<dynamic>? files = result['files'];

      String fullText = '';
      if (sharedSubject != null && sharedSubject.trim().isNotEmpty) {
        fullText += sharedSubject.trim();
      }
      if (sharedText != null && sharedText.trim().isNotEmpty) {
        if (fullText.isNotEmpty) {
          fullText += '\n\n';
        }
        fullText += sharedText.trim();
      }

      if (fullText.isNotEmpty) {
        _controller.text = fullText;
      }

      if (files != null && files.isNotEmpty) {
        attachments = files.map((p) {
          final file = File(p);
          return PlatformFile(
            name: p.split('/').last,
            path: p,
            size: file.existsSync() ? file.lengthSync() : 0,
          );
        }).toList();
        setState(() {});
      }

      if (_controller.text.isNotEmpty || attachments.isNotEmpty) {
        _sendEmail();
      }
    } catch (e) {
      print('Error handling initial share: $e');
    }
  }

  Future<void> _sendEmail() async {
    final message = _controller.text.trim();

    if ((message.isEmpty && attachments.isEmpty) ||
        toEmail == null || toEmail!.isEmpty ||
        fromEmail == null || fromEmail!.isEmpty ||
        apiKey == null || apiKey!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please check your settings and ensure a message or attachment is present.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': fromEmail,
          'to': [toEmail], // Resend API expects an array
          'subject': message.split('\n').first.isNotEmpty 
              ? message.split('\n').first 
              : 'QuickMail Message',
          'text': _buildBodyWithAttachmentList(message),
          if (attachments.isNotEmpty) 'attachments': _buildBase64Attachments(attachments),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        print("✅ Mail sent successfully");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Resend failed: ${response.statusCode} ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Email failed to send: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        // Small delay to show the success/error message before closing
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            SystemNavigator.pop();
          }
        });
      }
    }
  }

  List<Map<String, String>> _buildBase64Attachments(List<PlatformFile> files) {
    return files.where((f) => f.path != null).map((file) {
      try {
        final bytes = File(file.path!).readAsBytesSync();
        final base64Content = base64Encode(bytes);
        return {"filename": file.name, "content": base64Content};
      } catch (e) {
        print('Error reading file ${file.name}: $e');
        return <String, String>{}; // Return empty map for failed files
      }
    }).where((attachment) => attachment.isNotEmpty).toList();
  }

  String _buildBodyWithAttachmentList(String message) {
    final buffer = StringBuffer(message);
    if (attachments.isNotEmpty) {
      buffer.writeln('\n\n--- Attached files ---');
      for (var file in attachments) {
        buffer.writeln(file.name);
      }
    }
    return buffer.toString();
  }

  void _showSettings() {
    final toCtl = TextEditingController(text: toEmail);
    final fromCtl = TextEditingController(text: fromEmail);
    final keyCtl = TextEditingController(text: apiKey);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toCtl,
                decoration: const InputDecoration(labelText: 'To Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fromCtl,
                decoration: const InputDecoration(labelText: 'From Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: keyCtl,
                decoration: const InputDecoration(labelText: 'Resend API Key'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                toEmail = toCtl.text.trim();
                fromEmail = fromCtl.text.trim();
                apiKey = keyCtl.text.trim();
              });
              _savePrefs();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  cursorColor: Colors.white,
                ),
              ),
              if (attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${attachments.length} file(s) attached',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: _showSettings,
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                            );
                            if (result != null) {
                              setState(() {
                                attachments = result.files;
                              });
                              _showKeyboard();
                            }
                          },
                          child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.attach_file, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            try {
                              final data = await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                final text = data!.text!;
                                final currentText = _controller.text;
                                final selection = _controller.selection;

                                final newText =
                                    currentText.substring(0, selection.start) +
                                    text +
                                    currentText.substring(selection.end);

                                _controller.text = newText;
                                _controller.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(
                                        offset: selection.start + text.length,
                                      ),
                                    );
                              }
                            } catch (e) {
                              print('Error pasting from clipboard: $e');
                            }
                          },
                          child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.content_paste, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.blue.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SEND  ',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(Icons.send_outlined, color: Colors.white),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
