import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';
import '../models/institution.dart';

class InstitutionSelectionScreen extends StatefulWidget {
  const InstitutionSelectionScreen({super.key});

  @override
  State<InstitutionSelectionScreen> createState() => _InstitutionSelectionScreenState();
}

class _InstitutionSelectionScreenState extends State<InstitutionSelectionScreen> {
  String? _selectedInstitutionId;
  bool _isLoading = false;

  Map<String, dynamic> _getResponsiveValues(BoxConstraints constraints) {
    return ResponsiveUtils.getResponsiveValues(constraints);
  }

  Widget _buildMainTitle(Map<String, dynamic> responsive) {
    final titleFontSize = responsive['titleFontSize'] as double;

    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Text(
          'Seleccionar Institución',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildSubtitle(Map<String, dynamic> responsive, Color textMuted) {
    final subtitleFontSize = responsive['subtitleFontSize'] as double;

    return Text(
      'Elija la institución con la que desea trabajar',
      style: TextStyle(
        color: textMuted,
        fontSize: subtitleFontSize,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInstitutionList(List<Institution> institutions, Map<String, dynamic> responsive) {
    final bodyFontSize = responsive['bodyFontSize'] as double;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: institutions.length,
      itemBuilder: (context, index) {
        final institution = institutions[index];
        final isSelected = _selectedInstitutionId == institution.id;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
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
              style: TextStyle(
                fontSize: bodyFontSize,
                color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: institution.role != null
                ? Text('Rol: ${institution.role}', style: TextStyle(fontSize: bodyFontSize * 0.9))
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

  Widget _buildContinueButton(Map<String, dynamic> responsive) {
    final buttonWidth = responsive['buttonWidth'] as double;

    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedInstitutionId == null ? null : _continue,
        child: Text(_isLoading ? 'Continuando...' : 'Continuar'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
        child: ResponsiveUtils.buildResponsiveContainer(
          context: context,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final responsive = _getResponsiveValues(constraints);
                    final elementSpacing = responsive['elementSpacing'] as double;

                    return Column(
                      children: [
                        _buildMainTitle(responsive),
                        SizedBox(height: elementSpacing),

                        _buildSubtitle(responsive, colors.textMuted),
                        SizedBox(height: elementSpacing * 1.5),

                        _buildInstitutionList(institutions, responsive),
                        SizedBox(height: elementSpacing * 2),

                        _buildContinueButton(responsive),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (_selectedInstitutionId == null) return;

    setState(() {
      _isLoading = true;
    });

    // Simplemente actualizamos el estado. GoRouter se encargará del resto.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.selectInstitution(_selectedInstitutionId!);

    // Ya no es necesario el context.go() ni manejar el estado de carga aquí,
    // porque la pantalla será reemplazada automáticamente.
  }
}