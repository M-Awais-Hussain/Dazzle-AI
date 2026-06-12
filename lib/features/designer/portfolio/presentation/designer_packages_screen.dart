import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import '../application/portfolio_controller.dart';

class DesignerPackagesScreen extends ConsumerStatefulWidget {
  const DesignerPackagesScreen({super.key});

  @override
  ConsumerState<DesignerPackagesScreen> createState() => _DesignerPackagesScreenState();
}

class _DesignerPackagesScreenState extends ConsumerState<DesignerPackagesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _featuresController = TextEditingController();

  String? _editingPackageId;
  bool _isCreatingOrEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  void _startCreate() {
    setState(() {
      _editingPackageId = null;
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _featuresController.clear();
      _isCreatingOrEditing = true;
    });
  }

  void _startEdit(dynamic package) {
    setState(() {
      _editingPackageId = package.id;
      _nameController.text = package.name;
      _descController.text = package.description;
      _priceController.text = package.price.toStringAsFixed(0);
      _featuresController.text = package.features.join(', ');
      _isCreatingOrEditing = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final features = _featuresController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final success = await ref.read(designerPackagesProvider.notifier).savePackage(
          id: _editingPackageId,
          name: _nameController.text,
          description: _descController.text,
          price: price,
          features: features,
        );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation Package saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _isCreatingOrEditing = false;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save package. Please check details.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(designerPackagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isCreatingOrEditing ? 'MANAGE PACKAGE' : 'SERVICE PACKAGES',
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
          onPressed: () {
            if (_isCreatingOrEditing) {
              setState(() {
                _isCreatingOrEditing = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isCreatingOrEditing)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.textPrimary),
              onPressed: _startCreate,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _isCreatingOrEditing
              ? Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingPackageId == null ? 'Create Custom Package' : 'Edit Package Details',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Offer curated consultation packages for different tiers of service.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Package Name',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. Premium Room Redesign',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Package Description',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descController,
                              maxLines: 4,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Provide deep insight into what service you will deliver to the client...',
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
                                    'Package Price (Rs.)',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 199',
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
                                    'Features (Comma separated)',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _featuresController,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 3D Renders, Chat access',
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
                            onPressed: _save,
                            child: Text(
                              'SAVE PACKAGE TEMPLATE',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(designerPackagesProvider),
                  child: packagesAsync.when(
                    data: (packages) {
                      if (packages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.style_outlined, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: 16),
                                Text(
                                  'No Custom Packages Yet',
                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Set up custom consultation tiers like Basic Consultation (Rs. 49) or Premium Makeover (Rs. 299) to simplify booking.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton(
                                  onPressed: _startCreate,
                                  child: const Text('CREATE FIRST PACKAGE'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                          final pkg = packages[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pkg.name,
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${pkg.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pkg.description,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: pkg.features.map<Widget>((feature) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F3EE),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check, size: 12, color: AppColors.success),
                                          const SizedBox(width: 4),
                                          Text(
                                            feature,
                                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: AppColors.border, height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _startEdit(pkg),
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textPrimary),
                                      label: const Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: AppColors.surface,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Delete Package?'),
                                            content: const Text('Are you sure you want to remove this service package?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.pop(ctx);
                                                  await ref
                                                      .read(designerPackagesProvider.notifier)
                                                      .deletePackage(pkg.id);
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, st) => Center(child: Text('Error: $err')),
                  ),
                ),
    );
  }
}
