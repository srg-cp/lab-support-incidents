import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({Key? key}) : super(key: key);

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserIncidents();
  }

  void _loadUserIncidents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final provider = Provider.of<IncidentProvider>(context, listen: false);
      provider.getUserIncidents(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
      ),
      body: Consumer<IncidentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.expand(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar reportes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadUserIncidents,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.incidents.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'Sin reportes',
              message: 'Aún no has reportado ningún incidente.\nToca "Reportar Incidente" para comenzar.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadUserIncidents();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.incidents.length,
              itemBuilder: (context, index) {
                final incident = provider.incidents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IncidentCard(
                    incident: incident,
                    // No pasamos onTap para que no muestre acciones
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}