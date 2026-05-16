# Projet-TAD

Mini-projet SIE 2026 - Refonte d'une partie de la base GLPI pour le parc informatique CY Tech, avec prise en compte des sites de Cergy et Pau.

## Contenu

```text
docs/
  MiniProjetSIE2026.pdf
  Rapport.docx
  Rapport.pdf

sql/
  01_init_oracle.sql
  02_schema.sql
  03_indexes.sql
  04_views.sql
  05_plsql.sql
  06_bddr.sql
  07_test_data.sql
  08_performance_tests.sql
  09_run_all.sql
  10_performance_comparison.sql
```

## Exécution

`01_init_oracle.sql` doit être lancé avec un compte administrateur Oracle.

Ensuite, se connecter avec l'utilisateur applicatif :

```text
Utilisateur : CYTECH_ADMIN
Mot de passe : admin123
```

Puis lancer les scripts dans l'ordre :

```sql
@02_schema.sql
@03_indexes.sql
@04_views.sql
@05_plsql.sql
@06_bddr.sql
@07_test_data.sql
@08_performance_tests.sql
@10_performance_comparison.sql
```

Avec SQL*Plus ou SQLcl, le script complet peut être lancé depuis le dossier `sql` :

```sql
@09_run_all.sql
```

## Vérifications utiles

```sql
SELECT object_type, status, COUNT(*)
FROM user_objects
GROUP BY object_type, status
ORDER BY object_type, status;

SELECT id_site, COUNT(*) FROM MATERIEL GROUP BY id_site;
SELECT id_site, COUNT(*) FROM UTILISATEUR GROUP BY id_site;
```

Résultats attendus après chargement :

```text
MATERIEL    : 3000 Cergy, 3000 Pau
UTILISATEUR : 500 Cergy, 500 Pau
```

## Remarque

La comparaison de performance avec GLPI est simulée dans `10_performance_comparison.sql`, car le projet ne fournit pas une instance GLPI complète chargée avec les mêmes données.
