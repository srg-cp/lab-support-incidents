import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/colors.dart';

class ImageViewer extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback? onDelete;

  const ImageViewer({
    Key? key,
    this.imageUrl,
    this.imageFile,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageFile != null
              ? Image.file(
                  imageFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: AppColors.lightGray,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.accentGold,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: AppColors.lightGray,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 50,
                              color: AppColors.danger,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 200,
                      width: double.infinity,
                      color: AppColors.lightGray,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
        ),
        if (onDelete != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        // Botón para ver en pantalla completa
        if (imageUrl != null || imageFile != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      imageUrl: imageUrl,
                      imageFile: imageFile,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;

  const FullScreenImageViewer({
    Key? key,
    this.imageUrl,
    this.imageFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: imageFile != null
              ? Image.file(imageFile!)
              : imageUrl != null
                  ? Image.network(imageUrl!)
                  : const SizedBox(),
        ),
      ),
    );
  }
}
