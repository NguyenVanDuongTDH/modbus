import 'dart:typed_data';

import 'package:modbus/modbus.dart';
import 'package:modbus/src/tcp_master/modbus_tcp_master_core.dart';

Uint16List data = Uint16List(100);
Future<void> main() async {
  // SerialServer serial = SerialWindowsServerUSB("COM11");
  // ModbusSlave slave = ModbusSlave.RTU(serial);
  // slave.configHoldingRegisters(HoldingRegistersConfig.fromList(data));
  // slave.bind();
  print(ModbusMasterTCPCore.readRequest(123, 1, 0x03, 0, 10));
}
