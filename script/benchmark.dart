import 'package:xterm/xterm.dart';

void main() {
  BenchmarkWrite().run();
  BenchmarkWrite2().run();
  BenchmarkWriteBuffer().run();
}

abstract class Benchmark {
  String explain();

  void benchmark();

  void run() {
    print('benchmark: ${explain()}');
    print('preheating...');
    benchmark();
    final sw = Stopwatch()..start();
    print('running...');
    benchmark();
    sw.stop();
    print('result: ${sw.elapsedMilliseconds} ms');
  }
}

class BenchmarkWrite extends Benchmark {
  static const cycle = 1 << 20;
  static const data = 'hello world';

  String explain() {
    return "write '$data' to Terminal for $cycle times";
  }

  void benchmark() {
    final terminal = Terminal();
    for (var i = 0; i < cycle; i++) {
      terminal.write(data);
    }
  }
}

class BenchmarkWrite2 extends Benchmark {
  static const cycle = 100000;
  static const data = '100000';

  String explain() {
    return "write '$data' to Terminal for $cycle times";
  }

  void benchmark() {
    final terminal = Terminal();
    for (var i = 0; i < cycle; i++) {
      terminal.write(data);
    }
  }
}

class BenchmarkWriteBuffer extends Benchmark {
  static const cycle = 1 << 20;
  static const data = 'hello world';

  String explain() {
    return "write '$data' to StringBuffer for $cycle times";
  }

  void benchmark() {
    final buffer = StringBuffer();
    for (var i = 0; i < cycle; i++) {
      buffer.write(data);
    }
  }
}
