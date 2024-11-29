delimiter //
CREATE PROCEDURE inscribir_equipo(IN nid_torneo INT, IN nid_equipo INT, IN ndirector_tecnico INT, IN nsocio_creador INT)
BEGIN
  INSERT INTO gestor_torneos.inscripcion(id_torneo, numero_equipo, director_tecnico, socio_creador)
  VALUES(
    nid_torneo, nid_equipo, ndirector_tecnico, nsocio_creador
  );
END//
delimiter ;

delimiter // 
CREATE PROCEDURE inscribir_jugador(IN nid_equipo INT, IN nid_torneo INT , IN nid_jugador INT )
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
