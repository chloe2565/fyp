import 'package:flutter/material.dart';

class CustomDropdownMulti extends StatefulWidget {
  final Map<String, String> allItems;
  final Map<String, String> selectedItems;
  final ValueChanged<Map<String, String>> onChanged;
  final String? hint;
  final String? Function(Map<String, String>?)? validator;
  final bool enabled;
  final bool showSubtitle;

  const CustomDropdownMulti({
    Key? key,
    required this.allItems,
    required this.selectedItems,
    required this.onChanged,
    this.hint,
    this.validator,
    this.enabled = true,
    this.showSubtitle = true,
  }) : super(key: key);

  @override
  State<CustomDropdownMulti> createState() => CustomDropdownMultiState();
}

class CustomDropdownMultiState extends State<CustomDropdownMulti> {
  OverlayEntry? overlayEntry;
  final LayerLink layerLink = LayerLink();
  bool isOpen = false;
  String? errorText;
  Map<String, String> localSelectedItems = {};

  @override
  void dispose() {
    removeOverlay();
    super.dispose();
  }

  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
    isOpen = false;
  }

  void validate() {
    if (widget.validator != null) {
      setState(() {
        errorText = widget.validator!(widget.selectedItems);
      });
    }
  }

  void toggleDropdown() {
    if (!widget.enabled) return;

    if (isOpen) {
      removeOverlay();
      setState(() => isOpen = false);
    } else {
      showOverlay();
      setState(() => isOpen = true);
    }
  }

  void showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    const double dropdownHeight = 350;
    const double spacing = 4;

    // Calculate available space
    final spaceBelow = screenHeight - offset.dy - size.height - spacing;
    final spaceAbove = offset.dy - spacing;

    // Determine show above or below
    final showAbove = spaceBelow < dropdownHeight && spaceAbove > spaceBelow;

    // Calculate actual dropdown height based on available space
    final actualHeight = showAbove
        ? (spaceAbove < dropdownHeight ? spaceAbove : dropdownHeight)
        : (spaceBelow < dropdownHeight ? spaceBelow : dropdownHeight);

    // Calculate position
    final topPosition = showAbove
        ? offset.dy - actualHeight - spacing
        : offset.dy + size.height + spacing;

    final sortedEntries = widget.allItems.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Initialize local selected items from widget
    localSelectedItems = Map.from(widget.selectedItems);

    overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            removeOverlay();
            setState(() => isOpen = false);
          },
          child: Stack(
            children: [
              Positioned(
                left: offset.dx.clamp(0.0, screenWidth - size.width),
                top: topPosition.clamp(0.0, screenHeight - actualHeight),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width,
                      minWidth: size.width,
                      maxHeight: actualHeight,
                      minHeight: 100,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${localSelectedItems.length} selected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (localSelectedItems.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      localSelectedItems = {};
                                      widget.onChanged({});
                                      validate();
                                      setOverlayState(() {});
                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Clear All',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // List
                          Expanded(
                            child: widget.allItems.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No items available',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    shrinkWrap: true,
                                    itemCount: sortedEntries.length,
                                    itemBuilder: (context, index) {
                                      final entry = sortedEntries[index];
                                      final id = entry.key;
                                      final name = entry.value;
                                      final isSelected =
                                          localSelectedItems.containsKey(id);

                                      return CheckboxListTile(
                                        dense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 0,
                                        ),
                                        title: Text(
                                          name,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        subtitle: widget.showSubtitle
                                            ? Text(
                                                id,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : null,
                                        value: isSelected,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        onChanged: (bool? checked) {
                                          final updatedSelection =
                                              Map<String, String>.from(
                                                  localSelectedItems);
                                          if (checked == true) {
                                            updatedSelection[id] = name;
                                          } else {
                                            updatedSelection.remove(id);
                                          }
                                          localSelectedItems = updatedSelection;
                                          widget.onChanged(updatedSelection);
                                          validate();
                                          setOverlayState(() {});
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                removeOverlay();
                                setState(() => isOpen = false);
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Done'),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: layerLink,
          child: InkWell(
            onTap: toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: widget.enabled ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: errorText != null
                      ? Theme.of(context).colorScheme.error
                      : isOpen
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedItems.isEmpty
                          ? widget.hint ?? 'Select items'
                          : '${widget.selectedItems.length} selected',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: widget.selectedItems.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: widget.enabled
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}