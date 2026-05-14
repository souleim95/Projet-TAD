-- Objectif : création du schéma relationnel de la base cible
-- Contenu : tables, clés primaires, clés étrangères, contraintes UNIQUE et CHECK


-- 1. TABLES DE REFERENCE ET ORGANISATION

CREATE TABLE SITE (
    id_site NUMBER GENERATED ALWAYS AS IDENTITY,
    code_site VARCHAR2(10) NOT NULL,
    nom VARCHAR2(100) NOT NULL,
    ville VARCHAR2(80) NOT NULL,
    actif CHAR(1) DEFAULT '1' NOT NULL,

    CONSTRAINT pk_site PRIMARY KEY (id_site),
    CONSTRAINT uk_site_code UNIQUE (code_site),
    CONSTRAINT ck_site_actif CHECK (actif IN ('0', '1'))
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE ROLE (
    id_role NUMBER GENERATED ALWAYS AS IDENTITY,
    code_role VARCHAR2(20) NOT NULL,
    libelle VARCHAR2(100) NOT NULL,

    CONSTRAINT pk_role PRIMARY KEY (id_role),
    CONSTRAINT uk_role_code UNIQUE (code_role)
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE LOCALISATION (
    id_localisation NUMBER GENERATED ALWAYS AS IDENTITY,
    id_site NUMBER NOT NULL,
    batiment VARCHAR2(100),
    salle VARCHAR2(50),

    CONSTRAINT pk_localisation PRIMARY KEY (id_localisation),
    CONSTRAINT fk_localisation_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site)
)
CLUSTER SITE_MATERIEL_LOCALISATION(id_site);


-- 2. UTILISATEURS ET DROITS METIER

CREATE TABLE UTILISATEUR (
    id_user NUMBER GENERATED ALWAYS AS IDENTITY,
    login VARCHAR2(80) NOT NULL,
    nom VARCHAR2(80) NOT NULL,
    prenom VARCHAR2(80),
    email VARCHAR2(150),
    statut VARCHAR2(20) DEFAULT 'ACTIF' NOT NULL,
    id_site NUMBER NOT NULL,

    CONSTRAINT pk_utilisateur PRIMARY KEY (id_user),
    CONSTRAINT uk_utilisateur_login UNIQUE (login),
    CONSTRAINT uk_utilisateur_email UNIQUE (email),
    CONSTRAINT fk_utilisateur_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site),
    CONSTRAINT ck_utilisateur_statut CHECK (
        statut IN ('ACTIF', 'INACTIF', 'SUSPENDU')
    )
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE USER_ROLE_SITE (
    id_user_role_site NUMBER GENERATED ALWAYS AS IDENTITY,
    id_user NUMBER NOT NULL,
    id_role NUMBER NOT NULL,
    id_site NUMBER NOT NULL,
    date_debut DATE DEFAULT SYSDATE NOT NULL,
    date_fin DATE,

    CONSTRAINT pk_user_role_site PRIMARY KEY (id_user_role_site),
    CONSTRAINT fk_urs_user FOREIGN KEY (id_user)
        REFERENCES UTILISATEUR(id_user),
    CONSTRAINT fk_urs_role FOREIGN KEY (id_role)
        REFERENCES ROLE(id_role),
    CONSTRAINT fk_urs_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site),
    CONSTRAINT uk_urs_user_role_site UNIQUE (id_user, id_role, id_site),
    CONSTRAINT ck_urs_dates CHECK (
        date_fin IS NULL OR date_fin >= date_debut
    )
) TABLESPACE TS_CERGY_DATA;


-- 3. MATERIELS ET AFFECTATIONS

CREATE TABLE MATERIEL (
    id_materiel NUMBER GENERATED ALWAYS AS IDENTITY,
    inventaire VARCHAR2(50) NOT NULL,
    nom VARCHAR2(100) NOT NULL,
    type_materiel VARCHAR2(40) NOT NULL,
    statut VARCHAR2(30) DEFAULT 'EN_SERVICE' NOT NULL,
    id_site NUMBER NOT NULL,
    id_localisation NUMBER,
    id_user_responsable NUMBER,
    date_creation DATE DEFAULT SYSDATE NOT NULL,
    date_modification DATE,

    CONSTRAINT pk_materiel PRIMARY KEY (id_materiel),
    CONSTRAINT uk_materiel_inventaire UNIQUE (inventaire),
    CONSTRAINT fk_materiel_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site),
    CONSTRAINT fk_materiel_localisation FOREIGN KEY (id_localisation)
        REFERENCES LOCALISATION(id_localisation),
    CONSTRAINT fk_materiel_user FOREIGN KEY (id_user_responsable)
        REFERENCES UTILISATEUR(id_user),
    CONSTRAINT ck_materiel_statut CHECK (
        statut IN ('EN_SERVICE', 'AFFECTE', 'EN_STOCK', 'HS', 'MAINTENANCE')
    )
)
CLUSTER SITE_MATERIEL_LOCALISATION(id_site);


CREATE TABLE HISTO_AFFECTATION (
    id_histo NUMBER GENERATED ALWAYS AS IDENTITY,
    id_materiel NUMBER NOT NULL,
    id_user NUMBER,
    id_site NUMBER NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE,

    CONSTRAINT pk_histo_affectation PRIMARY KEY (id_histo),
    CONSTRAINT fk_histo_materiel FOREIGN KEY (id_materiel)
        REFERENCES MATERIEL(id_materiel),
    CONSTRAINT fk_histo_user FOREIGN KEY (id_user)
        REFERENCES UTILISATEUR(id_user),
    CONSTRAINT fk_histo_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site),
    CONSTRAINT ck_histo_dates CHECK (
        date_fin IS NULL OR date_fin >= date_debut
    )
) TABLESPACE TS_HISTO;


-- ============================================================
-- 4. RESEAU
-- ============================================================

CREATE TABLE EQUIPEMENT_RESEAU (
    id_equipement NUMBER GENERATED ALWAYS AS IDENTITY,
    nom VARCHAR2(100) NOT NULL,
    type_equipement VARCHAR2(50) NOT NULL,
    ip_mgmt VARCHAR2(45),
    id_site NUMBER NOT NULL,

    CONSTRAINT pk_equipement_reseau PRIMARY KEY (id_equipement),
    CONSTRAINT uk_equipement_ip_mgmt UNIQUE (ip_mgmt),
    CONSTRAINT fk_equipement_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site)
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE INTERFACE_RESEAU (
    id_interface NUMBER GENERATED ALWAYS AS IDENTITY,
    nom VARCHAR2(80) NOT NULL,
    mac VARCHAR2(17),
    debit_mbps NUMBER,
    mtu NUMBER DEFAULT 1500,
    id_materiel NUMBER,
    id_equipement NUMBER,

    CONSTRAINT pk_interface_reseau PRIMARY KEY (id_interface),
    CONSTRAINT uk_interface_mac UNIQUE (mac),
    CONSTRAINT fk_interface_materiel FOREIGN KEY (id_materiel)
        REFERENCES MATERIEL(id_materiel),
    CONSTRAINT fk_interface_equipement FOREIGN KEY (id_equipement)
        REFERENCES EQUIPEMENT_RESEAU(id_equipement),

    -- Une interface appartient soit à un matériel,
    -- soit à un équipement réseau, mais jamais aux deux.
    CONSTRAINT ck_iface_owner CHECK (
        (id_materiel IS NOT NULL AND id_equipement IS NULL)
        OR
        (id_materiel IS NULL AND id_equipement IS NOT NULL)
    ),

    CONSTRAINT ck_interface_mtu CHECK (
        mtu BETWEEN 576 AND 9000
    )
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE VLAN (
    id_vlan NUMBER GENERATED ALWAYS AS IDENTITY,
    numero_vlan NUMBER NOT NULL,
    nom VARCHAR2(100),
    id_site NUMBER NOT NULL,

    CONSTRAINT pk_vlan PRIMARY KEY (id_vlan),
    CONSTRAINT fk_vlan_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site),

    -- Le même numéro de VLAN peut exister à Cergy et à Pau,
    -- mais pas deux fois sur le même site.
    CONSTRAINT uk_vlan_site_numero UNIQUE (id_site, numero_vlan),

    CONSTRAINT ck_vlan_numero CHECK (
        numero_vlan BETWEEN 1 AND 4094
    )
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE SOUS_RESEAU (
    id_sous_reseau NUMBER GENERATED ALWAYS AS IDENTITY,
    cidr VARCHAR2(45) NOT NULL,
    passerelle VARCHAR2(45),
    id_vlan NUMBER NOT NULL,
    id_site NUMBER NOT NULL,

    CONSTRAINT pk_sous_reseau PRIMARY KEY (id_sous_reseau),
    CONSTRAINT uk_sous_reseau_cidr UNIQUE (cidr),
    CONSTRAINT fk_sous_reseau_vlan FOREIGN KEY (id_vlan)
        REFERENCES VLAN(id_vlan),
    CONSTRAINT fk_sous_reseau_site FOREIGN KEY (id_site)
        REFERENCES SITE(id_site)
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE ADRESSE_IP (
    id_ip NUMBER GENERATED ALWAYS AS IDENTITY,
    adresse VARCHAR2(45) NOT NULL,
    version_ip NUMBER NOT NULL,
    active CHAR(1) DEFAULT '1' NOT NULL,
    id_sous_reseau NUMBER NOT NULL,
    id_interface NUMBER,

    CONSTRAINT pk_adresse_ip PRIMARY KEY (id_ip),
    CONSTRAINT uk_adresse_ip UNIQUE (adresse),
    CONSTRAINT fk_adresse_ip_sous_reseau FOREIGN KEY (id_sous_reseau)
        REFERENCES SOUS_RESEAU(id_sous_reseau),
    CONSTRAINT fk_adresse_ip_interface FOREIGN KEY (id_interface)
        REFERENCES INTERFACE_RESEAU(id_interface),
    CONSTRAINT ck_adresse_ip_version CHECK (
        version_ip IN (4, 6)
    ),
    CONSTRAINT ck_adresse_ip_active CHECK (
        active IN ('0', '1')
    )
) TABLESPACE TS_CERGY_DATA;


CREATE TABLE CONNEXION (
    id_connexion NUMBER GENERATED ALWAYS AS IDENTITY,
    id_interface_a NUMBER NOT NULL,
    id_interface_b NUMBER NOT NULL,
    type_connexion VARCHAR2(50),
    active CHAR(1) DEFAULT '1' NOT NULL,
    date_creation DATE DEFAULT SYSDATE NOT NULL,

    CONSTRAINT pk_connexion PRIMARY KEY (id_connexion),
    CONSTRAINT fk_connexion_interface_a FOREIGN KEY (id_interface_a)
        REFERENCES INTERFACE_RESEAU(id_interface),
    CONSTRAINT fk_connexion_interface_b FOREIGN KEY (id_interface_b)
        REFERENCES INTERFACE_RESEAU(id_interface),

    -- Une interface ne peut pas être connectée à elle-même.
    CONSTRAINT ck_connexion_interfaces CHECK (
        id_interface_a <> id_interface_b
    ),

    CONSTRAINT ck_connexion_active CHECK (
        active IN ('0', '1')
    )
) TABLESPACE TS_CERGY_DATA;