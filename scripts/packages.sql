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

-- Especificaci�n del paquete
CREATE OR REPLACE PACKAGE PKG_ACADEMIA
AS
  FUNCTION function_calcular_promedio(
    nota_examen_oral NUMBER,
    nota_examen_escrito NUMBER
  ) RETURN NUMBER;
END PKG_ACADEMIA;
/

-- Cuerpo del paquete
CREATE OR REPLACE PACKAGE BODY PKG_ACADEMIA 
AS
  FUNCTION function_calcular_promedio(
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
  END function_calcular_promedio;  -- Nombre de la funci�n debe coincidir
END PKG_ACADEMIA;
/

-- Especificaci�n del paquete
CREATE OR REPLACE PACKAGE PKG_CLASES_PROGRAMADAS
AS
  PROCEDURE procedure_auditoria_clases_prog (
  nombre_tabla VARCHAR2,
  operacion VARCHAR2,
  id_registro INTEGER
  );
  FUNCTION function_comprobar_cupos(
    p_fecha_cupo DATE,
    p_codigo_hora INTEGER,
    p_codigo_nivel INTEGER,
    p_codigo_salon INTEGER
  ) RETURN NUMBER;
END PKG_CLASES_PROGRAMADAS;
/

-- Cuerpo del paquete
CREATE OR REPLACE PACKAGE BODY PKG_CLASES_PROGRAMADAS 
AS
  PROCEDURE procedure_auditoria_clases_prog (
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
  END procedure_auditoria_clases_prog;
  FUNCTION function_comprobar_cupos(
    p_fecha_cupo DATE,
    p_codigo_hora INTEGER,
    p_codigo_nivel INTEGER,
    p_codigo_salon INTEGER
  ) RETURN NUMBER
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
  END function_comprobar_cupos;
END PKG_CLASES_PROGRAMADAS;
/

