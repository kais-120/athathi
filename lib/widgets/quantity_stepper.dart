import 'package:flutter/material.dart';

/// − 3 + control. The "+" button is disabled at [max].
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.max,
    required this.onChanged,
  });

  final int quantity;
  final int max;

  /// Called with the new quantity (may be 0, meaning "remove").
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
          onPressed: onPressed,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, 'إنقاص', () => onChanged(quantity - 1)),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          button(Icons.add, 'زيادة',
              quantity >= max ? null : () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}
