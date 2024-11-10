--Trigger para que un estudiante no pueda programar el misma dia a la misma hora
CREATE OR REPLACE TRIGGER TRG_VERIFICAR_CLASE_PROGRAMADA
BEFORE INSERT ON CLASES_PROGRAMADAS
FOR EACH ROW
DECLARE
	v_count NUMBER;
BEGIN
	-- Contar cuántas clases ya están programadas para el estudiante en la misma 
	-- fecha y hora
	SELECT COUNT(*)
	INTO v_count
	FROM CLASES_PROGRAMADAS
	WHERE DNI_ESTUDIANTE = :NEW.DNI_ESTUDIANTE
  	AND FECHA_CLASE_PROGRAMADA = :NEW.FECHA_CLASE_PROGRAMADA
  	AND HORA_CLASE_PROGRAMADA = :NEW.HORA_CLASE_PROGRAMADA;

	-- Si ya hay una clase programada, lanzar un error
	IF v_count > 0 THEN
    	RAISE_APPLICATION_ERROR(-20002, 'El estudiante ya tiene una clase programada 
    	en esta fecha y hora.');
	END IF;
END;
/

---------------------------------------------------------------
--Triggers para probar los paquetes
--Trigger para la auditoria
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CLAS_PROG
AFTER UPDATE OR DELETE ON CLASES_PROGRAMADAS
FOR EACH ROW
BEGIN
  IF UPDATING THEN
    PKG_CLASES_PROGRAMADAS.procedure_auditoria_clases_prog('CLASES_PROGRAMADAS', 'UPDATE', :NEW.CODIGO_CLASE_PROGRAMADA);
  ELSIF DELETING THEN
    PKG_CLASES_PROGRAMADAS.procedure_auditoria_clases_prog('CLASES_PROGRAMADAS', 'DELETE', :OLD.CODIGO_CLASE_PROGRAMADA);
  END IF;
END;
/

--Trigger para probar la funcion comprobar cupos
CREATE OR REPLACE TRIGGER TRG_INCREMENTAR_CUPO
AFTER INSERT ON CLASES_PROGRAMADAS
FOR EACH ROW
DECLARE
  total_resultados INTEGER;
BEGIN
  total_resultados := PKG_CLASES_PROGRAMADAS.function_comprobar_cupos(:NEW.FECHA_CLASE_PROGRAMADA,:NEW.HORA_CLASE_PROGRAMADA,:NEW.CODIGO_NIVEL,:NEW.CODIGO_SALON);
  IF total_resultados = 0 THEN
    INSERT INTO CUPOS (CODIGO_CUPO, FECHA_CUPO, CODIGO_HORA, CODIGO_NIVEL, CODIGO_SALON, ESTUDIANTES_REGISTRADOS)
    VALUES (SEQ_CUPOS.NEXTVAL,:NEW.FECHA_CLASE_PROGRAMADA,:NEW.HORA_CLASE_PROGRAMADA,:NEW.CODIGO_NIVEL,:NEW.CODIGO_SALON, 1);
  END IF;
  IF total_resultados = 1 THEN
  -- Actualizar el contador de estudiantes registrados en la tabla CUPOS
    UPDATE CUPOS
    SET ESTUDIANTES_REGISTRADOS = ESTUDIANTES_REGISTRADOS + 1
    WHERE FECHA_CUPO = :NEW.FECHA_CLASE_PROGRAMADA
      AND CODIGO_HORA = :NEW.HORA_CLASE_PROGRAMADA
      AND CODIGO_NIVEL = :NEW.CODIGO_NIVEL
      AND CODIGO_SALON = :NEW.CODIGO_SALON;
  END IF;
  PKG_CLASES_PROGRAMADAS.procedure_auditoria_clases_prog('CLASES_PROGRAMADAS', 'INSERT', :NEW.CODIGO_CLASE_PROGRAMADA);
	-- Validar que la actualizaci�n afect� exactamente un registro
	IF SQL%ROWCOUNT = 0 THEN
    	RAISE_APPLICATION_ERROR(
        	-20002,
        	'No se encontr� un cupo correspondiente para la clase programada.'
    	);
	END IF;
END;
/

--Trigger para la funcion calcular promedio
CREATE OR REPLACE TRIGGER TRG_CALCULAR_NOTA_FINAL
BEFORE INSERT OR UPDATE ON NOTAS
FOR EACH ROW
DECLARE
	v_promedio NUMBER(5, 2);
BEGIN
	-- Verificar si ambas notas est�n presentes
	IF :NEW.NOTA_EXAMEN_ORAL IS NOT NULL AND :NEW.NOTA_EXAMEN_ESCRITO IS NOT NULL THEN
    	-- Calcular el promedio
    	v_promedio := PKG_ACADEMIA.function_calcular_promedio(:NEW.NOTA_EXAMEN_ORAL, :NEW.NOTA_EXAMEN_ESCRITO);
    	-- Actualizar el estado seg�n el promedio
    	IF v_promedio >= 4.0 THEN
        	:NEW.ESTADO := 1; -- Asigna el valor directamente a :NEW
          :NEW.PROMEDIO := v_promedio;
    	ELSE
        	:NEW.ESTADO := 2; -- Asigna el valor directamente a :NEW
          :NEW.PROMEDIO := v_promedio;
    	END IF;
	END IF; -- Si no hay notas, no hace nada
END;
/