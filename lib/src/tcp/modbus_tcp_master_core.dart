import 'dart:typed_data';

class ModbusFunctions {
  static const readCoils = 0x01;
  static const readDiscreteInputs = 0x02;
  static const readHoldingRegisters = 0x03;
  static const readInputRegisters = 0x04;
  static const writeSingleCoil = 0x05;
  static const writeSingleRegister = 0x06;
  static const readExceptionStatus = 0x07;
  static const writeMultipleCoils = 0x0f;
  static const writeMultipleRegisters = 0x10;
  static const reportSlaveId = 0x11;
}

class ModbusException {
  static const int illegalFunction = 0x01;
  static const int success = 0x00;
  static const int invalidSlaveID = 0xE0;
  static const int invalidFunction = 0xE1;
}

class ModbusMasterTCPCore {
  static bool checkLenght(Uint8List reponse) {
    if (reponse.length >= 8) {
      var view = ByteData.view(reponse.buffer);
      int len = view.getUint16(4);
      int function = view.getUint8(7);
      if (function > 0x80) return true;
      return  len + 6 == reponse.length;
    } else {
      return false;
    }
  }

  static dynamic readReponse(
      {required Uint8List response,
      required int count,
      required int slaveId,
      required int functions,
      required int address,
      required int quantity}) {
    var view = ByteData.view(response.buffer);
    int _count = view.getUint16(0);
    int _len = view.getUint16(4);
    int _unitId = view.getUint8(6);
    int _function = view.getUint8(7);
    int lenBuffer = view.getInt8(8);
    if (_unitId != slaveId) {
      return ModbusException.invalidSlaveID;
    }

    if (_function != functions) {
      return lenBuffer;
    }
    if (_count != count) {
      return -1;
    }

    switch (functions) {
      case ModbusFunctions.readCoils:
      case ModbusFunctions.readDiscreteInputs:
        List<bool> resBool = [];
        for (int byte in response.sublist(9, 9 + lenBuffer)) {
          for (int i = 0; i < 8; i++) {
            if (resBool.length < quantity) {
              resBool.add((byte >> i) & 1 == 1);
            } else {
              break;
            }
          }
        }
        return resBool;

      case ModbusFunctions.readInputRegisters:
      case ModbusFunctions.readHoldingRegisters:
        ByteData byteData =
            ByteData.view(response.sublist(9, 9 + lenBuffer).buffer);
        Uint16List uint16List = Uint16List(quantity);
        for (int i = 0; i < uint16List.length; i++) {
          uint16List[i] =
              byteData.getUint16(i * Uint16List.bytesPerElement, Endian.big);
        }
        return uint16List.toList();
    }
    return 0;
  }

  static Uint8List writeRequest(
      int count, int slaveId, int function, int address, List<dynamic> values) {
    Uint8List data = Uint8List(0);
    switch (function) {
      case ModbusFunctions.writeSingleCoil:
        data = Uint8List(4);
        ByteData.view(data.buffer)
          ..setUint16(0, address)
          ..setUint16(2, values[0] ? 0xff00 : 0x0000);
      case ModbusFunctions.writeSingleRegister:
        data = Uint8List(4);
        ByteData.view(data.buffer)
          ..setUint16(0, address)
          ..setUint16(2, values[0]);

      case ModbusFunctions.writeMultipleCoils:
        data = Uint8List(5 + (values.length / 8).ceil());
        ByteData.view(data.buffer)
          ..setUint16(0, address)
          ..setUint16(2, values.length)
          ..setUint8(4, (values.length / 8).ceil());
        for (int i = 0; i < values.length; i += 8) {
          for (int j = 0; j < 8 && i + j < values.length; j++) {
            if (values[i + j] != 0) {
              data[(i ~/ 8) + 5] |= (1 << j);
            }
          }
        }
        break;
      case ModbusFunctions.writeMultipleRegisters:
        data = Uint8List(5 + values.length * 2);
        ByteData.view(data.buffer)
          ..setUint16(0, address)
          ..setUint16(2, values.length)
          ..setUint8(4, values.length * 2);
        for (int i = 0; i < values.length; i++) {
          ByteData.view(data.buffer)
              .setUint16(5 + i * 2, values[i], Endian.big);
        }
        break;
    }
    return _addrequest(count, slaveId, function, data);
  }

  static Uint8List readRequest(
      int count, int slaveId, int function, int address, int amount) {
    var data = Uint8List(4);
    ByteData.view(data.buffer)
      ..setUint16(0, address)
      ..setUint16(2, amount);
    return _addrequest(count, slaveId, function, data);
  }

  static Uint8List _addrequest(
      int count, int slaveId, int function, Uint8List data) {
    Uint8List tcpHeader = Uint8List(7); // Modbus Application Header
    ByteData.view(tcpHeader.buffer)
      ..setUint16(0, count, Endian.big)
      ..setUint16(4, 1 /*unitId*/ + 1 /*fn*/ + data.length, Endian.big)
      ..setUint8(6, slaveId);

    Uint8List fn = Uint8List(1);
    fn[0] = function;
    return Uint8List.fromList(tcpHeader + fn + data);
  }
}
