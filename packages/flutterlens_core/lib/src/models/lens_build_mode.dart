enum LensBuildMode {
  debug,
  profile,
  unknown;

  String get label => switch (this) {
    LensBuildMode.debug => 'Debug',
    LensBuildMode.profile => 'Profile',
    LensBuildMode.unknown => 'Unknown',
  };
}
