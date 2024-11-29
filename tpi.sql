DROP DATABASE IF EXISTS gestor_torneos;
CREATE DATABASE gestor_torneos;
USE gestor_torneos;



CREATE TABLE socio(
    numero_socio INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    apellido VARCHAR(50) NOT  NULL,
    DNI INT NOT NULL,
    fecha_nacimiento DATE,
    telefono VARCHAR(50),
    direccion VARCHAR(50)
);

CREATE TABLE equipo(
    numero_equipo INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    numero_representante INT REFERENCES socio(numero_socio),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    categoria ENUM('MAXI', 'SUPER', 'MASTER') NOT NULL,
    division ENUM('A', 'B', 'C') NOT NULL 
);

CREATE TABLE torneo(
    id_torneo INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    socio_encargado INT NOT NULL REFERENCES socio,
    nombre VARCHAR(50) NOT  NULL,
    inicio_torneo DATE,
    fin_torneo DATE,
    inicio_inscripcion DATE,
    fin_inscripcion DATE
);

CREATE TABLE inscripcion(
    id_torneo INT NOT NULL REFERENCES torneo,
    id_equipo INT NOT NULL REFERENCES equipo,
    director_tecnico INT NOT NULL REFERENCES  socio,
    socio_creador INT NOT NULL REFERENCES socio,
    PRIMARY KEY (id_torneo, id_equipo)
);

CREATE TABLE inscripcion_jugador(
    id_torneo INT NOT NULL REFERENCES torneo,
    id_equipo INT NOT NULL REFERENCES equipo,
    nro_jugador INT NOT NULL REFERENCES jugador,
    validado BOOLEAN NOT NULL
);

CREATE TABLE jugador(
    numero_socio INT NOT NULL REFERENCES socio,
    numero_equipo INT REFERENCES equipo,
    foto VARCHAR(255) NOT NULL,
    PRIMARY KEY (numero_socio)
);

CREATE TABLE arbitro(
    numero_socio INT NOT NULL REFERENCES socio,
    nivel_de_experiencia ENUM('BAJO', 'MEDIO', 'ALTO'),
    certificado VARCHAR(255) NOT NULL ,
    PRIMARY KEY(numero_socio)
);

CREATE TABLE cancha(
    id_cancha INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre varchar(50) NOT NULL,
    direccion varchar(50) NOT NULL
);

CREATE TABLE fixture(
    id_torneo INT NOT NULL REFERENCES torneo,
    division ENUM('A', 'B', 'C') NOT NULL,
    categoria ENUM('MAXI', 'SUPER', 'MASTER') NOT NULL,
    PRIMARY KEY (id_torneo, division, categoria)
);

CREATE TABLE rueda(
    nro_rueda INT NOT NULL,
    id_torneo INT NOT NULL REFERENCES torneo,
    division ENUM('A', 'B', 'C') NOT NULL,
    categoria ENUM('MAXI', 'SUPER', 'MASTER') NOT NULL,
    PRIMARY KEY (nro_rueda, id_torneo, division, categoria)
);

CREATE TABLE fecha(
    nro_fecha INT NOT NULL,
    id_torneo INT NOT NULL REFERENCES torneo,
    nro_rueda INT NOT NULL REFERENCES rueda(nro_rueda),
    division ENUM('A', 'B', 'C') NOT NULL,
    categoria ENUM('MAXI', 'SUPER', 'MASTER') NOT NULL,
    PRIMARY KEY (nro_fecha, id_torneo, nro_rueda, division, categoria)
);

CREATE TABLE partido(
    id_partido INT NOT NULL PRIMARY KEY,
    id_torneo INT NOT NULL REFERENCES torneo,
    nro_rueda INT NOT NULL REFERENCES rueda(nro_rueda),
    nro_fecha INT NOT NULL REFERENCES fecha(nro_fecha),
    division ENUM('A', 'B', 'C') NOT NULL,
    categoria ENUM('MAXI', 'SUPER', 'MASTER') NOT NULL,
    equipo_local INT NOT NULL REFERENCES equipo,
    equipo_visitante INT NOT NULL REFERENCES equipo
);

CREATE TABLE informacion(
    id_partido INT NOT NULL PRIMARY KEY REFERENCES partido,
    numero_arbitro INT NOT NULL REFERENCES arbitro,
    id_cancha INT NOT NULL REFERENCES cancha,
    fecha_hora DATE NOT NULL,
    resultado ENUM('1:0', '0:1', '2:2', '+:-', '-:+', '-:-')
);

CREATE TABLE jugador_partido(
    numero_jugador INT NOT NULL REFERENCES jugador,
    id_partido INT NOT NULL REFERENCES partido,
    juega_para_local BOOLEAN NOT NULL,
    PRIMARY KEY (numero_jugador, id_partido)
);

CREATE TABLE falta(
    id_falta INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    numero_jugador INT NOT NULL REFERENCES jugador,
    id_partido INT NOT NULL REFERENCES partido,
    tipo ENUM ('ROJA', 'AMARILLA', 'SIN TARJETA') NOT NULL
);

CREATE TABLE gol(
    id_gol INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    numero_jugador INT NOT NULL REFERENCES jugador,
    id_partido INT NOT NULL REFERENCES partido,
    momento TIME NOT NULL,
    en_contra TINYINT DEFAULT 0
);
