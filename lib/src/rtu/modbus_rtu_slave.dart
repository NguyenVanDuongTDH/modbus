import 'package:modbus/modbus.dart';
import 'package:modbus/src/rtu/modbus_rtu_slave_core.dart';

class ModbusSlaveRTU extends ModbusSlave {
  SerialServer _server;
  List<ModbusRtuSlaveCore> _modbusCores = [];
  ModbusSlaveRTU(SerialServer server) : _server = server;
  @override
  Future<bool> bind() async {
    await _server.bind();
    _server.listen((socket) {
      final core = ModbusRtuSlaveCore(socket, this);
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
