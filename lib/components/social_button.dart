import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
  });

  factory SocialButton.apple({VoidCallback? onPressed}) => SocialButton(
    icon: const Icon(Icons.apple, size: 22),
    text: 'Apple',
    onPressed: onPressed,
  );

  factory SocialButton.google({VoidCallback? onPressed}) => SocialButton(
    icon: Image.network(
      'https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png',
      width: 22,
      height: 22,
    ),
    text: 'Sign in with Google',
    onPressed: onPressed,
  );

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: Color(0xFFE7E7EE)),
        foregroundColor: Colors.black87,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}
