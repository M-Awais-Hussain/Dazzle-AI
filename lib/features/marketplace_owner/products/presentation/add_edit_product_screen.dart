import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_product_controller.dart';
import 'package:ayyy/features/marketplace_owner/domain/marketplace_product.dart';

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
  late TextEditingController _colorsCtrl;
  bool _isFeatured = false;
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  late List<String> _existingImageUrls;

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
    _colorsCtrl = TextEditingController(text: p?.colors.join(', ') ?? '');
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
    _colorsCtrl.dispose();
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
          const SnackBar(
            content: Text('Product deleted!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final colorsList = _colorsCtrl.text.isEmpty
        ? <String>[]
        : _colorsCtrl.text.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    final controller = ref.read(marketplaceProductControllerProvider.notifier);

    bool success;
    if (_isEdit) {
      List<String> updatedImageUrls = List<String>.from(_existingImageUrls);
      
      // Upload new images if selected
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
        colors: colorsList,
        isFeatured: _isFeatured,
        imageUrls: updatedImageUrls,
        thumbnailUrl: updatedImageUrls.isNotEmpty ? updatedImageUrls.first : null,
      );
    } else {
      final product = await controller.createProduct(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        dimensions: _dimensionsCtrl.text,
        material: _materialCtrl.text,
        colors: colorsList,
        isFeatured: _isFeatured,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
      );
      success = product != null;
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
              Text(_isEdit ? 'Edit Product' : 'New Product', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 24),

              // Image Section
              Text('Product Images', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildImageSection(),
              if (uploadProgress > 0 && uploadProgress < 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(value: uploadProgress, color: AppColors.primary, backgroundColor: AppColors.border),
                ),
              const SizedBox(height: 24),

              // Form fields
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
              const SizedBox(height: 16),
              _field('Colors', _colorsCtrl, 'Comma separated: Black, White, Oak'),
              const SizedBox(height: 20),

              // Featured toggle
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

  Widget _buildImageSection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._selectedImages.map((file) => _imagePreview(file)),
        ..._existingImageUrls.map((url) => _networkImagePreview(url)),
        _addImageButton(),
      ],
    );
  }

  Widget _imagePreview(XFile file) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.network(file.path, width: 80, height: 80, fit: BoxFit.cover)
              : Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: -4, right: -4,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImages.remove(file)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _networkImagePreview(String url) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFF0EDE6), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
            ),
          ),
        ),
        Positioned(
          top: -4, right: -4,
          child: GestureDetector(
            onTap: () => setState(() => _existingImageUrls.remove(url)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
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
}
