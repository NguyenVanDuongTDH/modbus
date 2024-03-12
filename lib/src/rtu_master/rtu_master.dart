// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'package:modbus/src/modbus_abstract.dart';
import 'package:modbus/src/rtu_master/rtu_respose.dart';
import 'package:modbus/src/stack.dart';
import 'package:modbus/src/exceptions.dart';
import 'package:modbus/src/tcp_master/modbus_tcp_master_core.dart';
import 'package:serial/serial.dart';
import 'rtu_request.dart';

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

  RtuRequest? _ctx;

  Future<RtuResPonse> _readReponse() async {
    final response = RtuResPonse();
    do {
      await Future.delayed(const Duration(milliseconds: 1));
    } while (!response.process(_bytes, _ctx!, _timeOut));
    _bytes.clear();
    return response;
  }

  @override
  Future<void> close() async {
    _connected = false;
    _serial.close();
  }

  bool _outTime() {
    return DateTime.now().millisecondsSinceEpoch - _timeOldEvent > _timeOut;
  }

  @override
  Future<bool> connect() async {
    if (_connected == false) {
      bool res = await _serial.connect();
      if (res) {
        _serial.listen(
          (event) {
            if (_outTime()) {
              _bytes.clear();
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
    }
    return _connected;
  }

  @override
  Future<List<bool>> readCoils(int address, int quantity) async {
    return (await _read(ModbusFunctions.readCoils, address, quantity))
        .map((e) => e != 0)
        .toList();
  }

  @override
  Future<List<bool>> readDiscreteInputs(int address, int quantity) async {
    return (await _read(ModbusFunctions.readDiscreteInputs, address, quantity))
        .map((e) => e != 0)
        .toList();
  }

  @override
  Future<List<int>> readHoldingRegisters(int address, int quantity) async {
    return await _read(ModbusFunctions.readHoldingRegisters, address, quantity);
  }

  @override
  Future<List<int>> readInputRegisters(int address, int quantity) async {
    if (connected) {
      return await _read(ModbusFunctions.readInputRegisters, address, quantity);
    } else {
      throw ModbusException(ModbusError.Not_Connect);
    }
  }

  @override
  Future<bool> writeMultipleCoils(int address, List<bool> datas) async {
    if (connected) {
      return await _write(ModbusFunctions.writeMultipleCoils, address,
          datas.map((e) => e ? 1 : 0).toList());
    } else {
      throw ModbusException(ModbusError.Not_Connect);
    }
  }

  @override
  Future<bool> writeMultipleRegisters(int address, List<int> datas) async {
    if (connected) {
      return await _write(
          ModbusFunctions.writeMultipleRegisters, address, datas);
    } else {
      throw ModbusException(ModbusError.Not_Connect);
    }
  }

  @override
  Future<bool> writeSingleCoil(int address, bool value) async {
    if (connected) {
      return await _write(
          ModbusFunctions.writeSingleCoil, address, [value ? 0xff00 : 0]);
    } else {
      throw ModbusException(ModbusError.Not_Connect);
    }
  }

  @override
  Future<bool> writeSingleRegister(int address, int value) async {
    if (connected) {
      return await _write(
          ModbusFunctions.writeSingleRegister, address, [value]);
    } else {
      throw ModbusException(ModbusError.Not_Connect);
    }
  }

  Future<bool> _write(int function, int address, List<int> datas) async {
    int index = 0;
    if (!connected) {
      throw ModbusException(ModbusError.Not_Connect);
    }
    do {
      try {
        return await __write(function, address, datas);
      } catch (e) {
        if (e is ModbusException &&
            e.equals(ModbusError.Invalid_CRC) &&
            index < 3) {
          index++;
        } else {
          rethrow;
        }
      }
    } while (index < 3);
    throw ModbusException(ModbusError.Done_Know);
  }

  Future<bool> __write(int function, int address, List<int> datas) async {
    Completer<bool> completer = Completer();
    _stack.excute(() async {
      _ctx = RtuRequest.write(
          slaveId: _slaveId,
          function: function,
          address: address,
          datas: datas);
      _bytes.clear();
      _serial.write(_ctx!.request);

      final res = await _readReponse();
      if (res.error != ModbusError.Not_Error) {
        completer.completeError(res.error);
      } else {
        completer.complete(res.response[0] == 0);
      }
    });
    return await completer.future;
  }

  Future<List<int>> _read(int function, int address, int quantity) async {
    int index = 0;
    if (!connected) {
      throw ModbusException(ModbusError.Not_Connect);
    }
    do {
      try {
        return await __read(function, address, quantity);
      } catch (e) {
        if (index < 3 && e is ModbusException) {
          if (e.equals(ModbusError.Invalid_CRC)) {
            index += 1;
          }
        } else {
          rethrow;
        }
      }
    } while (index < 3);
    throw ModbusException(ModbusError.Done_Know);
  }

  Future<List<int>> __read(int function, int address, int quantity) async {
    Completer completer = Completer();
    _stack.excute(() async {
      _ctx = RtuRequest.read(
          slaveId: _slaveId,
          function: function,
          address: address,
          quantity: quantity);
      _bytes.clear();
      _serial.write(_ctx!.request);
      final res = await _readReponse();
      if (res.error != ModbusError.Not_Error) {
        completer.completeError(res.error);
      } else {
        completer.complete(res.response);
      }
    });
    return await completer.future;
  }
}







//








//