import 'package:flutter/material.dart';

class SendSuccessDialog extends StatelessWidget {
  final bool success;
  final VoidCallback onDone;
  const SendSuccessDialog({
    super.key,
    required this.success,
    required this.onDone,
  });

  @override
  // Widget build(BuildContext context) {
  //   return AlertDialog(
  //     backgroundColor: Colors.black87,
  //     content: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(
  //           success ? Icons.check_circle : Icons.error,
  //           color: success ? Colors.greenAccent : Colors.redAccent,
  //           size: 60,
  //         ),
  //         const SizedBox(height: 16),
  //         Text(
  //           success ? 'Sent!' : 'Failed to send',
  //           style: const TextStyle(color: Colors.white, fontSize: 18),
  //         ),
  //       ],
  //     ),
  //     actions: [
  //       TextButton(
  //         onPressed: onDone,
  //         child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
  //       ),
  //     ],
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.greenAccent : Colors.redAccent,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Sent!' : 'Failed to send',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
