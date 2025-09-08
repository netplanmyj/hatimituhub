import 'package:flutter/material.dart';
import 'quantity_input.dart';

class ProductSelector extends StatefulWidget {
  final List<dynamic> productTypes;
  final List<dynamic> products;
  final String? initialTypeId;
  final String? initialProductId;
  final int initialQuantity;
  final void Function(String typeId, String productId, int quantity)? onChanged;

  const ProductSelector({
    super.key,
    required this.productTypes,
    required this.products,
    this.initialTypeId,
    this.initialProductId,
    this.initialQuantity = 1,
    this.onChanged,
  });

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  late String selectedTypeId;
  late String selectedProductId;
  late int selectedQuantity;

  @override
  void initState() {
    super.initState();
    selectedTypeId =
        widget.initialTypeId ??
        (widget.productTypes.isNotEmpty
            ? (widget.productTypes.first is Map
                  ? widget.productTypes.first['id']
                  : widget.productTypes.first.id)
            : '');
    final filteredProducts = widget.products
        .where(
          (doc) =>
              (doc is Map
                  ? doc['type']?.toString()
                  : doc['type']?.toString()) ==
              selectedTypeId,
        )
        .toList();
    selectedProductId =
        widget.initialProductId ??
        (filteredProducts.isNotEmpty ? filteredProducts.first.id : '');
    selectedQuantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products
        .where((doc) => doc['type']?.toString() == selectedTypeId)
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<String>(
          value: selectedTypeId,
          items: widget.productTypes.map((typeDoc) {
            final typeName = typeDoc['name'] ?? typeDoc.id;
            final id =
                (typeDoc is Map ? typeDoc['id'] : typeDoc.id)?.toString() ?? '';
            return DropdownMenuItem<String>(value: id, child: Text(typeName));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTypeId =
                  value ??
                  (widget.productTypes.first is Map
                          ? widget.productTypes.first['id']
                          : widget.productTypes.first.id)
                      ?.toString() ??
                  '';
              final filtered = widget.products
                  .where(
                    (doc) =>
                        (doc is Map
                            ? doc['type']?.toString()
                            : doc['type']?.toString()) ==
                        selectedTypeId,
                  )
                  .toList();
              selectedProductId = filtered.isNotEmpty
                  ? (filtered.first is Map
                                ? filtered.first['id']
                                : filtered.first.id)
                            ?.toString() ??
                        ''
                  : '';
              widget.onChanged?.call(
                selectedTypeId,
                selectedProductId,
                selectedQuantity,
              );
            });
          },
        ),
        DropdownButton<String>(
          value: selectedProductId,
          items: filteredProducts.map((doc) {
            final name = doc['name'] ?? '';
            final id = (doc is Map ? doc['id'] : doc.id)?.toString() ?? '';
            return DropdownMenuItem<String>(value: id, child: Text(name));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedProductId = value ?? selectedProductId;
              widget.onChanged?.call(
                selectedTypeId,
                selectedProductId,
                selectedQuantity,
              );
            });
          },
        ),
        QuantityInput(
          quantity: selectedQuantity,
          onChanged: (val) {
            setState(() {
              selectedQuantity = val;
              widget.onChanged?.call(
                selectedTypeId,
                selectedProductId,
                selectedQuantity,
              );
            });
          },
        ),
      ],
    );
  }
}
