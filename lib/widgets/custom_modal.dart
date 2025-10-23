import 'package:flutter/material.dart';
import '../utils/colors.dart';

enum ModalType { success, warning, danger, info }

class CustomModal {
  static void show(
    BuildContext context, {
    required ModalType type,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onConfirm,
  }) {
    Color color;
    IconData icon;
    
    switch (type) {
      case ModalType.success:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case ModalType.warning:
        color = AppColors.warning;
        icon = Icons.warning;
        break;
      case ModalType.danger:
        color = AppColors.danger;
        icon = Icons.error;
        break;
      case ModalType.info:
        color = AppColors.info; 
        icon = Icons.info;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(buttonText ?? 'Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showConfirmation(
    BuildContext context, {
    required ModalType type,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    Color color;
    IconData icon;
    
    switch (type) {
          case ModalType.success:
            color = AppColors.success;
            icon = Icons.check_circle;
            break;
          case ModalType.warning:
            color = AppColors.warning;
            icon = Icons.warning;
            break;
          case ModalType.danger:
            color = AppColors.danger;
            icon = Icons.error;
            break;
          case ModalType.info:
            color = AppColors.info; 
            icon = Icons.info;
            break;
        }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.textLight),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        cancelText ?? 'Cancelar',
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(confirmText ?? 'Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
