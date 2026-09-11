"""Writes the train/val/test task splits under env/data.

Each task is a short spec of one Dart file with a public API, plus a usage
stub that must compile against the answer so the model cannot dodge the
API. Scoring is the analyzer under the package's ruleset on the first
draft, so tasks are chosen to exercise the rules that fire in practice:
constructors, immutable equality, initializing formals, futures and
streams, sinks and timers, JSON with strict types, sealed types, widgets.
"""
from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def t(id_, task_type, file, prompt, usage):
    return {"id": id_, "task_type": task_type, "file": file,
            "prompt": prompt.strip(), "usage": usage.strip()}


TRAIN = [
    t("money", "dart", "lib/money.dart", """
Implement `lib/money.dart`: an immutable value class `Money` with `final int cents`
and `final String currency`, a `const` constructor `Money({required int cents,
required String currency})`, `Money.parse(String text)` accepting the form
`12.34 EUR` (two decimals, a space, three uppercase letters) and throwing
`FormatException` otherwise, `operator +` that throws `ArgumentError` when
currencies differ, value equality and `hashCode` over both fields, and
`toString()` producing `12.34 EUR`.
""", """
bool useMoney() {
  const a = Money(cents: 100, currency: 'EUR');
  final b = Money.parse('1.00 EUR');
  final c = a + b;
  return a == b && c.cents == 200 && a.hashCode == b.hashCode &&
      a.toString() == '1.00 EUR';
}
"""),
    t("lru_cache", "dart", "lib/lru_cache.dart", """
Implement `lib/lru_cache.dart`: `class LruCache<K, V>` with
`LruCache({required int capacity})` (throws `ArgumentError` if capacity < 1),
`V? get(K key)` (marks the key most recently used), `void put(K key, V value)`
(evicts the least recently used entry when over capacity), `bool remove(K key)`,
`int get length`, and `Iterable<K> get keys` from least to most recently used.
""", """
int useLru() {
  final cache = LruCache<String, int>(capacity: 2)
    ..put('a', 1)
    ..put('b', 2);
  final hit = cache.get('a');
  cache.put('c', 3);
  final removed = cache.remove('c');
  final keys = cache.keys.toList();
  return (hit ?? 0) + cache.length + keys.length + (removed ? 1 : 0);
}
"""),
    t("retry", "dart", "lib/retry.dart", """
Implement `lib/retry.dart`: `Future<T> retry<T>(Future<T> Function() action,
{int attempts = 3, Duration delay = const Duration(milliseconds: 100),
bool Function(Object error)? retryIf})`. It runs `action`, and on an error
for which `retryIf` returns true (or any error when `retryIf` is null) waits
`delay` and tries again, up to `attempts` total tries; the last error is
rethrown. `attempts < 1` throws `ArgumentError` before running anything.
""", """
Future<int> useRetry() async {
  var calls = 0;
  final value = await retry<int>(
    () async {
      calls++;
      if (calls < 2) {
        throw StateError('flaky');
      }
      return calls;
    },
    attempts: 3,
    delay: Duration.zero,
    retryIf: (error) => error is StateError,
  );
  return value;
}
"""),
    t("event_bus", "dart", "lib/event_bus.dart", """
Implement `lib/event_bus.dart`: `class EventBus` with `Stream<T> on<T>()`
returning a broadcast stream of only the events that are `T`, `void emit(Object
event)`, and `Future<void> dispose()` that closes the underlying controller.
Emitting after dispose throws `StateError`.
""", """
Future<int> useBus() async {
  final bus = EventBus();
  final first = bus.on<int>().first;
  bus.emit(7);
  final value = await first;
  await bus.dispose();
  return value;
}
"""),
    t("json_user", "dart", "lib/user.dart", """
Implement `lib/user.dart`: an immutable `User` with `final int id`, `final
String name`, `final String? email`, `final List<String> roles`, a `const`
constructor with named parameters (`id` and `name` required, `roles` default
empty), `factory User.fromJson(Map<String, Object?> json)` that throws
`FormatException` whose message names the offending key on a missing required
key or a value of the wrong type, `Map<String, Object?> toJson()`, and value
equality and `hashCode` over all fields (compare `roles` element-wise).
""", """
bool useUser() {
  final user = User.fromJson(<String, Object?>{
    'id': 1, 'name': 'ada', 'roles': <Object?>['admin'],
  });
  const same = User(id: 1, name: 'ada', roles: ['admin']);
  final json = user.toJson();
  return user == same && user.hashCode == same.hashCode &&
      json['name'] == 'ada' && user.email == null;
}
"""),
    t("csv", "dart", "lib/csv.dart", """
Implement `lib/csv.dart`: `List<List<String>> parseCsv(String text, {String
separator = ','})` splitting rows on `\\n` (a trailing newline does not add a
row), fields on `separator`, with double-quoted fields that may contain the
separator and newlines, and `""` inside quotes meaning a literal quote. A
quote that is never closed throws `FormatException`.
""", """
int useCsv() {
  final rows = parseCsv('a,"b,c"\\n"x ""y"" z",d\\n');
  return rows.length + rows[0].length + rows[1][0].length;
}
"""),
    t("rate_limiter", "dart", "lib/rate_limiter.dart", """
Implement `lib/rate_limiter.dart`: `class RateLimiter` with `RateLimiter({required
int maxEvents, required Duration window})`, `bool tryAcquire(DateTime now)` that
returns true and records the event when fewer than `maxEvents` events happened
in the `window` ending at `now`, else false, and `void reset()`. Timestamps
older than the window are forgotten.
""", """
int useLimiter() {
  final limiter = RateLimiter(maxEvents: 2, window: const Duration(seconds: 1));
  final t0 = DateTime(2026);
  final a = limiter.tryAcquire(t0);
  final b = limiter.tryAcquire(t0);
  final c = limiter.tryAcquire(t0);
  limiter.reset();
  return [a, b, c].where((x) => x).length;
}
"""),
    t("traffic_light", "dart", "lib/traffic_light.dart", """
Implement `lib/traffic_light.dart`: `enum Phase { red, green, yellow }` and
`class TrafficLight` with `Phase get phase` (starts `red`), `void next()`
cycling red, green, yellow, red, `Stream<Phase> get changes` (a broadcast
stream that emits after every `next`), and `Future<void> dispose()` closing
the stream. `next()` after dispose throws `StateError`.
""", """
Future<Phase> useLight() async {
  final light = TrafficLight();
  final next = light.changes.first;
  light.next();
  final phase = await next;
  await light.dispose();
  return phase == light.phase ? phase : Phase.red;
}
"""),
    t("ring_buffer", "dart", "lib/ring_buffer.dart", """
Implement `lib/ring_buffer.dart`: `class RingBuffer<T>` with
`RingBuffer({required int capacity})` (throws `ArgumentError` if < 1), `void
add(T value)` overwriting the oldest when full, `List<T> toList()` oldest to
newest, `bool get isFull`, `int get length`, and `T? get latest`.
""", """
int useRing() {
  final buffer = RingBuffer<int>(capacity: 2)
    ..add(1)
    ..add(2)
    ..add(3);
  final items = buffer.toList();
  return items.first + (buffer.latest ?? 0) + buffer.length +
      (buffer.isFull ? 1 : 0);
}
"""),
    t("debouncer", "dart", "lib/debouncer.dart", """
Implement `lib/debouncer.dart`: `class Debouncer` with `Debouncer({required
Duration delay})`, `void call(void Function() action)` that schedules `action`
after `delay` and replaces any pending action, `void cancel()`, `bool get
isPending`, and `void dispose()` that cancels. Calling after dispose throws
`StateError`.
""", """
bool useDebouncer() {
  final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
  var fired = false;
  debouncer(() => fired = true);
  final pending = debouncer.isPending;
  debouncer
    ..cancel()
    ..dispose();
  return pending && !fired;
}
"""),
    t("date_range", "dart", "lib/date_range.dart", """
Implement `lib/date_range.dart`: an immutable `DateRange` with `final DateTime
start` and `final DateTime end`, a constructor `DateRange({required DateTime
start, required DateTime end})` that throws `ArgumentError` when `end` is before
`start`, `bool contains(DateTime moment)` (inclusive), `DateRange? intersect(
DateRange other)` (null when disjoint), `Duration get length`, value equality
and `hashCode`.
""", """
bool useRange() {
  final a = DateRange(start: DateTime(2026), end: DateTime(2026, 2));
  final b = DateRange(start: DateTime(2026, 1, 15), end: DateTime(2026, 3));
  final both = a.intersect(b);
  return a.contains(DateTime(2026, 1, 10)) && both != null &&
      a.length.inDays > 0 && a == a && a.hashCode == a.hashCode;
}
"""),
    t("tokenizer", "dart", "lib/tokenizer.dart", """
Implement `lib/tokenizer.dart`: `sealed class Token` with `final class
NumberToken extends Token` (`final double value`), `final class OperatorToken
extends Token` (`final String symbol`, one of `+ - * /`), and `final class
ParenToken extends Token` (`final bool isOpen`), each with a `const`
constructor taking its field as a positional parameter. `List<Token>
tokenize(String source)` skips whitespace, parses decimal numbers, and throws
`FormatException` naming the offending character otherwise.
""", """
int useTokens() {
  final tokens = tokenize('(1.5 + 2) * 3');
  var sum = 0;
  for (final token in tokens) {
    sum += switch (token) {
      NumberToken(:final value) => value.toInt(),
      OperatorToken(:final symbol) => symbol.length,
      ParenToken(:final isOpen) => isOpen ? 1 : 0,
    };
  }
  const paren = ParenToken(true);
  return sum + (paren.isOpen ? 1 : 0);
}
"""),
    t("tree", "dart", "lib/tree.dart", """
Implement `lib/tree.dart`: `class Node<T>` with `final T value`, `final
List<Node<T>> children`, a `const` constructor `Node(T value, {List<Node<T>>
children = const []})`, plus top-level `Iterable<T> depthFirst<T>(Node<T>
root)` (a lazy `sync*` pre-order walk) and `int depth<T>(Node<T> root)` (a
leaf has depth 1).
""", """
int useTree() {
  const tree = Node<int>(1, children: [Node(2), Node(3, children: [Node(4)])]);
  final values = depthFirst(tree).toList();
  return values.length + depth(tree);
}
"""),
    t("validator", "dart", "lib/validator.dart", """
Implement `lib/validator.dart`: `sealed class ValidationResult`, `final class
Valid extends ValidationResult` (const), `final class Invalid extends
ValidationResult` with `final List<String> errors` (const constructor, positional),
`ValidationResult validateEmail(String value)` (non-empty, one `@`, a dot after
it) and `ValidationResult validatePassword(String value)` (at least 8
characters, a digit, an uppercase letter; one error message per failed rule).
""", """
int useValidation() {
  final results = [validateEmail('a@b.c'), validatePassword('short')];
  var errors = 0;
  for (final result in results) {
    errors += switch (result) {
      Valid() => 0,
      Invalid(:final errors) => errors.length,
    };
  }
  const ok = Valid();
  return errors + (ok is ValidationResult ? 1 : 0);
}
"""),
    t("async_cache", "dart", "lib/async_cache.dart", """
Implement `lib/async_cache.dart`: `class AsyncCache<K, V>` with `Future<V>
fetch(K key, Future<V> Function(K key) loader)` that returns a cached value
when present, otherwise runs `loader` once even when called concurrently for
the same key (in-flight loads are shared), `void invalidate(K key)`, `void
clear()`, and `bool contains(K key)`. A failed load is not cached.
""", """
Future<int> useCache() async {
  final cache = AsyncCache<String, int>();
  final a = cache.fetch('k', (key) async => key.length);
  final b = cache.fetch('k', (key) async => -1);
  final values = await Future.wait([a, b]);
  cache.invalidate('k');
  cache.clear();
  return values[0] + values[1] + (cache.contains('k') ? 1 : 0);
}
"""),
    t("paginate", "dart", "lib/paginate.dart", """
Implement `lib/paginate.dart`: an immutable `Page<T>` with `final List<T>
items` and `final String? nextCursor` (const constructor, named parameters,
`items` required), and `Stream<T> paginate<T>(Future<Page<T>> Function(String?
cursor) fetch)`: an `async*` stream that starts with a null cursor, yields
every item of each page in order, and stops when a page's `nextCursor` is
null. An empty page with a non-null cursor is followed normally.
""", """
Future<int> usePaginate() async {
  final items = await paginate<int>((cursor) async {
    if (cursor == null) {
      return const Page(items: [1, 2], nextCursor: 'more');
    }
    return const Page(items: [3]);
  }).toList();
  return items.length;
}
"""),
    t("matrix", "dart", "lib/matrix.dart", """
Implement `lib/matrix.dart`: an immutable `Matrix` over `List<List<double>>`
with `Matrix(List<List<double>> rows)` (throws `ArgumentError` for ragged or
empty input), `factory Matrix.identity(int size)`, `int get rowCount`, `int
get columnCount`, `double at(int row, int column)`, `Matrix transpose()`,
`Matrix operator *(Matrix other)` (throws `ArgumentError` on a shape mismatch),
and value equality with `hashCode`.
""", """
double useMatrix() {
  final m = Matrix([
    [1, 2],
    [3, 4],
  ]);
  final product = m * Matrix.identity(2);
  return product.at(1, 0) + m.transpose().at(0, 1) + m.rowCount +
      m.columnCount + (product == m ? 1 : 0);
}
"""),
    t("config", "dart", "lib/config.dart", """
Implement `lib/config.dart`: an immutable `Config` with `final int port`,
`final bool verbose`, `final Uri baseUrl`, and `factory Config.fromEnvironment(
Map<String, String> env)` reading `PORT` (default 8080, must parse as an
integer in 1..65535), `VERBOSE` (`true`/`false`, default false), and `BASE_URL`
(required, must parse as an absolute URI). Every violation throws
`FormatException` whose message names the variable.
""", """
int useConfig() {
  final config = Config.fromEnvironment({
    'PORT': '9000',
    'BASE_URL': 'https://example.com',
  });
  return config.port + (config.verbose ? 1 : 0) + config.baseUrl.host.length;
}
"""),
    t("path_utils", "dart", "lib/path_utils.dart", """
Implement `lib/path_utils.dart` with three top-level functions: `String
joinPath(List<String> segments)` joining with `/` and collapsing repeated
slashes without touching a leading one, `String basename(String path)` (the
part after the last `/`), and `String? extension(String path)` (the text after
the last `.` of the basename, or null when there is none or the basename
starts with the dot).
""", """
int usePaths() {
  final joined = joinPath(['/a/', '/b', 'c.txt']);
  final ext = extension(joined) ?? '';
  return joined.length + basename(joined).length + ext.length;
}
"""),
    t("counter_notifier", "flutter", "lib/counter_notifier.dart", """
Implement `lib/counter_notifier.dart` using `package:flutter/foundation.dart`:
`class CounterNotifier extends ChangeNotifier` with `CounterNotifier({required
int max})`, `int get value` (starts at 0), `bool get isAtMax`, `void
increment()` (no-op at max, otherwise increments and notifies), and `void
reset()` (sets 0 and notifies only if the value changed).
""", """
int useCounter() {
  final counter = CounterNotifier(max: 2)
    ..increment()
    ..increment()
    ..increment();
  final atMax = counter.isAtMax;
  counter
    ..reset()
    ..dispose();
  return counter.value + (atMax ? 1 : 0);
}
"""),
    t("toggle_tile", "flutter", "lib/toggle_tile.dart", """
Implement `lib/toggle_tile.dart`: `class ToggleTile extends StatelessWidget`
with `final String label`, `final bool value`, `final ValueChanged<bool>
onChanged`, a `const` constructor with those three as required named
parameters plus a key, building a `ListTile` whose `title` is the label and
whose `trailing` is a `Switch` bound to `value` and `onChanged`.
""", """
import 'package:flutter/material.dart';

Widget useToggle() => ToggleTile(
  label: 'Dark mode',
  value: true,
  onChanged: (_) {},
);
"""),
    t("async_button", "flutter", "lib/async_button.dart", """
Implement `lib/async_button.dart`: `class AsyncButton extends StatefulWidget`
with `final Future<void> Function() onPressed`, `final Widget child`, a `const`
constructor with both required and a key. While `onPressed` runs the button is
disabled and shows a small `CircularProgressIndicator` instead of `child`;
afterwards it re-enables, and it must not call `setState` if the widget was
disposed while the future was pending. Errors from `onPressed` propagate.
""", """
import 'package:flutter/material.dart';

Widget useButton() => AsyncButton(
  onPressed: () async {},
  child: const Text('Save'),
);
"""),
    t("search_field", "flutter", "lib/search_field.dart", """
Implement `lib/search_field.dart`: `class SearchField extends StatefulWidget`
with `final ValueChanged<String> onChanged`, `final Duration debounce`, a
`const` constructor (`onChanged` required, `debounce` defaulting to 300 ms,
plus a key). It shows a `TextField` and calls `onChanged` with the latest text
only after `debounce` passes without another change; the pending timer and
the text controller are disposed with the state.
""", """
import 'package:flutter/material.dart';

Widget useSearch() => SearchField(
  onChanged: (_) {},
  debounce: const Duration(milliseconds: 100),
);
"""),
]

VAL = [
    t("duration_fmt", "dart", "lib/duration_fmt.dart", """
Implement `lib/duration_fmt.dart`: `String formatDuration(Duration d)`
returning `h:mm:ss` when at least one hour else `mm:ss` (negative durations
throw `ArgumentError`), and `Duration parseDuration(String text)` accepting
both forms and throwing `FormatException` on anything else.
""", """
int useDurations() {
  final text = formatDuration(const Duration(minutes: 5, seconds: 7));
  return parseDuration(text).inSeconds + parseDuration('1:00:00').inHours;
}
"""),
    t("priority_queue", "dart", "lib/priority_queue.dart", """
Implement `lib/priority_queue.dart`: `class PriorityQueue<T>` with
`PriorityQueue(int Function(T a, T b) compare)`, `void add(T value)`, `T
removeFirst()` (smallest by `compare`; throws `StateError` when empty), `T?
get first`, `int get length`, and `bool get isEmpty`. Use a binary heap.
""", """
int useQueue() {
  final queue = PriorityQueue<int>((a, b) => a.compareTo(b))
    ..add(3)
    ..add(1)
    ..add(2);
  final first = queue.removeFirst();
  return first + queue.length + (queue.first ?? 0) + (queue.isEmpty ? 1 : 0);
}
"""),
    t("preferences", "dart", "lib/preferences.dart", """
Implement `lib/preferences.dart`: `enum AppTheme { system, light, dark }` and an
immutable `Preferences` with `final AppTheme theme`, `final double fontScale`,
`final bool notifications`, a `const` constructor with defaults (`system`,
`1.0`, `true`), `factory Preferences.fromJson(Map<String, Object?> json)`
reading `theme` by enum name, `fontScale` as a number within 0.5..3.0, and
`notifications` as a bool, ignoring unknown keys and throwing `FormatException`
naming the key on a wrong type or range, plus `toJson()` and value equality.
""", """
bool usePreferences() {
  final prefs = Preferences.fromJson(<String, Object?>{'theme': 'dark', 'x': 1});
  const other = Preferences(theme: AppTheme.dark);
  return prefs == other && prefs.toJson()['theme'] == 'dark' &&
      prefs.fontScale == 1.0 && prefs.notifications;
}
"""),
    t("merge_streams", "dart", "lib/merge_streams.dart", """
Implement `lib/merge_streams.dart`: `Stream<T> merge<T>(List<Stream<T>>
sources)` returning a single-subscription stream that forwards every event
from every source as it arrives, forwards errors, completes when all sources
have completed, and cancels every source subscription when the listener
cancels. Pausing the result pauses every source.
""", """
Future<int> useMerge() async {
  final merged = merge<int>([
    Stream.fromIterable([1, 2]),
    Stream.fromIterable([3]),
  ]);
  final values = await merged.toList();
  return values.length;
}
"""),
    t("undo_stack", "dart", "lib/undo_stack.dart", """
Implement `lib/undo_stack.dart`: `class UndoStack<T>` with `void push(T
state)` (clears the redo history), `T? undo()` (returns the previous state or
null), `T? redo()`, `bool get canUndo`, `bool get canRedo`, `T? get current`,
and `void clear()`.
""", """
int useUndo() {
  final stack = UndoStack<String>()
    ..push('a')
    ..push('b');
  final previous = stack.undo();
  final again = stack.redo();
  final flags = (stack.canUndo ? 1 : 0) + (stack.canRedo ? 1 : 0);
  stack.clear();
  return (previous?.length ?? 0) + (again?.length ?? 0) + flags +
      (stack.current?.length ?? 0);
}
"""),
    t("slug", "dart", "lib/slug.dart", """
Implement `lib/slug.dart`: `String slugify(String title)` lowercasing,
replacing any run of characters outside `a-z0-9` with a single `-`, and
trimming leading and trailing `-`; and `bool isValidSlug(String value)` which
is true only for non-empty strings of `a-z0-9` and single `-` separators.
""", """
int useSlug() {
  final slug = slugify('  Hello, World!  ');
  return slug.length + (isValidSlug(slug) ? 1 : 0) + (isValidSlug('--') ? 1 : 0);
}
"""),
    t("ticker", "flutter", "lib/ticker.dart", """
Implement `lib/ticker.dart` using `package:flutter/foundation.dart`: `class
PeriodicTicker extends ChangeNotifier` with `PeriodicTicker({required Duration
interval})`, `int get ticks` (starts 0), `bool get isRunning`, `void start()`
(no-op while running; increments `ticks` and notifies every `interval`),
`void stop()`, and `dispose()` that stops the timer.
""", """
int useTicker() {
  final ticker = PeriodicTicker(interval: const Duration(seconds: 1))..start();
  final running = ticker.isRunning;
  ticker
    ..stop()
    ..dispose();
  return ticker.ticks + (running ? 1 : 0);
}
"""),
    t("result", "dart", "lib/result.dart", """
Implement `lib/result.dart`: `sealed class Result<T>` with `final class
Ok<T> extends Result<T>` (`final T value`, const positional constructor) and
`final class Err<T> extends Result<T>` (`final Object error`, const positional
constructor); on `Result<T>`: `T getOrElse(T Function() orElse)` and `Result<R>
map<R>(R Function(T value) transform)`; and a top-level `Result<T> guard<T>(T
Function() body)` that returns `Err` for a thrown `Exception` and lets an
`Error` propagate.
""", """
int useResult() {
  final result = guard<int>(() => int.parse('12')).map((v) => v * 2);
  final fallback = guard<int>(() => throw const FormatException()).getOrElse(() => 1);
  const err = Err<int>('boom');
  return result.getOrElse(() => 0) + fallback + (err is Result<int> ? 1 : 0);
}
"""),
    t("inventory", "flutter", "lib/inventory.dart", """
Implement `lib/inventory.dart` using `package:flutter/foundation.dart`: `class
Inventory extends ChangeNotifier` with `void add(String sku, int quantity)`
(quantity must be positive, else `ArgumentError`), `void remove(String sku, int
quantity)` (throws `StateError` when the stock is insufficient), `int
quantity(String sku)` (0 when unknown), `int get totalItems`, and `Map<String,
int> get stock` returning an unmodifiable view. Every change notifies once.
""", """
int useInventory() {
  final inventory = Inventory()
    ..add('a', 3)
    ..remove('a', 1);
  final stock = inventory.stock;
  final total = inventory.totalItems + inventory.quantity('b') + stock.length;
  inventory.dispose();
  return total;
}
"""),
    t("semver", "dart", "lib/semver.dart", """
Implement `lib/semver.dart`: an immutable `SemVer` with `final int major`,
`final int minor`, `final int patch`, a `const` constructor with three
positional parameters, `factory SemVer.parse(String text)` for `1.2.3` (throws
`FormatException` otherwise), `implements Comparable<SemVer>`, `operator <`
and `operator >`, value equality with `hashCode`, and `toString()`.
""", """
int useSemVer() {
  const a = SemVer(1, 2, 3);
  final b = SemVer.parse('1.3.0');
  return (a < b ? 1 : 0) + (b > a ? 1 : 0) + a.compareTo(b).sign +
      (a == const SemVer(1, 2, 3) ? 1 : 0) + a.toString().length +
      a.hashCode.sign;
}
"""),
    t("count_badge", "flutter", "lib/count_badge.dart", """
Implement `lib/count_badge.dart`: `class CountBadge extends StatelessWidget`
with `final int count`, `final int max`, a `const` constructor (`count`
required, `max` defaulting to 99, plus a key). It renders nothing (a
`SizedBox.shrink`) when `count` is 0, otherwise a rounded `DecoratedBox` with
the number, or `99+` style text when `count` exceeds `max`.
""", """
import 'package:flutter/material.dart';

Widget useBadge() => const CountBadge(count: 120, max: 99);
"""),
    t("expandable", "flutter", "lib/expandable.dart", """
Implement `lib/expandable.dart`: `class Expandable extends StatefulWidget`
with `final String title`, `final Widget child`, `final bool initiallyExpanded`,
a `const` constructor (`title` and `child` required, `initiallyExpanded`
defaulting to false, plus a key). A tappable header row shows the title and
an arrow icon that rotates when expanded; the child is shown below it with an
`AnimatedSize` transition.
""", """
import 'package:flutter/material.dart';

Widget useExpandable() => const Expandable(
  title: 'Details',
  child: Text('Body'),
);
"""),
]

TEST = [
    t("settings_parser", "dart", "lib/settings.dart",
      (HERE.parents[0] / "agents" / "tasks" / "settings_parser" / "prompt.md").read_text(), """
import 'dart:convert';

bool useSettings() {
  final settings = parseSettings('{"username":"ada"}');
  const same = Settings(username: 'ada');
  final round = parseSettings(jsonEncode(settings.toJson()));
  try {
    parseSettings('[]');
  } on SettingsFormatException catch (e) {
    return e.message.isNotEmpty && round == same && settings.fontSize == 14;
  }
  return false;
}
"""),
    t("search_model", "dart", "lib/search_model.dart",
      (HERE.parents[0] / "agents" / "tasks" / "search_model" / "prompt.md").read_text(), """
Future<int> useSearch() async {
  final model = SearchModel(fetcher: (query) async => [query])
    ..onQueryChanged('a');
  final status = model.status;
  final results = model.results;
  model.dispose();
  return results.length + (status == SearchStatus.idle ? 1 : 0) +
      (model.error == null ? 1 : 0) + model.query.length;
}
"""),
    t("countdown", "flutter", "lib/countdown.dart",
      (HERE.parents[0] / "agents" / "tasks" / "countdown" / "prompt.md").read_text(), """
import 'package:flutter/material.dart';

Widget useCountdown() {
  final controller = CountdownController(duration: const Duration(seconds: 5))
    ..start()
    ..pause()
    ..reset();
  final remaining = controller.remaining;
  return CountdownTimer(
    controller: controller,
    onFinished: remaining.inSeconds == 5 ? () {} : null,
  );
}
"""),
]


def main() -> None:
    for name, items in (("train", TRAIN), ("val", VAL), ("test", TEST)):
        out = HERE / "env" / "data" / name / "tasks.json"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(items, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"{name}: {len(items)} tasks")


if __name__ == "__main__":
    main()
