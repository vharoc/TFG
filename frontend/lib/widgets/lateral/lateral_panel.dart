import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'empty_card.dart';
import 'section_header.dart';
import 'see_all_button.dart';

class LateralPanel<T> extends StatelessWidget {
  final String header;
  final String emptyMessage;
  final String collapseLabel;
  final bool expanded;
  final bool loading;
  final List<T> items;
  final double spacing;
  final int maxItems;
  final ScrollController scrollController;

  final Widget Function(T item) itemBuilder;

  final VoidCallback onExpand;
  final VoidCallback onCollapse;


  const LateralPanel({
    super.key,
    required this.header,
    required this.emptyMessage,
    required this.collapseLabel,
    required this.expanded,
    required this.loading,
    required this.items,
    required this.spacing,
    required this.maxItems,
    required this.scrollController,
    required this.itemBuilder,
    required this.onExpand,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context){
    if(expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(header: header),
          SizedBox(height: spacing),
          Flexible(child: _buildExpandedContent(),),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onCollapse,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  collapseLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.usal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(header: header),
        SizedBox(height: spacing),
        _buildCollapsedContent(),
      ],
    );
  }

  Widget _buildExpandedContent(){
    if(loading) return const Center(child: CircularProgressIndicator());

    if(items.isEmpty) return LateralEmptyCard(mensaje: emptyMessage);

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return itemBuilder(item);
        }
      ),
    );
  }


  Widget _buildCollapsedContent() {
    if(loading) return const Center(child: CircularProgressIndicator());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (items.isEmpty) LateralEmptyCard(mensaje: emptyMessage)
        else ...items.take(maxItems).map((item) => itemBuilder(item)),
        LateralSeeAllButton(onTap: onExpand),
      ],
    );
  }

}
