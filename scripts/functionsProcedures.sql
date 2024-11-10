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