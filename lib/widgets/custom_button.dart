import 'package:flutter/material.dart';
import 'package:plantmitra_1/theme/app_colors.dart';
import 'package:plantmitra_1/theme/app_text_styles.dart';

enum ButtonType {
  primary,
  outline,
  google,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final Widget? leading;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.leading,
    this.height = 55,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide border;

    switch (type) {
      case ButtonType.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.white;
        border = BorderSide.none;
        break;

      case ButtonType.outline:
        backgroundColor = AppColors.white;
        foregroundColor = AppColors.primary;
        border = BorderSide(
          color: AppColors.primary,
          width: 1.5,
        );
        break;

      case ButtonType.google:
        backgroundColor = AppColors.white;
        foregroundColor = Colors.black87;
        border = BorderSide(
          color: AppColors.border,
        );
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: type == ButtonType.primary ? 2 : 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: border,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}