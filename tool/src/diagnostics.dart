import 'package:analyzer/error/error.dart';

/// Names of every analyzer diagnostic whose default severity is not already
/// error, lowercased to the form `analyzer.errors` expects.
///
/// Lint rules are not part of this list; they have their own registry and are
/// promoted from the `linter.rules` map instead.
Set<String> nonErrorDiagnosticNames() => {
  for (final code in diagnosticCodeValues)
    if (code.severity != DiagnosticSeverity.ERROR) code.lowerCaseName,
};
