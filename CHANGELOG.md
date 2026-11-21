# Changelog

## 1.9.0
- **Compte enseignant** : à la première ouverture, création du compte avec le nom et le prénom uniquement ; **mot de passe facultatif** (activable, modifiable ou supprimable dans les réglages). Mot de passe oublié : on retape le nom et le prénom du compte.
- Carte « Aujourd'hui » retirée de l'écran Quiz.
- **Bibliothèque de questions de culture générale** (231 questions en 16 catégories : histoire de la Tunisie, histoire générale, géographie, physique-chimie, biologie, astronomie, arabe, français, anglais, éducation islamique, éducation civique, sport, arts et patrimoine, informatique, culture mathématique). Bouton « مكتبة الأسئلة » dans l'écran Quiz : ajout d'une question ou d'une catégorie entière à votre banque, sans doublons.
- **Nouvelle icône d'application** (toque de diplômé, comme l'écran d'accueil).
- **Ajout d'élèves** : importer une liste depuis un fichier .txt / .csv ou coller une liste copiée (un nom par ligne), en plus de l'ajout un par un.
- **Photo de l'élève** (URL ou import depuis la galerie), masquée par défaut : elle s'affiche dans une fenêtre au clic sur le nom.
- **Emploi du temps lié à l'année scolaire** (champ `annee_scolaire`, modifiable en haut de l'écran) et **matière** (`matiere`) pour chaque séance. Base de données v7 : migration automatique, séances existantes rattachées à l'année en cours.

## 1.8.0
- **Application pour tous les professeurs (toutes matières)** : nouveau nom « أستاذي / Mon Prof », écran d'accueil sans π, bibliothèque de questions de mathématiques retirée (la banque de questions et l'outil intelligent restent). Les données existantes sont conservées.

## 1.7.1
- **Code secret supprimé complètement** (écran de verrouillage, réglages, fichiers `lock_gate.dart`, `app_lock.dart`, `pin_screen.dart`, dépendance `crypto`).
- **Emploi du temps** : zoom (pincer, 1x à 4x) et déplacement du doigt pour atteindre la dernière séance. Le tableau remplit toute la hauteur de la page.
- Correction du build : chaînes multi-lignes de `strings.dart` qui faisaient échouer la compilation.

## 1.7.0

### Modifications
- **Code secret facultatif** : désactivé par défaut, l'application s'ouvre directement. Dans les réglages : activer / changer / verrouiller maintenant / désactiver (le code actuel est demandé pour le désactiver).
- **« مكتبتي »** : le dossier « année scolaire » est supprimé. Le bouton « إضافة سنة دراسية » devient « إضافة مجلد » : créez vos propres dossiers (et sous-dossiers) sous les trois sections. Les anciennes années qui contenaient des fichiers deviennent de simples dossiers (aucun fichier perdu).
- **Emploi du temps** plus compact : les 6 jours se partagent la largeur de l'écran (plus de défilement horizontal), cases et polices plus petites.

## 1.6.0

### Nouveautés
- **Code secret (PIN)** : à l'ouverture de l'application (4 à 8 chiffres, créé au premier lancement, stocké sous forme de hash SHA-256 avec sel). Re-verrouillage après 2 minutes d'absence, délai d'attente après 5 erreurs, changement du code et « verrouiller maintenant » dans les réglages. Code oublié : effacement de toutes les données puis nouveau code.
- **Onglet « مكتبتي » : « دفتر الأستاذ »** avec trois sections empilées (فروض المراقبة, الفروض التأليفية, الدروس). Dossiers et sous-dossiers illimités, import de tout type de fichier, appareil photo, renommer, supprimer, recherche dans le dossier et recherche globale. Dossiers prêts « فرض مراقبة عدد 1 à 6 » et « فرض تأليفي عدد 1 à 3 » en un toucher. La bibliothèque par année scolaire reste en dessous.

## 1.5.0

### Nouveautés
- **Bibliothèque de questions** (écran Quiz) : 72 questions prêtes avec leurs réponses, en 9 thèmes (nombres, fractions, nombres relatifs, puissances et racines, algèbre, proportionnalité, géométrie, mesures, statistiques). Ajout d'une question ou de tout un thème à votre banque en un toucher, sans doublons. Vos propres questions restent possibles dans « بنك الأسئلة ».
- **Outil intelligent** (écran Quiz) : collez un texte brut de questions et réponses ; l'application sépare chaque question de ses choix, trouve la bonne réponse (« Réponse : B », ✓, *, Q/R...), ajoute des mauvaises réponses pour les réponses numériques, puis vous laisse vérifier et corriger avant l'ajout. Fonctionne hors-ligne.
- **Années scolaires libres** (مكتبتي) : saisissez n'importe quelle année (ex. 2031/2032) ou choisissez dans une liste qui va jusqu'à 2050.

## 1.4.0

### Nouveautés
- L'application s'appelle maintenant **Math-Thauraya** (nom sous l'icône, écran d'accueil, fichier APK).
- Liste des élèves : icône Notes (ملاحظات) pour chaque élève, avec un espace privé d'observations (enregistrement automatique). L'icône devient jaune quand une note existe. Modifier / supprimer passent dans le menu ⋮.
- Nouvel onglet « مكتبتي » après « الأجندة », organisé par année scolaire (2026/2027, ...).
  - Dossier « ملفاتي » : fichiers PDF, Word (.doc/.docx) et images (.jpg/.jpeg/.png), import depuis le téléphone ou photo directe avec la caméra.
  - Dossier « الفروض » : « فروض المراقبة » (فرض مراقبة عدد 1 à 6) et « الفروض التأليفية » (فرض تأليفي عدد 1 à 3), chacun avec import de fichiers et caméra.
- Base de données en version 4 (migration automatique, aucune donnée perdue).

## 1.3.0

### Nouveautés
- Écran d'accueil animé (π) et vraie icône d'application ; le nom sous l'icône devient « معلم الرياضيات ».
- Carte « Aujourd'hui » : séances du jour (emploi du temps), séance en cours surlignée, un toucher = classe active.
- Classement de la classe avec podium (🏆 sur l'écran du quiz et dans la page de la classe).
- Chrono par question (réglages : 10 / 20 / 30 / 60 s). À la fin du temps, la bonne réponse est montrée sans point.
- Tirage au sort équitable : personne n'est tiré deux fois avant que tout le monde soit passé.
- Réglages (⚙️) : chrono, sons et voix on/off, sauvegarde et restauration par copier-coller (WhatsApp, Notes), sans internet.
- Numéro de build Android croissant : chaque APK s'installe par-dessus le précédent.

## 1.2.0

### Nouveautés
- Sexe de l'élève (ذكر / أنثى) : sélecteur à l'ajout et à la modification d'un élève, enregistré en base (migration version 3, les élèves existants sont « ذكر » par défaut). Icône ♂/♀ dans la liste des élèves.
- Félicitation arabe selon le sexe de l'élève sélectionné : `أَحْسَنْتَ` (ذكر) ou `أَحْسَنْتِ` (أنثى), avec voyelles explicites, affichée dans la bannière et lue par la voix. Sans élève sélectionné : `أَحْسَنْتَ`.

## 1.1.0

### Nouveautés
- Voix arabe : le texte lu est `أَحْسَنْتَ` (avec voyelles) et non plus « أحسنت ». La voix `ar-SA` est essayée en premier.
- Sélection manuelle d'une question : liste déroulante sur l'écran du quiz, et saut vers n'importe quelle question pendant le quiz.
- « تمرين الإحماء » devient « السؤال ».
- Élève sélectionné affiché en grand sous les boutons « تلميذ عشوائي » et « بنك الأسئلة » ; choix manuel ou tirage au sort.
- Points persistants par élève (+1 par bonne réponse, affichés dans la liste des élèves, remise à zéro possible par classe). Base de données migrée en version 2.
- Chiffres occidentaux (0-9) partout, même en arabe : dates, titre du calendrier, questions, notes, salles. Les chiffres arabes saisis au clavier sont convertis automatiquement.
- Emploi du temps : séance 9 à 17:00 et fusion automatique des séances consécutives de la même classe.
- Workflow GitHub Actions : build de l'APK et publication d'une Release à chaque push sur `main`.

### Corrections et optimisations
- La base de données ne peut plus être ouverte deux fois en parallèle au démarrage.
- La voix est arrêtée en passant à la question suivante (plus de chevauchement).
- Les puces de la note du jour regroupent les séances consécutives d'une même classe.
- Suppression ou renommage d'un élève sélectionné : la sélection est mise à jour.
- Boîtes de confirmation factorisées (`confirmDialog`).
