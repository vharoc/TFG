import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../theme/theme.dart';
import 'chat_tile.dart';
import 'empty_card.dart';
import 'section_header.dart';
import 'see_all_button.dart';

class LateralChatsPanel extends StatelessWidget {
  final bool expanded;
  final bool loading;
  final List<Chat> chats;
  final double spacing;
  final int maxItems;
  final ScrollController scrollController;
  final ValueChanged<Chat> onChatTap;
  final ValueChanged<Chat> onDeleteChat;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  const LateralChatsPanel({
    super.key,
    required this.expanded,
    required this.loading,
    required this.chats,
    required this.spacing,
    required this.maxItems,
    required this.scrollController,
    required this.onChatTap,
    required this.onDeleteChat,
    required this.onExpand,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(header: 'Historial de chats'),
          SizedBox(height: spacing),
          Flexible(
            child: _buildExpandedContent(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onCollapse,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ocultar chats',
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
        const SectionHeader(header: 'Historial de chats'),
        SizedBox(height: spacing),
        _buildCollapsedContent(),
      ],
    );
  }

  Widget _buildExpandedContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chats.isEmpty) {
      return const LateralEmptyCard(mensaje: 'Aún no hay conversaciones');
    }

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        itemCount: chats.length,
        itemBuilder: (_, i) {
          final chat = chats[i];
          return LateralChatTile(
            chat: chat,
            onTap: () => onChatTap(chat),
            onDelete: () => onDeleteChat(chat),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chats.isEmpty) {
      return const LateralEmptyCard(mensaje: 'Aún no hay conversaciones');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...chats
            .take(maxItems)
            .map(
              (chat) => LateralChatTile(
                chat: chat,
                onTap: () => onChatTap(chat),
                onDelete: () => onDeleteChat(chat),
              ),
            ),
        LateralSeeAllButton(onTap: onExpand),
      ],
    );
  }
}