import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/institution_provider.dart';

/// Servicio que maneja la lógica de negocio para operaciones de usuarios
class UserFormService {
  /// Carga un usuario para edición si los parámetros de la ruta lo indican
  Future<User?> loadUserForEditing(
    BuildContext context,
    Map<String, String> queryParams,
  ) async {
    final isEdit = queryParams['edit'] == 'true';
    final userId = queryParams['userId'];

    if (!isEdit || userId == null) {
      return null;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      throw Exception('Debes iniciar sesión para editar usuarios');
    }

    await userProvider.loadUserById(token, userId);
    return userProvider.selectedUser;
  }

  /// Carga instituciones si es necesario para el rol de usuario
  Future<void> loadInstitutionsIfNeeded(
    BuildContext context,
    String userRole,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Solo cargar instituciones si el usuario actual es super_admin y está creando/editando admin_institucion
    if (authProvider.user?['rol'] == 'super_admin' && userRole == 'admin_institucion') {
      final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);

      // Solo cargar si no hay instituciones ya cargadas
      if (institutionProvider.institutions.isEmpty) {
        final token = authProvider.accessToken;
        if (token == null) return;

        await institutionProvider.loadInstitutions(
          token,
          page: 1,
          limit: 100, // Cargar todas para el dropdown
        );
      }
    }
  }

  /// Determina si el usuario está editando su propio perfil
  bool isSelfEditing(User? user, AuthProvider authProvider) {
    if (user == null) return false;

    final sessionUserId = authProvider.user?['id']?.toString();
    return sessionUserId != null && sessionUserId == user.id;
  }

  /// Llena los controladores del formulario con los datos del usuario
  void fillFormWithUserData(
    User user,
    TextEditingController nombresController,
    TextEditingController apellidosController,
    TextEditingController emailController,
    TextEditingController telefonoController,
    TextEditingController identificacionController,
    TextEditingController tituloController,
    TextEditingController especialidadController,
    TextEditingController nombreResponsableController,
    TextEditingController telefonoResponsableController,
    void Function(bool) setActivo,
    void Function(List<String>) setSelectedInstitutionIds,
  ) {
    nombresController.text = user.nombres;
    apellidosController.text = user.apellidos;
    emailController.text = user.email ?? '';
    telefonoController.text = user.telefono ?? '';
    setActivo(user.activo ?? true);

    // Preseleccionar instituciones si existen (un usuario puede pertenecer a varias)
    if (user.instituciones?.isNotEmpty ?? false) {
      setSelectedInstitutionIds(user.instituciones!.map((i) => i.id).toList());
    }

    if (user.estudiante != null) {
      identificacionController.text = user.estudiante!.identificacion;
      nombreResponsableController.text = user.estudiante!.nombreResponsable ?? '';
      telefonoResponsableController.text = user.estudiante!.telefonoResponsable ?? '';
    }

    // Para profesores
    if (user.rol == 'profesor') {
      tituloController.text = user.titulo ?? '';
      especialidadController.text = user.especialidad ?? '';
      identificacionController.text = user.identificacion ?? '';
    }
  }

  /// Valida que todos los steps del formulario sean válidos
  bool validateAllSteps(List<GlobalKey<FormState>> stepKeys) {
    for (final stepKey in stepKeys) {
      final valid = stepKey.currentState?.validate() ?? true;
      if (!valid) {
        return false;
      }
    }
    return true;
  }

  /// Crea la solicitud de creación de usuario
  CreateUserRequest createUserRequest({
    required String email,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String identificacion,
    required String userRole,
    required String titulo,
    required String especialidad,
    required String nombreResponsable,
    required String telefonoResponsable,
    required String? selectedInstitutionId,
    required AuthProvider authProvider,
  }) {
    final tempPassword = generateRandomPassword();

    return CreateUserRequest(
      email: email.trim(),
      password: tempPassword,
      nombres: nombres.trim(),
      apellidos: apellidos.trim(),
      telefono: telefono.trim().isNotEmpty ? telefono.trim() : null,
      identificacion: (userRole == 'estudiante' || userRole == 'profesor') ? identificacion.trim() : null,
      rol: userRole,
      titulo: userRole == 'profesor' ? titulo.trim() : null,
      especialidad: userRole == 'profesor' ? especialidad.trim() : null,
      nombreResponsable: userRole == 'estudiante' ? nombreResponsable.trim().isNotEmpty ? nombreResponsable.trim() : null : null,
      telefonoResponsable: userRole == 'estudiante' ? telefonoResponsable.trim().isNotEmpty ? telefonoResponsable.trim() : null : null,
      institucionId: userRole == 'admin_institucion' ? selectedInstitutionId : authProvider.selectedInstitutionId,
      rolEnInstitucion: userRole == 'admin_institucion' ? 'admin' : null,
    );
  }

  /// Crea la solicitud de actualización de usuario
  UpdateUserRequest createUpdateRequest({
    required String email,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String identificacion,
    required String userRole,
    required String titulo,
    required String especialidad,
    required String nombreResponsable,
    required String telefonoResponsable,
    required bool activo,
  }) {
    return UpdateUserRequest(
      email: email.trim(),
      nombres: nombres.trim(),
      apellidos: apellidos.trim(),
      telefono: telefono.trim().isNotEmpty ? telefono.trim() : null,
      identificacion: (userRole == 'estudiante' || userRole == 'profesor') ? identificacion.trim() : null,
      nombreResponsable: userRole == 'estudiante' ? nombreResponsable.trim().isNotEmpty ? nombreResponsable.trim() : null : null,
      telefonoResponsable: userRole == 'estudiante' ? telefonoResponsable.trim().isNotEmpty ? telefonoResponsable.trim() : null : null,
      activo: activo,
      titulo: userRole == 'profesor' ? titulo.trim() : null,
      especialidad: userRole == 'profesor' ? especialidad.trim() : null,
    );
  }

  /// Guarda el usuario (crea o actualiza)
  Future<bool> saveUser({
    required BuildContext context,
    required User? user,
    required CreateUserRequest? createRequest,
    required UpdateUserRequest? updateRequest,
    required String userRole,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      throw Exception('Debes iniciar sesión para ${user != null ? 'editar' : 'crear'} usuarios');
    }

    if (user != null) {
      // Modo edición
      return await userProvider.updateUser(token, user.id, updateRequest!);
    } else {
      // Modo creación
      return await userProvider.createUser(token, createRequest!);
    }
  }

  /// Genera una contraseña aleatoria segura
  String generateRandomPassword({int length = 12}) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*()';
    final Random random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Obtiene el nombre para mostrar del rol
  String getRoleDisplayName(String role) {
    switch (role) {
      case 'profesor':
        return 'Profesor';
      case 'estudiante':
        return 'Estudiante';
      case 'admin_institucion':
        return 'Administrador de Institución';
      case 'super_admin':
        return 'Super Administrador';
      default:
        return 'Usuario';
    }
  }
}