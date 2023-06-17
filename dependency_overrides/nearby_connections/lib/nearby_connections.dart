library nearby_connections;

import 'dart:typed_data';

class Payload {
  int id;
  PayloadType type;

  Uint8List? bytes;

  @Deprecated('Use uri instead, Only available on Android 10 and below.')
  String? filePath;
  String? uri;

  Payload({
    required this.id,
    this.bytes,
    this.type = PayloadType.NONE,
    this.filePath,
    this.uri,
  });
}

class PayloadTransferUpdate {
  int id, bytesTransferred, totalBytes;
  PayloadStatus status;

  PayloadTransferUpdate({
    required this.id,
    required this.bytesTransferred,
    required this.totalBytes,
    this.status = PayloadStatus.NONE,
  });
}

class ConnectionInfo {
  String endpointName, authenticationToken;
  bool isIncomingConnection;

  ConnectionInfo(this.endpointName, this.authenticationToken, this.isIncomingConnection);
}

enum Strategy { P2P_CLUSTER, P2P_STAR, P2P_POINT_TO_POINT }

enum Status { CONNECTED, REJECTED, ERROR }

enum PayloadStatus { NONE, SUCCESS, FAILURE, IN_PROGRESS, CANCELED }

enum PayloadType { NONE, BYTES, FILE, STREAM }

typedef void OnConnectionInitiated(String endpointId, ConnectionInfo connectionInfo);
typedef void OnConnectionResult(String endpointId, Status status);
typedef void OnDisconnected(String endpointId);

typedef void OnEndpointFound(String endpointId, String endpointName, String serviceId);
typedef void OnEndpointLost(String? endpointId);

typedef void OnPayloadReceived(String endpointId, Payload payload);

typedef void OnPayloadTransferUpdate(String endpointId, PayloadTransferUpdate payloadTransferUpdate);

class Nearby {
  Future<bool> checkLocationPermission() {
    throw UnimplementedError();
  }

  Future<bool> askLocationPermission() {
    throw UnimplementedError();
  }

  Future<bool> checkExternalStoragePermission() {
    throw UnimplementedError();
  }

  Future<bool> checkBluetoothPermission() {
    throw UnimplementedError();
  }

  Future<bool> checkLocationEnabled() {
    throw UnimplementedError();
  }

  Future<bool> enableLocationServices() {
    throw UnimplementedError();
  }

  void askExternalStoragePermission() {
    throw UnimplementedError();
  }

  void askBluetoothPermission() {
    throw UnimplementedError();
  }

  void askLocationAndExternalStoragePermission() {
    throw UnimplementedError();
  }

  Future<bool> copyFileAndDeleteOriginal(String sourceUri, String destinationFilepath) {
    throw UnimplementedError();
  }

  Future<bool> startAdvertising(
    String userNickName,
    Strategy strategy, {
    required OnConnectionInitiated onConnectionInitiated,
    required OnConnectionResult onConnectionResult,
    required OnDisconnected onDisconnected,
    String serviceId = "com.pkmnapps.nearby_connections",
  }) {
    throw UnimplementedError();
  }

  Future<void> stopAdvertising() {
    throw UnimplementedError();
  }

  Future<bool> startDiscovery(
    String userNickName,
    Strategy strategy, {
    required OnEndpointFound onEndpointFound,
    required OnEndpointLost onEndpointLost,
    String serviceId = "com.pkmnapps.nearby_connections",
  }) {
    throw UnimplementedError();
  }

  Future<void> stopDiscovery() {
    throw UnimplementedError();
  }

  Future<void> stopAllEndpoints() {
    throw UnimplementedError();
  }

  Future<void> disconnectFromEndpoint(String endpointId) {
    throw UnimplementedError();
  }

  Future<bool> requestConnection(
    String userNickName,
    String endpointId, {
    required OnConnectionInitiated onConnectionInitiated,
    required OnConnectionResult onConnectionResult,
    required OnDisconnected onDisconnected,
  }) {
    throw UnimplementedError();
  }

  Future<bool> acceptConnection(
    String endpointId, {
    required OnPayloadReceived onPayLoadRecieved,
    OnPayloadTransferUpdate? onPayloadTransferUpdate,
  }) {
    throw UnimplementedError();
  }

  Future<bool> rejectConnection(String endpointId) {
    throw UnimplementedError();
  }

  Future<void> sendBytesPayload(String endpointId, Uint8List bytes) {
    throw UnimplementedError();
  }

  Future<int> sendFilePayload(String endpointId, String filePath) {
    throw UnimplementedError();
  }

  Future<void> cancelPayload(int payloadId) {
    throw UnimplementedError();
  }
}
