/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'src/modbus_abstract.dart'
    show
        CoilsConfig,
        DiscreteInputsConfig,
        HoldingRegistersConfig,
        InputRegistersConfig,
        ModbusMaster,
        ModbusSlave;
export 'package:serial/serial.dart'
    show
        SerialClient,
        SerialClientTCP,
        SerialServer,
        SerialServerTCP,
        SerialWindowsMasterUSB,
        SerialWindowsServerUSB,
        SerialPortParity;

// TODO: Export any libraries intended for clients of this package.
