/// Non-secret app configuration.
/// Update [jetsonHost] to your Jetson Nano IP on the local network.
class AppConfig {
  static const String jetsonHost = String.fromEnvironment(
    'JETSON_HOST',
    defaultValue: '192.168.118.188',
  );

  static const int jetsonPort = int.fromEnvironment(
    'JETSON_PORT',
    defaultValue: 1235,
  );
}
