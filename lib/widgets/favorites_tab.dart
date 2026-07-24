import 'package:flutter/material.dart';

class FavoritesTab extends StatelessWidget {
  final List<String> favorites;
  final void Function(String) onFavoriteSelected;

  const FavoritesTab({
    super.key,
    required this.favorites,
    required this.onFavoriteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return favorites.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No favorites yet.\nAdd a fund to favorites to see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final code = favorites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => onFavoriteSelected(code),
                ),
              );
            },
          );
  }
}
