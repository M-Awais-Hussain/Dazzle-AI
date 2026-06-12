import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/user/marketplace/application/product_controller.dart';
import 'package:ayyy/features/user/marketplace/application/ai_room_controller.dart';
import 'package:ayyy/features/user/marketplace/presentation/ai_room_sheet.dart';
import 'package:ayyy/features/common/review/application/review_controller.dart';
import 'package:ayyy/features/user/marketplace/application/product_variant_providers.dart';
import 'package:ayyy/features/user/marketplace/domain/product_variant.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductDetailsScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productDetailState = ref.watch(productDetailsProvider(widget.id));

    return Scaffold(
      appBar: const DazzleAppBar(
        showBackButton: true,
      ),
      body: productDetailState.when(
        data: (product) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product images carousel
                    Consumer(
                      builder: (context, ref, child) {
                        final images = ref.watch(activeProductVariantImagesProvider(widget.id));
                        
                        // Preload images to prevent flashing on switch
                        for (final url in images) {
                          precacheImage(NetworkImage(url), context);
                        }

                        // Ensure index is valid for the current images length
                        if (images.isNotEmpty && _currentImageIndex >= images.length) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _currentImageIndex = 0;
                              });
                            }
                          });
                        }

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: Container(
                            key: ValueKey(images.isNotEmpty ? images.join() : 'empty'),
                            height: 300,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EDE6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: images.isNotEmpty
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: PageView.builder(
                                          // Recreate PageController if images change substantially, 
                                          // though AnimatedSwitcher + ValueKey handles the replacement mostly.
                                          itemCount: images.length,
                                          onPageChanged: (index) {
                                            setState(() {
                                              _currentImageIndex = index;
                                            });
                                          },
                                          itemBuilder: (context, index) {
                                            return Image.network(
                                              images[index],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Center(
                                                child: Icon(Icons.chair_outlined, size: 80, color: AppColors.textSecondary),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (images.length > 1)
                                        Positioned(
                                          right: 16,
                                          bottom: 16,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${_currentImageIndex + 1}/${images.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : const Center(
                                    child: Icon(Icons.chair_outlined, size: 80, color: AppColors.textSecondary),
                                  ),
                          ),
                        );
                      }
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Series label
                          Text(
                            '${product.category.toUpperCase()} COLLECTION',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Product name
                          Text(
                            product.name,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final stats = ref.watch(productRatingStatsProvider(widget.id));
                              if (stats.totalReviews == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${stats.averageRating.toStringAsFixed(1)} (${stats.totalReviews} ${stats.totalReviews == 1 ? "Review" : "Reviews"})',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Price & delivery
                          Text(
                            'Rs. ${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                'Free White Glove Delivery',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                product.stock > 0 ? Icons.inventory_2_outlined : Icons.warning_amber_rounded,
                                size: 14,
                                color: product.stock > 0 ? AppColors.textSecondary : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                product.stock > 0 ? '${product.stock} in stock' : 'Out of stock',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: product.stock > 0 ? AppColors.textSecondary : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Variants Selection
                          _buildVariantsSection(context, ref),

                          // Divider
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 16),

                          // Design Philosophy
                          Text(
                            'Design Philosophy',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description.isNotEmpty
                                ? product.description
                                : 'A premium interior piece, crafted to elevate the warmth, texture, and aesthetic flow of your home space.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),



                          // Dimensions
                          if (product.dimensions.isNotEmpty || product.material.isNotEmpty) ...[
                            Text(
                              'PRODUCT DETAILS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3EE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  if (product.dimensions.isNotEmpty)
                                    _DimensionItem(label: 'DIMENSIONS', value: product.dimensions),
                                  if (product.dimensions.isNotEmpty && product.material.isNotEmpty)
                                    Container(width: 1, height: 28, color: AppColors.border),
                                  if (product.material.isNotEmpty)
                                    _DimensionItem(label: 'MATERIAL', value: product.material),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],


                          // Reviews Section
                          Consumer(
                            builder: (context, ref, child) {
                              final stats = ref.watch(productRatingStatsProvider(widget.id));
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer Reviews',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Rating stats summary card
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        // Big average rating
                                        Column(
                                          children: [
                                            Text(
                                              stats.totalReviews > 0
                                                  ? stats.averageRating.toStringAsFixed(1)
                                                  : '0.0',
                                              style: GoogleFonts.inter(
                                                fontSize: 40,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: List.generate(
                                                5,
                                                (index) => Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: index < stats.averageRating.round()
                                                      ? Colors.amber
                                                      : AppColors.textSecondary.withValues(alpha: 0.3),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${stats.totalReviews} ${stats.totalReviews == 1 ? "review" : "reviews"}',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 20),
                                        // Progress lines
                                        Expanded(
                                          child: Column(
                                            children: List.generate(5, (index) {
                                              final starLevel = 5 - index;
                                              final count = stats.starBreakdown[starLevel] ?? 0;
                                              final double percent = stats.totalReviews > 0
                                                  ? count / stats.totalReviews
                                                  : 0.0;

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      '$starLevel',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(2),
                                                        child: LinearProgressIndicator(
                                                          value: percent,
                                                          backgroundColor: const Color(0xFFF5F3EE),
                                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                                            AppColors.primary,
                                                          ),
                                                          minHeight: 4,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    SizedBox(
                                                      width: 14,
                                                      child: Text(
                                                        '$count',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                        textAlign: TextAlign.end,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // List of reviews
                                  ref.watch(productReviewsProvider(widget.id)).when(
                                        data: (reviews) {
                                          if (reviews.isEmpty) {
                                            return Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 28),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F3EE),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'No product reviews written yet.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          return ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: reviews.length,
                                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                                            itemBuilder: (context, index) {
                                              final r = reviews[index];
                                              final dateFormatted = '${r.createdAt.year}/${r.createdAt.month}/${r.createdAt.day}';

                                              return Container(
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF5F3EE),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: r.reviewerAvatarUrl != null &&
                                                                  r.reviewerAvatarUrl!.isNotEmpty
                                                              ? ClipRRect(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  child: Image.network(
                                                                    r.reviewerAvatarUrl!,
                                                                    fit: BoxFit.cover,
                                                                    errorBuilder: (context, e, st) =>
                                                                        const Icon(Icons.person,
                                                                            size: 16,
                                                                            color: AppColors.textSecondary),
                                                                  ),
                                                                )
                                                              : const Icon(Icons.person,
                                                                  size: 16, color: AppColors.textSecondary),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    r.reviewerName ?? 'Verified Buyer',
                                                                    style: GoogleFonts.inter(
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: AppColors.textPrimary,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 6),
                                                                  // Verified Badge
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                        horizontal: 6, vertical: 2),
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.success.withValues(alpha: 0.1),
                                                                      borderRadius: BorderRadius.circular(4),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        const Icon(Icons.verified,
                                                                            color: AppColors.success, size: 10),
                                                                        const SizedBox(width: 2),
                                                                        Text(
                                                                          'VERIFIED BUYER',
                                                                          style: GoogleFonts.inter(
                                                                            fontSize: 7,
                                                                            fontWeight: FontWeight.w900,
                                                                            color: AppColors.success,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                dateFormatted,
                                                                style: GoogleFonts.inter(
                                                                  fontSize: 10,
                                                                  color: AppColors.textSecondary,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Row(
                                                          children: List.generate(
                                                            5,
                                                            (i) => Icon(
                                                              Icons.star,
                                                              size: 10,
                                                              color: i < r.rating
                                                                  ? Colors.amber
                                                                  : AppColors.textSecondary.withValues(alpha: 0.2),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      r.review,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: AppColors.textPrimary,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        loading: () => const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        error: (e, _) => const SizedBox.shrink(),
                                      ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // VIEW IN MY ROOM + EXTERNAL LINK
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Detect currently selected product image from provider
                                final activeImageUrl = ref.read(activeProductImageUrlProvider(widget.id));
                                String selectedImage = activeImageUrl ?? '';
                                
                                if (selectedImage.isEmpty) {
                                  final images = <String>[];
                                  if (product.imageUrl.isNotEmpty) {
                                    images.add(product.imageUrl);
                                  }
                                  for (final url in product.imageUrls) {
                                    if (url.isNotEmpty && !images.contains(url)) {
                                      images.add(url);
                                    }
                                  }
                                  selectedImage = images.isNotEmpty
                                      ? images[_currentImageIndex.clamp(0, images.length - 1)]
                                      : '';
                                }
                                if (selectedImage.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No product image available')),
                                  );
                                  return;
                                }

                                // Capture router before async gap
                                final router = GoRouter.of(context);

                                // Show room image selection bottom sheet
                                final source = await showModalBottomSheet<ImageSource>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const AiRoomSheet(),
                                );
                                if (source == null || !mounted) return;

                                // Pick room image
                                final picker = ImagePicker();
                                final file = await picker.pickImage(
                                  source: source,
                                  maxWidth: 1920,
                                  maxHeight: 1920,
                                  imageQuality: 85,
                                );
                                if (file == null || !mounted) return;

                                // Start AI generation pipeline (Canvas Editor Flow)
                                ref.read(aiRoomControllerProvider.notifier).prepareCanvas(
                                  product: product,
                                  selectedImageUrl: selectedImage,
                                  roomImagePath: file.path,
                                );

                                // Navigate to canvas editor screen
                                router.push('/marketplace/product/${product.id}/canvas-editor');
                              },
                              icon: const Icon(Icons.view_in_ar, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'VIEW IN MY ROOM',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final hasCoupon = product.couponCode != null && product.couponCode!.isNotEmpty;
                                final scaffoldMessenger = ScaffoldMessenger.of(context);

                                if (hasCoupon) {
                                  await Clipboard.setData(ClipboardData(text: product.couponCode!));
                                  if (!mounted) return;
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                          const SizedBox(width: 8),
                                          Text('Coupon ${product.couponCode} copied successfully!'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }

                                if (product.purchaseLink.isNotEmpty) {
                                  String urlString = product.purchaseLink;
                                  if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                    urlString = 'https://$urlString';
                                  }
                                  final uri = Uri.tryParse(urlString);
                                  if (uri != null) {
                                    try {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      if (!mounted) return;
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(content: Text('Could not open external store link')),
                                      );
                                    }
                                  } else {
                                    if (!mounted) return;
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(content: Text('Invalid store link provided for this product')),
                                    );
                                  }
                                } else {
                                  if (!mounted) return;
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(content: Text('No external store link provided for this product')),
                                  );
                                }
                              },
                              icon: Icon(
                                product.couponCode != null && product.couponCode!.isNotEmpty
                                    ? Icons.discount_outlined
                                    : Icons.storefront_outlined,
                                size: 16,
                              ),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  product.couponCode != null && product.couponCode!.isNotEmpty
                                      ? 'BUY WITH COUPON'
                                      : 'VISIT STORE',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF333333),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (product.couponCode != null && product.couponCode!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_offer, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              product.couponDescription?.isNotEmpty == true 
                                  ? product.couponDescription! 
                                  : 'Use code at checkout:',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.couponCode!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Failed to load product: $e',
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildVariantsSection(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(productColorVariantsProvider(widget.id));
    final imagesAsync = ref.watch(productVariantImagesProvider(widget.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colors
        colorsAsync.when(
          data: (colors) {
            if (colors.isEmpty) return const SizedBox.shrink();
            final selectedColor = ref.watch(selectedColorVariantProvider)[widget.id];
            
            // Filter colors to only those that have a linked image
            final List<ProductVariant> colorsWithImages = [];
            if (imagesAsync.hasValue) {
              for (final c in colors) {
                final hasImage = imagesAsync.value!.any((img) => img.colorVariantId == c.id);
                if (hasImage) {
                  colorsWithImages.add(c);
                }
              }
            } else {
              // While loading images, we might want to show all colors or none.
              // Let's show none until we know which ones have images to avoid pop-in
              return const SizedBox.shrink();
            }

            if (colorsWithImages.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COLOR',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colorsWithImages.map((colorVariant) {
                    final isSelected = selectedColor?.id == colorVariant.id;
                    final c = _hexToColor(colorVariant.hexCode ?? '#FFFFFF');

                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedColorVariantProvider.notifier).select(widget.id, colorVariant);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.black12,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        ),


      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}


class _DimensionItem extends StatelessWidget {
  final String label;
  final String value;
  const _DimensionItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
