import 'package:lint_benchmark/src/agents/stream.dart';
import 'package:test/test.dart';

const _stream = r'''
{"type":"system","subtype":"init","model":"claude-opus-5"}
{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"dart analyze"}}]}}
{"type":"user","message":{"content":[{"type":"tool_result","content":"Analyzing task_app...\n\n  error - lib/a.dart:3:1 - Missing await. - unawaited_futures\n   info - lib/a.dart:9:1 - Avoid print. - avoid_print\n  error - lib/a.dart:12:1 - Missing await. - unawaited_futures\n\n3 issues found."}]}}
{"type":"user","message":{"content":[{"type":"tool_result","content":[{"type":"text","text":"warning - lib/b.dart:1:1 - x - strict_raw_type"}]}]}}
{"type":"result","subtype":"success","num_turns":7,"duration_ms":81000,"total_cost_usd":0.42,"usage":{"input_tokens":120,"output_tokens":3400,"cache_read_input_tokens":90000,"cache_creation_input_tokens":5000},"modelUsage":{"claude-opus-5":{}}}
''';

void main() {
  group('parseResult', () {
    test('reads the final result event', () {
      final result = parseResult(_stream);
      expect(result.subtype, 'success');
      expect(result.numTurns, 7);
      expect(result.durationMs, 81000);
      expect(result.costUsd, 0.42);
      expect(result.inputTokens, 120 + 90000 + 5000);
      expect(result.outputTokens, 3400);
    });

    test('a stream without a result event is a failed run', () {
      final result = parseResult('{"type":"system"}\n');
      expect(result.subtype, 'no_result');
      expect(result.numTurns, 0);
    });
  });

  group('ruleMentions', () {
    test('counts rule codes in analyzer output the agent saw', () {
      expect(ruleMentions(_stream), {
        'unawaited_futures': 2,
        'avoid_print': 1,
        'strict_raw_type': 1,
      });
    });
  });

  group('countTests', () {
    test(
      'counts visible testDone events of the flutter test json reporter',
      () {
        const reporter = '''
{"type":"start"}
{"type":"testStart","test":{"id":1,"name":"loading test/x.dart"}}
{"type":"testDone","testID":1,"result":"success","hidden":true}
{"type":"testStart","test":{"id":2,"name":"a"}}
{"type":"testDone","testID":2,"result":"success","hidden":false}
{"type":"testStart","test":{"id":3,"name":"b"}}
{"type":"testDone","testID":3,"result":"failure","hidden":false}
{"type":"testStart","test":{"id":4,"name":"c"}}
{"type":"testDone","testID":4,"result":"error","hidden":false}
{"type":"done","success":false}
''';
        expect(countTests(reporter), (passed: 1, total: 3));
      },
    );
  });
}
