import 'package:flutter/material.dart';

/// Each entry: [Arabic, French, English]
const Map<String, List<String>> _strings = {
  // Navigation / general
  'appTitle': ['أستاذي', 'Mon Prof', 'My Teacher'],
  'navQuiz': ['الاختبار', 'Quiz', 'Quiz'],
  'navClasses': ['الأقسام', 'Classes', 'Classes'],
  'navTimetable': ['الجدول', 'Emploi du temps', 'Timetable'],
  'navCalendar': ['الأجندة', 'Agenda', 'Calendar'],
  'save': ['حفظ', 'Enregistrer', 'Save'],
  'cancel': ['إلغاء', 'Annuler', 'Cancel'],
  'delete': ['حذف', 'Supprimer', 'Delete'],
  'edit': ['تعديل', 'Modifier', 'Edit'],
  'close': ['إغلاق', 'Fermer', 'Close'],
  'ok': ['موافق', 'OK', 'OK'],
  'required': ['هذا الحقل مطلوب', 'Champ obligatoire', 'Required field'],
  'confirmDelete': ['هل تريد الحذف؟', 'Confirmer la suppression ?', 'Delete this item?'],
  'saved': ['تم الحفظ', 'Enregistré', 'Saved'],

  // Settings, timer, backup
  'settings': ['الإعدادات', 'Réglages', 'Settings'],
  'timerTitle': ['مؤقّت السؤال', 'Chrono par question', 'Question timer'],
  'timerOff': ['بدون', 'Aucun', 'Off'],
  'seconds': ['ث', 's', 's'],
  'timeUp': ['انتهى الوقت!', 'Temps écoulé !', 'Time is up!'],
  'soundTitle': ['الصوت والنطق', 'Sons et voix', 'Sound and voice'],
  'soundSub': ['صوت النجاح ونطق كلمة التشجيع', 'Son de réussite et voix', 'Success chime and spoken praise'],
  'backupTitle': ['نسخة احتياطية', 'Sauvegarde', 'Backup'],
  'backupCopy': ['نسخ بياناتي', 'Copier mes données', 'Copy my data'],
  'backupCopySub': ['تُنسخ كل بياناتك كنص. الصقه في واتساب أو الملاحظات للاحتفاظ به.', 'Toutes vos données sont copiées sous forme de texte. Collez-les dans WhatsApp ou Notes.', 'All your data is copied as text. Paste it into WhatsApp or Notes to keep it.'],
  'backupCopied': ['تم النسخ. الصقه الآن في مكان آمن.', 'Copié. Collez-le dans un endroit sûr.', 'Copied. Paste it somewhere safe now.'],
  'restoreTitle': ['استرجاع البيانات', 'Restaurer les données', 'Restore data'],
  'restoreSub': ['انسخ النسخة الاحتياطية ثم اضغط على الزر.', 'Copiez la sauvegarde puis touchez le bouton.', 'Copy your backup, then tap the button.'],
  'restoreConfirm': ['سيتم استبدال كل البيانات الحالية بالنسخة المنسوخة. هل تريد المتابعة؟', 'Toutes les données actuelles seront remplacées par la sauvegarde. Continuer ?', 'All current data will be replaced by the backup. Continue?'],
  'restoreOk': ['تم استرجاع البيانات', 'Données restaurées', 'Data restored'],
  'restoreFail': ['لا توجد نسخة صالحة في الحافظة', 'Aucune sauvegarde valide dans le presse-papiers', 'No valid backup in the clipboard'],
  'restore': ['استرجاع', 'Restaurer', 'Restore'],
  'aboutText': ['يعمل بدون إنترنت', 'Fonctionne sans internet', 'Works without internet'],

  // Student notes
  'studentNotes': ['ملاحظات', 'Observations', 'Notes'],
  'studentNoteHint': ['اكتب ملاحظاتك الخاصة عن هذا التلميذ...', 'Écrivez vos observations privées sur cet élève...', 'Write your private observations about this student...'],

  'addFolder': ['إضافة مجلد', 'Ajouter un dossier', 'Add folder'],
  'myFoldersTitle': ['مجلداتي', 'Mes dossiers', 'My folders'],
  'noFoldersYet': ['لا توجد مجلدات بعد. اضغط على «إضافة مجلد».', 'Aucun dossier. Touchez « Ajouter un dossier ».', 'No folders yet. Tap "Add folder".'],

  // Notebook (three sections)
  'nbHeading': ['دفتر الأستاذ', 'Cahier du professeur', 'Teacher\'s notebook'],
  'lessonsTitle': ['الدروس', 'Cours', 'Lessons'],
  'foldersCount': ['مجلد', 'dossiers', 'folders'],
  'itemsCount': ['عنصر', 'éléments', 'items'],
  'search': ['بحث', 'Rechercher', 'Search'],
  'searchHere': ['ابحث في هذا المجلد...', 'Rechercher dans ce dossier...', 'Search in this folder...'],
  'searchAll': ['ابحث عن مجلد أو ملف...', 'Chercher un dossier ou un fichier...', 'Search a folder or a file...'],
  'searchAllHint': ['اكتب جزءا من اسم المجلد أو الملف. يشمل البحث فروض المراقبة والفروض التأليفية والدروس.', 'Tapez une partie du nom. La recherche couvre les devoirs de contrôle, de synthèse et les cours.', 'Type part of a name. Search covers assessments, synthesis exams and lessons.'],
  'noResults': ['لا توجد نتائج', 'Aucun résultat', 'No results'],
  'newFolder': ['مجلد جديد', 'Nouveau dossier', 'New folder'],
  'folderName': ['اسم المجلد', 'Nom du dossier', 'Folder name'],
  'folderHint': ['مثال: السنة السابعة أساسي', 'Ex : 7ème année', 'e.g. Grade 7'],
  'btnFolder': ['مجلد', 'Dossier', 'Folder'],
  'btnFile': ['ملف', 'Fichier', 'File'],
  'btnPhoto': ['صورة', 'Photo', 'Photo'],
  'openFolder': ['فتح المجلد', 'Ouvrir le dossier', 'Open folder'],
  'openFile': ['فتح الملف', 'Ouvrir le fichier', 'Open file'],
  'newName': ['الاسم الجديد', 'Nouveau nom', 'New name'],
  'deleteFolderQ': ['حذف المجلد؟', 'Supprimer le dossier ?', 'Delete the folder?'],
  'deleteFileQ': ['حذف الملف؟', 'Supprimer le fichier ?', 'Delete the file?'],
  'deleteFolderBody': ['وكل ما بداخله سيُحذف نهائيا.', 'et tout son contenu seront supprimés définitivement.', 'and everything inside will be permanently deleted.'],
  'deleteFileBody': ['سيُحذف نهائيا من هاتفك.', 'sera supprimé définitivement du téléphone.', 'will be permanently deleted from the phone.'],
  'emptyFolder': ['هذا المجلد فارغ. أنشئ مجلدا، أو ارفع ملفا (PDF أو Word أو صورة...) أو التقط صورة.', 'Ce dossier est vide. Créez un dossier, importez un fichier (PDF, Word, image...) ou prenez une photo.', 'This folder is empty. Create a folder, upload a file (PDF, Word, image...) or take a photo.'],
  'makeCtrlFolders': ['إنشاء مجلدات فرض مراقبة عدد 1 إلى 6', 'Créer les dossiers devoir de contrôle 1 à 6', 'Create continuous assessment folders 1 to 6'],
  'makeSynthFolders': ['إنشاء مجلدات فرض تأليفي عدد 1 إلى 3', 'Créer les dossiers devoir de synthèse 1 à 3', 'Create synthesis exam folders 1 to 3'],
  'byYearHeading': ['المكتبة حسب السنة الدراسية', 'Bibliothèque par année scolaire', 'Library by academic year'],

  // Quiz library + AI tool
  'addedLabel': ['مضاف', 'ajoutées', 'added'],
  'addAll': ['إضافة الكل', 'Tout ajouter', 'Add all'],
  'addToBank': ['إضافة إلى بنك الأسئلة', 'Ajouter à ma banque', 'Add to my question bank'],
  'addedCount': ['تمت إضافة', 'Ajoutées', 'Added'],
  'skippedDup': ['مكرر تم تجاهله', 'Doublons ignorés', 'Duplicates skipped'],
  'aiTool': ['الأداة الذكية', 'Outil intelligent', 'AI tool'],
  'aiHelpTitle': ['كيف أكتب النص؟', 'Comment écrire le texte ?', 'How to write the text?'],
  'aiHelpBody': [
    'الصق أسئلتك كما هي. تتعرّف الأداة تلقائيا على:\n• ترقيم الأسئلة: 1) أو 1- أو سؤال 1: أو Q1.\n• الاختيارات: أ) ب) ج) أو A) B) C)، كل اختيار في سطر أو كلها في سطر واحد.\n• الإجابة الصحيحة: «الإجابة: ب» أو «Answer: B» أو علامة ✓ أو * بجانب الاختيار الصحيح.\n• الأسئلة بجواب فقط: «س: ... ج: 8». إذا كان الجواب عددا تضيف الأداة اختيارين خاطئين تلقائيا.\n• لكل سؤال 3 اختيارات (واحد صحيح واثنان خاطئان). إذا وُجد أكثر نحتفظ بالصحيح واثنين فقط.\nثم راجع النتيجة وعدّلها قبل الإضافة.',
    'Collez vos questions telles quelles. L\'outil reconnaît :\n• La numérotation : 1) ou 1- ou Question 1 : ou Q1.\n• Les choix : A) B) C) ou أ) ب) ج), un par ligne ou tous sur la même ligne.\n• La bonne réponse : « Réponse : B », « Answer: B », ou une marque ✓ ou * à côté du bon choix.\n• Les questions avec réponse seule : « Q: ... A: 8 ». Si la réponse est un nombre, deux mauvaises réponses sont ajoutées automatiquement.\n• 3 choix par question (1 bon, 2 faux). S\'il y en a plus, la bonne réponse et 2 autres sont gardées.\nPuis vérifiez et corrigez avant d\'ajouter.',
    'Paste your questions as they are. The tool recognises:\n• Question numbering: 1) or 1- or Question 1: or Q1.\n• Choices: A) B) C) or أ) ب) ج), one per line or all on one line.\n• The correct answer: "Answer: B", "الإجابة: ب", or a ✓ or * mark next to the right choice.\n• Answer-only questions: "Q: ... A: 8". If the answer is a number, two wrong answers are added automatically.\n• 3 choices per question (1 right, 2 wrong). If there are more, the correct one and 2 others are kept.\nThen review and edit before adding.',
  ],
  'aiExample': ['إدراج مثال', 'Insérer un exemple', 'Insert example'],
  'aiPasteHint': ['الصق هنا نص الأسئلة والإجابات...', 'Collez ici les questions et réponses...', 'Paste the questions and answers here...'],
  'aiPaste': ['لصق من الحافظة', 'Coller', 'Paste'],
  'aiAnalyze': ['تحليل النص', 'Analyser le texte', 'Analyze text'],
  'aiNothingFound': ['لم أجد أسئلة في هذا النص. راجع «كيف أكتب النص؟»', 'Aucune question trouvée. Voir « Comment écrire le texte ? »', 'No questions found. See "How to write the text?"'],
  'aiFound': ['تم العثور على', 'Trouvées', 'Found'],
  'aiNeedsReview': ['تحتاج مراجعة', 'à vérifier', 'need review'],
  'aiReady': ['جاهز', 'Prêt', 'Ready'],
  'aiBack': ['تعديل النص', 'Modifier le texte', 'Edit text'],
  'aiAddSelected': ['إضافة المحدد إلى بنك الأسئلة', 'Ajouter la sélection', 'Add selected to the bank'],
  'aiSelectCorrect': ['اختر الإجابة الصحيحة', 'Choisissez la bonne réponse', 'Select the correct answer'],
  'aiChoice': ['الاختيار', 'Choix', 'Choice'],
  'aiGenerated': ['أُضيف اختياران خاطئان تلقائيا. تأكد منهما.', 'Mauvaises réponses ajoutées automatiquement. Vérifiez-les.', 'Wrong answers were generated automatically. Please check them.'],
  'aiDropped': ['بعض الأسئلة فيها أكثر من 3 اختيارات: احتفظنا بالصحيح واثنين فقط.', 'Certaines questions avaient plus de 3 choix : la bonne réponse et 2 autres sont gardées.', 'Some questions had more than 3 choices: the correct one and 2 others were kept.'],

  // Free school years
  'yearTypeHint': ['اكتب السنة الدراسية، مثال: 2031/2032', 'Écrivez l\'année, ex : 2031/2032', 'Type the year, e.g. 2031/2032'],
  'yearAdd': ['إضافة', 'Ajouter', 'Add'],
  'yearPresets': ['أو اختر من القائمة (إلى 2050)', 'Ou choisissez dans la liste (jusqu\'à 2050)', 'Or pick from the list (up to 2050)'],
  'yearExists': ['هذه السنة موجودة بالفعل', 'Cette année existe déjà', 'This year already exists'],

  // My library
  'navLibrary': ['مكتبتي', 'Ma bibliothèque', 'My library'],
  'academicYear': ['السنة الدراسية', 'Année scolaire', 'Academic year'],
  'addYear': ['إضافة سنة دراسية', 'Ajouter une année scolaire', 'Add academic year'],
  'deleteYear': ['حذف السنة الدراسية', 'Supprimer l\'année scolaire', 'Delete academic year'],
  'deleteYearBody': ['سيتم حذف كل ملفات هذه السنة نهائيا.', 'Tous les fichiers de cette année seront supprimés définitivement.', 'All files of this year will be permanently deleted.'],
  'libMyFiles': ['ملفاتي', 'Mes fichiers', 'My files'],
  'examsTitle': ['الفروض', 'Les devoirs', 'Exams'],
  'ctrlTitle': ['فروض المراقبة', 'Devoirs de contrôle', 'Continuous assessments'],
  'synthTitle': ['الفروض التأليفية', 'Devoirs de synthèse', 'Synthesis exams'],
  'ctrlName': ['فرض مراقبة عدد', 'Devoir de contrôle n°', 'Continuous assessment no.'],
  'synthName': ['فرض تأليفي عدد', 'Devoir de synthèse n°', 'Synthesis exam no.'],
  'filesCount': ['ملف', 'fichiers', 'files'],
  'uploadFile': ['رفع ملف', 'Importer un fichier', 'Upload file'],
  'takePhoto': ['التقاط صورة', 'Prendre une photo', 'Take a photo'],
  'noFiles': ['لا توجد ملفات بعد. ارفع ملفا (PDF أو Word أو صورة) أو التقط صورة بالكاميرا.', 'Aucun fichier. Importez un PDF, Word ou image, ou prenez une photo.', 'No files yet. Upload a PDF, Word or image, or take a photo.'],
  'fileOpenFail': ['لا يوجد تطبيق لفتح هذا الملف على هاتفك', 'Aucune application pour ouvrir ce fichier', 'No app on this phone can open this file'],
  'fileMissing': ['الملف غير موجود على الهاتف', 'Fichier introuvable sur le téléphone', 'File not found on the phone'],
  'fileTypeRejected': ['يُسمح فقط بملفات PDF وWord وصور JPG/PNG', 'Seuls les PDF, Word et images JPG/PNG sont acceptés', 'Only PDF, Word and JPG/PNG images are allowed'],
  'fileAddFail': ['تعذّرت إضافة الملف', 'Impossible d\'ajouter le fichier', 'Could not add the file'],

  // Ranking, today, fair draw
  'ranking': ['الترتيب', 'Classement', 'Ranking'],
  'rankingOfClass': ['ترتيب القسم', 'Classement de la classe', 'Class ranking'],
  'noPointsYet': ['لا توجد نقاط بعد. أجيبوا عن الأسئلة لتظهر الأسماء هنا!', 'Pas encore de points. Répondez aux questions !', 'No points yet. Answer questions to climb the ranking!'],
  'today': ['اليوم', 'Aujourd\'hui', 'Today'],
  'noClassesToday': ['لا توجد حصص اليوم', 'Pas de séance aujourd\'hui', 'No classes today'],
  'nowLabel': ['الآن', 'En cours', 'Now'],
  'drawProgress': ['تم سحب', 'Déjà tirés', 'Drawn'],
  'newDrawRound': ['دورة سحب جديدة: عاد الجميع للقرعة', 'Nouveau tour : tout le monde est de retour', 'New round: everyone is back in the draw'],

  // Quiz
  'quizHeadline': ['السؤال', 'Quiz d\'échauffement', 'Warm-up quiz'],
  'questionsCount': ['سؤال', 'questions', 'questions'],
  'startQuiz': ['ابدأ الاختبار', 'Démarrer le quiz', 'Start quiz'],
  'questionBank': ['بنك الأسئلة', 'Banque de questions', 'Question bank'],
  'randomStudent': ['تلميذ عشوائي', 'Tirage au sort', 'Random student'],
  'activeClass': ['القسم الحالي', 'Classe active', 'Active class'],
  'noClassSelected': ['لم يتم اختيار قسم', 'Aucune classe sélectionnée', 'No class selected'],
  'chooseClass': ['اختيار القسم', 'Choisir la classe', 'Choose class'],
  'noClasses': ['أنشئ قسما أولا', 'Créez d\'abord une classe', 'Create a class first'],
  'noStudents': ['لا يوجد تلاميذ في هذا القسم', 'Aucun élève dans cette classe', 'No students in this class'],
  'noQuestions': ['أضف أسئلة أولا', 'Ajoutez d\'abord des questions', 'Add some questions first'],
  'addQuestion': ['إضافة سؤال', 'Ajouter une question', 'Add question'],
  'editQuestion': ['تعديل السؤال', 'Modifier la question', 'Edit question'],
  'question': ['السؤال', 'Question', 'Question'],
  'correctAnswer': ['الإجابة الصحيحة', 'Bonne réponse', 'Correct answer'],
  'wrongAnswer1': ['إجابة خاطئة 1', 'Mauvaise réponse 1', 'Wrong answer 1'],
  'wrongAnswer2': ['إجابة خاطئة 2', 'Mauvaise réponse 2', 'Wrong answer 2'],
  'noQuestionsYet': ['لا توجد أسئلة بعد. اضغط على «إضافة سؤال».', 'Aucune question. Touchez « Ajouter une question ».', 'No questions yet. Tap "Add question".'],
  // Shown AND spoken. Explicit diacritics make the voice pronounce the last letter correctly:
  // male = Ahsanta (fatha on the ta), female = Ahsanti (kasra under the ta).
  'bravo': ['أَحْسَنْتَ', 'Bravo !', 'Well done!'],
  'bravoFemale': ['أَحْسَنْتِ', 'Bravo !', 'Well done!'],
  'next': ['السؤال التالي', 'Question suivante', 'Next question'],
  'finish': ['إنهاء', 'Terminer', 'Finish'],
  'score': ['النتيجة', 'Score', 'Score'],
  'quizFinished': ['انتهى الاختبار', 'Quiz terminé', 'Quiz finished'],
  'restart': ['إعادة', 'Recommencer', 'Restart'],
  'pickStudent': ['اختر تلميذا', 'Choisir un élève', 'Pick a student'],
  'picking': ['جاري السحب...', 'Tirage en cours...', 'Picking...'],
  'drawAgain': ['سحب جديد', 'Nouveau tirage', 'Draw again'],

  'pickQuestion': ['اختيار سؤال محدد', 'Choisir une question précise', 'Pick a specific question'],
  'autoOrder': ['ترتيب عشوائي لكل الأسئلة', 'Ordre aléatoire', 'Random order'],
  'jumpToQuestion': ['الانتقال إلى سؤال', 'Aller à une question', 'Go to a question'],
  'selectedStudent': ['التلميذ المختار', 'Élève sélectionné', 'Selected student'],
  'noStudentSelected': ['لم يتم اختيار تلميذ - اضغط للاختيار', 'Aucun élève sélectionné - touchez pour choisir', 'No student selected - tap to choose'],
  'points': ['نقاط', 'pts', 'pts'],
  'chooseStudent': ['اختيار تلميذ', 'Choisir un élève', 'Choose a student'],
  'clearSelection': ['إلغاء الاختيار', 'Désélectionner', 'Clear selection'],
  'resetPoints': ['تصفير النقاط', 'Remettre les points à zéro', 'Reset points'],
  'resetPointsConfirm': ['هل تريد تصفير نقاط كل تلاميذ هذا القسم؟', 'Remettre à zéro les points de toute la classe ?', 'Reset the points of the whole class?'],
  'reset': ['تصفير', 'Remettre à zéro', 'Reset'],

  // Classes & students
  'addClass': ['إضافة قسم', 'Ajouter une classe', 'Add class'],
  'className': ['اسم القسم', 'Nom de la classe', 'Class name'],
  'classHint': ['مثال: 7ème B1', 'Ex : 7ème B1', 'e.g. 7th B1'],
  'rename': ['تعديل الاسم', 'Renommer', 'Rename'],
  'studentsCount': ['تلميذ', 'élèves', 'students'],
  'addStudents': ['إضافة تلاميذ', 'Ajouter des élèves', 'Add students'],
  'editStudent': ['تعديل التلميذ', 'Modifier l\'élève', 'Edit student'],
  'studentName': ['اسم التلميذ', 'Nom de l\'élève', 'Student name'],
  'gender': ['الجنس', 'Sexe', 'Gender'],
  'male': ['ذكر', 'Garçon', 'Male'],
  'female': ['أنثى', 'Fille', 'Female'],
  'genderAddHint': ['نفس الجنس لكل الأسماء المضافة. أضف الذكور ثم الإناث على دفعتين.', 'Même sexe pour tous les noms ajoutés. Ajoutez les garçons puis les filles en deux fois.', 'Same gender for every name added. Add boys, then girls, in two batches.'],
  'oneNamePerLine': ['اسم واحد في كل سطر', 'Un nom par ligne', 'One name per line'],
  'setActive': ['تعيين كقسم حالي', 'Définir comme classe active', 'Set as active class'],
  'noClassesYet': ['لا توجد أقسام بعد. اضغط على «إضافة قسم».', 'Aucune classe. Touchez « Ajouter une classe ».', 'No classes yet. Tap "Add class".'],
  'noStudentsYet': ['لا يوجد تلاميذ. اضغط على «إضافة تلاميذ».', 'Aucun élève. Touchez « Ajouter des élèves ».', 'No students yet. Tap "Add students".'],

  // Timetable
  'd1': ['الاثنين', 'Lundi', 'Monday'],
  'd2': ['الثلاثاء', 'Mardi', 'Tuesday'],
  'd3': ['الأربعاء', 'Mercredi', 'Wednesday'],
  'd4': ['الخميس', 'Jeudi', 'Thursday'],
  'd5': ['الجمعة', 'Vendredi', 'Friday'],
  'd6': ['السبت', 'Samedi', 'Saturday'],
  'importList': ['استيراد قائمة (txt / csv)', 'Importer une liste (txt / csv)', 'Import a list (txt / csv)'],
  'pasteList': ['لصق قائمة منسوخة', 'Coller une liste copiée', 'Paste a copied list'],
  'quizLibrary': ['مكتبة الأسئلة', 'Bibliothèque de questions', 'Question library'],
  'quizLibrarySub': ['أسئلة ثقافة عامة جاهزة في شتى المواد. أضفها لبنكك وعدّل عليها كما تشاء.', 'Questions de culture générale dans toutes les matières. Ajoutez-les à votre banque et modifiez-les.', 'General-culture questions for every subject. Add them to your bank and edit them freely.'],
  'accountCreate': ['إنشاء حساب الأستاذ', 'Créer le compte de l\'enseignant', 'Create teacher account'],
  'accountCreateBtn': ['إنشاء الحساب', 'Créer le compte', 'Create account'],
  'accountWelcome': ['اللقب والاسم فقط، وكلمة السر اختيارية', 'Nom et prénom seulement, mot de passe facultatif', 'Last and first name only, password optional'],
  'accountTitle': ['حساب الأستاذ', 'Compte enseignant', 'Teacher account'],
  'accountEdit': ['تعديل الاسم واللقب', 'Modifier nom et prénom', 'Edit name'],
  'firstName': ['الاسم', 'Prénom', 'First name'],
  'lastName': ['اللقب', 'Nom', 'Last name'],
  'nameRequired': ['أدخل اللقب والاسم', 'Saisissez le nom et le prénom', 'Enter last and first name'],
  'nameMismatch': ['الاسم أو اللقب غير مطابق', 'Nom ou prénom incorrect', 'Name does not match'],
  'password': ['كلمة السر', 'Mot de passe', 'Password'],
  'passwordTitle': ['أدخل كلمة السر', 'Entrez le mot de passe', 'Enter your password'],
  'passwordOptional': ['حماية بكلمة سر (اختياري)', 'Protéger par mot de passe (facultatif)', 'Protect with a password (optional)'],
  'passwordConfirm': ['أعد كتابة كلمة السر', 'Confirmez le mot de passe', 'Confirm password'],
  'passwordShort': ['كلمة السر قصيرة (4 أحرف على الأقل)', 'Mot de passe trop court (4 caractères minimum)', 'Password too short (min. 4 characters)'],
  'passwordMismatch': ['كلمتا السر غير متطابقتين', 'Les mots de passe ne correspondent pas', 'Passwords do not match'],
  'passwordWrong': ['كلمة السر غير صحيحة', 'Mot de passe incorrect', 'Wrong password'],
  'passwordCurrent': ['كلمة السر الحالية', 'Mot de passe actuel', 'Current password'],
  'passwordSet': ['تفعيل كلمة سر', 'Activer un mot de passe', 'Set a password'],
  'passwordChange': ['تغيير كلمة السر', 'Changer le mot de passe', 'Change password'],
  'passwordRemove': ['حذف كلمة السر', 'Supprimer le mot de passe', 'Remove password'],
  'passwordSaved': ['تم حفظ كلمة السر', 'Mot de passe enregistré', 'Password saved'],
  'passwordRemoved': ['تم حذف كلمة السر', 'Mot de passe supprimé', 'Password removed'],
  'unlock': ['دخول', 'Ouvrir', 'Unlock'],
  'forgotPassword': ['نسيت كلمة السر؟', 'Mot de passe oublié ?', 'Forgot password?'],
  'forgotPasswordBody': ['اكتب لقب واسم الحساب بالضبط لحذف كلمة السر (بياناتك تبقى كما هي).', 'Saisissez exactement le nom et le prénom du compte pour supprimer le mot de passe (vos données sont conservées).', 'Type the exact last and first name of the account to remove the password (your data is kept).'],
  'confirm': ['تأكيد', 'Confirmer', 'Confirm'],
  'photo': ['الصورة', 'Photo', 'Photo'],
  'photoUrl': ['أو رابط الصورة (URL)', 'Ou lien de la photo (URL)', 'Or photo link (URL)'],
  'photoImport': ['رفع صورة', 'Importer une photo', 'Upload a photo'],
  'photoRemove': ['حذف الصورة', 'Supprimer la photo', 'Remove photo'],
  'noPhoto': ['لا توجد صورة لهذا التلميذ', 'Aucune photo pour cet élève', 'No photo for this student'],
  'subject': ['المادة', 'Matière', 'Subject'],
  'subjectHint': ['مثال: جبر، هندسة', 'Ex : Algèbre, Géométrie', 'e.g. Algebra, Geometry'],
  'schoolYearEdit': ['تعديل السنة الدراسية', 'Modifier l\'année scolaire', 'Edit school year'],
  'schoolYearHint': ['مثال: 2026/2027', 'Ex : 2026/2027', 'e.g. 2026/2027'],
  'period': ['الحصة', 'Séance', 'Period'],
  'room': ['القاعة', 'Salle', 'Room'],
  'clearSlot': ['مسح', 'Vider', 'Clear'],
  'editWholeBlock': ['تعديل الكتلة كاملة', 'Modifier tout le bloc', 'Edit the whole block'],
  'pickClassForSlot': ['اختر القسم', 'Choisir la classe', 'Choose the class'],

  // Calendar & notes
  'notebookHint': ['اضغط على يوم لفتح دفتر الملاحظات', 'Touchez un jour pour ouvrir son cahier', 'Tap a day to open its notebook'],
  'recentNotes': ['آخر الملاحظات', 'Notes récentes', 'Recent notes'],
  'writeNotes': ['اكتب ملاحظاتك هنا...', 'Écrivez vos notes ici...', 'Write your notes here...'],
  'lessonProgress': ['تقدم الدرس', 'Avancement du cours', 'Lesson progress'],
  'reminder': ['تذكير', 'Rappel', 'Reminder'],
  'studentRemark': ['ملاحظة عن تلميذ', 'Remarque sur un élève', 'Student remark'],
  'classesThatDay': ['حصص هذا اليوم', 'Séances du jour', 'Classes this day'],
};

extension Tr on BuildContext {
  /// Active language code: 'ar', 'fr' or 'en'.
  String get lang => Localizations.localeOf(this).languageCode;

  /// Translate a key into the active language.
  /// Reading the locale from [Localizations] makes the widget rebuild when the language changes.
  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    switch (lang) {
      case 'fr':
        return entry[1];
      case 'en':
        return entry[2];
      default:
        return entry[0];
    }
  }

  /// Praise for a correct answer. In Arabic it depends on the student's gender:
  /// أَحْسَنْتَ (male) / أَحْسَنْتِ (female). Other languages use the same text for both.
  String bravoFor({required bool female}) => t(female ? 'bravoFemale' : 'bravo');
}
