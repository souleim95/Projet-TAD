-- Tests de performance et plans d'exécution

SET ECHO ON;
SET FEEDBACK ON;
SET LINESIZE 180;
SET PAGESIZE 120;
SET TIMING ON;

DELETE FROM PLAN_TABLE
WHERE statement_id LIKE 'TAD_%';
COMMIT;


-- T01 : parc matériel de Cergy par site, type et statut

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T01' FOR
SELECT id_materiel, inventaire, nom, type_materiel, statut
FROM MATERIEL
WHERE id_site = 1
  AND type_materiel = 'PORTABLE'
  AND statut = 'EN_SERVICE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T01', 'BASIC +PREDICATE +ALIAS'));


-- T02 : utilisateurs actifs de Pau

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T02' FOR
SELECT id_user, login, nom, prenom
FROM UTILISATEUR
WHERE id_site = 2
  AND statut = 'ACTIF';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T02', 'BASIC +PREDICATE +ALIAS'));


-- T03 : rôles techniques par site

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T03' FOR
SELECT urs.id_user, urs.id_role, urs.id_site
FROM USER_ROLE_SITE urs
JOIN ROLE r
    ON urs.id_role = r.id_role
WHERE urs.id_site = 1
  AND r.code_role = 'TECHNICIEN';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T03', 'BASIC +PREDICATE +ALIAS'));


-- T04 : localisations de Cergy par bâtiment et salle

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T04' FOR
SELECT id_localisation, batiment, salle
FROM LOCALISATION
WHERE id_site = 1
  AND batiment = 'CERGY-BAT-1'
  AND salle = 'S001';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T04', 'BASIC +PREDICATE +ALIAS'));


-- T05 : adresses IP actives d'un VLAN de Pau

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T05' FOR
SELECT ip.adresse, ip.version_ip, sr.cidr, v.numero_vlan
FROM VLAN v
JOIN SOUS_RESEAU sr
    ON sr.id_vlan = v.id_vlan
JOIN ADRESSE_IP ip
    ON ip.id_sous_reseau = sr.id_sous_reseau
WHERE v.id_site = 2
  AND v.numero_vlan = 2001
  AND ip.active = '1';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T05', 'BASIC +PREDICATE +ALIAS'));


-- T06 : topologie réseau de Cergy

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T06' FOR
SELECT nom_site, nom_equipement, nom_interface, adresse, numero_vlan
FROM V_TOPOLOGIE_RESEAU
WHERE id_site = 1
  AND numero_vlan = 1001
  AND ip_active = '1';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T06', 'BASIC +PREDICATE +ALIAS'));


-- T07 : interfaces d'un matériel connu

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T07' FOR
SELECT ir.id_interface, ir.nom, ir.mac, ip.adresse
FROM MATERIEL m
JOIN INTERFACE_RESEAU ir
    ON ir.id_materiel = m.id_materiel
LEFT JOIN ADRESSE_IP ip
    ON ip.id_interface = ir.id_interface
WHERE m.inventaire = 'CGY-MAT-001000';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T07', 'BASIC +PREDICATE +ALIAS'));


-- T08 : connexions actives depuis une interface de Cergy

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T08' FOR
SELECT c.id_connexion, c.id_interface_a, c.id_interface_b, c.type_connexion
FROM CONNEXION c
WHERE c.id_interface_a = (
    SELECT MIN(id_interface)
    FROM V_INTERFACES_RESEAU_CERGY
)
  AND c.active = '1';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T08', 'BASIC +PREDICATE +ALIAS'));


-- T09 : vision globale BDDR des matériels

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T09' FOR
SELECT id_site, type_materiel, COUNT(*) AS nb_materiels
FROM V_MATERIEL_GLOBAL
GROUP BY id_site, type_materiel;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T09', 'BASIC +PREDICATE +ALIAS'));


-- T10 : parc global par site et statut

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T10' FOR
SELECT code_site, statut_materiel, COUNT(*) AS nb_materiels
FROM V_PARC_GLOBAL
WHERE statut_materiel IN ('EN_SERVICE', 'AFFECTE', 'MAINTENANCE')
GROUP BY code_site, statut_materiel;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T10', 'BASIC +PREDICATE +ALIAS'));


-- T11 : historique des affectations par site

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T11' FOR
SELECT id_histo, id_materiel, id_user, date_debut, date_fin
FROM HISTO_AFFECTATION
WHERE id_site = 1
  AND date_debut >= SYSDATE - 900;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T11', 'BASIC +PREDICATE +ALIAS'));


-- T12 : vue matérialisée du parc global

EXPLAIN PLAN SET STATEMENT_ID = 'TAD_T12' FOR
SELECT code_site, type_materiel, COUNT(*) AS nb_materiels
FROM MV_PARC_GLOBAL
GROUP BY code_site, type_materiel;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'TAD_T12', 'BASIC +PREDICATE +ALIAS'));

SET TIMING OFF;
SET ECHO OFF;
