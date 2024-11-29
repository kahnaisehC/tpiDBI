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

delimiter //
CREATE PROCEDURE generar_fixture(IN nid_torneo INT, IN nro_ruedas INT)
BEGIN
IF nro_ruedas <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Numero de ruedas menor a 0';
ELSE
    SET @maxiA = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'MAXI' && division = 'A'
    );
    SET @maxiB = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'MAXI' && division = 'B'
    );
    SET @maxiC = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'MAXI' && division = 'C'
    );
    SET @superA = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'SUPER' && division = 'A'
    );
    SET @superB = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'SUPER' && division = 'B'
    );
    SET @superC = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'SUPER' && division = 'C'
    );
    SET @masterA = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'MASTER' && division = 'A'
    );
    SET @masterB = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'MASTER' && division = 'B'
    );
    SET @masterC = (
      SELECT id_equipo
      FROM inscripcion
      LEFT JOIN equipo ON equipo.numero_equipo inscripcion.numero_equipo
      WHERE id_torneo = nid_torneo && categoria = 'MASTER' && division = 'C'
    );

    -- maxiA
    crear_ruedas: LOOP
    SET nro_ruedas = nro_ruedas -1;
    IF nro_ruedas < 0 THEN
      LEAVE crear_ruedas;
    END IF;



    ITERATE nro_ruedas;
    END LOOP;
  END IF;
END//
delimiter ;
