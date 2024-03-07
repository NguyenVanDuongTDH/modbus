import 'package:modbus/src/rtu/modbus_rtu_master.dart';
import 'package:modbus/src/rtu/modbus_rtu_slave.dart';
import 'package:serial/serial.dart';

abstract class ModbusMaster {
  static ModbusMasterRTU RTU(SerialClient serial) {
    return ModbusMasterRTU(serial);
  }
  void setSlaveId(int slaveId);

  Future<bool> connect();

  Future<void> close();

  Future<List<bool>?> readCoils(int address, int quantity);

  Future<List<bool>?> readDiscreteInputs(int address, int quantity);

  Future<List<int>?> readHoldingRegisters(int address, int quantity);

  Future<List<int>?> readInputRegisters(int address, int quantity);

  Future<bool> writeMultipleCoils(int address, List<bool> datas);

  Future<bool> writeMultipleRegisters(int address, List<int> datas);

  Future<bool> writeSingleCoil(int address, bool value);

  Future<bool> writeSingleRegister(int address, int value);
}

abstract class ModbusSlave {
  ModbusSlaveRTU RTU(SerialServer server) {
    return ModbusSlaveRTU(server);
  }

  int slaveId = 1;
  Future<bool> bind();
  Future<void> close();
  HoldingRegistersConfig? holdingRegisters;
  void configHoldingRegisters(HoldingRegistersConfig config);
  CoilsConfig? coils;
  void configCoils(CoilsConfig config);
  DiscreteInputsConfig? discreteInputs;
  void configDiscreteInputs(DiscreteInputsConfig config);
  InputRegistersConfig? inputRegisters;
  void configureInputRegisters(InputRegistersConfig config);
}

class InputRegistersConfig {
  int start;
  int end;
  int? Function(int address) readInputsRegisters;
  InputRegistersConfig(this.start, this.end,
      {required this.readInputsRegisters});
}

class DiscreteInputsConfig {
  int start;
  int end;
  bool? Function(int address) readInputs;
  DiscreteInputsConfig(this.start, this.end, {required this.readInputs});
}

class HoldingRegistersConfig {
  int start;
  int end;
  void Function(int address, int value) writeRegisters;
  int? Function(int address) readRegisters;
  HoldingRegistersConfig(this.start, this.end,
      {required this.writeRegisters, required this.readRegisters});
}

class CoilsConfig {
  int start;
  int end;
  void Function(int address, bool value) writeCoils;
  bool? Function(int address) readCoils;
  CoilsConfig(this.start, this.end,
      {required this.writeCoils, required this.readCoils});
}
