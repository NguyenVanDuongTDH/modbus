// ignore_for_file: prefer_final_fields

import 'package:serial/serial.dart';

import '../modbus_abstract.dart';
import 'tcp_slave_core.dart';

class ModbusSlaveTCP extends ModbusSlave {
  SerialServer _server;
  List<ModbusTCPSlaveCore> _modbusCores = [];
  ModbusSlaveTCP(SerialServer server) : _server = server;
  @override
  Future<bool> bind() async {
    await _server.bind();
    _server.listen((socket) {
      final core = ModbusTCPSlaveCore(socket, this);
      _modbusCores.add(core);
      core.onclose = () {
        _modbusCores.remove(core);
      };
    });
    return true;
  }

  @override
  Future<void> close() async {
    _server.close();
  }

  @override
  void configHoldingRegisters(HoldingRegistersConfig config) {
    holdingRegisters = config;
  }

  @override
  void configCoils(CoilsConfig config) {
    coils = config;
  }

  @override
  void configDiscreteInputs(DiscreteInputsConfig config) {
    discreteInputs = config;
  }

  @override
  void configureInputRegisters(InputRegistersConfig config) {
    inputRegisters = config;
  }
}
