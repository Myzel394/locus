import 'package:flutter_test/flutter_test.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/services/location_point_service.dart';

// DuckDuckGo's headquarter
final CENTER = LatLng(40.04114, -75.48702);
final RADIUS = 100.0;
final INSIDE_POINT = LatLng(40.04114, -75.48702);
// Some random point in Russia - this should pretty much be outside the radius
final OUTSIDE_POINT = LatLng(60.14924, 63.49002);

void main() {
  group("Radius based location when enter", () {
    final alarm = RadiusBasedRegionLocationAlarm(
      type: RadiusBasedRegionLocationAlarmType.whenEnter,
      center: CENTER,
      radius: RADIUS,
      zoneName: "Test",
    );

    test("works with definitive locations", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(OUTSIDE_POINT),
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
        ),
        LocationAlarmTriggerType.yes,
      );
    });
  });
}
