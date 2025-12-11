import 'package:flutter/material.dart';

/// Servicio que maneja la lógica de validación de formularios
class FormValidationService {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]+$');

  /// Valida un email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }

    final email = value.trim();
    if (!_emailRegex.hasMatch(email)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  /// Valida nombres
  static String? validateNombres(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Los nombres son obligatorios';
    }

    final nombres = value.trim();
    if (nombres.length < 2) {
      return 'Los nombres deben tener al menos 2 caracteres';
    }

    return null;
  }

  /// Valida apellidos
  static String? validateApellidos(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Los apellidos son obligatorios';
    }

    final apellidos = value.trim();
    if (apellidos.length < 2) {
      return 'Los apellidos deben tener al menos 2 caracteres';
    }

    return null;
  }

  /// Valida teléfono
  static String? validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Teléfono es opcional
    }

    final telefono = value.trim();
    if (!_phoneRegex.hasMatch(telefono)) {
      return 'Ingresa un número de teléfono válido';
    }

    return null;
  }

  /// Valida identificación
  static String? validateIdentificacion(String? value, String userRole) {
    // Solo requerido para profesor y estudiante
    if (userRole == 'admin_institucion' || userRole == 'super_admin') {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'La identificación es obligatoria';
    }

    final identificacion = value.trim();
    if (identificacion.length < 5) {
      return 'La identificación debe tener al menos 5 caracteres';
    }

    return null;
  }

  /// Valida título para profesores
  static String? validateTitulo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El título es obligatorio';
    }

    final titulo = value.trim();
    if (titulo.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }

    return null;
  }

  /// Valida especialidad para profesores
  static String? validateEspecialidad(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La especialidad es obligatoria';
    }

    final especialidad = value.trim();
    if (especialidad.length < 3) {
      return 'La especialidad debe tener al menos 3 caracteres';
    }

    return null;
  }

  /// Valida teléfono del responsable para estudiantes
  static String? validateTelefonoResponsable(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Es opcional
    }

    final telefono = value.trim();
    if (!_phoneRegex.hasMatch(telefono)) {
      return 'Ingresa un número de teléfono válido';
    }

    return null;
  }

  /// Enfoca el primer campo inválido en un step específico
  static void focusFirstInvalidField(
    int step,
    String userRole,
    Map<String, TextEditingController> controllers,
    Map<String, FocusNode> focusNodes,
    Map<String, GlobalKey<FormFieldState<String>>> fieldKeys,
  ) {
    if (step == 0) {
      // Step Cuenta
      final email = controllers['email']!.text.trim();
      if (email.isEmpty || !_emailRegex.hasMatch(email)) {
        _focusAndScroll(focusNodes['email']!, fieldKeys['email']!);
        return;
      }
    } else if (step == 1) {
      // Step Info Personal
      final nombres = controllers['nombres']!.text.trim();
      final apellidos = controllers['apellidos']!.text.trim();
      final telefono = controllers['telefono']!.text.trim();
      final identificacion = controllers['identificacion']!.text.trim();

      if (nombres.isEmpty || nombres.length < 2) {
        _focusAndScroll(focusNodes['nombres']!, fieldKeys['nombres']!);
        return;
      }
      if (apellidos.isEmpty || apellidos.length < 2) {
        _focusAndScroll(focusNodes['apellidos']!, fieldKeys['apellidos']!);
        return;
      }
      if (telefono.isNotEmpty && !_phoneRegex.hasMatch(telefono)) {
        _focusAndScroll(focusNodes['telefono']!, fieldKeys['telefono']!);
        return;
      }
      if (!(userRole == 'admin_institucion' || userRole == 'super_admin')) {
        if (identificacion.isEmpty || identificacion.length < 5) {
          _focusAndScroll(
              focusNodes['identificacion']!, fieldKeys['identificacion']!);
          return;
        }
      }
    } else if (step == 2) {
      // Step detalles por rol
      if (userRole == 'profesor') {
        final titulo = controllers['titulo']!.text.trim();
        final especialidad = controllers['especialidad']!.text.trim();
        if (titulo.isEmpty || titulo.length < 3) {
          _focusAndScroll(focusNodes['titulo']!, fieldKeys['titulo']!);
          return;
        }
        if (especialidad.isEmpty || especialidad.length < 3) {
          _focusAndScroll(
              focusNodes['especialidad']!, fieldKeys['especialidad']!);
          return;
        }
      } else if (userRole == 'estudiante') {
        final telefonoResp = controllers['telefonoResponsable']!.text.trim();
        if (telefonoResp.isNotEmpty && !_phoneRegex.hasMatch(telefonoResp)) {
          _focusAndScroll(focusNodes['telefonoResponsable']!,
              fieldKeys['telefonoResponsable']!);
          return;
        }
      }
    }
  }

  static void _focusAndScroll(
      FocusNode focusNode, GlobalKey<FormFieldState<String>> fieldKey) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = fieldKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300));
      }
    });
  }
}
