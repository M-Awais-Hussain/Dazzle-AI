import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import '../application/portfolio_controller.dart';
import '../domain/portfolio_project.dart';

class AddEditPortfolioScreen extends ConsumerStatefulWidget {
  final PortfolioProject? project;

  const AddEditPortfolioScreen({super.key, this.project});

  @override
  ConsumerState<AddEditPortfolioScreen> createState() => _AddEditPortfolioScreenState();
}

class _AddEditPortfolioScreenState extends ConsumerState<AddEditPortfolioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _typeController = TextEditingController(text: 'Living Room');
  final _timeController = TextEditingController(text: '2 weeks');
  final _priceController = TextEditingController(text: '1500');
  final _tagsController = TextEditingController(text: 'Minimal, Scandi, Luxe');
  
  final List<String> _existingImages = [];
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _titleController.text = widget.project!.title;
      _descController.text = widget.project!.description;
      _typeController.text = widget.project!.projectType;
      _timeController.text = widget.project!.completionTime;
      _priceController.text = widget.project!.pricing.toStringAsFixed(0);
      _tagsController.text = widget.project!.styleTags.join(', ');
      _existingImages.addAll(widget.project!.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _typeController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingImages.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image for your project visual gallery.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final styleTags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final price = double.tryParse(_priceController.text) ?? 0.0;

    bool success;
    if (widget.project != null) {
      success = await ref.read(designerProjectsProvider.notifier).updateProject(
            projectId: widget.project!.id,
            title: _titleController.text,
            description: _descController.text,
            existingImages: _existingImages,
            newImageFiles: _selectedImages,
            styleTags: styleTags,
            pricing: price,
            projectType: _typeController.text,
            completionTime: _timeController.text,
          );
    } else {
      success = await ref.read(designerProjectsProvider.notifier).addProject(
            title: _titleController.text,
            description: _descController.text,
            imageFiles: _selectedImages,
            styleTags: styleTags,
            pricing: price,
            projectType: _typeController.text,
            completionTime: _timeController.text,
          );
    }
    
    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      final successMsg = widget.project != null
          ? 'Masterpiece updated successfully in your studio portfolio!'
          : 'Masterpiece added successfully to your studio portfolio!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final errorMsg = widget.project != null
          ? 'Failed to update portfolio piece. Please check details.'
          : 'Failed to add portfolio piece. Please check details.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.project != null ? 'EDIT STUDIO PROJECT' : 'NEW STUDIO PROJECT';
    final buttonText = widget.project != null ? 'UPDATE PORTFOLIO ITEM' : 'PUBLISH TO PORTFOLIO';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleText,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Details',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Provide comprehensive information to captivate high-profile clients.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Title',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. Scandi Minimalist Living Room',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Describe the style, architecture, spatial planning, and design language...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Project Type',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _typeController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Living Room',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timeline',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _timeController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 2 weeks',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pricing / Budget',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 1500',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Style Tags (Comma separated)',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _tagsController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Minimal, Luxe',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Project Visual Gallery',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 28),
                                SizedBox(height: 6),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 100,
                            child: (_existingImages.isEmpty && _selectedImages.isEmpty)
                                ? Center(
                                    child: Text(
                                      'Select actual image files of your design projects to showcase to clients.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _existingImages.length + _selectedImages.length,
                                    itemBuilder: (context, index) {
                                      if (index < _existingImages.length) {
                                        final url = _existingImages[index];
                                        return Stack(
                                          children: [
                                            Container(
                                              width: 100,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                borderRadius: BorderRadius.circular(16),
                                                image: DecorationImage(
                                                  image: NetworkImage(url),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 16,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _existingImages.removeAt(index);
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        final localIndex = index - _existingImages.length;
                                        final file = _selectedImages[localIndex];
                                        return Stack(
                                          children: [
                                            Container(
                                              width: 100,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                borderRadius: BorderRadius.circular(16),
                                                image: DecorationImage(
                                                  image: FileImage(file),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 16,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedImages.removeAt(localIndex);
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submit,
                        child: Text(
                          buttonText,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
