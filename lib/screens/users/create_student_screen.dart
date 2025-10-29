import 'package:flutter/material.dart';
import 'user_form_screen.dart';

class CreateStudentScreen extends StatelessWidget {
  const CreateStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UserFormScreen(userRole: 'estudiante');
  }
}