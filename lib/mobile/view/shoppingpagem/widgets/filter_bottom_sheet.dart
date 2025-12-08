import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart' as bloc_model;

class FilterBottomSheet {
  static void show(BuildContext context) {
    final bloc = context.read<ShoppingPageBlocM>();
    final state = bloc.state;

    // Récupération des marques et tailles depuis le state ou définition locale
    final List<String> brands = ['Nike', 'Adidas', 'Puma', 'Reebok', 'Converse'];
    final List<String> sizes = ['S', 'M', 'L', 'XL', 'XXL'];

    // Variables locales pour gérer l'état des filtres dans le modal
    RangeValues priceRange = RangeValues(
      state.minPrice ?? 0,
      state.maxPrice ?? 1000,
    );
    String selectedBrand = state.selectedBrand ?? '';
    String selectedSize = state.selectedSize ?? '';
    bool onlyInStock = state.onlyInStock ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtres Avancés',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Contenu scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Prix
                          _buildFilterSection(
                            title: '💰 Prix',
                            child: Column(
                              children: [
                                RangeSlider(
                                  values: priceRange,
                                  min: 0,
                                  max: 1000,
                                  divisions: 20,
                                  activeColor: Colors.green,
                                    labels: RangeLabels(
                                      "${priceRange.start.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA",
                                      "${priceRange.end.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA",
                                    ),
                                  onChanged: (values) {
                                    setStateModal(() {
                                      priceRange = values;
                                    });
                                  },
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${priceRange.start.round()} FCFA',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${priceRange.end.round()} FCFA',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section Marque
                          _buildFilterSection(
                            title: '🏷️ Marque',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButton<String>(
                                value:
                                    selectedBrand.isEmpty ? null : selectedBrand,
                                hint: const Text('Toutes les marques'),
                                isExpanded: true,
                                underline: const SizedBox(),
                                icon: Icon(Icons.arrow_drop_down,
                                    color: Colors.green),
                                items: brands.map((String brand) {
                                  return DropdownMenuItem<String>(
                                    value: brand,
                                    child: Text(brand),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setStateModal(() {
                                      selectedBrand = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section Taille
                          _buildFilterSection(
                            title: '📏 Taille',
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: sizes
                                  .map((size) => _buildSizeChip(
                                        size,
                                        selectedSize == size,
                                        () {
                                          setStateModal(() {
                                            selectedSize =
                                                selectedSize == size ? '' : size;
                                          });
                                        },
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section Stock
                          _buildFilterSection(
                            title: '📦 Disponibilité',
                            child: Container(
                              decoration: BoxDecoration(
                                color: onlyInStock
                                    ? Colors.green.shade50
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: onlyInStock
                                      ? Colors.green.shade300
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: CheckboxListTile(
                                title: const Text(
                                  'En stock uniquement',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                    'Afficher seulement les produits disponibles'),
                                value: onlyInStock,
                                activeColor: Colors.green,
                                onChanged: (value) {
                                  if (value != null) {
                                    setStateModal(() {
                                      onlyInStock = value;
                                    });
                                  }
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer avec boutons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Annuler',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              // Appliquer les filtres via le BLoC
                              bloc.add(
                                ApplyAdvancedFiltersEvent(
                                  minPrice: priceRange.start,
                                  maxPrice: priceRange.end,
                                  brand: selectedBrand.isEmpty
                                      ? null
                                      : selectedBrand,
                                  size:
                                      selectedSize.isEmpty ? null : selectedSize,
                                  onlyInStock: onlyInStock,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text('Appliquer',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper pour les sections de filtres
  static Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // Helper pour les chips de taille
  static Widget _buildSizeChip(String size, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade500 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          size,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static String _formatPrice(double value) {
    return "${value.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
  }
}
