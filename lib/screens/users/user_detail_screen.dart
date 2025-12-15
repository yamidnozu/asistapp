import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/gestionar_acudientes_sheet.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import 'dart:math';

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
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          user.nombreCompleto,
          style: textStyles.titleLarge,
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
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
                // Mostrar identificación para todos los usuarios que la tengan
                if (user.esEstudiante && user.estudiante != null)
                  _buildInfoItem(
                      'Identificación', user.estudiante!.identificacion)
                else if (user.identificacion != null &&
                    user.identificacion!.isNotEmpty)
                  _buildInfoItem('Identificación', user.identificacion!),
                _buildInfoItem(
                    'Estado', (user.activo == true) ? 'Activo' : 'Inactivo',
                    valueColor:
                        (user.activo == true) ? colors.success : colors.error),
              ],
            ),

            SizedBox(height: spacing.lg),

            // Información específica para profesores
            if (user.esProfesor) ...[
              _buildInfoSection(
                context,
                'Información del Profesor',
                [
                  if (user.titulo != null && user.titulo!.isNotEmpty)
                    _buildInfoItem('Título', user.titulo!),
                  if (user.especialidad != null &&
                      user.especialidad!.isNotEmpty)
                    _buildInfoItem('Especialidad', user.especialidad!),
                ],
              ),
              SizedBox(height: spacing.lg),
            ],

            // Información específica del rol
            if (user.esEstudiante && user.estudiante != null) ...[
              _buildInfoSection(
                context,
                'Información del Estudiante',
                [
                  _buildInfoItem('Código QR', user.estudiante!.codigoQr),
                  if (user.estudiante!.nombreResponsable != null)
                    _buildInfoItem('Nombre del Responsable',
                        user.estudiante!.nombreResponsable!),
                  if (user.estudiante!.telefonoResponsable != null)
                    _buildInfoItem('Teléfono del Responsable',
                        user.estudiante!.telefonoResponsable!),
                ],
              ),
              SizedBox(height: spacing.md),
              // Botón para gestionar acudientes
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    GestionarAcudientesSheet.show(
                      context,
                      user.estudiante!.id,
                      user.nombreCompleto,
                    );
                  },
                  icon: const Icon(Icons.family_restroom),
                  label: const Text('Gestionar Acudientes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.info,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: spacing.md),
                  ),
                ),
              ),
              SizedBox(height: spacing.lg),
            ],

            // Información de instituciones
            if (user.instituciones?.isNotEmpty ?? false) ...[
              _buildInfoSection(
                context,
                'Instituciones',
                (user.instituciones ?? [])
                    .map((inst) => _buildInfoItem(
                          inst.nombre,
                          _getInstitutionRoleDisplayName(inst.rolEnInstitucion),
                        ))
                    .toList(),
              ),
              SizedBox(height: spacing.lg),
            ],

            // Información adicional
            _buildInfoSection(
              context,
              'Información del Sistema',
              [
                _buildInfoItem('ID de Usuario', user.id),
                _buildInfoItem(
                    'Fecha de Creación',
                    user.createdAt != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt!)
                        : 'No disponible'),
              ],
            ),

            // Botón regenerar contraseña (para todos los usuarios)
            SizedBox(height: spacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRegenerarPasswordDialog(context),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Regenerar Contraseña'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.warning,
                  side: BorderSide(color: colors.warning),
                  padding: EdgeInsets.symmetric(vertical: spacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegenerarPasswordDialog(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: colors.warning),
            SizedBox(width: spacing.sm),
            const Text('Regenerar Contraseña'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '\u00bfEst\u00e1 seguro de regenerar la contrase\u00f1a de ${user.nombreCompleto}?'),
            SizedBox(height: spacing.sm),
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: colors.warning, size: 18),
                  SizedBox(width: spacing.xs),
                  Expanded(
                    child: Text(
                      'La contrase\u00f1a actual ser\u00e1 invalidada.',
                      style: TextStyle(color: colors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _regenerarPassword(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerarPassword(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No hay sesi\u00f3n activa')),
      );
      return;
    }

    // Generar contrase\u00f1a temporal
    final newPassword = _generateRandomPassword();

    final userService = UserService();
    final success =
        await userService.changePassword(token, user.id, newPassword);

    if (success && context.mounted) {
      _showNewPasswordDialog(context, newPassword);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al regenerar la contrase\u00f1a'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _generateRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    const specials = '!@#%^&*';
    final random = Random.secure();

    final password = StringBuffer();
    for (var i = 0; i < 8; i++) {
      password.write(chars[random.nextInt(chars.length)]);
    }
    password.write(specials[random.nextInt(specials.length)]);
    password.write(random.nextInt(10));

    return password.toString();
  }

  void _showNewPasswordDialog(BuildContext context, String password) {
    final colors = context.colors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: colors.success),
            const SizedBox(width: 8),
            const Text('Contrase\u00f1a Regenerada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nueva contrase\u00f1a temporal:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      password,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: password));
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                              content: Text('Contrase\u00f1a copiada')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: colors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Comparta esta contrase\u00f1a con el usuario. No se volver\u00e1 a mostrar.',
                      style: TextStyle(color: colors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, List<Widget> items) {
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
                fontWeight:
                    valueColor != null ? FontWeight.w500 : FontWeight.normal,
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
      case 'acudiente':
        return 'Acudiente';
      default:
        return role;
    }
  }

  String _getInstitutionRoleDisplayName(String? role) {
    if (role == null || role.isEmpty) return 'Sin rol específico';
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'miembro':
      case 'member':
        return 'Miembro';
      case 'director':
        return 'Director';
      case 'profesor':
        return 'Profesor';
      default:
        // Capitalizar la primera letra
        return role[0].toUpperCase() + role.substring(1);
    }
  }
}
