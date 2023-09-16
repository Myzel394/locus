import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/services/location_alarm_service/enums.dart';
import 'package:locus/services/location_alarm_service/index.dart';
import 'package:locus/services/location_point_service.dart';

// DuckDuckGo's headquarter
final CENTER = LatLng(40.04114, -75.48702);
const RADIUS = 100.0;
final INSIDE_POINT = LatLng(40.04114, -75.48702);
// Some random point in Russia - this should be pretty much outside the radius
final OUTSIDE_POINT = LatLng(60.14924, 63.49002);
final MAYBE_POINT = LatLng(40.04136, -75.48662);

void main() {
  group("Radius based location with whenEnter", () {
    final alarm = GeoLocationAlarm.create(
      type: RadiusBasedRegionLocationAlarmType.whenEnter,
      center: CENTER,
      radius: RADIUS,
      zoneName: "Test",
    );

    test("works on enter with definitive locations", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(OUTSIDE_POINT),
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
        ),
        LocationAlarmTriggerType.yes,
      );
    });

    test("enter does not work on leave", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
          LocationPointService.dummyFromLatLng(OUTSIDE_POINT),
        ),
        LocationAlarmTriggerType.no,
      );
    });

    test("works with maybe low accuracy as first point", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(INSIDE_POINT, accuracy: 200),
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
        ),
        LocationAlarmTriggerType.yes,
      );
    });

    test("does not work with maybe point as second point", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
          LocationPointService.dummyFromLatLng(MAYBE_POINT, accuracy: 80),
        ),
        LocationAlarmTriggerType.no,
      );
    });
  });

  group("Radius based location with whenLeave", () {
    final alarm = GeoLocationAlarm.create(
      type: RadiusBasedRegionLocationAlarmType.whenLeave,
      center: CENTER,
      radius: RADIUS,
      zoneName: "Test",
    );

    test("works on leave with definitive locations", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
          LocationPointService.dummyFromLatLng(OUTSIDE_POINT),
        ),
        LocationAlarmTriggerType.yes,
      );
    });

    test("leave does not work on enter", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(OUTSIDE_POINT),
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
        ),
        LocationAlarmTriggerType.no,
      );
    });

    test("works with maybe low accuracy as first point", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(INSIDE_POINT, accuracy: 200),
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
        ),
        LocationAlarmTriggerType.no,
      );
    });

    test("does not work with maybe point as second point", () {
      expect(
        alarm.check(
          LocationPointService.dummyFromLatLng(INSIDE_POINT),
          LocationPointService.dummyFromLatLng(MAYBE_POINT, accuracy: 80),
        ),
        LocationAlarmTriggerType.no,
      );
    });
  });
}
