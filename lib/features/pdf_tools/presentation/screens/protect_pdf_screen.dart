import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_tool_result_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/pdf_document_picker_sheet.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';

class ProtectPdfScreen extends StatefulWidget {
  const ProtectPdfScreen({super.key});

  @override
  State<ProtectPdfScreen> createState() => _ProtectPdfScreenState();
}

class _ProtectPdfScreenState extends State<ProtectPdfScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _obscurePassword = true;

  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _titleController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDF to Protect',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _titleController.text = '${p.basenameWithoutExtension(file.path)}_Protected';
      });
    }
  }

  Future<void> _protectPdf() async {
    if (_selectedFile == null) return;

    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an encryption password.')),
      );
      return;
    }

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.'), backgroundColor: AppColors.error),
      );
      return;
    }

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.protectPdf(
      userId: userId,
      sourcePdf: _selectedFile!,
      password: pass,
      outputTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Protect PDF',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Protection failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Protect PDF',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. File Selection Card
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                    width: _selectedFile != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF855300).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF855300), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile != null
                                ? p.basename(_selectedFile!.path)
                                : 'Select PDF Document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedFile != null ? 'Ready to encrypt' : 'Tap to select document to lock',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_horiz_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedFile != null) ...[
              // Banner info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 22, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AES-256 Bit Encryption will lock this document. A password will be required to open or print.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSecondaryContainer,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'User Password / PIN',
                  prefixIcon: const Icon(Icons.password_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _protectPdf,
                icon: const Icon(Icons.lock_rounded),
                label: const Text('Encrypt and Protect PDF'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
