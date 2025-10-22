import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

/// Card reutilizable que usa el theme del sistema
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Card(
      color: backgroundColor ?? colors.surface,
      elevation: elevation ?? 2,
      shadowColor: colors.shadow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(spacing.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(spacing.borderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.all(spacing.cardPadding),
          child: child,
        ),
      ),
    );
  }
}

/// Scaffold reutilizable con theme integrado
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? appBar;

  const AppScaffold({
    this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.appBar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: appBar ?? (title != null ? AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        shadowColor: colors.shadow,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textStyles.headlineMedium,
        title: Text(title!),
        leading: showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed ?? () => Navigator.maybePop(context),
        ) : null,
        actions: actions,
      ) : null),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.screenPadding),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Texto con theme integrado
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const AppText(
    this.text, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    super.key,
  });

  // Constructores convenientes
  const AppText.headlineLarge(
    this.text, {
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    super.key,
  }) : style = null;

  const AppText.headlineMedium(
    this.text, {
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    super.key,
  }) : style = null;

  const AppText.bodyLarge(
    this.text, {
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    super.key,
  }) : style = null;

  const AppText.bodyMedium(
    this.text, {
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    super.key,
  }) : style = null;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    TextStyle resolvedStyle;
    if (style != null) {
      resolvedStyle = style!;
    } else {
      // Determinar el estilo basado en el constructor usado
      final constructorName = runtimeType.toString();
      if (constructorName.contains('headlineLarge')) {
        resolvedStyle = textStyles.headlineLarge;
      } else if (constructorName.contains('headlineMedium')) {
        resolvedStyle = textStyles.headlineMedium;
      } else if (constructorName.contains('bodyLarge')) {
        resolvedStyle = textStyles.bodyLarge;
      } else {
        resolvedStyle = textStyles.bodyMedium;
      }
    }

    return Text(
      text,
      style: resolvedStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Espaciador con theme integrado
class AppSpacer extends StatelessWidget {
  final double? width;
  final double? height;

  const AppSpacer({this.width, this.height, super.key});

  // Espaciadores convenientes
  const AppSpacer.xs({super.key}) : width = null, height = null;
  const AppSpacer.sm({super.key}) : width = null, height = null;
  const AppSpacer.md({super.key}) : width = null, height = null;
  const AppSpacer.lg({super.key}) : width = null, height = null;
  const AppSpacer.xl({super.key}) : width = null, height = null;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    double resolvedWidth = width ?? 0;
    double resolvedHeight = height ?? 0;

    // Si no se especificaron dimensiones, usar el espaciado basado en el constructor
    if (width == null && height == null) {
      final constructorName = runtimeType.toString();
      if (constructorName.contains('xs')) {
        resolvedHeight = spacing.xs;
      } else if (constructorName.contains('sm')) {
        resolvedHeight = spacing.sm;
      } else if (constructorName.contains('md')) {
        resolvedHeight = spacing.md;
      } else if (constructorName.contains('lg')) {
        resolvedHeight = spacing.lg;
      } else if (constructorName.contains('xl')) {
        resolvedHeight = spacing.xl;
      }
    }

    return SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
    );
  }
}