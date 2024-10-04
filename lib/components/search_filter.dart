// search_filter.dart
import 'package:flutter/material.dart';

class SearchFilter extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchQueryChanged;
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const SearchFilter({
    Key? key,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            onChanged: onSearchQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              hintText: 'Digite o que você procura...',
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => onFilterSelected('Mais recentes'),
              child: FilterButton(
                label: 'Mais recentes',
                isSelected: selectedFilter == 'Mais recentes',
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => onFilterSelected('Mais distantes'),
              child: FilterButton(
                label: 'Mais distantes',
                isSelected: selectedFilter == 'Mais distantes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const FilterButton({
    Key? key,
    required this.label,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected ? Colors.green : Colors.grey[300],
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
    );
  }
}
