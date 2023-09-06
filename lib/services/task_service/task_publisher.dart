import 'dart:convert';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/api/nostr-events.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/utils/cryptography/encrypt.dart';
import 'package:locus/utils/cryptography/utils.dart';
import 'package:locus/utils/location/index.dart';

import 'enums.dart';
import 'task.dart';

class TaskPublisher {
  final Task task;

  const TaskPublisher(this.task);

  // Generates a link that can be used to retrieve the task
  // This link is primarily used for sharing the task to the web app
  // Here's the process:
  // 1. Generate a random password
  // 2. Encrypt the task with the password
  // 3. Publish the encrypted task to a random Nostr relay
  // 4. Generate a link that contains the password and the Nostr relay ID
  Future<String> generateLink(
    final String host, {
    final void Function(TaskLinkPublishProgress progress)? onProgress,
  }) async {
    onProgress?.call(TaskLinkPublishProgress.startsSoon);

    final message = await task.cryptography.generateViewKeyContent();

    onProgress?.call(TaskLinkPublishProgress.encrypting);

    final passwordSecretKey = await generateSecretKey();
    final password = await passwordSecretKey.extractBytes();
    final cipherText = await encryptUsingAES(message, passwordSecretKey);

    onProgress?.call(TaskLinkPublishProgress.publishing);

    final manager = NostrEventsManager(
      relays: task.relays,
      privateKey: task.nostrPrivateKey,
    );
    final publishedEvent = await manager.publishMessage(cipherText, kind: 1001);

    onProgress?.call(TaskLinkPublishProgress.creatingURI);

    final parameters = {
      // Password
      "p": password,
      // Key
      "k": task.nostrPublicKey,
      // ID
      "i": publishedEvent.id,
      // Relay
      "r": task.relays,
    };

    final fragment = base64Url.encode(jsonEncode(parameters).codeUnits);
    final uri = Uri(
      scheme: "https",
      host: host,
      path: "/",
      fragment: fragment,
    );

    onProgress?.call(TaskLinkPublishProgress.done);
    passwordSecretKey.destroy();

    return uri.toString();
  }

  Future<void> publishLocation(
    final LocationPointService locationPoint,
  ) async {
    final eventManager = NostrEventsManager.fromTask(task);

    final rawMessage = jsonEncode(locationPoint.toJSON());
    final message = await task.cryptography.encrypt(rawMessage);

    try {
      await eventManager.publishMessage(message);
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Task ${task.id}",
        "Failed to publish location: $error",
      );

      task.outstandingLocations[locationPoint] = 0;

      rethrow;
    }
  }

  Future<LocationPointService> publishCurrentPosition() async {
    final position = await getCurrentPosition();
    final locationPoint = await LocationPointService.fromPosition(position);

    await publishLocation(locationPoint);

    return locationPoint;
  }

  Future<void> publishOutstandingPositions() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Task ${task.id}",
      "Publishing outstanding locations...",
    );

    // Iterate over point and tries
    for (final entry in task.outstandingLocations.entries) {
      final locationPoint = entry.key;
      final tries = entry.value;

      if (tries >= LOCATION_PUBLISH_MAX_TRIES) {
        FlutterLogs.logInfo(
          LOG_TAG,
          "Task ${task.id}",
          "Skipping location point as it has been published too many times.",
        );

        task.outstandingLocations.remove(locationPoint);

        continue;
      }

      try {
        await publishLocation(locationPoint);

        task.outstandingLocations.remove(locationPoint);
      } catch (error) {
        FlutterLogs.logError(
          LOG_TAG,
          "Task ${task.id}",
          "Failed to publish outstanding location: $error",
        );
      }
    }
  }
}
