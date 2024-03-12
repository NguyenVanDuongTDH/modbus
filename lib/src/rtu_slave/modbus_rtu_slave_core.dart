// // ignore_for_file: curly_braces_in_flow_control_structures

// import 'dart:typed_data';

// import 'package:modbus/modbus.dart';

// ignore_for_file: curly_braces_in_flow_control_structures, prefer_final_fields

import 'dart:typed_data';
import 'package:modbus/src/rtu_slave/modbus_rtu_slave.dart';
import 'package:modbus/src/until.dart';
import 'package:serial/serial.dart';

class ModbusRtuSlaveCore {
  SerialClient _serial;
  int _timeOut = 300;
  List<int> _bytes = [];
  ModbusSlaveRTU _ctx;
  void Function()? onclose;

  ModbusRtuSlaveCore(SerialClient serial, ModbusSlaveRTU ctx)
      : _serial = serial,
        _ctx = ctx {
    serial.listen((event) async {
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
      } while (!checkLength(_bytes) &&
          DateTime.now().millisecondsSinceEpoch - timeStart < _timeOut);
      if (_bytes.length >= 8) {
        process(Uint8List.fromList(_bytes));
      }
      _bytes.clear();
      isloop = false;
    }
  }

  static bool checkLength(List<int> bytes) {
    if (bytes.length > 256) return false;
    if (bytes.length < 8) return false;
    switch (bytes[1]) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        return bytes.length == 8;
      case 15:
      case 16:
        return bytes.length == 9 + bytes[6];
      default:
        return false;
    }
  }

  bool process(Uint8List bytes) {
    if (_checkRequest(bytes)) {
      switch (bytes[1]) {
        case 1:
          _processReadCoils(bytes);
          break;
        case 2:
          _processReadDiscreteInputs(bytes);
          break;
        case 3:
          _processReadHoldingRegisters(bytes);
          break;
        case 4:
          _processReadInputRegisters(bytes);
          break;
        case 5:
          _processWriteSingleCoil(bytes);
          break;
        case 6:
          _processWriteSingleHoldingRegister(bytes);
          break;
        case 15:
          _processWriteMultipleCoils(bytes);
          break;
        case 16:
          _processWriteMultipleHoldingRegisters(bytes);
          break;
        default:
          _exceptionResponse(bytes, 1);
          break;
      }
      return true;
    } else {
      return false;
    }
  }

  void _processWriteMultipleHoldingRegisters(Uint8List bytes) async {
    int startAddress = bytesToWord(bytes[2], bytes[3]);
    int quantity = bytesToWord(bytes[4], bytes[5]);
    if (_ctx.holdingRegisters == null) {
      _exceptionResponse(bytes, 1);
    } else if (_ctx.holdingRegisters!.end - _ctx.holdingRegisters!.start <= 0) {
      _exceptionResponse(bytes, 1);
    }
    //số lượng đọc
    else if (quantity == 0 || quantity > 123 || bytes[6] != (quantity * 2))
      _exceptionResponse(bytes, 3);

    //
    else if (startAddress > (_ctx.holdingRegisters!.end - quantity) ||
        startAddress < _ctx.holdingRegisters!.start)
      _exceptionResponse(bytes, 2);
    else {
      for (int i = 0; i < quantity; i++) {
        _ctx.holdingRegisters!.writeRegisters(
            startAddress + i, bytesToWord(bytes[i * 2 + 7], bytes[i * 2 + 8]));
      }
      _writeResponse(bytes, 6);
    }
  }

  void _processWriteMultipleCoils(Uint8List request) async {
    Uint8List bytes = Uint8List(256)..setAll(0, request);
    int startAddress = bytesToWord(bytes[2], bytes[3]);
    int quantity = bytesToWord(bytes[4], bytes[5]);
    if (_ctx.coils == null || _ctx.coils!.end - _ctx.coils!.start <= 0)
      _exceptionResponse(bytes, 1);
    else if (quantity == 0 ||
        quantity > 1968 ||
        bytes[6] != div8RndUp(quantity))
      _exceptionResponse(bytes, 3);
    else if (startAddress < _ctx.coils!.start ||
        startAddress > (_ctx.coils!.end - quantity))
      _exceptionResponse(bytes, 2);
    else {
      try {
        for (int i = 0; i < quantity; i++) {
          _ctx.coils!.writeCoils(
              startAddress + i, bitRead(bytes[7 + (i >> 3)], i & 7) != 0);
        }
        _writeResponse(bytes, 6);
      } catch (e) {
        _exceptionResponse(bytes, 2);
      }
    }
  }

  void _processWriteSingleHoldingRegister(Uint8List request) async {
    Uint8List bytes = Uint8List(256)..setAll(0, request);
    int address = bytesToWord(bytes[2], bytes[3]);
    int value = bytesToWord(bytes[4], bytes[5]);
    if (_ctx.holdingRegisters == null ||
        _ctx.holdingRegisters!.end - _ctx.holdingRegisters!.start <= 0)
      _exceptionResponse(bytes, 1);
    else if (address > _ctx.holdingRegisters!.end ||
        address < _ctx.holdingRegisters!.start)
      _exceptionResponse(bytes, 2);
    else {
      _ctx.holdingRegisters!.writeRegisters(address, value);
      _writeResponse(bytes, 6);
    }
  }

  void _processWriteSingleCoil(Uint8List request) async {
    Uint8List bytes = Uint8List(256)..setAll(0, request);
    int address = bytesToWord(bytes[2], bytes[3]);
    int value = bytesToWord(bytes[4], bytes[5]);
    if (_ctx.coils == null || _ctx.coils!.end - _ctx.coils!.start <= 0)
      _exceptionResponse(bytes, 1);
    else if (value != 0 && value != 0xFF00)
      _exceptionResponse(bytes, 3);
    else if (address < _ctx.coils!.start || address > _ctx.coils!.end)
      _exceptionResponse(bytes, 2);
    else {
      _ctx.coils!.writeCoils(address, value != 0);
      _writeResponse(bytes, 6);
    }
  }

  void _processReadInputRegisters(Uint8List request) {
    Uint8List bytes = Uint8List(256)..setAll(0, request);
    int startAddress = bytesToWord(bytes[2], bytes[3]);
    int quantity = bytesToWord(bytes[4], bytes[5]);
    if (_ctx.inputRegisters == null ||
        _ctx.inputRegisters!.end - _ctx.inputRegisters!.start <= 0)
      _exceptionResponse(bytes, 1);
    else if (quantity == 0 || quantity > 125)
      _exceptionResponse(bytes, 3);
    else if (startAddress < _ctx.inputRegisters!.start ||
        startAddress > (_ctx.inputRegisters!.end - quantity))
      _exceptionResponse(bytes, 2);
    else {
      try {
        bytes[2] = quantity * 2;
        for (int i = 0; i < quantity; i++) {
          int res = _ctx.inputRegisters!.readInputsRegisters(startAddress + i)!;
          bytes[3 + (i * 2)] = highByte(res);
          bytes[4 + (i * 2)] = lowByte(res);
        }
        _writeResponse(bytes, 3 + bytes[2]);
      } catch (e) {
        _exceptionResponse(bytes, 2);
      }
    }
  }

  void _processReadDiscreteInputs(Uint8List request) {
    Uint8List bytes = Uint8List(256)..setAll(0, request);
    int startAddress = bytesToWord(bytes[2], bytes[3]);
    int quantity = bytesToWord(bytes[4], bytes[5]);
    if (_ctx.discreteInputs == null ||
        _ctx.discreteInputs!.end - _ctx.discreteInputs!.start <= 0)
      _exceptionResponse(bytes, 1);
    else if (quantity == 0 || quantity > 2000)
      _exceptionResponse(bytes, 3);
    else if (startAddress > (_ctx.discreteInputs!.end - quantity) ||
        startAddress < _ctx.discreteInputs!.start)
      _exceptionResponse(bytes, 2);
    else {
      try {
        bytes[2] = div8RndUp(quantity);
        for (int i = 0; i < quantity; i++) {
          bytes[3 + (i >> 3)] = bitWrite(bytes[3 + (i >> 3)], i & 7,
              _ctx.discreteInputs!.readInputs(startAddress + i)! ? 1 : 0);
        }
        _writeResponse(bytes, 3 + bytes[2]);
      } catch (e) {
        _exceptionResponse(bytes, 2);
      }
    }
  }

  void _processReadCoils(Uint8List request) async {
    Uint8List bytes = Uint8List(256)..setAll(0, request);
    int startAddress = bytesToWord(bytes[2], bytes[3]);
    int quantity = bytesToWord(bytes[4], bytes[5]);
    if (_ctx.coils == null || _ctx.coils!.end - _ctx.coils!.start <= 0) {
      _exceptionResponse(bytes, 1);
    } else if (quantity == 0 || quantity > 2000) {
      _exceptionResponse(bytes, 3);
    } else if (startAddress < _ctx.coils!.start ||
        startAddress > (_ctx.coils!.end - quantity)) {
      _exceptionResponse(bytes, 2);
    } else {
      try {
        bytes[2] = div8RndUp(quantity);
        for (int i = 0; i < quantity; i++) {
          bool read = _ctx.coils!.readCoils(startAddress + i)!;
          bytes[3 + (i >> 3)] =
              bitWrite(bytes[3 + (i >> 3)], i & 7, read ? 1 : 0);
        }
        _writeResponse(bytes, 3 + bytes[2]);
      } catch (e) {
        _exceptionResponse(bytes, 2);
      }
    }
  }

  bool _checkRequest(Uint8List request) {
    if (request[0] != _ctx.slaveId && request[0] != 0) return false;
    if (crc16(request, request.length - 2) ==
        request[request.length - 1] << 8 | request[request.length - 2]) {
      return true;
    }
    return false;
  }

  void _writeResponse(Uint8List bytes, int len) async {
    if (bytes[0] != 0) {
      int crc = crc16(bytes, len);
      bytes[len] = lowByte(crc);
      bytes[len + 1] = highByte(crc);
      return _serial.write(bytes, length: len + 2);
    }
  }

  void _exceptionResponse(Uint8List bytes, int code) {
    bytes[1] |= 0x80;
    bytes[2] = code;
    _writeResponse(bytes, 3);
  }

  void _processReadHoldingRegisters(Uint8List request) {
    Uint8List bytes = Uint8List(256)..setAll(0, request);
    int startAddress = bytesToWord(bytes[2], bytes[3]);
    int quantity = bytesToWord(bytes[4], bytes[5]);

    if (_ctx.holdingRegisters == null) {
      _exceptionResponse(bytes, 1);
    } else if (_ctx.holdingRegisters!.end - _ctx.holdingRegisters!.start <= 0) {
      _exceptionResponse(bytes, 1);
    } else if (quantity == 0 || quantity > 125) {
      _exceptionResponse(bytes, 3);
    } else if (startAddress > (_ctx.holdingRegisters!.end - quantity) ||
        startAddress < _ctx.holdingRegisters!.start) {
      _exceptionResponse(bytes, 2);
    } else {
      try {
        bytes[2] = quantity * 2;
        for (int i = 0; i < quantity; i++) {
          int res = _ctx.holdingRegisters!.readRegisters(startAddress + i)!;
          bytes[3 + (i * 2)] = highByte(res);
          bytes[4 + (i * 2)] = lowByte(res);
        }
        _writeResponse(bytes, 3 + bytes[2]);
      } catch (e) {
        _exceptionResponse(bytes, 2);
      }
    }
  }
}
