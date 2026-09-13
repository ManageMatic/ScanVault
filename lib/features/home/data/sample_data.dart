import '../../../shared/models/document.dart';
import '../../../shared/models/document_page.dart';
import '../../../shared/models/folder.dart';
import '../../../shared/models/pdf_metadata.dart';

/// Realistic mock sample data for development as specified by the Stitch design.
class SampleData {
  SampleData._();

  static List<Folder> get initialFolders => [
        Folder(
          id: 'folder-1',
          name: 'Legal & Identity',
          colorHex: '#00685F',
          iconName: 'verified_user',
          documentCount: 4,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Folder(
          id: 'folder-2',
          name: 'Financial & Invoices',
          colorHex: '#855300',
          iconName: 'receipt_long',
          documentCount: 8,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Folder(
          id: 'folder-3',
          name: 'Medical Records',
          colorHex: '#BA1A1A',
          iconName: 'medical_services',
          documentCount: 3,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Folder(
          id: 'folder-4',
          name: 'Tax Vault 2026',
          colorHex: '#1976D2',
          iconName: 'account_balance',
          documentCount: 3,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];

  static List<Document> get initialDocuments => [
        Document(
          id: 'doc-1',
          title: 'Employment Agreement - Q3.pdf',
          type: DocumentType.pdf,
          folderId: 'folder-1',
          tags: ['Work', 'Contract', 'Confidential'],
          fileSize: 1468006, // ~1.4 MB
          isFavorite: true,
          hasOcr: true,
          extractedOcrText:
              'MUTUAL NON-DISCLOSURE AND EMPLOYMENT AGREEMENT. This agreement is entered into as of September 2026 between the Employer and Employee.',
          metadata: const PDFMetadata(
            title: 'Employment Agreement',
            author: 'Corporate Legal Dept',
            pageCount: 3,
            fileSize: 1468006,
          ),
          pages: [
            DocumentPage(
              id: 'page-1-1',
              pageNumber: 1,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            ),
            DocumentPage(
              id: 'page-1-2',
              pageNumber: 2,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            ),
            DocumentPage(
              id: 'page-1-3',
              pageNumber: 3,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        Document(
          id: 'doc-2',
          title: 'Utility Invoice - Electric.pdf',
          type: DocumentType.pdf,
          folderId: 'folder-2',
          tags: ['Utility', 'Home', 'Paid'],
          fileSize: 327680, // 320 KB
          isFavorite: false,
          hasOcr: true,
          extractedOcrText:
              'PACIFIC POWER & GAS. Account: 8493-2019-44. Statement Date: Aug 28, 2026. Total Amount Due: \$124.50. Status: PAID.',
          metadata: const PDFMetadata(
            title: 'Monthly Electric Invoice',
            pageCount: 1,
            fileSize: 327680,
          ),
          pages: [
            DocumentPage(
              id: 'page-2-1',
              pageNumber: 1,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        ),
        Document(
          id: 'doc-3',
          title: 'Passport ID Verification.jpg',
          type: DocumentType.scan,
          folderId: 'folder-1',
          tags: ['Identity', 'Travel'],
          fileSize: 2202009, // 2.1 MB
          isFavorite: true,
          isEncrypted: false,
          hasOcr: false,
          pages: [
            DocumentPage(
              id: 'page-3-1',
              pageNumber: 1,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
            ),
            DocumentPage(
              id: 'page-3-2',
              pageNumber: 2,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
        ),
        Document(
          id: 'doc-4',
          title: 'Medical Lab Report - Biomarkers.pdf',
          type: DocumentType.pdf,
          folderId: 'folder-3',
          tags: ['Health', 'Confidential'],
          fileSize: 3984588, // 3.8 MB
          isFavorite: true,
          hasOcr: true,
          extractedOcrText:
              'DIAGNOSTIC BIOCARE LABS. Patient ID: 90214. Panel: Comprehensive Metabolic Profile. Results all in reference range.',
          metadata: const PDFMetadata(
            title: 'Lab Report',
            pageCount: 4,
            fileSize: 3984588,
          ),
          pages: [
            DocumentPage(
              id: 'page-4-1',
              pageNumber: 1,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 4)),
            ),
            DocumentPage(
              id: 'page-4-2',
              pageNumber: 2,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 4)),
            ),
            DocumentPage(
              id: 'page-4-3',
              pageNumber: 3,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 4)),
            ),
            DocumentPage(
              id: 'page-4-4',
              pageNumber: 4,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 4)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Document(
          id: 'doc-5',
          title: 'W2 Tax Statement 2025.pdf',
          type: DocumentType.pdf,
          folderId: 'folder-4',
          tags: ['Tax', 'IRS', 'Finance'],
          fileSize: 840200, // 840 KB
          isFavorite: false,
          hasOcr: true,
          extractedOcrText:
              'Form W-2 Wage and Tax Statement 2025. Copy B - To be filed with employee federal tax return.',
          metadata: const PDFMetadata(
            title: 'Form W-2 Wage Statement',
            pageCount: 2,
            fileSize: 840200,
          ),
          pages: [
            DocumentPage(
              id: 'page-5-1',
              pageNumber: 1,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 8)),
            ),
            DocumentPage(
              id: 'page-5-2',
              pageNumber: 2,
              imagePath: '',
              createdAt: DateTime.now().subtract(const Duration(days: 8)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ];
}
