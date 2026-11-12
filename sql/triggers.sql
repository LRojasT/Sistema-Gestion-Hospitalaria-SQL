/*
1) Trigger que garantice que únicamente los doctores con la formación adecuada y 
   actualizada puedan programar nuevas intervenciones médicas para las que se han certificado. 
   Es decir, que el certificado sea valido para la fecha del procedimiento que va a realizar.
   Diferenciar mediante mensajes de error específicos entre ambos casos...
*/

DELIMITER // 
DROP TRIGGER IF EXISTS check_doctor_certification // 

CREATE TRIGGER check_doctor_certification 
BEFORE INSERT ON undergoes 
FOR EACH ROW 
BEGIN 
    DECLARE v_expiry_date DATE; 
    DECLARE v_is_trained INT DEFAULT 0; 
    DECLARE v_proc_date DATE; 
    
    SET v_proc_date = STR_TO_DATE(NEW.date, '%d/%m/%Y'); 
    
    SELECT COUNT(*), MAX(STR_TO_DATE(certificationexpires, '%d/%m/%Y')) 
    INTO v_is_trained, v_expiry_date 
    FROM trained_in 
    WHERE physicianid = NEW.physicianid 
      AND treatmentid = NEW.procedureid;
      
    IF v_is_trained = 0 THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El doctor no posee la certificación requerida para este procedimiento.'; 
    ELSEIF v_proc_date > v_expiry_date THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: La certificación del doctor se encuentra caducada para la fecha indicada.'; 
    END IF; 
END //
DELIMITER ;

-- PRUEBAS TRIGGER 1
INSERT INTO trained_in (physicianid, treatmentid, certificationdate, certificationexpires) VALUES (3, 1, '01/01/2020', '31/12/2025');
-- 1. Éxito
INSERT INTO undergoes (patientid, procedureid, stayid, date, physicianid, assistingnurseid) VALUES (100000001, 1, 3215, '15/06/2024', 3, 101);
-- 2. Error No Certificado
-- INSERT INTO undergoes (patientid, procedureid, stayid, date, physicianid, assistingnurseid) VALUES (100000001, 2, 3215, '15/06/2024', 3, 101);
-- 3. Error Caducado
-- INSERT INTO undergoes (patientid, procedureid, stayid, date, physicianid, assistingnurseid) VALUES (100000001, 1, 3215, '01/01/2026', 3, 101);


/*
2) Con el diseño actual de la base de datos, la política de gestión de borrados de pacientes no 
   permite llevar a cabo el borrado... generar sentencias SQL para permitir borrado...
   Posteriormente, codificar un trigger que impida la eliminación de pacientes que no cumplan 
   con las condiciones...
*/
ALTER TABLE appointments DROP FOREIGN KEY appointments_ibfk_1; 
ALTER TABLE appointments ADD CONSTRAINT fk_app_pat FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE; 

ALTER TABLE prescribes DROP FOREIGN KEY prescribes_ibfk_2; 
ALTER TABLE prescribes ADD CONSTRAINT fk_pres_pat FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE; 

ALTER TABLE stay DROP FOREIGN KEY stay_ibfk_1; 
ALTER TABLE stay ADD CONSTRAINT fk_stay_pat FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE; 

ALTER TABLE undergoes DROP FOREIGN KEY undergoes_ibfk_1; 
ALTER TABLE undergoes ADD CONSTRAINT fk_und_pat FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE; 

DELIMITER // 
DROP TRIGGER IF EXISTS prevent_patient_delete // 

CREATE TRIGGER prevent_patient_delete 
BEFORE DELETE ON patient 
FOR EACH ROW 
BEGIN 
    DECLARE v_future_appts INT DEFAULT 0; 
    DECLARE v_recent_activity INT DEFAULT 0; 
    DECLARE v_today DATE; 
    
    SET v_today = CURDATE(); 
    
    SELECT COUNT(*) INTO v_future_appts 
    FROM appointments 
    WHERE patientid = OLD.ssn 
      AND STR_TO_DATE(start_dt_time, '%d/%m/%Y') > v_today;
      
    IF v_future_appts > 0 THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede borrar al paciente porque tiene citas futuras programadas.'; 
    END IF; 
    
    SELECT (
        (SELECT COUNT(*) FROM stay WHERE patientid = OLD.ssn AND STR_TO_DATE(end_time, '%d/%m/%Y') >= DATE_SUB(v_today, INTERVAL 3 YEAR)) + 
        (SELECT COUNT(*) FROM undergoes WHERE patientid = OLD.ssn AND STR_TO_DATE(date, '%d/%m/%Y') >= DATE_SUB(v_today, INTERVAL 3 YEAR)) + 
        (SELECT COUNT(*) FROM prescribes WHERE patientid = OLD.ssn AND STR_TO_DATE(date, '%d/%m/%Y') >= DATE_SUB(v_today, INTERVAL 3 YEAR)) + 
        (SELECT COUNT(*) FROM appointments WHERE patientid = OLD.ssn AND STR_TO_DATE(start_dt_time, '%d/%m/%Y') >= DATE_SUB(v_today, INTERVAL 3 YEAR))
    ) INTO v_recent_activity;
    
    IF v_recent_activity > 0 THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede borrar al paciente por tener historial médico activo en los últimos 3 años.'; 
    END IF; 
END //
DELIMITER ;

-- PRUEBAS TRIGGER 2
-- Caso 1: Error (Citas futuras)
DELETE FROM appointments WHERE appointmentid = 9001; DELETE FROM patient WHERE ssn = 999999901; 
INSERT INTO patient (ssn, name, address, phonenum, insuranceid, pcpid) VALUES (999999901, 'Future Guy', 'Calle Test', '555-0001', 901, 1); 
INSERT INTO appointments (appointmentid, patientid, prepnurseid, physicianid, start_dt_time, end_dt_time, examinationroom) VALUES (9001, 999999901, 101, 1, '01/01/2030', '01/01/2030', 'A'); 
-- DELETE FROM patient WHERE ssn = 999999901; 

-- Caso 2: Error (Actividad reciente)
DELETE FROM stay WHERE stayid = 8001; DELETE FROM patient WHERE ssn = 999999902; 
INSERT INTO patient (ssn, name, address, phonenum, insuranceid, pcpid) VALUES (999999902, 'Recent Guy', 'Calle Test', '555-0002', 902, 1); 
INSERT INTO stay (stayid, patientid, roomid, start_time, end_time) VALUES (8001, 999999902, 101, '01/01/2025', '05/01/2025'); 
-- DELETE FROM patient WHERE ssn = 999999902; 

-- Caso 3: Éxito (Paciente antiguo)
DELETE FROM stay WHERE stayid = 8002; DELETE FROM patient WHERE ssn = 999999903; 
INSERT INTO patient (ssn, name, address, phonenum, insuranceid, pcpid) VALUES (999999903, 'Old Guy', 'Calle Test', '555-0003', 903, 1); 
INSERT INTO stay (stayid, patientid, roomid, start_time, end_time) VALUES (8002, 999999903, 101, '01/01/2000', '05/01/2000'); 
DELETE FROM patient WHERE ssn = 999999903; 
SELECT * FROM patient WHERE ssn = 999999903;