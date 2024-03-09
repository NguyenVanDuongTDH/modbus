class ModbusException implements Exception {
  final String msg;

  const ModbusException(this.msg);

  @override
  String toString() => 'MODBUS ERROR: $msg';
}
class ModbusExceptionString extends ModbusException {
  ModbusExceptionString(String msg) : super(msg);
}
