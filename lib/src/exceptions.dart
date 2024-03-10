// ignore_for_file: constant_identifier_names

enum ModbusError {
  Invalid_SlaveID,
  Invalid_Function,
  Slave_Error_Return,
  Invalid_CRC,
  Time_Out,
  Error_Read_Request,
  Not_Connect,
  Invalid_Quantity
}

class _ModbusException implements Exception {
  final ModbusError error;

  const _ModbusException(this.error);

  @override
  String toString() => '$error'.replaceAll("_", " ").replaceAll(".", ": ");
}

class ModbusException extends _ModbusException {
  ModbusException(super.error);
}
