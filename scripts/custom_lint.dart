import 'dart:io';

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  int errors = 0;

  for (final file in files) {
    final content = file.readAsStringSync();

    // Check for direct service instantiation (violates DI rule)
    if (RegExp(r'new\s+\w+Service\(').hasMatch(content)) {
      print('${file.path}: Direct service instantiation found. Use GetIt instead.');
      errors++;
    }

    // Check for business logic in view files
    if (file.path.contains('/views/') &&
        (content.contains('Repository(') || content.contains('Service('))) {
      print('${file.path}: Business logic found in view file. Move to ViewModel.');
      errors++;
    }

    // Check for missing documentation on public APIs
    if (!file.path.contains('_test.dart')) {
      final publicApis = RegExp(r'(class|enum|extension|typedef)\s+\w+').allMatches(content);
      for (final match in publicApis) {
        final linesBefore = content.substring(0, match.start).split('\n');
        if (linesBefore.last.trim().isEmpty &&
            (linesBefore.length < 2 || !linesBefore[linesBefore.length - 2].trim().startsWith('///'))) {
          print('${file.path}: Missing documentation for ${match.group(0)}');
          errors++;
        }
      }
    }
  }

  if (errors > 0) {
    print('$errors custom lint errors found');
    exit(1);
  }

  print('No custom lint errors found');
}
