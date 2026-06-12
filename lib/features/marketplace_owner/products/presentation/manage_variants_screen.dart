import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/marketplace_owner/application/product_variant_controller.dart';
import 'package:ayyy/features/marketplace_owner/domain/product_variant.dart';
import 'package:ayyy/features/marketplace_owner/domain/product_variant_image.dart';

class ManageVariantsScreen extends ConsumerStatefulWidget {
  final String productId;
  const ManageVariantsScreen({super.key, required this.productId});

  @override
  ConsumerState<ManageVariantsScreen> createState() => _ManageVariantsScreenState();
}

class _ManageVariantsScreenState extends ConsumerState<ManageVariantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    Widget sheet;
    if (_tabController.index == 0) {
      sheet = _AddColorVariantSheet(productId: widget.productId);
    } else {
      sheet = _AddVariantImageSheet(productId: widget.productId);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final variantsAsync = ref.watch(ownerProductVariantsProvider(widget.productId));
    final imagesAsync = ref.watch(ownerProductVariantImagesProvider(widget.productId));

    return Scaffold(
      appBar: const DazzleAppBar(
        showBackButton: true,
        title: 'Manage Variants',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.textPrimary),
        label: Text(
          'Add',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(text: 'COLORS'),
              Tab(text: 'IMAGES'),
            ],
          ),
          Expanded(
            child: variantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text('Error loading variants: $err')),
              data: (variants) {
                final colors = variants.where((v) => v.isColor).toList();
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVariantList(colors, 'color'),
                    imagesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (err, stack) => Center(child: Text('Error loading images: $err')),
                      data: (images) => _buildVariantImagesList(images, variants),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantList(List<ProductVariant> variants, String type) {
    if (variants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'color' ? Icons.palette_outlined : Icons.dashboard_customize_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type variants yet',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: variants.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final variant = variants[index];
        return Dismissible(
          key: Key(variant.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Delete Variant', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                content: const Text('Are you sure you want to delete this variant? Associated images might lose their link.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref.read(productVariantControllerProvider.notifier).deleteVariant(variant.id, widget.productId);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: variant.isColor && variant.hexCode != null
                  ? Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hexToColor(variant.hexCode!),
                        border: Border.all(color: Colors.black12),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EDE6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.crop_original, color: AppColors.textSecondary),
                    ),
              title: Text(
                variant.isColor ? (variant.colorName ?? 'Unknown Color') : (variant.layoutType == 'vertical' ? 'Vertical Layout' : 'Horizontal Layout'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              subtitle: Text(
                variant.isColor ? (variant.hexCode ?? '') : 'Layout Variant',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.swipe_left, color: Colors.black26, size: 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVariantImagesList(List<ProductVariantImage> images, List<ProductVariant> allVariants) {
    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No variant images yet',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: images.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final image = images[index];
        
        final linkedColor = image.colorVariantId != null 
            ? allVariants.where((v) => v.id == image.colorVariantId).firstOrNull 
            : null;
            
        final linkedLayout = image.layoutVariantId != null 
            ? allVariants.where((v) => v.id == image.layoutVariantId).firstOrNull 
            : null;

        return Dismissible(
          key: Key(image.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Delete Image', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                content: const Text('Are you sure you want to delete this variant image?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref.read(productVariantControllerProvider.notifier).deleteVariantImage(image.id, widget.productId);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image.displayThumbnail,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56, height: 56,
                    color: const Color(0xFFF0EDE6),
                    child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                  ),
                ),
              ),
              title: Text(
                'Variant Image',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              subtitle: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (linkedColor != null)
                    Chip(
                      label: Text(linkedColor.colorName ?? 'Color', style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: _hexToColor(linkedColor.hexCode ?? '#FFFFFF').withValues(alpha: 0.2),
                    ),
                  if (linkedLayout != null)
                    Chip(
                      label: Text(linkedLayout.layoutType == 'vertical' ? 'Vertical' : 'Horizontal', style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (linkedColor == null && linkedLayout == null)
                    Text('Unlinked Image', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
                ],
              ),
              trailing: const Icon(Icons.swipe_left, color: Colors.black26, size: 20),
            ),
          ),
        );
      },
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ----------------------------------------------------------------------
// COLOR VARIANT SHEET
// ----------------------------------------------------------------------

class _AddColorVariantSheet extends ConsumerStatefulWidget {
  final String productId;
  const _AddColorVariantSheet({required this.productId});

  @override
  ConsumerState<_AddColorVariantSheet> createState() => _AddColorVariantSheetState();
}

class _AddColorVariantSheetState extends ConsumerState<_AddColorVariantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hexCtrl = TextEditingController(text: '#');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final controller = ref.read(productVariantControllerProvider.notifier);
    
    final variant = await controller.createColorVariant(
      productId: widget.productId,
      colorName: _nameCtrl.text,
      hexCode: _hexCtrl.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (variant != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Color variant created'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create color variant')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHeader(title: 'Add Color Variant'),
                const SizedBox(height: 24),
                _field('Color Name', _nameCtrl, 'e.g. Midnight Black', required: true),
                const SizedBox(height: 16),
                _field('Hex Code', _hexCtrl, 'e.g. #000000', required: true),
                const SizedBox(height: 32),
                _SubmitButton(isLoading: _isLoading, label: 'Save Color', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// IMAGE UPLOAD SHEET
// ----------------------------------------------------------------------

class _AddVariantImageSheet extends ConsumerStatefulWidget {
  final String productId;
  const _AddVariantImageSheet({required this.productId});

  @override
  ConsumerState<_AddVariantImageSheet> createState() => _AddVariantImageSheetState();
}

class _AddVariantImageSheetState extends ConsumerState<_AddVariantImageSheet> {
  XFile? _image;
  bool _isLoading = false;
  String? _selectedColorId;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => _isLoading = true);
    final controller = ref.read(productVariantControllerProvider.notifier);
    
    final success = await controller.uploadVariantImage(
      productId: widget.productId,
      imageFile: _image!,
      colorVariantId: _selectedColorId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variant image uploaded'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload variant image')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final variantsAsync = ref.watch(ownerProductVariantsProvider(widget.productId));
    final uploadProgress = ref.watch(variantUploadProgressProvider);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHeader(title: 'Upload Variant Image'),
              const SizedBox(height: 20),
              
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      image: _image != null
                          ? DecorationImage(
                              image: kIsWeb ? NetworkImage(_image!.path) as ImageProvider : FileImage(File(_image!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text('Upload Image', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              variantsAsync.when(
                data: (variants) {
                  final colors = variants.where((v) => v.isColor).toList();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (colors.isNotEmpty) ...[
                        Text('Link to Color (Optional)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedColorId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          hint: const Text('Select a color'),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('None')),
                            ...colors.map((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16, height: 16, margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _hexToColor(c.hexCode ?? '#FFFFFF'),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                  ),
                                  Text(c.colorName ?? 'Unknown'),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (val) => setState(() => _selectedColorId = val),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 32),
              
              if (uploadProgress > 0 && uploadProgress < 1) ...[
                LinearProgressIndicator(value: uploadProgress, color: AppColors.primary),
                const SizedBox(height: 16),
              ],
              
              _SubmitButton(isLoading: _isLoading, label: 'Upload Image', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ----------------------------------------------------------------------
// HELPER WIDGETS
// ----------------------------------------------------------------------

class _SheetHeader extends StatelessWidget {
  final String title;
  const _SheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isLoading, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

Widget _field(String label, TextEditingController ctrl, String hint, {bool required = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
        decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      ),
    ],
  );
}
