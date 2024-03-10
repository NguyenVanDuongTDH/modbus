// ignore_for_file: unused_element

import 'dart:typed_data';

import 'package:modbus/modbus.dart';
import 'package:modbus/src/until.dart';

import '../tcp/modbus_tcp_master_core.dart';

class RtuRequest {
  int slaveId = 0;
  int function = 0;
  int quantity = 0;
  int address = 0;
  List<int> datas = [];
  RtuRequest._(
      {required this.slaveId,
      required this.function,
      required this.quantity,
      required this.address,
      required List<int> datas});

  factory RtuRequest.write(
      {required int slaveId,
      required int function,
      required int address,
      required List<int> datas}) {
    return RtuRequest._(
        slaveId: slaveId,
        function: function,
        quantity: -1,
        address: address,
        datas: datas);
  }
  factory RtuRequest.read(
      {required int slaveId,
      required int function,
      required int address,
      required int quantity}) {
    return RtuRequest._(
        slaveId: slaveId,
        function: function,
        address: address,
        quantity: quantity,
        datas: []);
  }

  Uint8List get request => _request();
  Uint8List _request() {
    switch (function) {
      case ModbusFunctions.readCoils:
      case ModbusFunctions.readDiscreteInputs:
      case ModbusFunctions.readInputRegisters:
      case ModbusFunctions.readHoldingRegisters:
        return _readRequest(
            slaveId: slaveId,
            functions: function,
            address: address,
            quantity: quantity);

      case ModbusFunctions.writeMultipleCoils:
      case ModbusFunctions.writeMultipleRegisters:
      case ModbusFunctions.writeSingleCoil:
      case ModbusFunctions.writeSingleRegister:
        return _writeRequest(
            slaveId: slaveId,
            functions: function,
            address: address,
            datas: datas);
    }
    throw ModbusException(ModbusError.Done_Know);
  }

  static Uint8List _readRequest(
      {required int slaveId,
      required int functions,
      required int address,
      required int quantity}) {
    Uint8List ADU = Uint8List(8);
    ByteData.view(ADU.buffer)
      ..setUint8(0, slaveId)
      ..setUint8(1, functions)
      ..setUint16(2, address, Endian.big)
      ..setUint16(4, quantity, Endian.big);
    ByteData.view(ADU.buffer).setUint16(6, crc16(ADU, 6), Endian.little);
    return ADU;
  }

  static Uint8List _writeRequest(
      {required int slaveId,
      required int functions,
      required int address,
      required List<int> datas}) {
    Uint8List DPU = Uint8List(256);
    ByteData.view(DPU.buffer)
      ..setUint8(0, slaveId)
      ..setUint8(1, functions)
      ..setUint16(2, address);
    switch (functions) {
      case ModbusFunctions.writeSingleCoil:
        ByteData.view(DPU.buffer).setInt16(4, datas[0], Endian.big);
        ByteData.view(DPU.buffer).setInt16(6, crc16(DPU, 6), Endian.little);
        return DPU.sublist(0, 8);
      case ModbusFunctions.writeSingleRegister:
        ByteData.view(DPU.buffer).setInt16(4, datas[0], Endian.big);
        ByteData.view(DPU.buffer).setInt16(6, crc16(DPU, 6), Endian.little);
        return DPU.sublist(0, 8);

      case ModbusFunctions.writeMultipleCoils:
        ByteData.view(DPU.buffer).setInt16(4, datas.length, Endian.big);
        DPU[6] = (datas.length / 8).ceil();

        for (int i = 0; i < datas.length; i += 8) {
          for (int j = 0; j < 8 && i + j < datas.length; j++) {
            if (datas[i + j] != 0) {
              DPU[(i ~/ 8) + 7] |= (1 << j);
            }
          }
        }
        ByteData.view(DPU.buffer)
            .setInt16(7 + DPU[6], crc16(DPU, 7 + DPU[6]), Endian.little);
        return DPU.sublist(0, 9 + DPU[6]);

      case ModbusFunctions.writeMultipleRegisters:
        ByteData.view(DPU.buffer)
          ..setInt16(4, datas.length, Endian.big)
          ..setUint8(6, lowByte(datas.length << 1));

        for (int i = 0; i < datas.length; i++) {
          ByteData.view(DPU.buffer).setUint16(7 + i * 2, datas[i], Endian.big);
        }
        ByteData.view(DPU.buffer)
            .setInt16(7 + DPU[6], crc16(DPU, 7 + DPU[6]), Endian.little);
        return DPU.sublist(0, 9 + DPU[6]);
    }
    return Uint8List(0);
  }
}
