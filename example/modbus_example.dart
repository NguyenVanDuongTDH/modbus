import 'dart:typed_data';

import 'package:modbus/modbus.dart';
import 'package:serial/serial.dart';

Uint16List data = Uint16List(100);
Future<void> main() async {
  SerialServer serial = Serial.tcp(host, port)
  ModbusSlave slave = ModbusSlave.RTU(serial);
  slave.configHoldingRegisters(HoldingRegistersConfig.fromList(data));
  slave.bind();
}
