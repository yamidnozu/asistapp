import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget _buildUserName(AuthProvider authProvider, TextStyle headlineMedium, Color primary, bool isSmallScreen) {
    final user = authProvider.user;
    final userName = user?['name'] ?? user?['email'] ?? 'Usuario';

    return Text(
      userName,
      style: headlineMedium.copyWith(
        color: primary,
        fontSize: isSmallScreen ? 18 : 24,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSignOutButton(AuthProvider authProvider) {
    return ElevatedButton(
      onPressed: () async {
        await authProvider.logout();
      },
      child: const Text('Cerrar Sesión'),
    );
  }

  Widget _buildBody(AuthProvider authProvider, dynamic textStyles, Color primaryColor, Map<String, dynamic> responsive) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: responsive['maxWidth']),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive['horizontalPadding'],
                        vertical: responsive['verticalPadding'],
                      ),
                      child: Column(
                        children: [
                          _buildUserName(authProvider, textStyles.headlineMedium, primaryColor, responsive['isSmallScreen']),
                          SizedBox(height: responsive['elementSpacing']),

                          const Text(
                            'Has iniciado sesión correctamente',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: responsive['elementSpacing']),

                          _buildSignOutButton(authProvider),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final responsive = ResponsiveUtils.getResponsiveValues(constraints);
          return _buildBody(authProvider, textStyles, colors.primary, responsive);
        },
      ),
    );
  }
}