import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

class GlassTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoicePressed;
  final bool readOnly;
  final VoidCallback? onTap;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText = 'Ask me anything or search...',
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.onVoicePressed,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: AppDimensions.borderFull,
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: AppDimensions.borderFull,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: _isFocused
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: AppDimensions.borderFull,
              border: Border.all(
                color: _isFocused
                    ? AppColors.primaryContainer.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.14),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 10.0),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    style: AppTypography.bodyMedium(color: AppColors.onSurface),
                    cursorColor: AppColors.primaryContainer,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: AppTypography.bodyMedium(color: AppColors.onSurfaceMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8.0),
                  widget.trailing!,
                ] else if (widget.onVoicePressed != null) ...[
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(
                      Icons.mic,
                      color: AppColors.secondaryHighlight,
                      size: 20,
                    ),
                    onPressed: widget.onVoicePressed,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
