import 'dart:typed_data';

int lowByte(int w) {
  return w & 0xff;
}

int highByte(int w) {
  return (w >> 8) & 0xff;
}

int bitRead(int value, int bit) {
  return (value >> bit) & 0x01;
}

int bitSet(int value, int bit) {
  return value | (1 << bit);
}

int bitClear(int value, int bit) {
  return value & ~(1 << bit);
}

int bitToggle(int value, int bit) {
  return value ^ (1 << bit);
}

int bitWrite(int value, int bit, int bitValue) {
  return bitValue != 0 ? bitSet(value, bit) : bitClear(value, bit);
}

int word(int h, int l) {
  return (h << 8) | l;
}

int crc16_update(int crc, int a) {
  int i;
  crc ^= a;
  for (i = 0; i < 8; ++i) {
    if (crc & 1 != 0) {
      crc = (crc >> 1) ^ 0xA001;
    } else {
      crc = (crc >> 1);
    }
  }
  return crc;
}

int crc16(Uint8List buf, int len) {
  int crc = 0xFFFF;

  for (var i = 0; i < len; i++) {
    crc ^= buf[i];
    for (int i = 0; i < 8; i++) {
      if ((crc & 0x0001) != 0) {
        crc >>= 1;
        crc ^= 0xA001;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc;
}

int div8RndUp(int value) {
  return (value + 7) >> 3;
}

int bytesToWord(int high, int low) {
  return (high << 8) | low;
}
