import 'package:gms_check/gms_check.dart';
import 'package:locus/constants/app.dart';

bool isUsingWrongAppFlavor() => isGMSFlavor != GmsCheck().isGmsAvailable;
