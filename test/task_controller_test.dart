import 'package:flutter_test/flutter_test.dart';
import 'package:daymark_flutter/data/task_repository.dart';
import 'package:daymark_flutter/models/task_item.dart';
import 'package:daymark_flutter/state/task_controller.dart';

import 'fakes/in_memory_task_repository.dart';

void main() {
  TaskItem draft(String title) => TaskItem(
        id: 'manual-$title',
        title: title,
        createdAt: DateTime(2026, 11, 4),
      );

  void addTask(TaskController controller, String title) {
    controller.add(
      title: title,
      description: '',
      category: TaskCategory.work,
      priority: TaskPriority.high,
    );
  }

  test('first launch persists demo tasks so they never regenerate', () async {
    final repo = InMemoryTaskRepository();
    final controller = TaskController(repo);
    addTearDown(controller.dispose);

    await controller.load();

    expect(repo.writes.length, 1);
    expect(repo.writes.single.length, 6);
    expect(controller.phase, TaskPhase.ready);

    // Simulate a restart with the persisted payload.
    final restartedRepo = InMemoryTaskRepository(
      snapshot: TaskSnapshot(List.of(repo.writes.single)),
    );
    final restarted = TaskController(restartedRepo);
    addTearDown(restarted.dispose);
    await restarted.load();

    expect(restarted.tasks.length, 6);
    expect(restartedRepo.writes, isEmpty);
  });

  test('mutations are rejected until load completes (cold-start race)', () async {
    final repo = InMemoryTaskRepository();
    final controller = TaskController(repo);
    addTearDown(controller.dispose);

    final added = controller.add(
      title: '抢跑任务',
      description: '',
      category: TaskCategory.work,
      priority: TaskPriority.high,
    );

    expect(added, isNull);
    expect(controller.canEdit, isFalse);
    expect(repo.writes, isEmpty);

    await controller.load();
    expect(controller.canEdit, isTrue);
    expect(controller.tasks.length, 6);
  });

  test('a write failure is reported, and retrySave clears it', () async {
    final repo = InMemoryTaskRepository(snapshot: const TaskSnapshot([]));
    final controller = TaskController(repo);
    addTearDown(controller.dispose);
    await controller.load();

    repo.failWrite = true;
    addTask(controller, '写失败');
    await controller.flush();
    expect(controller.hasWriteError, isTrue);
    expect(controller.errorMessage, contains('保存失败'));

    repo.failWrite = false;
    controller.retrySave();
    await controller.flush();
    expect(controller.hasWriteError, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('an older failed write cannot leave the newest state stuck', () async {
    final repo = InMemoryTaskRepository(snapshot: const TaskSnapshot([]));
    final controller = TaskController(repo);
    addTearDown(controller.dispose);
    await controller.load();

    repo.failWriteAt = 1;
    addTask(controller, '第一次');
    addTask(controller, '第二次');
    await controller.flush();

    expect(controller.hasWriteError, isFalse);
  });

  test('read failure is read-only and retryLoad can recover', () async {
    final repo = InMemoryTaskRepository()..failRead = true;
    final controller = TaskController(repo);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.phase, TaskPhase.readFailure);
    expect(controller.canEdit, isFalse);
    expect(controller.errorMessage, contains('只读'));

    repo.failRead = false;
    repo.snapshot = const TaskSnapshot([]);
    await controller.retryLoad();
    expect(controller.phase, TaskPhase.ready);
    expect(controller.canEdit, isTrue);
  });

  test('skipped malformed records are surfaced, not fatal', () async {
    final repo = InMemoryTaskRepository(
      snapshot: TaskSnapshot([draft('正常任务')], skipped: 2),
    );
    final controller = TaskController(repo);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.phase, TaskPhase.ready);
    expect(controller.skippedRecords, 2);
    expect(controller.tasks.single.title, '正常任务');
  });

  test('remove and restore keep the list consistent', () async {
    final task = draft('待删除');
    final repo = InMemoryTaskRepository(snapshot: TaskSnapshot([task]));
    final controller = TaskController(repo);
    addTearDown(controller.dispose);
    await controller.load();

    controller.remove(task);
    expect(controller.tasks, isEmpty);
    controller.restore(task);
    controller.restore(task);
    expect(controller.tasks.length, 1);
    await controller.flush();
  });
}
