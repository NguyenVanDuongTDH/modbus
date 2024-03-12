import 'dart:typed_data';

import 'package:modbus/modbus.dart';

Uint16List data = Uint16List(100);
Future<void> main() async {
  SerialServer serial = SerialServer.winUsb("COM10");
  ModbusSlave slave = ModbusSlave.RTU(serial);
  slave.configHoldingRegisters(HoldingRegistersConfig.fromList(data));
  slave.bind();
}
