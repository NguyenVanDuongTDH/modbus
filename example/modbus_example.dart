import 'dart:typed_data';

import 'package:modbus/modbus.dart';
import 'package:modbus/src/rtu_master/rtu_master.dart';

Uint16List data = Uint16List(100);
Future<void> main() async {
  SerialServer serial = SerialWindowsServerUSB("COM3",
      baudRate: 9600, bits: 8, parity: 0, stopBits: 1);
  ModbusSlave slave = ModbusSlave.RTU(serial);
  slave.configHoldingRegisters(HoldingRegistersConfig(
    0,
    100,
    writeRegisters: (address, value) {
      data[address] = value;
    },
    readRegisters: (address) {
      return 1;
    },
  ));
  slave.bind();
}
