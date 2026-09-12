import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/app_failure.dart';

/// Writes an export somewhere the user can find it again without going through
/// the share sheet.
///
/// Android has no path-based route into the public Downloads folder from API
/// 29 on — and `path_provider` therefore offers none — so the platform side
/// puts the bytes there through MediaStore. iOS has no Downloads folder at
/// all; the app's own Documents directory is the equivalent, and it is the one
/// the Files app shows under "Poisa".
class FileSaveService {
  const FileSaveService();

  static const MethodChannel _channel = MethodChannel(
    'com.kori.moneytracker/downloads',
  );

  /// Saves [bytes] as [fileName] and returns the folder name to show the user.
  Future<String> saveToDownloads({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final String? location = await _channel.invokeMethod<String>(
          'saveToDownloads',
          <String, Object?>{
            'fileName': fileName,
            'mimeType': mimeType,
            'bytes': bytes,
          },
        );
        return location ?? 'Downloads';
      }

      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return _displayName(directory.path);
    } on PlatformException catch (error) {
      throw AppFailure(
        FailureKind.unknown,
        debugMessage: 'Save to downloads failed: ${error.message}',
      );
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Writes [bytes] to a private temporary file, for handing to the share
  /// sheet. Nothing here is meant to outlive the share.
  Future<File> writeTemporary({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// The last path segment, which is what a user recognises — the full
  /// sandbox path is noise in a snackbar.
  static String _displayName(String path) {
    final List<String> parts = path.split(Platform.pathSeparator)
      ..removeWhere((String part) => part.isEmpty);
    return parts.isEmpty ? path : parts.last;
  }
}
