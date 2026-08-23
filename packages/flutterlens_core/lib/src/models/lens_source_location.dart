class LensSourceLocation {
  const LensSourceLocation({
    required this.file,
    this.line,
    this.column,
  });

  final String file;
  final int? line;
  final int? column;

  String get display {
    final lineValue = line;
    final columnValue = column;
    if (lineValue == null) return file;
    if (columnValue == null) return '$file:$lineValue';
    return '$file:$lineValue:$columnValue';
  }

  @override
  bool operator ==(Object other) {
    return other is LensSourceLocation &&
        other.file == file &&
        other.line == line &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(file, line, column);
}
