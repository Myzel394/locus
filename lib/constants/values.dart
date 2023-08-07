import 'package:flutter/services.dart';

const REPOSITORY_URL = "https://github.com/Myzel394/locus";
const TRANSLATION_HELP_URL = "https://github.com/Myzel394/locus";
const DONATION_URL = "https://github.com/Myzel394/locus";
const APK_RELEASES_URL = "https://github.com/Myzel394/locus/releases";

const BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER = 25;

const LOCATION_FETCH_TIME_LIMIT = Duration(minutes: 5);
const LOCATION_INTERVAL = Duration(minutes: 1);

const TRANSFER_DATA_USERNAME = "locus_transfer";
final TRANSFER_SUCCESS_MESSAGE = Uint8List.fromList([1, 2, 3, 4]);

const CURRENT_APP_VERSION = "0.14.0";

const LOG_TAG = "LocusLog";

const HTTP_TIMEOUT = Duration(seconds: 30);
const MAYBE_TRIGGER_MINIMUM_TIME_BETWEEN = Duration(hours: 4);

const BATTERY_SAVER_ENABLED_MINIMUM_TIME_BETWEEN_HEADLESS_RUNS =
    Duration(minutes: 60);

const LIVE_LOCATION_STALE_DURATION = Duration(minutes: 1);

const LOCATION_POLYLINE_OPAQUE_AMOUNT_THRESHOLD = 100;

const LOCATION_MERGE_DISTANCE_THRESHOLD = 75.0;
