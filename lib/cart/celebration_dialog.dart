import 'package:flutter/material.dart';
import 'package:new_project/order/order_medicine.dart';

class CelebrationDialog extends StatefulWidget {
  const CelebrationDialog({super.key});

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Festive icon container with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Festive title with gradient text
                ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [Colors.orange.shade600, Colors.amber.shade400],
                      ).createShader(bounds),
                  child: Text(
                    'Order Confirmed!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Important for ShaderMask to work
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle with festive accent
                Text(
                  'Your order has been placed successfully!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Festive button with gradient
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.amber.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor:
                          Colors.transparent, // Important for gradient
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderMedicine(),
                          ),
                        ),

                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
