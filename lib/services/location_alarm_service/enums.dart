enum LocationAlarmTriggerType {
  yes,
  no,
  maybe,
}

enum LocationAlarmType {
  geo,
  proximity,
  // Required for migration, same as `geo`
  radiusBasedRegion,
}

enum LocationRadiusBasedTriggerType {
  whenEnter,
  whenLeave,
}
