// ignore_for_file: non_constant_identifier_names

import 'package:modbus/modbus.dart';
import 'package:modbus/src/rtu_slave/modbus_rtu_slave.dart';
import 'package:modbus/src/rtu_master/rtu_master.dart';
import 'package:serial/serial.dart';

import 'tcp_master/modbus_tcp_master.dart';

abstract class ModbusMaster {
  static ModbusMasterRTUTest RTU(SerialClient serial) {
    return ModbusMasterRTUTest(serial);
  }
  static ModbusMasterTCP TCP(SerialClient serial) {
    return ModbusMasterTCP(serial);
  }

  bool get connected;

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
  static ModbusSlaveRTU RTU(SerialServer server) {
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

  factory HoldingRegistersConfig.fromList(List<int> holdings) {
    return HoldingRegistersConfig(0, holdings.length,
        writeRegisters: (address, value) => holdings[address] = value,
        readRegisters: (address) => holdings[address]);
  }
}

class CoilsConfig {
  int start;
  int end;
  void Function(int address, bool value) writeCoils;
  bool? Function(int address) readCoils;
  CoilsConfig(this.start, this.end,
      {required this.writeCoils, required this.readCoils});
}
