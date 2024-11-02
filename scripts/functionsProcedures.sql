--Funcion para comprobar cupos
CREATE OR REPLACE FUNCTION function_comprobar_cupos(
  p_fecha_cupo DATE,
  p_codigo_hora INTEGER,
  p_codigo_nivel INTEGER,
  p_codigo_salon INTEGER
) 
RETURN INTEGER
IS
  respuesta INTEGER := 0;
  CURSOR cupos_cursor IS
    SELECT COUNT(*)
    FROM cupos
    WHERE FECHA_CUPO = p_fecha_cupo
      AND CODIGO_HORA = p_codigo_hora
      AND CODIGO_NIVEL = p_codigo_nivel
      AND CODIGO_SALON = p_codigo_salon;
BEGIN
-- Abrir cursor
  OPEN cupos_cursor;

  -- Obtener datos del cursor
  FETCH cupos_cursor INTO respuesta;

  -- Cerrar cursor
  CLOSE cupos_cursor;

  RETURN respuesta;
END;
/

--Crear sequencia para cupos
DROP SEQUENCE SEQ_CUPOS;
CREATE SEQUENCE SEQ_CUPOS 
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

--Crear tabla y sequencia para auditoria
DROP TABLE AUDITORIAS_CLASES_PROG;
CREATE TABLE AUDITORIAS_CLASES_PROG (
  CODIGO_AUD INTEGER,
  NOMBRE_TABLA VARCHAR2(50),
  OPERACION VARCHAR2(20),
  ID_REGISTRO INTEGER,
  DESCRIPCION VARCHAR2(250),
  FECHA TIMESTAMP,
  CONSTRAINT PK_AUD_CLAS_PROG PRIMARY KEY (CODIGO_AUD)
);

DROP SEQUENCE SEQ_AUD_CLAS_PROG ;
CREATE SEQUENCE SEQ_AUD_CLAS_PROG 
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

--Procedure para la auditoria
CREATE OR REPLACE PROCEDURE procedure_auditoria_clases_prog(
  nombre_tabla VARCHAR2,
  operacion VARCHAR2,
  id_registro INTEGER
) 
IS
  descripcion VARCHAR2(50);
BEGIN
  -- Aqu� va la l�gica del procedimiento
  IF operacion = 'INSERT' THEN
    descripcion := 'Registro insertado';
  ELSIF operacion = 'UPDATE' THEN
    descripcion := 'Registro editado';
  ELSIF operacion = 'DELETE' THEN
    descripcion := 'Registro eliminado';
  END IF;
  INSERT INTO AUDITORIAS_CLASES_PROG VALUES (SEQ_AUD_CLAS_PROG.NEXTVAL, nombre_tabla, operacion, id_registro, descripcion, SYSTIMESTAMP);
END;
/

--Trigger para la auditoria
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CLAS_PROG
AFTER UPDATE OR DELETE ON CLASES_PROGRAMADAS
FOR EACH ROW
BEGIN
  IF UPDATING THEN
    procedure_auditoria_clases_prog('CLASES_PROGRAMADAS', 'UPDATE', :NEW.CODIGO_CLASE_PROGRAMADA);
  ELSIF DELETING THEN
    procedure_auditoria_clases_prog('CLASES_PROGRAMADAS', 'DELETE', :OLD.CODIGO_CLASE_PROGRAMADA);
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
  total_resultados := function_comprobar_cupos(:NEW.FECHA_CLASE_PROGRAMADA,:NEW.HORA_CLASE_PROGRAMADA,:NEW.CODIGO_NIVEL,:NEW.CODIGO_SALON);
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
  procedure_auditoria_clases_prog('CLASES_PROGRAMADAS', 'INSERT', :NEW.CODIGO_CLASE_PROGRAMADA);
	-- Validar que la actualizaci�n afect� exactamente un registro
	IF SQL%ROWCOUNT = 0 THEN
    	RAISE_APPLICATION_ERROR(
        	-20002,
        	'No se encontr� un cupo correspondiente para la clase programada.'
    	);
	END IF;
END;
/

-----------------------------------------------------------------------

--Funcion para calcular promedio
CREATE OR REPLACE FUNCTION function_calcular_promedio(
  nota_examen_oral NUMBER,
  nota_examen_escrito NUMBER
) 
RETURN NUMBER
IS
  sumarespuesta NUMBER(5, 2) := 0.0;
  respuesta NUMBER(5, 2) := 0.0;
BEGIN
  sumarespuesta := nota_examen_oral + nota_examen_escrito;
  respuesta := sumarespuesta / 2;
  RETURN respuesta;
END;
/

--Trigger para la funcion calcular promedio
CREATE OR REPLACE TRIGGER TRG_CALCULAR_NOTA_FINAL
BEFORE UPDATE ON NOTAS
FOR EACH ROW
DECLARE
	v_promedio NUMBER(5, 2);
BEGIN
	-- Verificar si ambas notas est�n presentes
	IF :NEW.NOTA_EXAMEN_ORAL IS NOT NULL AND :NEW.NOTA_EXAMEN_ESCRITO IS NOT NULL THEN
    	-- Calcular el promedio
    	v_promedio := function_calcular_promedio(:NEW.NOTA_EXAMEN_ORAL, :NEW.NOTA_EXAMEN_ESCRITO);
    	-- Actualizar el estado seg�n el promedio
    	IF v_promedio >= 4.0 THEN
        	:NEW.ESTADO := 1; -- Asigna el valor directamente a :NEW
    	ELSE
        	:NEW.ESTADO := 2; -- Asigna el valor directamente a :NEW
    	END IF;
	END IF; -- Si no hay notas, no hace nada
END;
/