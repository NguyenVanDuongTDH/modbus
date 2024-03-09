import 'dart:async';
import 'dart:typed_data';

import 'package:modbus/modbus.dart';
import 'package:modbus/src/stack.dart';
import 'package:modbus/src/tcp/modbus_tcp_master_core.dart';

import 'exceptions.dart';

class ModbusMasterTCP extends ModbusMaster {
  SerialClient _serial;
  int _slaveId = 1;
  Stack _stack = Stack();
  List<int> _bytes = [];
  int _timeOldEvent = 0;
  int _timeOut = 1000;
  int _count = 0;
  bool _connected = false;

  ModbusMasterTCP(SerialClient serial) : _serial = serial;
  @override
  // TODO: implement connected
  bool get connected => _connected;
  @override
  Future<void> close() async {
    _serial.close();
  }

  Future<Uint8List?> _readReponse() async {
    do {
      if (_timeOldEvent == 0) {
        _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
      }
      await Future.delayed(const Duration(microseconds: 1));
    } while (!ModbusMasterTCPCore.checkLenght(Uint8List.fromList(_bytes)) &&
        DateTime.now().millisecondsSinceEpoch - _timeOldEvent < _timeOut);
    _timeOldEvent = 0;
    if (ModbusMasterTCPCore.checkLenght(Uint8List.fromList(_bytes))) {
      Uint8List res = Uint8List.fromList(_bytes);
      _bytes.clear();
      return res;
    } else {
      _bytes.clear();
      return null;
    }
  }

  @override
  Future<bool> connect() async {
    bool res = await _serial.connect();
    _serial.listen(
      (event) {
        if (DateTime.now().millisecondsSinceEpoch - _timeOldEvent > _timeOut) {
          _bytes.clear();
          _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
        } else {
          _timeOldEvent = DateTime.now().millisecondsSinceEpoch;
        }
        _bytes.addAll(event);
        // print(event);
      },
      onDone: () {
        _connected = false;
      },
    );
    _connected = res;
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
    if (quantity < 1 || quantity > 125) throw ModbusAmountException();
    return await _read(0x03, address, quantity);
  }

  @override
  Future<List<int>?> readInputRegisters(int address, int quantity) async {
    if (quantity < 1 || quantity > 125) throw ModbusAmountException();
    return await _read(0x04, address, quantity);
  }

  @override
  void setSlaveId(int slaveId) {
    _slaveId = slaveId;
  }

  @override
  Future<bool> writeMultipleCoils(int address, List<bool> datas) async {
    return await _write(ModbusFunctions.writeMultipleCoils, address, datas);
  }

  @override
  Future<bool> writeMultipleRegisters(int address, List<int> datas) async {
    return await _write(ModbusFunctions.writeMultipleRegisters, address, datas);
  }

  @override
  Future<bool> writeSingleCoil(int address, bool value) async {
    return await _write(ModbusFunctions.writeSingleCoil, address, [value]);
  }

  @override
  Future<bool> writeSingleRegister(int address, int value) async {
    return await _write(ModbusFunctions.writeSingleRegister, address, [value]);
  }

  Future<bool> _write(
    int function,
    int address,
    List<dynamic> values,
  ) async {
    Completer completer = Completer();
    _stack.excute(() async {
      _count < 0xFFF ? _count++ : _count = 0;
      int tempCount = _count;

      _bytes.clear();
      final request = ModbusMasterTCPCore.writeRequest(
          tempCount, _slaveId, function, address, values);
      _serial.write(request);
      final response = await _readReponse();
      completer.complete(ModbusMasterTCPCore.readReponse(
          response: response!,
          count: tempCount,
          slaveId: _slaveId,
          functions: function,
          address: address,
          quantity: values.length));
    });
    dynamic res = await completer.future.timeout(
      Duration(milliseconds: _timeOut),
      onTimeout: () {
        return null;
      },
    );
    return res == 0;
  }

  Future<dynamic> _read(int function, int address, int quantity) async {
    Completer completer = Completer();
    _stack.excute(() async {
      _count < 0xFFF ? _count++ : _count = 0;
      int tempCount = _count;

      _bytes.clear();
      final request = ModbusMasterTCPCore.readRequest(
          tempCount, _slaveId, function, address, quantity);
      _serial.write(request);
      final response = await _readReponse();

      completer.complete(ModbusMasterTCPCore.readReponse(
          response: response!,
          count: tempCount,
          slaveId: _slaveId,
          functions: function,
          address: address,
          quantity: quantity));
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
