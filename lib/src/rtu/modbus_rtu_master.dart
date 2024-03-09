import 'dart:async';
import 'dart:typed_data';
import 'package:modbus/src/modbus_abstract.dart';
import 'package:modbus/src/stack.dart';
import 'package:modbus/src/tcp/exceptions.dart';
import 'package:serial/serial.dart';

import 'modbus_rtu_master_core.dart';

class ModbusMasterRTU extends ModbusMaster {
  SerialClient _serial;
  int _slaveId = 1;
  Stack _stack = Stack();
  List<int> _bytes = [];
  int _timeOldEvent = 0;
  int _timeOut = 1000;
  bool _connected = false;

  ModbusMasterRTU(SerialClient serial) : _serial = serial;
  @override
  bool get connected => _connected;

  @override
  void setSlaveId(int slaveId) {
    _slaveId = slaveId;
  }

  Future<Uint8List> _readReponse() async {
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
      throw "Error Read Request";
    }
  }

  @override
  Future<void> close() async {
    _connected = false;
    _serial.close();
  }

  @override
  Future<bool> connect() async {
    if (_connected == false) {
      bool res = await _serial.connect();
      _serial.listen(
        (event) {
          if (DateTime.now().millisecondsSinceEpoch - _timeOldEvent >
              _timeOut) {
            _bytes.clear();
            _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
          } else {
            _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
          }
          _bytes.addAll(event);
        },
        onDone: () {
          _connected = false;
        },
      );
      _connected = res;
      return res;
    }
    return _connected;
  }

  @override
  Future<List<bool>?> readCoils(int address, int quantity) async {
    if (connected) {
      return await _read(0x01, address, quantity);
    }
    return null;
  }

  @override
  Future<List<bool>?> readDiscreteInputs(int address, int quantity) async {
    if (connected) {
      return await _read(0x02, address, quantity);
    }
    return null;
  }

  @override
  Future<List<int>?> readHoldingRegisters(int address, int quantity) async {
    if (connected) {
      return await _read(0x03, address, quantity);
    }
    return null;
  }

  @override
  Future<List<int>?> readInputRegisters(int address, int quantity) async {
    if (connected) {
      return await _read(0x04, address, quantity);
    }
    return null;
  }

  @override
  Future<bool> writeMultipleCoils(int address, List<bool> datas) async {
    if (connected) {
      return await _write(15, address, datas.map((e) => e ? 1 : 0).toList());
    }
    return false;
  }

  @override
  Future<bool> writeMultipleRegisters(int address, List<int> datas) async {
    if (connected) {
      return await _write(16, address, datas);
    }
    return false;
  }

  @override
  Future<bool> writeSingleCoil(int address, bool value) async {
    if (connected) {
      return await _write(5, address, [value ? 0xff00 : 0]);
    }
    return false;
  }

  @override
  Future<bool> writeSingleRegister(int address, int value) async {
    if (connected) {
      return await _write(6, address, [value]);
    }
    return false;
  }

  Future<bool> _write(int func, int address, List<int> datas) async {
    Completer completer = Completer();
    _stack.excute(() async {
      _bytes.clear();
      _serial.write(ModbusRtuCore.writeRequest(
          slaveId: _slaveId, functions: func, address: address, datas: datas));

      final rePonse = await _readReponse();

      final res = ModbusRtuCore.readReponse(
          response: rePonse,
          slaveId: _slaveId,
          functions: func,
          address: address,
          quantity: 0);
      if (!completer.isCompleted) {
        completer.complete(res);
      }
    });

    dynamic res = await completer.future.timeout(
      Duration(milliseconds: _timeOut),
      onTimeout: () {
        return null;
      },
    );
    return res == 0;
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

      final res = ModbusRtuCore.readReponse(
          response: rePonse,
          slaveId: _slaveId,
          functions: func,
          address: address,
          quantity: quantity);
      if (!completer.isCompleted) {
        completer.complete(res);
      }
    });

    return await completer.future.timeout(
      Duration(milliseconds: _timeOut),
      onTimeout: () {
        throw ModbusExceptionString("time out");
      },
    );
  }
}







//








//