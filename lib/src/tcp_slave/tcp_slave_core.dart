// ignore_for_file: prefer_final_fields

import 'package:modbus/src/tcp_slave/tcp_slave.dart';
import 'package:serial/serial.dart';

class ModbusTCPSlaveCore {
  SerialClient socket;
  ModbusSlaveTCP ctx;
  void Function()? onclose;
  List<int> _bytes = [];
  int _timeOut = 300;

  ModbusTCPSlaveCore(this.socket, this.ctx) {
    socket.listen((event) async {
      _bytes.addAll(event);
      readData();
    }, onDone: onclose);
  }

  bool isloop = false;
  Future<void> readData() async {
    if (isloop == false) {
      int timeStart = DateTime.now().millisecondsSinceEpoch;
      isloop = true;
      do {
        await Future.delayed(const Duration(milliseconds: 1));
      } while (
          // !checkLength(_bytes) &&
          DateTime.now().millisecondsSinceEpoch - timeStart < _timeOut);
      if (_bytes.length >= 8) {
        // process(Uint8List.fromList(_bytes));
      }
      _bytes.clear();
      isloop = false;
    }
  }
}