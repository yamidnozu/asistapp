import 'package:flutter/material.dart';
import 'user_form_screen.dart';

class CreateProfessorScreen extends StatelessWidget {
  const CreateProfessorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UserFormScreen(userRole: 'profesor');
  }
}