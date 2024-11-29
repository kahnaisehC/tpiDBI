delimiter //
CREATE PROCEDURE inscribir_equipo(IN nid_torneo INT, IN nid_equipo INT, IN ndirector_tecnico INT, IN nsocio_creador INT)
BEGIN
  INSERT INTO gestor_torneos.inscripcion(id_torneo, id_equipo, director_tecnico, socio_creador)
  VALUES(
    nid_torneo, nid_equipo, ndirector_tecnico, nsocio_creador
  );
END//
delimiter ;
