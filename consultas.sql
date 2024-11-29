-- CONSULTA 1
-- Procedure que toma los datos necesarios para crear una inscripcion de un equipo al torneo

delimiter //
CREATE PROCEDURE inscribir_equipo(IN nid_torneo INT, IN nid_equipo INT, IN ndirector_tecnico INT, IN nsocio_creador INT)
BEGIN
  INSERT INTO gestor_torneos.inscripcion(id_torneo, numero_equipo, director_tecnico, socio_creador)
  VALUES(
    nid_torneo, nid_equipo, ndirector_tecnico, nsocio_creador
  );
END//
delimiter ;

-- CONSULTA 2
-- Procedure que toma los datos para crear un socio y luego crear un jugador en base a ese socio.
-- Luego, un segundo procedure para inscribir un jugador al torneo
-- Posee algunos checkeos para determinar si el jugador se puede inscribir al torneo con su equipo
-- (chequea si el jugador esta registrado en el equipo y luedo si la categoria del equipo es compatible con la edad que tendra el jugador al inicio del torneo)

delimiter // 

CREATE PROCEDURE registrar_jugador(IN nnombre VARCHAR(50), IN napellido VARCHAR(50), IN nDNI INT, IN nfecha_nacimiento DATE, IN ntelefono VARCHAR(50), IN ndireccion VARCHAR(50), IN nnro_equipo INT, IN nfoto VARCHAR(255))
BEGIN 
  INSERT INTO socio(nombre, apellido, DNI, fecha_nacimiento, telefono, direccion) VALUES(nnombre, napellido, nDNI, nfecha_nacimiento, ntelefono, ndireccion);
  SET @id_socio = (SELECT MAX(id_socio) FROM socio);
  INSERT INTO jugador(numero_socio, numero_equipo, foto) VALUES(@id_socio, nnro_equipo, nfoto);
END//


CREATE PROCEDURE inscribir_jugador_a_torneo(IN nid_equipo INT, IN nid_torneo INT , IN nid_jugador INT )
BEGIN

  SET @edad = (
    (SELECT YEAR(fecha_nacimiento)
    FROM socio
    WHERE nid_jugador = socio.numero_socio)
    - (SELECT YEAR(inicio_torneo) 
      FROM torneo
      WHERE nid_torneo = id_torneo
    )
  );
  SET @categoria = 
  CASE 
    WHEN @edad >= 41 AND @edad <= 45 THEN 'MAXI'
    WHEN @edad >= 46 AND @edad <= 50 THEN 'SUPER'
    WHEN @edad >= 51 AND @edad <= 55 THEN 'MASTER'
  END;
  IF (SELECT COUNT(*) FROM jugador WHERE nid_jugador = numero_jugador && numero_equipo != nid_equipo) = 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El jugador no esta registrado en el equipo';
  ELSEIF ((SELECT categoria FROM equipo WHERE nid_equipo = numero_equipo) <> @categoria) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La categoria del equipo no coincide con la categoria del jugador para el torneo al que se quiere inscribir';
  ELSE 
    INSERT INTO inscribir_jugador(id_torneo, id_equipo, nro_jugador) VALUES(nid_torneo, nid_equipo, nid_jugador);
  END IF;
END//

delimiter ;


-- CONSULTA 7
-- se declaran helper functions para obtener la cantidad de goles, partidos ganados, perdidos, etc para facilitar la query de la visitante
-- Por ultimo, se declara un procedure que toma el id de un torneo, la division y la categoria y muestra una vista ordenada respecto
-- a la cantidad de puntos y demas criterios mencionados en el enunciado de los equipos que estan inscriptos a ese torneo y pertenecen a esa division y categoria

delimiter //

CREATE FUNCTION get_goles_local(nnumero_equipo INT,id_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
  RETURN (
SELECT COUNT(*) AS goles_local
FROM gol
INNER JOIN equipo ON partido.equipo_local = equipo.numero_equipo
INNER JOIN partido ON partido.id_partido = gol.id_partido
INNER JOIN jugador_partido ON (jugador_partido.numero_jugador = gol.numero_jugador AND jugador_partido.id_partido = gol.id_partido)
WHERE partido.equipo_local = nnumero_equipo 
  AND partido.id_torneo = nid_torneo
  AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo
)
  AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
      AND(
    (jugador_partido.juega_para_local AND gol.en_contra = FALSE) 
    OR (NOT jugador_partido.juega_para_local AND gol.en_contra = TRUE)
  )
GROUP BY equipo_local)//

CREATE FUNCTION get_goles_visitante(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
  RETURN (
    SELECT COUNT(*) AS goles_visitante
    FROM gol
    INNER JOIN partido ON partido.id_partido = gol.id_partido
    INNER JOIN equipo ON partido.equipo_visitante = equipo.numero_equipo
    INNER JOIN jugador_partido ON (jugador_partido.numero_jugador = gol.numero_jugador AND jugador_partido.id_partido = gol.id_partido)
    WHERE (partido.equipo_visitante = nnumero_equipo)
      AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo
)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
      AND(
        (NOT jugador_partido.juega_para_local AND gol.en_contra = FALSE) 
        OR (jugador_partido.juega_para_local AND gol.en_contra = TRUE)
      )
    GROUP BY partido.equipo_visitante
  )//

CREATE FUNCTION get_goles_a_favor(nnumero_equipo INT,nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (get_goles_local(nnumero_equipo, nid_torneo) + get_goles_visitante(nnumero_equipo ,nid_torneo ))//


CREATE FUNCTION get_goles_en_contra_local(nnumero_equipo INT,id_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
  RETURN (
SELECT COUNT(*) AS goles_local
FROM gol
INNER JOIN equipo ON partido.equipo_local = equipo.numero_equipo
INNER JOIN partido ON partido.id_partido = gol.id_partido
INNER JOIN jugador_partido ON (jugador_partido.numero_jugador = gol.numero_jugador AND jugador_partido.id_partido = gol.id_partido)
WHERE partido.equipo_local = nnumero_equipo 
  AND partido.id_torneo = nid_torneo
  AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo
)
  AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
      AND(
    (jugador_partido.juega_para_local AND gol.en_contra = TRUE) 
    OR (NOT jugador_partido.juega_para_local AND gol.en_contra = FALSE)
  )
GROUP BY equipo_local)//

CREATE FUNCTION get_goles_en_contra_visitante(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
  RETURN (
    SELECT COUNT(*) AS goles_visitante
    FROM gol
    INNER JOIN partido ON partido.id_partido = gol.id_partido
    INNER JOIN equipo ON partido.equipo_visitante = equipo.numero_equipo
    INNER JOIN jugador_partido ON (jugador_partido.numero_jugador = gol.numero_jugador AND jugador_partido.id_partido = gol.id_partido)
    WHERE (partido.equipo_visitante = nnumero_equipo)
      AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo
)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
      AND(
        (NOT jugador_partido.juega_para_local AND gol.en_contra = TRUE) 
        OR (jugador_partido.juega_para_local AND gol.en_contra = FALSE)
      )
    GROUP BY partido.equipo_visitante
  )//

CREATE FUNCTION get_goles_en_contra(nnumero_equipo INT,nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (get_goles_en_contra_local(nnumero_equipo, nid_torneo) + get_goles_en_contra_visitante(nnumero_equipo ,nid_torneo ))//


-- query obtener goles de visitante de un equipo nnumero_equipo

-- query obtener partidos ganados de un equipo de local
CREATE FUNCTION get_partidos_ganados_local(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (
SELECT COUNT(*) AS partidos_ganados
FROM partido
INNER JOIN equipo ON equipo.numero_equipo = partido.equipo_local
INNER JOIN informacion ON partido.id_partido = informacion.id_partido
WHERE (equipo.numero_equipo = nnumero_equipo)
  AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo
)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
  AND (
    informacion.resultado = '1:0'
    OR informacion.resultado = '+:-'
  )
  GROUP BY partido.equipo_local
)//

-- query obtener partidos ganados de un equipo de visitante 
CREATE FUNCTION get_partidos_ganados_visitante(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
  RETURN (
SELECT COUNT(*) AS partidos_ganados
FROM partido
INNER JOIN equipo ON equipo.numero_equipo = partido.equipo_visitante
INNER JOIN informacion ON partido.id_partido = informacion.id_partido
WHERE (equipo.numero_equipo = nnumero_equipo)
  AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
  AND (
    informacion.resultado = '0:1'
    OR informacion.resultado = '-:+')
  GROUP BY partido.equipo_visitante
)//

CREATE FUNCTION get_partidos_ganados(nnumero_equipo INt, nid_torneo INT)
RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (get_partidos_ganados_local(nnumero_equipo, nid_torneo) + get_partidos_ganados_visitante, nid_torneo)//

CREATE FUNCTION get_partidos_empatados_local(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (
SELECT COUNT(*) AS partidos_ganados
FROM partido
INNER JOIN equipo ON equipo.numero_equipo = partido.equipo_local
INNER JOIN informacion ON partido.id_partido = informacion.id_partido
WHERE (equipo.numero_equipo = nnumero_equipo)
  AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo
)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
  AND (
    informacion.resultado = '2:2'
  )
  GROUP BY partido.equipo_local
)//

-- query obtener partidos ganados de un equipo de visitante 
CREATE FUNCTION get_partidos_empatados_visitante(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
  RETURN (
SELECT COUNT(*) AS partidos_ganados
FROM partido
INNER JOIN equipo ON equipo.numero_equipo = partido.equipo_visitante
INNER JOIN informacion ON partido.id_partido = informacion.id_partido
WHERE (equipo.numero_equipo = nnumero_equipo)
  AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
  AND (
    informacion.resultado = '2:2')
  GROUP BY partido.equipo_visitante
)//

CREATE FUNCTION get_partidos_empatado(nnumero_equipo INt, nid_torneo INT)
RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (get_partidos_empatados_visitante(nnumero_equipo, nid_torneo) + get_partidos_empatados_local(nnumero_equipo, nid_torneo))//


CREATE FUNCTION get_partidos_perdidos_local(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (
SELECT COUNT(*) AS partidos_ganados
FROM partido
INNER JOIN equipo ON equipo.numero_equipo = partido.equipo_local
INNER JOIN informacion ON partido.id_partido = informacion.id_partido
WHERE (equipo.numero_equipo = nnumero_equipo)
  AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo
)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
  AND (
    informacion.resultado = '0:1'
    OR informacion.resultado = '-:-'
    OR informacion.resultado = '-:+'
  )
  GROUP BY partido.equipo_local
)//

-- query obtener partidos ganados de un equipo de visitante 
CREATE FUNCTION get_partidos_perdidos_visitante(nnumero_equipo INT, nid_torneo INT)
  RETURNS INT NOT DETERMINISTIC READS SQL DATA
  RETURN (
SELECT COUNT(*) AS partidos_ganados
FROM partido
INNER JOIN equipo ON equipo.numero_equipo = partido.equipo_visitante
INNER JOIN informacion ON partido.id_partido = informacion.id_partido
WHERE (equipo.numero_equipo = nnumero_equipo)
  AND partido.id_torneo = nid_torneo
      AND partido.division = (SELECT division FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
      AND partido.categoria = (SELECT categoria FROM equipo WHERE nnumero_equipo = equipo.numero_equipo)
  AND (
    informacion.resultado = '0:1'
    OR informacion.resultado = '-:-'
    OR informacion.resultado = '-:+'
  )
  GROUP BY partido.equipo_visitante
)//

CREATE FUNCTION get_partidos_perdidos(nnumero_equipo INt, nid_torneo INT)
RETURNS INT NOT DETERMINISTIC READS SQL DATA
RETURN (get_partidos_ganados_local(nnumero_equipo, nid_torneo) + get_partidos_ganados_visitante, nid_torneo)//

CREATE PROCEDURE get_tabla_de_posiciones(IN ndivision ENUM('A', 'B', 'C'), IN ncategoria ENUM('MAXI' ,'SUPER', 'MASTER'), IN nid_torneo INT)
BEGIN
  SELECT equipo.nombre AS equipo, 
  get_partidos_ganados(equipo.nombre, inscripcion.id_torneo)*3
  + get_partidos_empatado(equipo.nombre, inscripcion.id_torneo) AS PTS,
  get_partidos_ganados(equipo.nombre, inscripcion.id_torneo) AS PG, 
  get_partidos_empatado(equipo.nombre, inscripcion.id_torneo) AS PE, 
  get_partidos_perdidos(equipo.nombre, inscripcion.id_torneo) AS PP, 
  get_goles_a_favor(equipo.nombre, inscripcion.id_torneo) AS GF, 
  get_goles_en_contra(equipo.nombre, inscripcion.id_torneo) AS GC, 
  get_goles_a_favor(equipo.nombre, inscripcion.id_torneo) - get_goles_en_contra AS DIF
  FROM equipo
  JOIN inscripcion ON equipo.numero_equipo = inscripcion.numero_equipo
  WHERE inscripcion.id_torneo = nid_torneo AND equipo.division = ndivision AND equipo.categoria = ncategoria
  ORDER BY PTS DESC, DIF DESC, GF DESC;
END//

delimiter ; 
