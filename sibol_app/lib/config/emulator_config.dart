/// Firebase emulator ports for SIBOL demonstration mode.
///
/// Must stay aligned with [firebase.json] and
/// `shared/emulator/canonical_ports.json`.
abstract final class EmulatorConfig {
  static const int authPort = 9099;
  static const int firestorePort = 8195;
  static const int functionsPort = 5001;
}
