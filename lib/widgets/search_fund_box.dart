import 'package:flutter/material.dart';

class SearchFundBox extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onAddFavorite;
  final bool isFavorite;

  const SearchFundBox({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onAddFavorite,
    required this.isFavorite,
  });

  @override
  State<SearchFundBox> createState() => _SearchFundBoxState();
}

class _SearchFundBoxState extends State<SearchFundBox> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: 'Fund Code (e.g., KLU)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => widget.onSearch(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Get Fund'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: widget.onAddFavorite,
                icon: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : null,
                ),
                label: const Text('Favorite'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
