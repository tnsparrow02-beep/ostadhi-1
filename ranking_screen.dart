import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'strings.dart';
import 'widgets.dart';

/// Leaderboard of one class: podium for the top 3, then the other students.
/// Ranking is by points (students with the same points share the same rank).
class RankingScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const RankingScreen({super.key, required this.schoolClass});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Student> _students = [];
  List<int> _ranks = [];
  bool _loading = true;

  static const _gold = Color(0xFFF59E0B);
  static const _silver = Color(0xFF94A3B8);
  static const _bronze = Color(0xFFB45309);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DatabaseHelper.instance.getStudents(widget.schoolClass.id!);
    list.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0 ? byPoints : a.name.compareTo(b.name);
    });
    final ranks = <int>[];
    for (var i = 0; i < list.length; i++) {
      ranks.add(i > 0 && list[i].points == list[i - 1].points ? ranks[i - 1] : i + 1);
    }
    if (!mounted) return;
    setState(() {
      _students = list;
      _ranks = ranks;
      _loading = false;
    });
  }

  Color _medal(int index) => index == 0 ? _gold : (index == 1 ? _silver : _bronze);

  Widget _podiumColumn(int index) {
    final s = _students[index];
    final color = _medal(index);
    final height = index == 0 ? 150.0 : (index == 1 ? 110.0 : 80.0);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.emoji_events_rounded, color: color, size: index == 0 ? 46 : 36),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              s.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          PointsBadge(points: s.points),
          const SizedBox(height: 8),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Text(
              '${_ranks[index]}',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPoints = _students.isNotEmpty && _students.first.points > 0;

    return Scaffold(
      appBar: AppBar(title: Text('${context.t('ranking')}  ·  ${widget.schoolClass.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? EmptyState(icon: Icons.person_outline_rounded, message: context.t('noStudentsYet'))
              : !hasPoints
                  ? EmptyState(icon: Icons.emoji_events_outlined, message: context.t('noPointsYet'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Podium: 2nd - 1st - 3rd
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_students.length > 1) _podiumColumn(1),
                            _podiumColumn(0),
                            if (_students.length > 2) _podiumColumn(2),
                          ],
                        ),
                        const SizedBox(height: 16),
                        for (var i = 3; i < _students.length; i++)
                          SoftCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                                  child: Text(
                                    '${_ranks[i]}',
                                    style: const TextStyle(
                                      color: AppColors.indigo,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _students[i].name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                PointsBadge(points: _students[i].points),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}
