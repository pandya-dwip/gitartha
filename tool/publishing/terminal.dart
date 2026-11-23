import 'dart:io';

/// Terminal I/O for the publisher, behind an interface so the command can be
/// tested with scripted input.
abstract interface class PublisherTerminal {
  /// Whether input comes from a real terminal (required for the password).
  bool get isInteractive;

  void write(String text);

  /// Reads one visible line, or null at end of input.
  String? readLine(String prompt);

  /// Reads one line **without echoing it**, or null if input is not an
  /// interactive terminal (then the secret cannot be entered safely).
  String? readSecret(String prompt);
}

/// The real terminal (stdin/stdout).
class StdioTerminal implements PublisherTerminal {
  const StdioTerminal();

  @override
  bool get isInteractive => stdin.hasTerminal;

  @override
  void write(String text) => stdout.write(text);

  @override
  String? readLine(String prompt) {
    stdout.write(prompt);
    return stdin.readLineSync()?.trim();
  }

  @override
  String? readSecret(String prompt) {
    if (!stdin.hasTerminal) return null;
    stdout.write(prompt);
    final echo = stdin.echoMode;
    try {
      stdin.echoMode = false;
      return stdin.readLineSync();
    } finally {
      stdin.echoMode = echo;
      stdout.writeln();
    }
  }
}
