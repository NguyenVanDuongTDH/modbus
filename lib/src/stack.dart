import 'dart:collection';

class Stack {
  DoubleLinkedQueue<Future<dynamic> Function()> waitQueue = DoubleLinkedQueue();
  bool isRun = false;
  List<int> bytes = [];

  void excute(Future<dynamic> Function() queue) {
    waitQueue.addLast(queue);
    loop();
  }

  Future<void> loop() async {
    if (isRun == false) {
      isRun = true;
      while (waitQueue.isNotEmpty) {
        final first = waitQueue.removeFirst();
        await first();
      }
      isRun = false;
    }
  }
}