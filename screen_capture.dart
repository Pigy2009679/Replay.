import 'package:flutter/services.dart';

class RecordingFile {
  final String path;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;

  RecordingFile({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  factory RecordingFile.fromMap(Map<dynamic, dynamic> map) {
    return RecordingFile(
      path: map['path'] as String,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      sizeBytes: map['sizeBytes'] as int,
    );
  }

  String get dateLabel {
    final d = createdAt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get sizeLabel {
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ScreenCapture {
  static const _channel = MethodChannel('com.replay.app/screen_capture');

  Future<bool> startRecording() async {
    try {
      return await _channel.invokeMethod<bool>('startRecording') ?? false;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to start screen recording.');
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _channel.invokeMethod('pauseRecording');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to pause recording.');
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _channel.invokeMethod('resumeRecording');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to resume recording.');
    }
  }

  Future<void> stopRecording() async {
    try {
      await _channel.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to stop recording.');
    }
  }

  Future<List<RecordingFile>> listRecordings() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('listRecordings') ?? [];
      return result
          .whereType<Map<dynamic, dynamic>>()
          .map(RecordingFile.fromMap)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on PlatformException {
      return [];
    }
  }
}
