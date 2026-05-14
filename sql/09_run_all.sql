-- =============================================================================
-- PROJET TAD 2026 - CY TECH
-- Script de déploiement complet et tests de performance
-- =============================================================================

-- Nettoyage optionnel au début
-- @00_reset.sql

PROMPT --- ETAPE 1 : Initialisation des Tablespaces et Utilisateurs ---
@01_init_oracle.sql

PROMPT --- ETAPE 2 : Création du Schéma Relationnel ---
@02_schema.sql

PROMPT --- ETAPE 3 : Optimisation via Index et Clusters ---
@03_indexes.sql

PROMPT --- ETAPE 4 : Création des Vues Métier ---
@04_views.sql

PROMPT --- ETAPE 5 : Implémentation de la Logique PL/SQL (Triggers/Procédures) ---
@05_plsql.sql

PROMPT --- ETAPE 6 : Configuration de la BDDR (Cergy/Pau) ---
@06_bddr.sql

PROMPT --- ETAPE 7 : Injection du Jeu de Données Massif (PL/SQL) ---
@07_test_data.sql

PROMPT --- ETAPE 8 : Exécution des Tests de Performance (Explain Plan) ---
@08_performance_tests.sql

PROMPT ======================================================================
PROMPT DEPLOIEMENT ET VALIDATION TERMINÉS AVEC SUCCÈS
PROMPT ======================================================================