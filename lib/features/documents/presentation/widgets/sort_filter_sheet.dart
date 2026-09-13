import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/documents_controller.dart';

/// Modal bottom sheet for adjusting sorting and filtering criteria.
class SortFilterSheet extends StatefulWidget {
  final DocumentSortOption currentSort;
  final DocumentFilterType currentFilter;
  final Function(DocumentSortOption, DocumentFilterType) onApply;

  const SortFilterSheet({
    super.key,
    required this.currentSort,
    required this.currentFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required DocumentSortOption currentSort,
    required DocumentFilterType currentFilter,
    required Function(DocumentSortOption, DocumentFilterType) onApply,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Sort & Filter',
      child: SortFilterSheet(
        currentSort: currentSort,
        currentFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> {
  late DocumentSortOption _selectedSort;
  late DocumentFilterType _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentSort;
    _selectedFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort Section
        Text(
          'SORT BY',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortChoice(DocumentSortOption.newest, 'Newest First'),
            _buildSortChoice(DocumentSortOption.oldest, 'Oldest First'),
            _buildSortChoice(DocumentSortOption.nameAsc, 'Name (A to Z)'),
            _buildSortChoice(DocumentSortOption.nameDesc, 'Name (Z to A)'),
            _buildSortChoice(DocumentSortOption.sizeLargest, 'Size (Largest)'),
            _buildSortChoice(DocumentSortOption.sizeSmallest, 'Size (Smallest)'),
          ],
        ),
        const SizedBox(height: 20),

        // Filter Section
        Text(
          'FILTER BY TYPE',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChoice(DocumentFilterType.all, 'All Files'),
            _buildFilterChoice(DocumentFilterType.pdfOnly, 'PDFs Only'),
            _buildFilterChoice(DocumentFilterType.scansOnly, 'Scans Only'),
            _buildFilterChoice(DocumentFilterType.ocrOnly, 'With OCR Text'),
            _buildFilterChoice(DocumentFilterType.favoritesOnly, 'Starred Only'),
          ],
        ),
        const SizedBox(height: 28),

        // Apply Button
        PrimaryButton(
          label: 'Apply Filters',
          onPressed: () {
            widget.onApply(_selectedSort, _selectedFilter);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildSortChoice(DocumentSortOption option, String label) {
    final isSelected = _selectedSort == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedSort = option);
      },
      selectedColor: AppColors.primary,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildFilterChoice(DocumentFilterType type, String label) {
    final isSelected = _selectedFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = type);
      },
      selectedColor: AppColors.primary,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
