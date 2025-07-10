import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/app_enums.dart';

class EisenhowerListScreen extends StatelessWidget {
  static const quadrantTitlesZh = [
    '重要且緊急',
    '重要不緊急',
    '不重要但緊急',
    '不重要不緊急',
  ];
  static const quadrantTitlesEn = [
    'Important & Urgent',
    'Important, Not Urgent',
    'Not Important, Urgent',
    'Not Important, Not Urgent',
  ];
  final List<Task> tasks;
  final Future<void> Function(BuildContext, int quadrant, {double? coordinateImportance, double? coordinateUrgency}) onAdd;
  final Future<void> Function(BuildContext, Task) onEdit;
  final void Function(Task) onDelete;
  final AppLanguage language;
  const EisenhowerListScreen({super.key, required this.tasks, required this.onAdd, required this.onEdit, required this.onDelete, required this.language});

  @override
  Widget build(BuildContext context) {
    final titles = language == AppLanguage.zh ? quadrantTitlesZh : quadrantTitlesEn;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final aspect = (width / 2) / (height / 2);
          return GridView.builder(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspect,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: 4,
            itemBuilder: (context, i) {
              final quadrantTasks = tasks.where((t) => t.quadrant == i).toList();
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onAdd(context, i),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[i],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(),
                        Expanded(
                          child: quadrantTasks.isEmpty
                              ? Center(
                                  child: Text(
                                    language == AppLanguage.zh ? '點擊新增' : 'Tap to add',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: quadrantTasks.length,
                                  itemBuilder: (context, j) {
                                    final task = quadrantTasks[j];
                                    return Dismissible(
                                      key: Key('task_${task.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        color: Colors.red,
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(language == AppLanguage.zh ? '確認刪除' : 'Confirm Delete'),
                                            content: Text(language == AppLanguage.zh ? '確定要刪除這個待辦事項嗎？' : 'Are you sure you want to delete this task?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: Text(language == AppLanguage.zh ? '取消' : 'Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                child: Text(language == AppLanguage.zh ? '刪除' : 'Delete'),
                                              ),
                                            ],
                                          ),
                                        ) ?? false;
                                      },
                                      onDismissed: (direction) {
                                        onDelete(task);
                                      },
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(task.title),
                                        onTap: () => onEdit(context, task),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}