import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.onNextPage,
    required this.onPreviousPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing page $currentPage of ${_calculateTotalPages()}',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                'Total: $totalItems user${totalItems != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 16),
              _buildPageButton(
                icon: Icons.arrow_back_ios,
                enabled: hasPreviousPage,
                onPressed: onPreviousPage,
              ),
              SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.arrow_forward_ios,
                enabled: hasNextPage,
                onPressed: onNextPage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.white),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }

  int _calculateTotalPages() {
    if (totalItems == 0) return 1;
    return (totalItems / 5).ceil(); // Assuming 5 items per page
  }
}
