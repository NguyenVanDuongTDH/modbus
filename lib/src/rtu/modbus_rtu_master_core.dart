// ignore_for_file: unused_field, non_constant_identifier_names, unused_local_variable, avoid_single_cascade_in_expression_statements, no_leading_underscores_for_local_identifiers

import 'dart:typed_data';

import 'package:modbus/src/until.dart';

class ModbusRtuCore {
  static const int _ku8MaxBufferSize = 64;
//
  static const int ku8MBReadCoils = 0x01;
  static const int ku8MBReadDiscreteInputs = 0x02;
  static const int ku8MBWriteSingleCoil = 0x05;
  static const int ku8MBWriteMultipleCoils = 0x0F;
  static const int ku8MBReadHoldingRegisters = 0x03;
  static const int ku8MBReadInputRegisters = 0x04;
  static const int ku8MBWriteSingleRegister = 0x06;
  static const int ku8MBWriteMultipleRegisters = 0x10;
  static const int ku8MBMaskWriteRegister = 0x16;
  static const int ku8MBReadWriteMultipleRegisters = 0x17;

  static const int _ku8MBIllegalFunction = 0x01;
  static const int _ku8MBIllegalDataAddress = 0x02;
  static const int _ku8MBIllegalDataValue = 0x03;
  static const int _ku8MBSlaveDeviceFailure = 0x04;
  static const int _ku8MBSuccess = 0x00;
  static const int _ku8MBInvalidSlaveID = 0xE0;
  static const int _ku8MBInvalidFunction = 0xE1;
  static const int _ku8MBResponseTimedOut = 0xE2;
  static const int _ku8MBInvalidCRC = 0xE3;

  static Uint8List writeRequest(
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
      case ku8MBWriteSingleCoil:
        ByteData.view(DPU.buffer).setInt16(4, datas[0], Endian.big);
        ByteData.view(DPU.buffer).setInt16(6, crc16(DPU, 6), Endian.little);
        return DPU.sublist(0, 8);
      case ku8MBWriteSingleRegister:
        ByteData.view(DPU.buffer).setInt16(4, datas[0], Endian.big);
        ByteData.view(DPU.buffer).setInt16(6, crc16(DPU, 6), Endian.little);
        return DPU.sublist(0, 8);

      case ku8MBWriteMultipleCoils:
        ByteData.view(DPU.buffer).setInt16(4, datas.length, Endian.big);
        DPU[6] = (datas.length / 8).ceil();
        
        for (int i = 0; i < datas.length; i += 8) {
          int value = 0;
          for (int j = 0; j < 8 && i + j < datas.length; j++) {
            if (datas[i + j] != 0) {
              DPU[(i ~/ 8) + 7] |= (1 << j); 
            }
          }
          
        }


        ByteData.view(DPU.buffer)
            .setInt16(7 + DPU[6], crc16(DPU, 7 + DPU[6]), Endian.little);
        return DPU.sublist(0, 9 + DPU[6]);

      case ku8MBWriteMultipleRegisters:
        ByteData.view(DPU.buffer)
          ..setInt16(4, datas.length, Endian.big)
          ..setUint8(6, lowByte(datas.length << 1));
        ;

        for (int i = 0; i < datas.length; i++) {
          ByteData.view(DPU.buffer).setUint16(7 + i * 2, datas[i], Endian.big);
        }
        ByteData.view(DPU.buffer)
            .setInt16(7 + DPU[6], crc16(DPU, 7 + DPU[6]), Endian.little);
        return DPU.sublist(0, 9 + DPU[6]);
    }
    return Uint8List(0);
  }

  static Uint8List boolListToUint8List(List<bool> boolList) {
    int length = boolList.length;
    Uint8List uint8List =
        Uint8List((length / 8).ceil()); // Tạo một Uint8List có độ dài cần thiết
    for (int i = 0; i < length; i += 8) {
      int value = 0;
      for (int j = 0; j < 8 && i + j < length; j++) {
        if (boolList[i + j]) {
          value |= (1 << j); // Thiết lập bit tương ứng nếu giá trị là true
        }
      }
      uint8List[i ~/ 8] = value; // Gán giá trị vào Uint8List
    }
    return uint8List;
  }

  static Uint8List readRequest(
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

  static bool checkLengthRePonse(List<int> datas) {
    if (datas.length > 3) {
      switch (datas[1]) {
        case 1:
        case 2:
        case 3:
        case 4:
          return datas.length == 5 + datas[2];
        case 5:
        case 6:
        case 15:
        case 16:
          return datas.length == 8;
      }
    }
    return false;
  }

  static dynamic readReponse(
      {required Uint8List response,
      required int slaveId,
      required int functions,
      required int address,
      required int quantity}) {
    if (response[0] != slaveId) {
      return _ku8MBInvalidSlaveID;
    }
    if ((response[1] & 0x7F) != functions) {
      return _ku8MBInvalidFunction;
    }
    if (bitRead(response[1], 7) != 0) {
      return response[2];
    }
    if (response[response.length - 2] | response[response.length - 1] << 8 !=
        crc16(response, response.length - 2)) {
      return _ku8MBInvalidCRC;
    }

    int i = 0;
    switch (response[1]) {
      case ku8MBReadCoils:
      case ku8MBReadDiscreteInputs:
        List<bool> resBool = [];
        for (int byte in response.sublist(3, 3 + response[2])) {
          for (int i = 0; i < 8; i++) {
            if (resBool.length < quantity) {
              resBool.add((byte >> i) & 1 == 1);
            } else {
              break;
            }
          }
        }
        return resBool;

      case ku8MBReadInputRegisters:
      case ku8MBReadHoldingRegisters:
      case ku8MBReadWriteMultipleRegisters:
        ByteData byteData =
            ByteData.view(response.sublist(3, 3 + response[2]).buffer);
        Uint16List uint16List = Uint16List(quantity);
        for (int i = 0; i < uint16List.length; i++) {
          uint16List[i] = byteData.getUint16(i * Uint16List.bytesPerElement, Endian.big);
        }
        return uint16List.toList();
    }
    return 0;
  }
}
