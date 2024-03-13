import 'dart:typed_data';
import 'package:modbus/modbus.dart';
import 'package:modbus/src/tcp_master/modbus_tcp_master_core.dart';
import 'package:modbus/src/tcp_master_test/tcp_request.dart';

class ModbusTcpReponse {
  List<int> response = [];
  ModbusError error = ModbusError.Not_Error;
  int startTime = DateTime.now().millisecondsSinceEpoch;
  void clear() {
    response.clear();
    error = ModbusError.Not_Error;
  }

  bool process(List<int> bytes, ModbusTcpRequest ctx, int timeOut) {
    if (DateTime.now().millisecondsSinceEpoch - startTime > timeOut) {
      error = ModbusError.Time_Out;
      return true;
    }
    if (bytes.length < 5) {
      return false;
    }
    if (checkError(bytes, ctx)) {
      return true;
    }

    switch (bytes[1]) {
      case ModbusFunctions.readCoils:
      case ModbusFunctions.readDiscreteInputs:
      case ModbusFunctions.readInputRegisters:
      case ModbusFunctions.readHoldingRegisters:
        return checkReadReponse(bytes, ctx);
      case ModbusFunctions.writeSingleCoil:
      case ModbusFunctions.writeSingleRegister:
      case ModbusFunctions.writeMultipleCoils:
      case ModbusFunctions.writeMultipleRegisters:
        return checkWriteRepose(bytes, ctx);
      default:
        return checkError(bytes, ctx);
    }
  }

  bool checkError(List<int> bytes, ModbusTcpRequest ctx) {
    if (bytes[6] != ctx.slaveId) {
      //slaveid tcp
      error = ModbusError.Invalid_SlaveID;
      return true;
    }
    if (bytes[7] == ctx.function | 0x80) {
      //error tcp
      error = ModbusError.Slave_Error_Return;
      return true;
    }
    if (bytes[7] != ctx.function) {
      //function tcp
      error = ModbusError.Invalid_Function;
      return true;
    }

    return false;
  }

  bool checkWriteRepose(List<int> bytes, ModbusTcpRequest ctx) {
    if (bytes.length == 8) {
      //TODO
      response.clear();
      response.add(0);
      return true;
    } else if (bytes.length < 8) {
      return false;
    } else {
      error = ModbusError.Done_Know;
      return true;
    }
  }

  bool checkReadReponse(List<int> bytes, ModbusTcpRequest ctx) {
    if (bytes.length < 5 + bytes[2]) {
      return false;
    } else if (bytes.length > 5 + bytes[2]) {
      error = ModbusError.Error_Read_Request;
      return true;
    }
   
    switch (bytes[1]) {
      case ModbusFunctions.readCoils:
      case ModbusFunctions.readDiscreteInputs:
        response.clear();
        for (int byte in bytes.sublist(3, 3 + bytes[2])) {
          for (int i = 0; i < 8; i++) {
            if (response.length < ctx.quantity) {
              response.add((byte >> i) & 1);
            } else {
              break;
            }
          }
        }
        return true;

      case ModbusFunctions.readInputRegisters:
      case ModbusFunctions.readHoldingRegisters:
        response.clear();
        ByteData byteData = ByteData.view(
            Uint8List.fromList(bytes.sublist(3, 3 + bytes[2])).buffer);
        for (int i = 0; i < ctx.quantity; i++) {
          response.add(
              byteData.getUint16(i * Uint16List.bytesPerElement, Endian.big));
        }
        return true;
      default:
        error = ModbusError.Done_Know;
        return true;
    }
  }


}
