DROP PROCEDURE controlador_clases;
CREATE OR REPLACE PROCEDURE controlador_clases (
    p_fecha DATE,
    p_hora NUMBER,
    p_dni VARCHAR2
) AS
    v_cod_clase_prog NUMBER;
    v_cupos_registrados NUMBER;
    v_salon_code NUMBER;
    v_profesor_dni VARCHAR2(50);
BEGIN
    -- Check for existing classes at the given date and time
    FOR clase_rec IN (
        SELECT COD_CLASE_PROG, CUPOS_REGISTRADOS
        FROM CLASES_PROGRAMADAS
        WHERE FECHA = p_fecha
          AND COD_HORA = p_hora
    ) LOOP
        IF clase_rec.CUPOS_REGISTRADOS < 6 THEN
            -- Update the existing class with available spots
            v_cod_clase_prog := clase_rec.COD_CLASE_PROG;
            v_cupos_registrados := clase_rec.CUPOS_REGISTRADOS + 1;

            -- Update the class with the incremented number of registered spots
            UPDATE CLASES_PROGRAMADAS
            SET CUPOS_REGISTRADOS = v_cupos_registrados
            WHERE COD_CLASE_PROG = v_cod_clase_prog;

            -- Add the student to the class
            agregar_estudiante_clase(v_cod_clase_prog, p_dni);

            -- Log the update action in the audit table
            log_audit_action('CLASES_PROGRAMADAS', 'UPDATE', v_cod_clase_prog, 'Added student ' || p_dni);
            RETURN;  -- Exit after successfully adding the student
        END IF;
    END LOOP;

    -- If no existing class with available spots was found, create a new class
    v_cod_clase_prog := CLASES_PROGRAMADAS_SEQ.NEXTVAL;

    -- Get a random available salon using the `default_salon_code` function
    v_salon_code := default_salon_code(p_fecha, p_hora);
    IF v_salon_code IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'No available salons for the specified date and time.');
    END IF;

    -- Get a random available professor using the `default_professor` function
    v_profesor_dni := default_professor(p_fecha, p_hora);
    IF v_profesor_dni IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'No available professors for the specified date and time.');
    END IF;

    -- Insert the new class with the assigned salon and professor
    INSERT INTO CLASES_PROGRAMADAS (
        COD_CLASE_PROG, COD_NIVEL, FECHA, COD_HORA, COD_SALON, CUPOS_REGISTRADOS, PROFESOR
    ) VALUES (
        v_cod_clase_prog,
        1,                 -- Assuming COD_NIVEL is 1; adjust if necessary
        p_fecha,
        p_hora,
        TO_NUMBER(v_salon_code),
        1,                 -- Starting with 1 student registered
        v_profesor_dni
    );

    -- Add the student to the new class
    agregar_estudiante_clase(v_cod_clase_prog, p_dni);

    -- Log the insert action in the audit table
    log_audit_action('CLASES_PROGRAMADAS', 'INSERT', v_cod_clase_prog, 'Created new class and added student ' || p_dni);
    
    COMMIT;
END controlador_clases;
/