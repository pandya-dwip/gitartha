/// Thrown when application configuration is missing, malformed or unsafe.
///
/// The [message] is written for developers: it should say what is wrong and
/// how to fix it (usually by editing `.env`).
class ConfigurationException implements Exception {
  const ConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'ConfigurationException: $message';
}
