import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanvault/features/auth/data/offline_auth_repository.dart';
import 'package:scanvault/features/auth/domain/auth_controller.dart';
import 'package:scanvault/features/image_processing/domain/image_processor.dart';
import 'package:scanvault/shared/models/document.dart';
import 'package:scanvault/shared/models/folder.dart';

void main() {
  group('Phase 2 Auth & User Isolation Tests', () {
    test('OfflineAuthRepository sign up and sign in flow', () async {
      final repo = OfflineAuthRepository();
      final controller = AuthController(repo);

      expect(controller.isAuthenticated, true); // initialized with default local user

      final registered = await controller.signUp(
        name: 'Test Vault User',
        email: 'test@vault.local',
        password: 'password123',
      );

      expect(registered, true);
      expect(controller.isAuthenticated, true);
      expect(controller.currentUser?.email, 'test@vault.local');
      expect(controller.currentUser?.name, 'Test Vault User');

      await controller.signOut();
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);

      final loggedIn = await controller.signIn(
        email: 'test@vault.local',
        password: 'password123',
      );
      expect(loggedIn, true);
      expect(controller.isAuthenticated, true);
    });

    test('Auth controller validation and error normalization', () async {
      final repo = OfflineAuthRepository();
      final controller = AuthController(repo);
      await controller.signOut();

      final failed = await controller.signIn(
        email: 'invalid_email_test',
        password: '',
      );
      expect(failed, false);
      expect(controller.errorMessage, isNotNull);
    });
  });

  group('Phase 2 Image Processing & Optimization Tests', () {
    test('Image processor parameters and preset bounds', () {
      final dummyBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final processed = ImageProcessor.processImageSync(
        rawBytes: dummyBytes,
        params: const ImageEnhancementParams(
          filterMode: ScanFilterMode.documentClean,
          brightness: 0.1,
          contrast: 1.1,
        ),
        preset: CompressionPreset.small,
      );

      expect(processed, isNotNull);
    });
  });

  group('Phase 2 Document Models & Storage Calculations', () {
    test('Document model copyWith and defaults', () {
      final doc = Document(
        id: 'doc-test-1',
        title: 'Tax Document.pdf',
        pdfPath: '/vault/users/123/doc1.pdf',
        fileSize: 1048576, // 1 MB
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      );

      final favDoc = doc.copyWith(isFavorite: true);
      expect(favDoc.isFavorite, true);
      expect(favDoc.fileSize, 1048576);
      expect(favDoc.id, 'doc-test-1');
      expect(favDoc.filePath, '/vault/users/123/doc1.pdf');
    });

    test('Folder model creation and attributes', () {
      final folder = Folder(
        id: 'folder-1',
        name: 'Work Receipts',
        colorHex: '#00685F',
        iconName: 'receipt',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(folder.name, 'Work Receipts');
      expect(folder.colorHex, '#00685F');
    });
  });
}
