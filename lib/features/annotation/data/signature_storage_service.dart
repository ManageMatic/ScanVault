import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/digital_signature_model.dart';

class SignatureStorageService {
  const SignatureStorageService();

  Future<Directory> _getSignaturesDir(String userId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'users', userId, 'signatures'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _getMetadataFile(String userId) async {
    final dir = await _getSignaturesDir(userId);
    return File(p.join(dir.path, 'signatures_metadata.json'));
  }

  Future<List<DigitalSignature>> getSignatures(String userId) async {
    try {
      final metaFile = await _getMetadataFile(userId);
      if (!await metaFile.exists()) return [];

      final content = await metaFile.readAsString();
      if (content.trim().isEmpty) return [];

      final list = jsonDecode(content) as List<dynamic>;
      final result = <DigitalSignature>[];
      for (final item in list) {
        final sig = DigitalSignature.fromJson(item as Map<String, dynamic>);
        if (File(sig.imagePath).existsSync()) {
          result.add(sig);
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<DigitalSignature> saveSignature({
    required String userId,
    required String title,
    required List<int> pngBytes,
  }) async {
    final dir = await _getSignaturesDir(userId);
    final id = 'sig_${const Uuid().v4().substring(0, 8)}';
    final filePath = p.join(dir.path, '$id.png');

    final imageFile = File(filePath);
    await imageFile.writeAsBytes(pngBytes, flush: true);

    final signature = DigitalSignature(
      id: id,
      title: title.trim().isNotEmpty ? title.trim() : 'Signature ${DateTime.now().hour}:${DateTime.now().minute}',
      imagePath: filePath,
      createdAt: DateTime.now(),
    );

    final current = await getSignatures(userId);
    current.insert(0, signature);

    final metaFile = await _getMetadataFile(userId);
    await metaFile.writeAsString(
      jsonEncode(current.map((s) => s.toJson()).toList()),
      flush: true,
    );

    return signature;
  }

  Future<void> deleteSignature({
    required String userId,
    required String signatureId,
  }) async {
    final current = await getSignatures(userId);
    final targetIndex = current.indexWhere((s) => s.id == signatureId);
    if (targetIndex >= 0) {
      final sig = current.removeAt(targetIndex);
      final file = File(sig.imagePath);
      if (await file.exists()) {
        await file.delete();
      }

      final metaFile = await _getMetadataFile(userId);
      await metaFile.writeAsString(
        jsonEncode(current.map((s) => s.toJson()).toList()),
        flush: true,
      );
    }
  }
}
