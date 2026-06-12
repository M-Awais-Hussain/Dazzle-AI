import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_product_controller.dart';
import 'package:ayyy/features/marketplace_owner/application/product_variant_controller.dart';
import 'package:ayyy/features/marketplace_owner/domain/marketplace_product.dart';
import 'package:ayyy/features/marketplace_owner/domain/product_variant_image.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final MarketplaceProduct? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _dimensionsCtrl;
  late TextEditingController _materialCtrl;
  late TextEditingController _purchaseLinkCtrl;
  late TextEditingController _couponCodeCtrl;
  late TextEditingController _couponDescCtrl;
  bool _isFeatured = false;
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  late List<String> _existingImageUrls;

  // Temporary variant state for NEW products
  final List<Map<String, String>> _tempColors = [];

  // Image assignments for NEW products (color index -> set of image indices)
  final Map<int, Set<int>> _colorImageAssignments = {};

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _existingImageUrls = p != null ? List<String>.from(p.imageUrls) : <String>[];
    _titleCtrl = TextEditingController(text: p != null ? (p.title ?? p.name ?? '') : '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '');
    _dimensionsCtrl = TextEditingController(text: p?.dimensions ?? '');
    _materialCtrl = TextEditingController(text: p?.material ?? '');
    _purchaseLinkCtrl = TextEditingController(text: p?.purchaseLink ?? '');
    _couponCodeCtrl = TextEditingController(text: p?.couponCode ?? '');
    _couponDescCtrl = TextEditingController(text: p?.couponDescription ?? '');
    _isFeatured = p?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _dimensionsCtrl.dispose();
    _materialCtrl.dispose();
    _purchaseLinkCtrl.dispose();
    _couponCodeCtrl.dispose();
    _couponDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await ref.read(marketplaceProductControllerProvider.notifier).deleteProduct(widget.product!.id);
      setState(() => _isLoading = false);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted!'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final controller = ref.read(marketplaceProductControllerProvider.notifier);

    bool success;
    if (_isEdit) {
      List<String> updatedImageUrls = List<String>.from(_existingImageUrls);

      if (_selectedImages.isNotEmpty) {
        final newUrls = await controller.uploadImages(widget.product!.id, _selectedImages);
        updatedImageUrls.addAll(newUrls);
      }

      success = await controller.updateProduct(
        id: widget.product!.id,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        dimensions: _dimensionsCtrl.text,
        material: _materialCtrl.text,
        colors: widget.product?.colors ?? <String>[],
        isFeatured: _isFeatured,
        purchaseLink: _purchaseLinkCtrl.text,
        couponCode: _couponCodeCtrl.text,
        couponDescription: _couponDescCtrl.text,
        imageUrls: updatedImageUrls,
        thumbnailUrl: updatedImageUrls.isNotEmpty ? updatedImageUrls.first : null,
      );
    } else {
      final colorsList = _tempColors.map((c) => c['name']!).toList();
      final product = await controller.createProduct(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        dimensions: _dimensionsCtrl.text,
        material: _materialCtrl.text,
        colors: colorsList,
        isFeatured: _isFeatured,
        purchaseLink: _purchaseLinkCtrl.text,
        couponCode: _couponCodeCtrl.text,
        couponDescription: _couponDescCtrl.text,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (product != null) {
        success = true;
        final variantController = ref.read(productVariantControllerProvider.notifier);

        // Create color variants
        List<String> colorIds = [];
        for (int i = 0; i < _tempColors.length; i++) {
          final c = _tempColors[i];
          final v = await variantController.createColorVariant(
            productId: product.id, colorName: c['name']!, hexCode: c['hex']!, sortOrder: i,
          );
          colorIds.add(v?.id ?? '');
        }

        // Create color-image links
        for (final entry in _colorImageAssignments.entries) {
          final colorIdx = entry.key;
          final imageIndices = entry.value;
          if (colorIdx >= 0 && colorIdx < colorIds.length) {
            final colorId = colorIds[colorIdx];
            if (colorId.isNotEmpty) {
              for (final imgIdx in imageIndices) {
                if (imgIdx >= 0 && imgIdx < product.imageUrls.length) {
                  await variantController.linkVariantImage(
                    productId: product.id,
                    imageUrl: product.imageUrls[imgIdx],
                    colorVariantId: colorId,
                  );
                }
              }
            }
          }
        }
      } else {
        success = false;
      }
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Product updated!' : 'Product created!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uploadProgress = ref.watch(productUploadProgressProvider);

    return Scaffold(
      appBar: DazzleAppBar(showBackButton: true, actions: [
        if (_isEdit && !_isLoading)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _deleteProduct,
          ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else
          TextButton(
            onPressed: _submit,
            child: Text('SAVE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1)),
          ),
      ]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEdit ? 'Edit Product' : 'New Product',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 24),

              // ── Section: Product Images ─────────────────────────────
              _sectionHeader('Product Images', Icons.photo_library_outlined),
              const SizedBox(height: 12),
              _buildImageGrid(),
              if (uploadProgress > 0 && uploadProgress < 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: uploadProgress,
                      color: AppColors.primary,
                      backgroundColor: AppColors.border,
                      minHeight: 6,
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // ── Section: Basic Info ─────────────────────────────────
              _sectionHeader('Basic Info', Icons.info_outline),
              const SizedBox(height: 12),
              _field('Title', _titleCtrl, 'Product title', required: true),
              const SizedBox(height: 16),
              _field('Description', _descCtrl, 'Product description', maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field('Price', _priceCtrl, '0', keyboardType: TextInputType.number, required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Stock', _stockCtrl, '0', keyboardType: TextInputType.number, required: true)),
                ],
              ),
              const SizedBox(height: 16),
              _field('Dimensions', _dimensionsCtrl, 'e.g. 120x60x45 cm'),
              const SizedBox(height: 16),
              _field('Material', _materialCtrl, 'e.g. Solid Oak Wood'),
              const SizedBox(height: 28),

              // ── Section: Color Variants ─────────────────────────────
              _isEdit ? _buildEditModeColorSection() : _buildNewModeColorSection(),
              const SizedBox(height: 28),

              // ── Section: Links & Coupons ────────────────────────────
              _sectionHeader('Purchase & Coupons', Icons.link),
              const SizedBox(height: 12),
              _field('External Store Link', _purchaseLinkCtrl, 'https://your-store.com/product', required: false),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field('Coupon Code', _couponCodeCtrl, 'e.g. SAVE20')),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Coupon Desc.', _couponDescCtrl, 'e.g. Use code at checkout')),
                ],
              ),
              const SizedBox(height: 24),

              // ── Featured toggle ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Featured Product', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('Highlight this product in the marketplace', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Switch(
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SECTION HEADER ──────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3)),
      ],
    );
  }

  // ─── FORM FIELD ──────────────────────────────────────────────────────

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboardType, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  // ─── IMAGE GRID ──────────────────────────────────────────────────────

  Widget _buildImageGrid() {
    final bool hasImages = _selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasImages)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 40),
                  const SizedBox(height: 8),
                  Text('Tap to add product images', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingImageUrls.asMap().entries.map((e) => _networkImageTile(e.value, e.key)),
                ..._selectedImages.asMap().entries.map((e) => _localImageTile(e.value, e.key)),
                _addImageTile(),
              ],
            ),
          ),
        if (hasImages)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_existingImageUrls.length + _selectedImages.length} image(s) — these can be assigned to color or layout variants below',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _localImageTile(XFile file, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(file.path, width: 90, height: 90, fit: BoxFit.cover)
                : Image.file(File(file.path), width: 90, height: 90, fit: BoxFit.cover),
          ),
          // Index badge
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('#${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            top: -4, right: -4,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedImages.removeAt(index);
                // Clean up assignments referencing this index
                _removeImageFromAssignments(index + _existingImageUrls.length);
              }),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkImageTile(String url, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, width: 90, height: 90, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: const Color(0xFFF0EDE6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
              ),
            ),
          ),
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
              child: Text('#${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            top: -4, right: -4,
            child: GestureDetector(
              onTap: () => setState(() {
                _existingImageUrls.removeAt(index);
                _removeImageFromAssignments(index);
              }),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addImageTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 24),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _removeImageFromAssignments(int globalIdx) {
    for (final set in _colorImageAssignments.values) {
      set.remove(globalIdx);
      // Shift indices down for images after the removed one
      final shifted = set.where((i) => i > globalIdx).toList();
      for (final i in shifted) {
        set.remove(i);
        set.add(i - 1);
      }
    }
  }

  // ─── Total image count helper ────────────────────────────────────────

  int get _totalImageCount => _existingImageUrls.length + _selectedImages.length;

  Widget _buildImageThumbByGlobalIndex(int globalIdx, {double size = 64, VoidCallback? onRemove}) {
    Widget image;
    if (globalIdx < _existingImageUrls.length) {
      image = Image.network(_existingImageUrls[globalIdx], width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(width: size, height: size, color: const Color(0xFFF0EDE6), child: const Icon(Icons.broken_image, size: 20)));
    } else {
      final localIdx = globalIdx - _existingImageUrls.length;
      if (localIdx < _selectedImages.length) {
        final file = _selectedImages[localIdx];
        image = kIsWeb
            ? Image.network(file.path, width: size, height: size, fit: BoxFit.cover)
            : Image.file(File(file.path), width: size, height: size, fit: BoxFit.cover);
      } else {
        image = Container(width: size, height: size, color: const Color(0xFFF0EDE6), child: const Icon(Icons.broken_image, size: 20));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
          if (onRemove != null)
            Positioned(
              top: -4, right: -4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── NEW MODE: COLOR VARIANTS ────────────────────────────────────────

  Widget _buildNewModeColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Color Variants', Icons.palette_outlined),
        const SizedBox(height: 4),
        Text('Assign product images to each color separately',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ..._tempColors.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final assigned = _colorImageAssignments[i] ?? {};
          return _buildVariantCard(
            leading: _colorSwatch(c['hex']!),
            title: c['name']!,
            subtitle: c['hex']!,
            assignedImageIndices: assigned,
            onDelete: () => setState(() {
              _tempColors.removeAt(i);
              _colorImageAssignments.remove(i);
              // Shift keys above i down by 1
              final newMap = <int, Set<int>>{};
              _colorImageAssignments.forEach((k, v) {
                newMap[k > i ? k - 1 : k] = v;
              });
              _colorImageAssignments
                ..clear()
                ..addAll(newMap);
            }),
            onAssign: () => _showImageAssignmentPicker(
              label: 'Assign images to "${c['name']}"',
              assignedIndices: Set<int>.from(assigned),
              onConfirm: (indices) => setState(() => _colorImageAssignments[i] = indices),
            ),
            onRemoveImage: (imgIdx) => setState(() => _colorImageAssignments[i]?.remove(imgIdx)),
          );
        }),
        const SizedBox(height: 8),
        _addVariantButton('Add Color', Icons.palette_outlined, _addColorDialog),
      ],
    );
  }

  // ─── EDIT MODE: COLOR VARIANTS ───────────────────────────────────────

  Widget _buildEditModeColorSection() {
    final variantsAsync = ref.watch(ownerProductVariantsProvider(widget.product!.id));
    final imagesAsync = ref.watch(ownerProductVariantImagesProvider(widget.product!.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Color Variants', Icons.palette_outlined),
        const SizedBox(height: 4),
        Text('Each color shows its assigned images',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        variantsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          data: (variants) {
            final colors = variants.where((v) => v.isColor).toList();
            final allVarImages = imagesAsync.whenData((d) => d).value ?? <ProductVariantImage>[];

            return Column(
              children: [
                ...colors.map((color) {
                  final linkedImages = allVarImages.where((img) => img.colorVariantId == color.id).toList();
                  return _buildEditVariantCard(
                    leading: _colorSwatch(color.hexCode ?? '#CCCCCC'),
                    title: color.colorName ?? 'Unknown',
                    subtitle: color.hexCode ?? '',
                    linkedImages: linkedImages,
                    onDelete: () async {
                      final ok = await _confirmDelete('Delete color "${color.colorName}"?');
                      if (ok) {
                        await ref.read(productVariantControllerProvider.notifier).deleteVariant(color.id, widget.product!.id);
                      }
                    },
                    onAssignImage: () => _showEditModeImageAssignPicker(
                      variantId: color.id,
                      variantType: 'color',
                      linkedImages: linkedImages,
                    ),
                    onRemoveImage: (img) async {
                      await ref.read(productVariantControllerProvider.notifier).deleteVariantImage(img.id, widget.product!.id);
                    },
                  );
                }),
                const SizedBox(height: 8),
                _addVariantButton('Add Color', Icons.palette_outlined, _addColorDialogEdit),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── VARIANT CARD (NEW MODE) ─────────────────────────────────────────

  Widget _buildVariantCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required Set<int> assignedImageIndices,
    required VoidCallback onDelete,
    required VoidCallback onAssign,
    required Function(int) onRemoveImage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 16, indent: 14, endIndent: 14),
          // Assigned images row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: assignedImageIndices.isEmpty && _totalImageCount == 0
                ? Text('Add product images first, then assign them here',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic))
                : SizedBox(
                    height: 72,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...assignedImageIndices.map((idx) => _buildImageThumbByGlobalIndex(idx, onRemove: () => onRemoveImage(idx))),
                        _assignImageButton(onAssign),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── VARIANT CARD (EDIT MODE) ────────────────────────────────────────

  Widget _buildEditVariantCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required List<ProductVariantImage> linkedImages,
    required VoidCallback onDelete,
    required VoidCallback onAssignImage,
    required Function(ProductVariantImage) onRemoveImage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 16, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...linkedImages.map((img) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(img.displayThumbnail, width: 64, height: 64, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(width: 64, height: 64, color: const Color(0xFFF0EDE6), child: const Icon(Icons.broken_image, size: 20))),
                        ),
                        Positioned(
                          top: -4, right: -4,
                          child: GestureDetector(
                            onTap: () => onRemoveImage(img),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  _assignImageButton(onAssignImage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ASSIGN IMAGE BUTTON ─────────────────────────────────────────────

  Widget _assignImageButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), style: BorderStyle.solid, width: 1.5),
          color: AppColors.primary.withValues(alpha: 0.06),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 2),
            Text('Assign', style: TextStyle(fontSize: 9, color: AppColors.primary.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── ADD VARIANT BUTTON ──────────────────────────────────────────────

  Widget _addVariantButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─── COLOR SWATCH ────────────────────────────────────────────────────

  Widget _colorSwatch(String hex) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _hexToColor(hex),
        border: Border.all(color: Colors.black12, width: 1.5),
        boxShadow: [BoxShadow(color: _hexToColor(hex).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
      ),
    );
  }

  // ─── IMAGE ASSIGNMENT PICKER (NEW MODE) ──────────────────────────────

  void _showImageAssignmentPicker({
    required String label,
    required Set<int> assignedIndices,
    required Function(Set<int>) onConfirm,
  }) {
    if (_totalImageCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add product images first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSelectionSheet(
        label: label,
        totalImages: _totalImageCount,
        existingUrls: _existingImageUrls,
        localFiles: _selectedImages,
        initialSelected: assignedIndices,
        onConfirm: (indices) {
          onConfirm(indices);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ─── IMAGE ASSIGNMENT PICKER (EDIT MODE) ─────────────────────────────

  void _showEditModeImageAssignPicker({
    required String variantId,
    required String variantType,
    required List<ProductVariantImage> linkedImages,
  }) {
    if (_existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product images available to assign')),
      );
      return;
    }

    final linkedUrls = linkedImages.map((img) => img.imageUrl).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditModeImageSelectionSheet(
        productId: widget.product!.id,
        variantId: variantId,
        variantType: variantType,
        imageUrls: _existingImageUrls,
        alreadyLinkedUrls: linkedUrls,
      ),
    );
  }

  // ─── ADD COLOR DIALOG (NEW MODE) ─────────────────────────────────────

  Future<void> _addColorDialog() async {
    final nameCtrl = TextEditingController();
    final hexCtrl = TextEditingController(text: '#');
    Color previewColor = Colors.grey;

    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, color: previewColor, border: Border.all(color: Colors.black12)),
              ),
              const SizedBox(width: 10),
              Text('Add Color', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Color Name', hintText: 'e.g. Midnight Black', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 12),
              TextField(
                controller: hexCtrl,
                decoration: InputDecoration(labelText: 'Hex Code', hintText: 'e.g. #FF0000', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (val) {
                  final c = _hexToColor(val);
                  setDialogState(() => previewColor = c);
                },
              ),
              const SizedBox(height: 16),
              // Quick color presets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickColorChip('Black', '#000000', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('White', '#FFFFFF', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Red', '#E74C3C', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Blue', '#3498DB', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Green', '#2ECC71', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Brown', '#8B4513', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Grey', '#95A5A6', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Beige', '#F5F0E1', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'name': nameCtrl.text, 'hex': hexCtrl.text}),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (res != null && res['name']!.isNotEmpty) {
      setState(() => _tempColors.add(res));
    }
  }

  Widget _quickColorChip(String name, String hex, TextEditingController nameCtrl, TextEditingController hexCtrl, Function(Color) onSelect) {
    final color = _hexToColor(hex);
    return GestureDetector(
      onTap: () {
        nameCtrl.text = name;
        hexCtrl.text = hex;
        onSelect(color);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: Colors.black12))),
            const SizedBox(width: 6),
            Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ─── ADD COLOR (EDIT MODE) ───────────────────────────────────────────

  Future<void> _addColorDialogEdit() async {
    final nameCtrl = TextEditingController();
    final hexCtrl = TextEditingController(text: '#');
    Color previewColor = Colors.grey;

    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: previewColor, border: Border.all(color: Colors.black12))),
              const SizedBox(width: 10),
              Text('Add Color', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Color Name', hintText: 'e.g. Walnut', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 12),
              TextField(
                controller: hexCtrl,
                decoration: InputDecoration(labelText: 'Hex Code', hintText: 'e.g. #8B4513', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (val) => setDialogState(() => previewColor = _hexToColor(val)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _quickColorChip('Black', '#000000', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('White', '#FFFFFF', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Red', '#E74C3C', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Blue', '#3498DB', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Green', '#2ECC71', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                  _quickColorChip('Brown', '#8B4513', nameCtrl, hexCtrl, (c) => setDialogState(() => previewColor = c)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'name': nameCtrl.text, 'hex': hexCtrl.text}),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (res != null && res['name']!.isNotEmpty && mounted) {
      final controller = ref.read(productVariantControllerProvider.notifier);
      final variant = await controller.createColorVariant(
        productId: widget.product!.id, colorName: res['name']!, hexCode: res['hex']!,
      );
      if (variant != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Color added!'), backgroundColor: AppColors.success));
      }
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    ) ?? false;
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    final cleaned = hexString.replaceFirst('#', '');
    if (cleaned.length == 6 || cleaned.length == 7) buffer.write('ff');
    buffer.write(cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned);
    try {
      return Color(int.parse(buffer.toString().padRight(8, '0'), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// IMAGE SELECTION SHEET (NEW MODE)
// ════════════════════════════════════════════════════════════════════════

class _ImageSelectionSheet extends StatefulWidget {
  final String label;
  final int totalImages;
  final List<String> existingUrls;
  final List<XFile> localFiles;
  final Set<int> initialSelected;
  final Function(Set<int>) onConfirm;

  const _ImageSelectionSheet({
    required this.label,
    required this.totalImages,
    required this.existingUrls,
    required this.localFiles,
    required this.initialSelected,
    required this.onConfirm,
  });

  @override
  State<_ImageSelectionSheet> createState() => _ImageSelectionSheetState();
}

class _ImageSelectionSheetState extends State<_ImageSelectionSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(widget.label,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onConfirm(_selected),
                    child: Text('Done (${_selected.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Tap images to select or deselect',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            // Image grid
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
                ),
                itemCount: widget.totalImages,
                itemBuilder: (context, idx) {
                  final isSelected = _selected.contains(idx);
                  Widget image;
                  if (idx < widget.existingUrls.length) {
                    image = Image.network(widget.existingUrls[idx], fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: const Color(0xFFF0EDE6), child: const Icon(Icons.broken_image)));
                  } else {
                    final localIdx = idx - widget.existingUrls.length;
                    final file = widget.localFiles[localIdx];
                    image = kIsWeb
                        ? Image.network(file.path, fit: BoxFit.cover)
                        : Image.file(File(file.path), fit: BoxFit.cover);
                  }

                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selected.remove(idx);
                      } else {
                        _selected.add(idx);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(isSelected ? 9 : 12), child: image),
                          if (isSelected)
                            Positioned(
                              top: 4, right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                            ),
                          Positioned(
                            bottom: 4, left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                              child: Text('#${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// EDIT MODE IMAGE SELECTION SHEET
// ════════════════════════════════════════════════════════════════════════

class _EditModeImageSelectionSheet extends ConsumerStatefulWidget {
  final String productId;
  final String variantId;
  final String variantType; // 'color' or 'layout'
  final List<String> imageUrls;
  final Set<String> alreadyLinkedUrls;

  const _EditModeImageSelectionSheet({
    required this.productId,
    required this.variantId,
    required this.variantType,
    required this.imageUrls,
    required this.alreadyLinkedUrls,
  });

  @override
  ConsumerState<_EditModeImageSelectionSheet> createState() => _EditModeImageSelectionSheetState();
}

class _EditModeImageSelectionSheetState extends ConsumerState<_EditModeImageSelectionSheet> {
  bool _isSaving = false;

  Future<void> _assignImage(String imageUrl) async {
    setState(() => _isSaving = true);
    final controller = ref.read(productVariantControllerProvider.notifier);
    await controller.linkVariantImage(
      productId: widget.productId,
      imageUrl: imageUrl,
      colorVariantId: widget.variantType == 'color' ? widget.variantId : null,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image assigned!'), backgroundColor: AppColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlinked = widget.imageUrls.where((url) => !widget.alreadyLinkedUrls.contains(url)).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Assign an Image', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            if (_isSaving)
              const LinearProgressIndicator(color: AppColors.primary),
            if (unlinked.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: AppColors.success.withValues(alpha: 0.6)),
                    const SizedBox(height: 12),
                    Text('All images are already assigned!', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              Flexible(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
                  ),
                  itemCount: unlinked.length,
                  itemBuilder: (context, idx) {
                    return GestureDetector(
                      onTap: _isSaving ? null : () => _assignImage(unlinked[idx]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(unlinked[idx], fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: const Color(0xFFF0EDE6), child: const Icon(Icons.broken_image))),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
