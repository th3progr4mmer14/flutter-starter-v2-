import 'package:flutter_starter_v2/features/devices/domain/device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Device conserva sus datos al pasar por JSON', () {
    const device = Device(
      id: '1',
      name: 'Sensor A1',
      location: 'Planta 1',
      type: DeviceType.sensor,
      status: DeviceStatus.online,
      threshold: 80,
      latitude: 19.43,
      longitude: -99.13,
    );

    final copy = Device.fromJson(device.toJson());

    expect(copy.name, device.name);
    expect(copy.status, device.status);
    expect(copy.hasLocation, isTrue);
    expect(copy.latitude, device.latitude);
  });
}
