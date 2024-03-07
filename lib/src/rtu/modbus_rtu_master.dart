import 'dart:async';
import 'dart:typed_data';
import 'package:modbus/src/modbus_abstract.dart';
import 'package:modbus/src/stack.dart';
import 'package:serial/serial.dart';

import 'modbus_rtu_master_core.dart';

class ModbusMasterRTU extends ModbusMaster {
  SerialClient _serial;
  int _slaveId = 1;
  Stack _stack = Stack();
  List<int> _bytes = [];
  int _timeOldEvent = 0;
  int _timeOut = 1000;

  ModbusMasterRTU(SerialClient serial) : _serial = serial;

  @override
  void setSlaveId(int slaveId) {
    _slaveId = slaveId;
  }

  Future<Uint8List?> _readReponse() async {
    do {
      if (_timeOldEvent == 0) {
        _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
      }
      await Future.delayed(const Duration(microseconds: 1));
    } while (!ModbusRtuCore.checkLengthRePonse(_bytes) &&
        DateTime.now().millisecondsSinceEpoch - _timeOldEvent < _timeOut);
    _timeOldEvent = 0;
    if (ModbusRtuCore.checkLengthRePonse(_bytes)) {
      Uint8List res = Uint8List.fromList(_bytes);
      _bytes.clear();
      return res;
    } else {
      _bytes.clear();
      return null;
    }
  }

  @override
  Future<void> close() async {
    _serial.close();
  }

  @override
  Future<bool> connect() async {
    bool res = await _serial.connect();
    _serial.listen((event) {
      if (DateTime.now().millisecondsSinceEpoch - _timeOldEvent > _timeOut) {
        _bytes.clear();
        _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
      } else {
        _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
      }
      _bytes.addAll(event);
    });
    return res;
  }

  @override
  Future<List<bool>?> readCoils(int address, int quantity) async {
    return await _read(0x01, address, quantity);
  }

  @override
  Future<List<bool>?> readDiscreteInputs(int address, int quantity) async {
    return await _read(0x02, address, quantity);
  }

  @override
  Future<List<int>?> readHoldingRegisters(int address, int quantity) async {
    return await _read(0x03, address, quantity);
  }

  @override
  Future<List<int>?> readInputRegisters(int address, int quantity) async {
    return await _read(0x04, address, quantity);
  }

  @override
  Future<bool> writeMultipleCoils(int address, List<bool> datas) async {
    return await _write(15, address, datas.map((e) => e ? 1 : 0).toList()) == 0;
  }

  @override
  Future<bool> writeMultipleRegisters(int address, List<int> datas) async {
    return await _write(16, address, datas) == 0;
  }

  @override
  Future<bool> writeSingleCoil(int address, bool value) async {
    return await _write(5, address, [value ? 0xff00 : 0]) == 0;
  }

  @override
  Future<bool> writeSingleRegister(int address, int value) async {
    return await _write(6, address, [value]) == 0;
  }

  Future<int> _write(int func, int address, List<int> datas) async {
    Completer completer = Completer();
    _stack.excute(() async {
      _bytes.clear();
      _serial.write(ModbusRtuCore.writeRequest(
          slaveId: _slaveId, functions: func, address: address, datas: datas));

      final rePonse = await _readReponse();

      if (rePonse != null) {
        final res = ModbusRtuCore.readReponse(
            response: rePonse,
            slaveId: _slaveId,
            functions: func,
            address: address,
            quantity: 0);
        if (!completer.isCompleted) {
          completer.complete(res);
        }
      }
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    dynamic res = await completer.future.timeout(
      Duration(milliseconds: _timeOut),
      onTimeout: () {
        return null;
      },
    );
    return res;
  }

  Future<dynamic> _read(int func, int address, int quantity) async {
    Completer completer = Completer();
    _stack.excute(() async {
      _bytes.clear();
      _serial.write(ModbusRtuCore.readRequest(
          slaveId: _slaveId,
          functions: func,
          address: address,
          quantity: quantity));

      final rePonse = await _readReponse();
      if (rePonse != null) {
        final res = ModbusRtuCore.readReponse(
            response: rePonse,
            slaveId: _slaveId,
            functions: func,
            address: address,
            quantity: quantity);
        if (!completer.isCompleted) {
          completer.complete(res);
        }
      }
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    dynamic res = await completer.future.timeout(
      Duration(milliseconds: _timeOut),
      onTimeout: () {
        return null;
      },
    );
    if (res is int) {
      return null;
    } else {
      return res;
    }
  }
}







//








//