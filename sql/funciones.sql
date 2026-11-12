/*
1) Codifica una función almacenada denominada total_cost_patient que calcule y devuelva el 
   coste total acumulado de todos los procedimientos médicos registrados en la tabla undergoes 
   que un paciente, pasado como parámetro, haya recibido.
*/
DELIMITER // 
DROP FUNCTION IF EXISTS total_cost_patient // 

CREATE FUNCTION total_cost_patient(p_ssn INT) RETURNS INT DETERMINISTIC READS SQL DATA 
BEGIN 
    DECLARE v_total_cost INT DEFAULT 0; 
    SELECT IFNULL(SUM(mp.cost), 0) INTO v_total_cost 
    FROM undergoes u 
    JOIN medical_procedure mp ON u.procedureid = mp.code 
    WHERE u.patientid = p_ssn; 
    RETURN v_total_cost; 
END //
DELIMITER ;

-- Prueba Función L
SELECT ssn, name, total_cost_patient(ssn) AS 'Gasto Total' FROM patient ORDER BY `Gasto Total` DESC LIMIT 1;


/*
2) Codifica una función almacenada denominada calc_stay_cost que calcule y devuelva el 
   coste total de una estancia pasada como parámetro.
*/
DELIMITER // 
DROP FUNCTION IF EXISTS calc_stay_cost // 

CREATE FUNCTION calc_stay_cost(p_stayid INT) RETURNS INT DETERMINISTIC READS SQL DATA 
BEGIN 
    DECLARE v_days INT; 
    DECLARE v_rate INT; 
    DECLARE v_room_type VARCHAR(20); 
    
    SELECT r.roomtype, DATEDIFF(STR_TO_DATE(s.end_time, '%d/%m/%Y'), STR_TO_DATE(s.start_time, '%d/%m/%Y')) 
    INTO v_room_type, v_days 
    FROM stay s 
    JOIN room r ON s.roomid = r.roomnumber 
    WHERE s.stayid = p_stayid; 
    
    IF v_room_type = 'ICU' THEN SET v_rate = 500; 
    ELSEIF v_room_type = 'Single' THEN SET v_rate = 300; 
    ELSEIF v_room_type = 'Double' THEN SET v_rate = 150; 
    ELSE SET v_rate = 100; 
    END IF; 
    
    IF v_days <= 0 THEN SET v_days = 1; END IF; 
    
    RETURN v_days * v_rate; 
END //
DELIMITER ;

-- Prueba Función M
SELECT stayid, calc_stay_cost(stayid) AS 'Coste Estancia' FROM stay LIMIT 10;