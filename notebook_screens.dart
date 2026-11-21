import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'database_helper.dart';
import 'digits.dart';
import 'nb_files.dart';
import 'sections.dart';
import 'strings.dart';
import 'widgets.dart';

// ───────────────────────── Top of the "مكتبتي" tab ─────────────────────────

/// "دفتر الأستاذ": a search bar and three big sections stacked vertically:
/// فروض المراقبة (top), الفروض التأليفية (middle), الدروس (bottom).
class NotebookHome extends StatefulWidget {
  const NotebookHome({super.key});

  @override
  State<NotebookHome> createState() => _NotebookHomeState();
}

class _NotebookHomeState extends State<NotebookHome> {
  Map<String, SectionStats> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await DatabaseHelper.instance.nbSectionStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<void> _go(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
          child: Row(
            children: [
              const Icon(Icons.folder_copy_rounded, color: AppColors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t('nbHeading'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        SoftCard(
          onTap: () => _go(const NotebookSearchScreen()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('searchAll'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        for (final section in kSections)
          _SectionCard(
            info: section,
            stats: _stats[section.key] ?? const SectionStats(0, 0),
            onTap: () => _go(
              NotebookFolderScreen(
                section: section.key,
                parentId: null,
                title: section.title(context),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final SectionInfo info;
  final SectionStats stats;
  final VoidCallback onTap;

  const _SectionCard({required this.info, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = info.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.black, 0.28)!],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 7)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(info.icon, color: Colors.white, size: 38),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.folders} ${context.t('foldersCount')}  ·  ${stats.files} ${context.t('filesCount')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Folder content ─────────────────────────

/// Content of a section (parentId == null) or of one of its folders.
/// Create folders and subfolders, add any file, take photos, rename, delete, filter by name.
class NotebookFolderScreen extends StatefulWidget {
  final String section;
  final int? parentId;
  final String title;

  const NotebookFolderScreen({
    super.key,
    required this.section,
    required this.parentId,
    required this.title,
  });

  @override
  State<NotebookFolderScreen> createState() => _NotebookFolderScreenState();
}

class _NotebookFolderScreenState extends State<NotebookFolderScreen> {
  final _db = DatabaseHelper.instance;
  final _filterCtrl = TextEditingController();

  List<NbNode> _items = [];
  Map<int, int> _counts = {};
  String _trail = '';
  bool _loading = true;
  bool _busy = false;
  bool _searching = false;
  String _filter = '';

  SectionInfo get _info => sectionByKey(widget.section);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _db.nbChildren(widget.section, widget.parentId);
    final counts = await _db.nbChildCounts(widget.section);
    List<NbNode> chain = [];
    if (widget.parentId != null) chain = await _db.nbPathTo(widget.parentId!);
    if (!mounted) return;
    var trail = '';
    if (widget.parentId != null) {
      final parents = chain.length > 1 ? chain.sublist(0, chain.length - 1) : <NbNode>[];
      trail = [_info.title(context), ...parents.map((n) => n.name)].join('  ›  ');
    }
    setState(() {
      _items = items;
      _counts = counts;
      _trail = trail;
      _loading = false;
    });
  }

  // ───────── actions ─────────
  Future<void> _newFolder() async {
    final name = await promptText(
      context,
      title: context.t('newFolder'),
      label: context.t('folderName'),
      hint: context.t('folderHint'),
    );
    if (name == null || name.isEmpty) return;
    await _db.nbInsertFolder(widget.section, widget.parentId, name);
    _load();
  }

  Future<void> _addFiles() async {
    setState(() => _busy = true);
    try {
      // No type filter: any file can be added (PDF, Word, images, Excel, ...).
      final picked = await openFiles();
      for (final f in picked) {
        final stored = await FileStore.save(widget.section, f, f.name);
        await _db.nbInsertFile(
          widget.section,
          widget.parentId,
          name: f.name,
          path: stored.path,
          ext: stored.ext,
          size: stored.size,
        );
      }
    } catch (_) {
      if (mounted) showSnack(context, context.t('fileAddFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  String _photoName() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'IMG_${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}.jpg';
  }

  Future<void> _takePhoto() async {
    setState(() => _busy = true);
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2600,
      );
      if (shot != null) {
        final name = _photoName();
        final stored = await FileStore.save(widget.section, shot, name);
        await _db.nbInsertFile(
          widget.section,
          widget.parentId,
          name: name,
          path: stored.path,
          ext: stored.ext,
          size: stored.size,
        );
      }
    } catch (_) {
      if (mounted) showSnack(context, context.t('fileAddFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  Future<void> _openItem(NbNode n) async {
    if (n.isFolder) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NotebookFolderScreen(section: widget.section, parentId: n.id, title: n.name),
        ),
      );
      _load();
    } else {
      await openNodeFile(context, n);
    }
  }

  Future<void> _rename(NbNode n) async {
    final name = await promptText(
      context,
      title: context.t('rename'),
      label: context.t('newName'),
      initial: n.name,
    );
    if (name == null || name.isEmpty || name == n.name) return;
    var finalName = name;
    // Keep the extension of a file if the new name has none (so the phone still knows how to open it).
    if (!n.isFolder && n.ext.isNotEmpty && !name.contains('.')) {
      finalName = '$name.${n.ext}';
    }
    await _db.nbRename(n.id, finalName);
    _load();
  }

  Future<void> _delete(NbNode n) async {
    final ok = await confirmDialog(
      context,
      title: context.t(n.isFolder ? 'deleteFolderQ' : 'deleteFileQ'),
      body: '«${n.name}» ${context.t(n.isFolder ? 'deleteFolderBody' : 'deleteFileBody')}',
      confirmLabel: context.t('delete'),
    );
    if (!ok) return;
    final paths = await _db.nbDelete(n.id);
    await FileStore.deleteFiles(paths);
    _load();
  }

  /// Ready-made folders for the exam sections (offered when the section is empty).
  Future<void> _createTemplates() async {
    final isControl = widget.section == kControl.key;
    final total = isControl ? 6 : 3;
    final prefix = context.t(isControl ? 'ctrlName' : 'synthName');
    for (var i = 1; i <= total; i++) {
      await _db.nbInsertFolder(widget.section, widget.parentId, '$prefix $i');
    }
    _load();
  }

  // ───────── UI ─────────
  List<NbNode> get _visible {
    final q = westernDigits(_filter).trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((n) => n.name.toLowerCase().contains(q)).toList();
  }

  Widget _leading(NbNode n) {
    final Color color = n.isFolder ? _info.color : fileLook(n.ext).color;
    final IconData icon = n.isFolder ? Icons.folder_rounded : fileLook(n.ext).icon;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: n.isFolder ? 32 : 30),
    );
  }

  Widget _tile(NbNode n) {
    final sub = n.isFolder
        ? '${_counts[n.id] ?? 0} ${context.t('itemsCount')}'
        : '${formatSize(n.size)}  ·  ${n.added.length >= 10 ? n.added.substring(0, 10) : n.added}';
    return SoftCard(
      onTap: () => _openItem(n),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          _leading(n),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'open') _openItem(n);
              if (v == 'rename') _rename(n);
              if (v == 'delete') _delete(n);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'open',
                child: Text(context.t(n.isFolder ? 'openFolder' : 'openFile')),
              ),
              PopupMenuItem(value: 'rename', child: Text(context.t('rename'))),
              PopupMenuItem(
                value: 'delete',
                child: Text(context.t('delete'), style: const TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _info.color,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _busy ? null : _newFolder,
              icon: const Icon(Icons.create_new_folder_rounded),
              label: Text(context.t('btnFolder')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _busy ? null : _addFiles,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(context.t('btnFile')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _busy ? null : _takePhoto,
              icon: const Icon(Icons.photo_camera_rounded),
              label: Text(context.t('btnPhoto')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final isExamRoot = widget.parentId == null &&
        (widget.section == kControl.key || widget.section == kSynthesis.key);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _filterCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: context.t('searchHere'),
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _filter = v),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  if (_trail.isNotEmpty)
                    Text(
                      _trail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
                    ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: context.t('search'),
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _filter = '';
                  _filterCtrl.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _actionBar(),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.folder_open_rounded,
                        message: context.t('emptyFolder'),
                        action: isExamRoot
                            ? OutlinedButton.icon(
                                onPressed: _createTemplates,
                                icon: const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  context.t(widget.section == kControl.key
                                      ? 'makeCtrlFolders'
                                      : 'makeSynthFolders'),
                                ),
                              )
                            : null,
                      )
                    : visible.isEmpty
                        ? EmptyState(icon: Icons.search_off_rounded, message: context.t('noResults'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: visible.length,
                            itemBuilder: (_, i) => _tile(visible[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Search everywhere ─────────────────────────

/// Search folders and files by name in the three sections.
class NotebookSearchScreen extends StatefulWidget {
  const NotebookSearchScreen({super.key});

  @override
  State<NotebookSearchScreen> createState() => _NotebookSearchScreenState();
}

class _NotebookSearchScreenState extends State<NotebookSearchScreen> {
  final _db = DatabaseHelper.instance;
  final _ctrl = TextEditingController();

  List<NbNode> _results = [];
  Map<int, NbNode> _folders = {};
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    final all = await _db.nbAllFolders();
    if (!mounted) return;
    setState(() => _folders = {for (final f in all) f.id: f});
  }

  Future<void> _search(String text) async {
    final q = text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    final found = await _db.nbSearch(q);
    if (!mounted || _ctrl.text.trim() != q) return; // the text changed meanwhile
    setState(() {
      _results = found;
      _searched = true;
    });
  }

  /// "الدروس › السنة السابعة › الهندسة": where the item lives.
  String _location(NbNode n) {
    final names = <String>[];
    int? parent = n.parentId;
    var guard = 0;
    while (parent != null && guard < 60) {
      final f = _folders[parent];
      if (f == null) break;
      names.insert(0, f.name);
      parent = f.parentId;
      guard++;
    }
    return [sectionByKey(n.section).title(context), ...names].join('  ›  ');
  }

  Future<void> _open(NbNode n) async {
    if (n.isFolder) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotebookFolderScreen(section: n.section, parentId: n.id, title: n.name),
        ),
      );
      await _loadFolders();
      _search(_ctrl.text);
    } else {
      await openNodeFile(context, n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 17),
          cursorColor: Colors.white,
          inputFormatters: const [WesternDigitsFormatter()],
          decoration: InputDecoration(
            hintText: context.t('searchAll'),
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: !_searched
          ? EmptyState(icon: Icons.manage_search_rounded, message: context.t('searchAllHint'))
          : _results.isEmpty
              ? EmptyState(icon: Icons.search_off_rounded, message: context.t('noResults'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final n = _results[i];
                    final info = sectionByKey(n.section);
                    final look = fileLook(n.ext);
                    final color = n.isFolder ? info.color : look.color;
                    return SoftCard(
                      onTap: () => _open(n),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(n.isFolder ? Icons.folder_rounded : look.icon, color: color),
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
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  _location(n),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
