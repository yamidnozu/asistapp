import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../theme/theme_extensions.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.nombreCompleto,
          style: textStyles.titleLarge,
        ),
        backgroundColor: colors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/users');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica
            _buildInfoSection(
              context,
              'Información Básica',
              [
                _buildInfoItem('Nombres', user.nombres),
                _buildInfoItem('Apellidos', user.apellidos),
                _buildInfoItem('Email', user.email ?? 'No especificado'),
                _buildInfoItem('Teléfono', user.telefono ?? 'No especificado'),
                _buildInfoItem('Rol', _getRoleDisplayName(user.rol ?? '')),
                _buildInfoItem('Estado', (user.activo == true) ? 'Activo' : 'Inactivo',
                    valueColor: (user.activo == true) ? colors.success : colors.error),
              ],
            ),

            SizedBox(height: spacing.lg),

            // Información específica del rol
            if (user.esEstudiante && user.estudiante != null) ...[
              _buildInfoSection(
                context,
                'Información del Estudiante',
                [
                  _buildInfoItem('Identificación', user.estudiante!.identificacion),
                  _buildInfoItem('Código QR', user.estudiante!.codigoQr),
                  if (user.estudiante!.nombreResponsable != null)
                    _buildInfoItem('Nombre del Responsable', user.estudiante!.nombreResponsable!),
                  if (user.estudiante!.telefonoResponsable != null)
                    _buildInfoItem('Teléfono del Responsable', user.estudiante!.telefonoResponsable!),
                ],
              ),
              SizedBox(height: spacing.lg),
            ],

            // Información de instituciones
            if (user.instituciones?.isNotEmpty ?? false) ...[
              _buildInfoSection(
                context,
                'Instituciones',
                (user.instituciones ?? []).map((inst) => _buildInfoItem(
                  inst.nombre,
                  inst.rolEnInstitucion ?? 'Sin rol específico',
                )).toList(),
              ),
              SizedBox(height: spacing.lg),
            ],

            // Información adicional
            _buildInfoSection(
              context,
              'Información del Sistema',
              [
                _buildInfoItem('ID de Usuario', user.id),
                _buildInfoItem('Fecha de Creación', user.createdAt != null 
                  ? _formatDate(user.createdAt!) 
                  : 'No disponible'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> items) {
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textStyles.titleMedium.bold,
            ),
            SizedBox(height: spacing.md),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrador';
      case 'admin_institucion':
        return 'Administrador de Institución';
      case 'profesor':
        return 'Profesor';
      case 'estudiante':
        return 'Estudiante';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}