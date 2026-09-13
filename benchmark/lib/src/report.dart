/// [replacement], keeping the markers.
String replaceBetweenMarkers(
  String text,
  String replacement, {
  String marker = 'benchmark',
}) {
  final open = '<!-- $marker -->\n';
  final close = '<!-- /$marker -->';
  final start = text.indexOf(open);
  final end = text.indexOf(close);
  if (start < 0 || end < 0 || end < start) {
    throw StateError('$marker markers not found');
  }
  return text.replaceRange(start + open.length, end, replacement);
}
