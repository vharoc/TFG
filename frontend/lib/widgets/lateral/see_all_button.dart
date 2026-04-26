import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class LateralSeeAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const LateralSeeAllButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Ver todo',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.usal,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: AppTheme.usal,
            ),
          ],
        ),
      ),
    );
  }
}
