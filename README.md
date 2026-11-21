# Mon Prof (Flutter)

Assistant de classe hors-ligne pour professeur (toutes matières) : quiz, classes et points des élèves, emploi du temps (9 séances, fusion automatique), calendrier et notes. Arabe / français / anglais, chiffres toujours en 0-9.

## Fichiers (tous à la racine du dépôt)
- `*.dart` : le code (rangé automatiquement dans `lib/` par le workflow)
- `pubspec.yaml` : dépendances
- `success.wav` : son de réussite (rangé dans `assets/sounds/`)
- `build_apk.yml` : le workflow GitHub Actions (doit aussi exister dans `.github/workflows/`)
- `CHANGELOG.md` : liste des changements

## Mettre le projet sur GitHub
1. Créer un dépôt sur <https://github.com/new>.
2. **Add file > Upload files** : glisser **tous** les fichiers de ce dossier, puis **Commit changes** (branche `main`).
3. **Add file > Create new file**. Dans le nom, taper exactement `.github/workflows/build_apk.yml` (taper `/` crée les dossiers). Coller le contenu de `build_apk.yml`, puis **Commit changes**.
4. **Settings > Actions > General > Workflow permissions** : choisir **Read and write permissions**, puis **Save**.

## Récupérer l'APK
Chaque push sur `main` lance le build (5 à 10 minutes).
- **Releases** (colonne de droite du dépôt) : télécharger `math-teacher-v1.1.N.apk`.
- ou **Actions** > dernier run > **Artifacts** > `math-teacher-apk`.

Lancement manuel : **Actions > Build & Release Android APK > Run workflow**.

## Utilisation
- **Quiz** : liste déroulante pour choisir une question précise (sinon ordre aléatoire) ; pendant le quiz, l'icône liste permet de sauter à une question.
- **Élève sélectionné** : tirage au sort ou choix manuel ; son nom s'affiche en grand sous les boutons. Bonne réponse du premier coup = +1 point (réglable avec `kPointOnlyFirstTry` dans `presentation_screen.dart`).
- **Classes** : points visibles à côté de chaque élève ; bouton de remise à zéro.
- **Emploi du temps** : les séances consécutives de la même classe sont fusionnées.
