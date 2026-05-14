-- =============================================================================
-- Nom du fichier : 08_performance_tests.sql
-- Projet : TAD - Refonte BDD GLPI (CY Tech)
-- Objectif : Analyser les performances et valider les choix d'indexation/BDDR
-- =============================================================================

SET ECHO ON;
SET FEEDBACK ON;
SET LINESIZE 150;
SET PAGESIZE 100;

PROMPT ======================================================================
PROMPT TEST 1 : Recherche par Numéro de Série (Validation des Index B-Tree)
PROMPT Objectif : Vérifier qu'Oracle utilise l'index au lieu d'un Full Table Scan.
PROMPT ======================================================================

-- Simulation d'une recherche précise sur 3000 matériels
EXPLAIN PLAN FOR 
SELECT * FROM MATERIEL WHERE num_serie = 'SN-ABC123XYZ';

-- Affichage du plan : On cherche "INDEX RANGE SCAN" ou "INDEX UNIQUE SCAN"
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


PROMPT ======================================================================
PROMPT TEST 2 : Filtrage par Statut (Validation des Index Bitmap)
PROMPT Objectif : Vérifier l'efficacité sur les colonnes à faible cardinalité.
PROMPT ======================================================================

EXPLAIN PLAN FOR
SELECT COUNT(*) FROM MATERIEL 
WHERE statut = 'EN_SERVICE' AND id_site = 1;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


PROMPT ======================================================================
PROMPT TEST 3 : Topologie Réseau (Validation des Jointures et Clusters)
PROMPT Objectif : Mesurer le coût de la jointure entre Matériel et Interfaces.
PROMPT ======================================================================

EXPLAIN PLAN FOR
SELECT m.nom_materiel, i.mac_adresse, ip.adresse
FROM MATERIEL m
JOIN INTERFACE_RESEAU i ON m.id_mat = i.id_mat
JOIN ADRESSE_IP ip ON i.id_ip = ip.id_ip
WHERE m.id_site = 1;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


PROMPT ======================================================================
PROMPT TEST 4 : Vue Globale Distribuée (Validation de la BDDR)
PROMPT Objectif : Analyser comment Oracle traite l'union entre Cergy et Pau.
PROMPT ======================================================================

-- Ce test utilise la vue créée dans 04_views.sql qui fait le lien avec 06_bddr.sql
EXPLAIN PLAN FOR
SELECT site_nom, COUNT(*) as total_materiels
FROM V_PARC_GLOBAL_DISTRIBUE
GROUP BY site_nom;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


PROMPT ======================================================================
PROMPT TEST 5 : Recherche Utilisateur par Email
PROMPT ======================================================================

EXPLAIN PLAN FOR
SELECT nom, prenom, id_site 
FROM UTILISATEUR 
WHERE email LIKE 'user250%';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

PROMPT ======================================================================
PROMPT TESTS TERMINÉS. 
PROMPT Veuillez copier ces plans d'exécution dans la partie "Résultats" du rapport.
PROMPT ======================================================================

SET ECHO OFF;