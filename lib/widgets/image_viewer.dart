import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/colors.dart';
import '../services/storage_service.dart';

class ImageViewer extends StatelessWidget {
  final String? imageBase64; // Cambiado de imageUrl a imageBase64
  final File? imageFile;
  final VoidCallback? onDelete;

  const ImageViewer({
    Key? key,
    this.imageBase64,
    this.imageFile,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    
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
              : imageBase64 != null
                  ? _buildBase64Image(storageService, imageBase64!)
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
        if (imageBase64 != null || imageFile != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      imageBase64: imageBase64,
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

  Widget _buildBase64Image(StorageService storageService, String base64String) {
    try {
      final bytes = storageService.base64ToBytes(base64String);
      return Image.memory(
        bytes,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
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
      );
    } catch (e) {
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
    }
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String? imageBase64;
  final File? imageFile;

  const FullScreenImageViewer({
    Key? key,
    this.imageBase64,
    this.imageFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    
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
              : imageBase64 != null
                  ? Image.memory(storageService.base64ToBytes(imageBase64!))
                  : const SizedBox(),
        ),
      ),
    );
  }
}
