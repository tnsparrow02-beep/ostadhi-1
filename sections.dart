import 'package:flutter/material.dart';

import 'strings.dart';

/// One of the three sections of "دفتر الأستاذ" (inside the "مكتبتي" tab).
class SectionInfo {
  final String key;
  final String titleKey;
  final IconData icon;
  final Color color;

  const SectionInfo({
    required this.key,
    required this.titleKey,
    required this.icon,
    required this.color,
  });

  String title(BuildContext context) => context.t(titleKey);
}

const SectionInfo kControl = SectionInfo(
  key: 'control',
  titleKey: 'ctrlTitle',
  icon: Icons.assignment_turned_in_rounded,
  color: Color(0xFF2563EB),
);

const SectionInfo kSynthesis = SectionInfo(
  key: 'synthesis',
  titleKey: 'synthTitle',
  icon: Icons.workspace_premium_rounded,
  color: Color(0xFF7C3AED),
);

const SectionInfo kLessons = SectionInfo(
  key: 'lessons',
  titleKey: 'lessonsTitle',
  icon: Icons.menu_book_rounded,
  color: Color(0xFF059669),
);

/// Your own folders (button "إضافة مجلد" in مكتبتي). Not one of the three main sections.
const SectionInfo kMyFolders = SectionInfo(
  key: 'library',
  titleKey: 'myFoldersTitle',
  icon: Icons.folder_copy_rounded,
  color: Color(0xFF3730A3),
);

/// Order on screen: top = control tests, middle = synthesis exams, bottom = lessons.
const List<SectionInfo> kSections = [kControl, kSynthesis, kLessons];

SectionInfo sectionByKey(String key) => [...kSections, kMyFolders]
    .firstWhere((s) => s.key == key, orElse: () => kLessons);
