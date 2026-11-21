import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'nb_files.dart';
import 'notebook_screens.dart';
import 'sections.dart';
import 'strings.dart';
import 'widgets.dart';

/// "مكتبتي" tab: the three sections (فروض المراقبة / الفروض التأليفية / الدروس)
/// and your own folders (button "إضافة مجلد").
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _db = DatabaseHelper.instance;
  List<NbNode> _folders = [];
  Map<int, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.nbChildren(kMyFolders.key, null);
    final counts = await _db.nbChildCounts(kMyFolders.key);
    if (!mounted) return;
    setState(() {
      _folders = items.where((n) => n.isFolder).toList();
      _counts = counts;
      _loading = false;
    });
  }

  Future<void> _addFolder() async {
    final name = await promptText(
      context,
      title: context.t('addFolder'),
      label: context.t('folderName'),
      hint: context.t('folderHint'),
    );
    if (name == null || name.isEmpty) return;
    await _db.nbInsertFolder(kMyFolders.key, null, name);
    _load();
  }

  Future<void> _open(NbNode n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotebookFolderScreen(section: kMyFolders.key, parentId: n.id, title: n.name),
      ),
    );
    _load();
  }

  Future<void> _rename(NbNode n) async {
    final name = await promptText(
      context,
      title: context.t('rename'),
      label: context.t('newName'),
      initial: n.name,
    );
    if (name == null || name.isEmpty || name == n.name) return;
    await _db.nbRename(n.id, name);
    _load();
  }

  Future<void> _delete(NbNode n) async {
    final ok = await confirmDialog(
      context,
      title: context.t('deleteFolderQ'),
      body: '«${n.name}» ${context.t('deleteFolderBody')}',
      confirmLabel: context.t('delete'),
    );
    if (!ok) return;
    final paths = await _db.nbDelete(n.id);
    await FileStore.deleteFiles(paths);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFolder,
        icon: const Icon(Icons.create_new_folder_rounded),
        label: Text(context.t('addFolder')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // دفتر الأستاذ: فروض المراقبة / الفروض التأليفية / الدروس
          const NotebookHome(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
            child: Row(
              children: [
                const Icon(Icons.folder_copy_rounded, color: AppColors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.t('myFoldersTitle'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_folders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.t('noFoldersYet'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            )
          else
            for (final n in _folders)
              SoftCard(
                onTap: () => _open(n),
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.folder_rounded, color: AppColors.indigo, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${_counts[n.id] ?? 0} ${context.t('itemsCount')}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => v == 'rename' ? _rename(n) : _delete(n),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'rename', child: Text(context.t('rename'))),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            context.t('delete'),
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
