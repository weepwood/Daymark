import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daymark_flutter/state/task_filter.dart';
import 'package:daymark_flutter/ui/widgets/task_filters.dart';

void main() {
  testWidgets('全部优先级 can be selected again (null popup value regression)',
      (WidgetTester tester) async {
    PriorityFilter? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilterBar(
          category: null,
          priorityFilter: PriorityFilter.high,
          onCategoryChanged: (_) {},
          onPriorityChanged: (value) => selected = value,
          visibleCount: 0,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部优先级'));
    await tester.pumpAndSettle();

    expect(selected, PriorityFilter.all);
  });

  testWidgets('choosing a priority filter reports the concrete value',
      (WidgetTester tester) async {
    PriorityFilter? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilterBar(
          category: null,
          priorityFilter: PriorityFilter.all,
          onCategoryChanged: (_) {},
          onPriorityChanged: (value) => selected = value,
          visibleCount: 3,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('高优先级'));
    await tester.pumpAndSettle();

    expect(selected, PriorityFilter.high);
  });
}
