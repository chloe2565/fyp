import 'package:flutter/material.dart';

class CustomDropdownSingle extends StatefulWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final String? Function(String?)? validator;
  final bool enabled;

  const CustomDropdownSingle({
    Key? key,
    this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CustomDropdownSingle> createState() => CustomDropdownSingleState();
}

class CustomDropdownSingleState extends State<CustomDropdownSingle> {
  OverlayEntry? overlayEntry;
  final LayerLink layerLink = LayerLink();
  bool isOpen = false;
  String? errorText;

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
        errorText = widget.validator!(widget.value);
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

    const double maxDropdownHeight = 250;
    const double spacing = 4;

    // Calculate available space
    final spaceBelow = screenHeight - offset.dy - size.height - spacing;
    final spaceAbove = offset.dy - spacing;

    // Determine if we should show above or below
    final showAbove = spaceBelow < maxDropdownHeight && spaceAbove > spaceBelow;

    // Calculate actual dropdown height
    final itemHeight = 48.0;
    final calculatedHeight = (widget.items.length * itemHeight).clamp(50.0, maxDropdownHeight);
    final actualHeight = showAbove
        ? (spaceAbove < calculatedHeight ? spaceAbove : calculatedHeight)
        : (spaceBelow < calculatedHeight ? spaceBelow : calculatedHeight);

    // Calculate position
    final topPosition = showAbove
        ? offset.dy - actualHeight - spacing
        : offset.dy + size.height + spacing;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
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
                    minHeight: 50,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final isSelected = widget.value == item;

                        return InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            removeOverlay();
                            setState(() => isOpen = false);
                            validate();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange.shade50
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item[0].toUpperCase() + item.substring(1),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                      ? Colors.red
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
                      widget.value != null
                          ? widget.value![0].toUpperCase() +
                              widget.value!.substring(1)
                          : widget.hint ?? 'Select',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: widget.value != null ? Colors.black : Colors.grey,
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
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}