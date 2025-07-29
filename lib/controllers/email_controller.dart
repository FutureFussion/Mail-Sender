import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/note.dart';

class EmailController {
  final String username = 'ahmadtech116p@gmail.com';
  final String appPassword = 'lvdbufychdowdupg';

  Future<bool> sendNote(Note note) async {
    final message = Message()
      ..from = Address(username, 'Quick Notes')
      ..recipients.add(username)
      ..subject = 'Quick Note - ${DateTime.now()}'
      ..text = note.content;

    final smtpServer = gmail(username, appPassword.replaceAll(' ', ''));

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }
}
