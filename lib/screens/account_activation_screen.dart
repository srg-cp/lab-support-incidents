import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AccountActivationScreen extends StatelessWidget {
  const AccountActivationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.account_circle,
                size: 80,
                color: AppColors.primaryBlue,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Título
            const Text(
              'Activando tu cuenta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Descripción
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Estamos configurando tu cuenta por primera vez.\nEsto solo tomará unos segundos.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Indicador de carga
            const CircularProgressIndicator(
              color: AppColors.primaryBlue,
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Texto de estado
            const Text(
              'Por favor espera...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}