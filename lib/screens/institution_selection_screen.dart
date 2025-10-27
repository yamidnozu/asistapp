import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../screens/home_screen.dart';
import '../screens/super_admin_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';
import '../models/institution.dart';

class InstitutionSelectionScreen extends StatefulWidget {
  const InstitutionSelectionScreen({super.key});

  @override
  State<InstitutionSelectionScreen> createState() => _InstitutionSelectionScreenState();
}

class _InstitutionSelectionScreenState extends State<InstitutionSelectionScreen> {
  String? _selectedInstitutionId;
  bool _isLoading = false;
  Map<String, dynamic> _getResponsiveValues(BoxConstraints constraints, double lg, double xxl, double xl, double sm, double md) {
    final isSmallScreen = constraints.maxWidth < 600;
    final horizontalPadding = isSmallScreen ? lg : xxl;
    final verticalPadding = isSmallScreen ? xl : xxl * 2;
    final titleSpacing = isSmallScreen ? sm : md;
    final subtitleSpacing = isSmallScreen ? xl : xxl;

    return {
      'isSmallScreen': isSmallScreen,
      'horizontalPadding': horizontalPadding,
      'verticalPadding': verticalPadding,
      'titleSpacing': titleSpacing,
      'subtitleSpacing': subtitleSpacing,
    };
  }
  Widget _buildMainTitle(TextStyle displayLarge, bool isSmallScreen) {
    return Text(
      'Seleccionar Institución',
      style: displayLarge.copyWith(
        fontSize: isSmallScreen ? 28 : 40,
      ),
      textAlign: TextAlign.center,
    );
  }
  Widget _buildSubtitle(TextStyle bodyMedium, Color textMuted, bool isSmallScreen) {
    return Text(
      'Elija la institución con la que desea trabajar',
      style: bodyMedium.copyWith(
        color: textMuted,
        fontSize: isSmallScreen ? 14 : 16,
      ),
      textAlign: TextAlign.center,
    );
  }
  Widget _buildInstitutionList(List<Institution> institutions, ColorScheme colorScheme, TextStyle bodyLarge) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: institutions.length,
      itemBuilder: (context, index) {
        final institution = institutions[index];
        final isSelected = _selectedInstitutionId == institution.id;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          child: ListTile(
            leading: Radio<String>(
              value: institution.id,
              groupValue: _selectedInstitutionId,
              onChanged: (value) {
                setState(() {
                  _selectedInstitutionId = value;
                });
              },
            ),
            title: Text(
              institution.name,
              style: bodyLarge.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            subtitle: institution.role != null
                ? Text('Rol: ${institution.role}')
                : null,
            onTap: () {
              setState(() {
                _selectedInstitutionId = institution.id;
              });
            },
          ),
        );
      },
    );
  }
  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _isLoading || _selectedInstitutionId == null ? null : _continue,
      child: Text(_isLoading ? 'Continuando...' : 'Continuar'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    final authProvider = Provider.of<AuthProvider>(context);
    final institutions = authProvider.institutions;

    if (institutions == null || institutions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No hay instituciones disponibles'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final responsive = _getResponsiveValues(constraints, spacing.lg, spacing.xxl, spacing.xl, spacing.sm, spacing.md);
            final isSmallScreen = responsive['isSmallScreen'] as bool;
            final horizontalPadding = responsive['horizontalPadding'] as double;
            final verticalPadding = responsive['verticalPadding'] as double;
            final titleSpacing = responsive['titleSpacing'] as double;
            final subtitleSpacing = responsive['subtitleSpacing'] as double;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: AppConstants.instance.maxScreenWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildMainTitle(textStyles.displayLarge, isSmallScreen),
                      SizedBox(height: titleSpacing),
                      _buildSubtitle(textStyles.bodyMedium, colors.textMuted, isSmallScreen),
                      SizedBox(height: subtitleSpacing),
                      _buildInstitutionList(institutions, context.colorScheme, textStyles.bodyLarge),
                      SizedBox(height: spacing.xxl),
                      _buildContinueButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (_selectedInstitutionId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.selectInstitution(_selectedInstitutionId!);
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        final userRole = user?['rol'] as String?;

        Widget dashboard;
        switch (userRole) {
          case 'super_admin':
            dashboard = const SuperAdminDashboard();
            break;
          case 'admin_institucion':
            dashboard = const AdminDashboard();
            break;
          case 'profesor':
            dashboard = const TeacherDashboard();
            break;
          case 'estudiante':
            dashboard = const StudentDashboard();
            break;
          default:
            dashboard = const HomeScreen();
            break;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => dashboard,
          ),
        );
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}