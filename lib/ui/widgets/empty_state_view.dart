import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../theme/app_tokens.dart';

enum EmptyReason { firstRun, filtered, search, allDone }

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.reason,
    required this.onCreate,
    this.onClear,
    this.query = '',
  });

  final EmptyReason reason;
  final VoidCallback onCreate;
  final VoidCallback? onClear;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, title, detail, action, showClear) = switch (reason) {
      EmptyReason.firstRun => (
          Icons.playlist_add_rounded,
          '从第一条任务开始',
          '把要做的事记下来，按自己的节奏完成。',
          '创建任务',
          false
        ),
      EmptyReason.filtered => (
          Icons.filter_alt_off_outlined,
          '当前筛选下没有任务',
          '试着换个分类、优先级或视图。',
          '清除筛选',
          true
        ),
      EmptyReason.search => (
          Icons.search_off_rounded,
          '没有匹配的任务',
          query.isEmpty ? '换个关键词再试试。' : '没有匹配「$query」的任务。',
          '清空搜索',
          true
        ),
      EmptyReason.allDone => (
          Icons.task_alt_rounded,
          '清单已清空',
          '当前视图里没有待办了，去已完成里看看成果吧。',
          '查看已完成',
          false
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Space.s12, horizontal: Space.s6),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.selectedBg,
          ),
          child: Icon(icon, size: 30, color: colors.brand),
        ),
        const Gap(Space.s4),
        Text(title, style: context.textStyles.headlineSmall),
        const Gap(Space.s2),
        Text(detail,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium
                ?.copyWith(color: colors.textSecondary)),
        const Gap(Space.s4),
        TextButton.icon(
          onPressed: showClear ? (onClear ?? onCreate) : onCreate,
          icon: Icon(showClear ? Icons.close_rounded : Icons.add_rounded, size: 18),
          label: Text(action),
        ),
      ]),
    );
  }
}
