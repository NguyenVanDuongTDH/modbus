import 'dart:typed_data';

import 'package:modbus/modbus.dart';
import 'package:modbus/src/rtu_master/rtu_master.dart';

Uint16List data = Uint16List(100);
Future<void> main() async {
  SerialClient serial = SerialWindowsClientUSB("COM4", baudRate: 115200);
  ModbusMaster slave = ModbusMaster.RTU(serial);
  slave.setSlaveId(1);
  await slave.connect();
  print(await slave.writeMultipleRegisters(0, [1, 1221]));
  print(await slave.readHoldingRegisters(0, 10));
  slave.close();
}
