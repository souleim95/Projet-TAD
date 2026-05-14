-- ============================================================
-- Mini-projet GLPI CY Tech
-- Fichier : 01_init_oracle.sql
-- Objectif : initialisation de l'environnement Oracle
-- Contenu : tablespaces, cluster, utilisateurs Oracle, rôles et privilèges
-- ============================================================


-- ============================================================
-- 1. CREATION DES TABLESPACES
-- ============================================================

CREATE TABLESPACE TS_CERGY_DATA
DATAFILE 'cergy_data.dbf'
SIZE 50M
AUTOEXTEND ON;

CREATE TABLESPACE TS_PAU_DATA
DATAFILE 'pau_data.dbf'
SIZE 50M
AUTOEXTEND ON;

CREATE TABLESPACE TS_INDEX
DATAFILE 'index_data.dbf'
SIZE 30M
AUTOEXTEND ON;

CREATE TABLESPACE TS_HISTO
DATAFILE 'histo_data.dbf'
SIZE 30M
AUTOEXTEND ON;


-- ============================================================
-- 2. CREATION DU CLUSTER ORACLE
-- Objectif : regrouper physiquement les données souvent
-- consultées ensemble autour de la clé id_site.
-- Exemple : SITE, LOCALISATION, MATERIEL.
-- ============================================================

CREATE CLUSTER SITE_MATERIEL_LOCALISATION (
    id_site NUMBER
)
TABLESPACE TS_CERGY_DATA;


-- Index obligatoire pour utiliser le cluster Oracle
CREATE INDEX idx_cluster_site
ON CLUSTER SITE_MATERIEL_LOCALISATION;


-- ============================================================
-- 3. CREATION DES ROLES ORACLE
-- Ces rôles correspondent aux profils techniques d'accès à la base.
-- Ils sont différents de la table métier ROLE.
-- ============================================================

CREATE ROLE ROLE_CYTECH_ADMIN;
CREATE ROLE ROLE_CYTECH_TECHNICIEN;
CREATE ROLE ROLE_CYTECH_LECTURE;
CREATE ROLE ROLE_CYTECH_CERGY;
CREATE ROLE ROLE_CYTECH_PAU;


-- ============================================================
-- 4. CREATION DES UTILISATEURS ORACLE
-- Ces comptes représentent les utilisateurs techniques de la base.
-- Ils sont différents de la table métier UTILISATEUR.
-- ============================================================

CREATE USER CYTECH_ADMIN IDENTIFIED BY admin123
DEFAULT TABLESPACE TS_CERGY_DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON TS_CERGY_DATA
QUOTA UNLIMITED ON TS_PAU_DATA
QUOTA UNLIMITED ON TS_INDEX
QUOTA UNLIMITED ON TS_HISTO;

CREATE USER CYTECH_CERGY IDENTIFIED BY cergy123
DEFAULT TABLESPACE TS_CERGY_DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON TS_CERGY_DATA;

CREATE USER CYTECH_PAU IDENTIFIED BY pau123
DEFAULT TABLESPACE TS_PAU_DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON TS_PAU_DATA;

CREATE USER CYTECH_READONLY IDENTIFIED BY readonly123
DEFAULT TABLESPACE TS_CERGY_DATA
TEMPORARY TABLESPACE TEMP;


-- ============================================================
-- 5. PRIVILEGES GENERAUX
-- ============================================================

GRANT CREATE SESSION TO CYTECH_ADMIN;
GRANT CREATE SESSION TO CYTECH_CERGY;
GRANT CREATE SESSION TO CYTECH_PAU;
GRANT CREATE SESSION TO CYTECH_READONLY;


-- Privilèges de création pour l'administrateur du projet
GRANT CREATE TABLE TO CYTECH_ADMIN;
GRANT CREATE VIEW TO CYTECH_ADMIN;
GRANT CREATE PROCEDURE TO CYTECH_ADMIN;
GRANT CREATE TRIGGER TO CYTECH_ADMIN;
GRANT CREATE SEQUENCE TO CYTECH_ADMIN;
GRANT CREATE MATERIALIZED VIEW TO CYTECH_ADMIN;


-- ============================================================
-- 6. ATTRIBUTION DES ROLES AUX UTILISATEURS ORACLE
-- ============================================================

GRANT ROLE_CYTECH_ADMIN TO CYTECH_ADMIN;
GRANT ROLE_CYTECH_TECHNICIEN TO CYTECH_ADMIN;

GRANT ROLE_CYTECH_CERGY TO CYTECH_CERGY;
GRANT ROLE_CYTECH_TECHNICIEN TO CYTECH_CERGY;

GRANT ROLE_CYTECH_PAU TO CYTECH_PAU;
GRANT ROLE_CYTECH_TECHNICIEN TO CYTECH_PAU;

GRANT ROLE_CYTECH_LECTURE TO CYTECH_READONLY;