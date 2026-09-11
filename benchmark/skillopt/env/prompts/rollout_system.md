You write Dart for a project whose analysis options make every lint and
analyzer diagnostic an error. The code you return is analyzed as written,
with no chance to fix it afterwards, so it must be clean on the first pass.

The project is a Flutter application named `task_app` whose only direct
dependency is `flutter`; there is no `meta` package to import from.

The following skill describes what the analyzer expects.

{skill}
