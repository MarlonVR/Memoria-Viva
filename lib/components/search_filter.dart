import 'package:flutter/material.dart';

class SearchFilter extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchQueryChanged;
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const SearchFilter({
    super.key,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            onChanged: onSearchQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              hintText: 'Digite o que você procura...',
              hintStyle: const TextStyle(fontSize: 20),
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
            SizedBox(
              width: screenWidth * 0.45,  // 45% da largura da tela
              child: GestureDetector(
                onTap: () => onFilterSelected('Mais recentes'),
                child: FilterButton(
                  label: 'Mais recentes',
                  isSelected: selectedFilter == 'Mais recentes',
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: screenWidth * 0.45,  // 45% da largura da tela
              child: GestureDetector(
                onTap: () => onFilterSelected('Mais distantes'),
                child: FilterButton(
                  label: 'Mais distantes',
                  isSelected: selectedFilter == 'Mais distantes',
                ),
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
    super.key,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected ? const Color.fromARGB(255, 76, 175, 125) : Colors.grey[300],
        border: Border.all(
          color: isSelected ? const Color.fromARGB(255, 76, 175, 125) : Colors.grey,
          width: 2,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }
}
