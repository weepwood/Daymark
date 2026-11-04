import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daymark_flutter/ui/widgets/task_editor.dart';

void main() {
  testWidgets('任务编辑器能够正常渲染', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TaskEditor()),
      ),
    );

    expect(find.text('创建新任务'), findsOneWidget);
    expect(find.text('任务名称'), findsOneWidget);
    expect(find.text('任务分类'), findsOneWidget);
  });
}
