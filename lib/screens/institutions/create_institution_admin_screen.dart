import 'package:flutter/material.dart';
// The screen only delegates to UserFormScreen
import '../../models/institution.dart';
// Other providers or widgets are not needed here; functionality is handled by UserFormScreen
import '../users/user_form_screen.dart';

class CreateInstitutionAdminScreen extends StatelessWidget {
  final Institution institution;

  const CreateInstitutionAdminScreen({
    super.key,
    required this.institution,
  });

  @override
  Widget build(BuildContext context) {
    // Delegate the entire user creation flow to the centralized UserFormScreen.
    // We pass the institution id so the form preselects it for admin creation.
    return UserFormScreen(
      userRole: 'admin_institucion',
      initialInstitutionId: institution.id,
    );
  }
}