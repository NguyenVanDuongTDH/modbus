import 'dart:typed_data';

class ModbusCoreTcp {
  static bool checkLenght(Uint8List reponse) {
    if (reponse.length >= 8) {
      var view = ByteData.view(reponse.buffer);
      int len = view.getUint16(4);
      int function = view.getUint8(7);
      if (function > 0x80) return true;
      return len + 6 == reponse.length;
    } else {
      return false;
    }
  }
}
