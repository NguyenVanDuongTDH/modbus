import 'dart:typed_data';

import 'package:modbus/modbus.dart';

Uint16List data = Uint16List(100);
Future<void> main() async {
  
  SerialServer serial = SerialWindowsServerUSB("COM11");
  ModbusSlave slave = ModbusSlave.RTU(serial);
  slave.configHoldingRegisters(HoldingRegistersConfig(
    0,
    10,
    writeRegisters: (address, value) {
      print("Registers[$address] = $value");
      data[address] = value;
    },
    readRegisters: (address) {
      print("read[$address] = ${data[address]}");
      return data[address];
    },
  ));
  slave.bind();
}
