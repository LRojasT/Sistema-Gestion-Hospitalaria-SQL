/*
Consulta 1: Obtener el nombres de los doctores, los medicamentos y la 
fecha de prescripción de los mismos de aquellos doctores que están afiliados al departamento 
de “General Medicine” y que han recetado algún medicamento en el año 2023 ó 2024.
*/ 
SELECT DISTINCT 
    p.name AS 'Nombre Doctor', 
    m.name AS 'Medicamento', 
    pr.date AS 'Fecha Prescripcion'
FROM physician p
INNER JOIN affiliated_with aw ON p.employeeid = aw.physicianid
INNER JOIN department d ON aw.departmentid = d.departmentid
INNER JOIN prescribes pr ON p.employeeid = pr.physicianid
INNER JOIN medication m ON pr.medicationid = m.code
WHERE d.name = 'General Medicine'
  AND STR_TO_DATE(pr.date, '%d/%m/%Y') BETWEEN '2023-01-01' AND '2024-12-31';

/*
Consulta 2: Obtener el nombre del paciente con el ingreso más largo y el 
paciente con el ingreso más corto en el hospital, mostrando para cada uno su nombre, el 
número de habitación donde estuvo ingresado, así como el piso y bloque de la misma, la 
duración de la estancia en días y el tipo de estancia (más largo o más corto).
*/
SELECT
    pa.name AS patient_name,
    r.roomnumber AS room_number,
    r.blockfloorid AS block_floor,
    r.blockcodeid AS block_code,
    DATEDIFF(STR_TO_DATE(s.end_time, '%d/%m/%Y'), STR_TO_DATE(s.start_time, '%d/%m/%Y')) AS stay_time,
    'longest' AS stay_type
FROM patient pa
INNER JOIN stay s ON pa.ssn = s.patientid
INNER JOIN room r ON s.roomid = r.roomnumber
WHERE
    DATEDIFF(STR_TO_DATE(s.end_time, '%d/%m/%Y'), STR_TO_DATE(s.start_time, '%d/%m/%Y')) = 
    (SELECT MAX(DATEDIFF(STR_TO_DATE(end_time, '%d/%m/%Y'), STR_TO_DATE(start_time, '%d/%m/%Y')))
        FROM stay
    )

UNION ALL

SELECT
    pa.name AS patient_name,
    r.roomnumber AS room_number,
    r.blockfloorid AS block_floor,
    r.blockcodeid AS block_code,
    DATEDIFF(STR_TO_DATE(s.end_time, '%d/%m/%Y'), STR_TO_DATE(s.start_time, '%d/%m/%Y')) AS stay_time,
    'shortest' AS stay_type
FROM
    patient pa
INNER JOIN stay s ON pa.ssn = s.patientid
INNER JOIN room r ON s.roomid = r.roomnumber
WHERE
    DATEDIFF(STR_TO_DATE(s.end_time, '%d/%m/%Y'), STR_TO_DATE(s.start_time, '%d/%m/%Y')) = 
    (
        SELECT MIN(DATEDIFF(STR_TO_DATE(end_time, '%d/%m/%Y'), STR_TO_DATE(start_time, '%d/%m/%Y')))
        FROM stay);

/*
Consulta 3: Actualizar la descripción de los medicamentos agregando la 
nota de “Possible discontinuation” (posible descatalogación) a aquellos que no han sido 
recetados durante los últimos dos años por doctores pertenecientes al departamento de 
“General Medicine”, evitando además incluir aquellos que ya contengan dicha advertencia 
en su descripción actual.
*/
UPDATE medication m
SET m.description = CONCAT(m.description, ' - Possible discontinuation')
WHERE m.description NOT LIKE '%Possible discontinuation%'
AND m.code NOT IN (
    SELECT pr.medicationid
    FROM prescribes pr
    JOIN physician p ON pr.physicianid = p.employeeid
    JOIN affiliated_with aw ON p.employeeid = aw.physicianid
    JOIN department d ON aw.departmentid = d.departmentid
    WHERE d.name = 'General Medicine'
    AND STR_TO_DATE(pr.date, '%d/%m/%Y') >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
);

/*
Consulta 4: Obtener un listado detallado de los doctores del hospital, 
mostrando para cada uno su nombre, el número total de procedimientos realizados, el coste 
total de dichos procedimientos y el coste promedio por procedimiento. Los resultados deben 
estar ordenados de mayor a menor según el número de procedimientos realizados.
*/
SELECT 
    doc.name AS 'Nombre Doctor',
    COUNT(u.procedureid) AS 'Num Procedimientos',
    IFNULL(SUM(mp.cost), 0) AS 'Coste Total',
    IFNULL(AVG(mp.cost), 0) AS 'Coste Promedio'
FROM physician doc
LEFT JOIN undergoes u ON doc.employeeid = u.physicianid
LEFT JOIN medical_procedure mp ON u.procedureid = mp.code
GROUP BY doc.employeeid, doc.name
ORDER BY `Num Procedimientos` DESC;

/*
Consulta 5: Obtener los doctores (nombre y posición) que han realizado 
todos los procedimientos médicos con coste superior a 5000 y que haya realizado más de 3 
procedimientos médicos de cualquiera de los tipos en total.
*/
SELECT p.name AS 'Nombre Doctor', p.position AS 'Cargo'
FROM physician p
JOIN undergoes u_count ON p.employeeid = u_count.physicianid
GROUP BY p.employeeid, p.name, p.position
HAVING COUNT(u_count.procedureid) > 3 
AND NOT EXISTS (
    SELECT mp.code
    FROM medical_procedure mp
    WHERE mp.cost > 5000
    AND mp.code NOT IN (
        SELECT u.procedureid
        FROM undergoes u
        WHERE u.physicianid = p.employeeid
    )
);

/*
Consulta 6: Obtener el personal de enfermería que siempre han estado 
asignadas a turnos en el mismo sitio (bloque y piso) y que además, si han participado en 
procedimientos médicos, siempre haya sido con el mismo doctores.
*/
SELECT n.name AS 'Nombre Enfermero'
FROM nurse n
JOIN on_call oc ON n.employeeid = oc.nurseid
LEFT JOIN undergoes u ON n.employeeid = u.assistingnurseid
GROUP BY n.employeeid, n.name
HAVING 
    COUNT(DISTINCT CONCAT(oc.blockfloorid, '-', oc.blockcodeid)) = 1
    AND
    COUNT(DISTINCT u.physicianid) <= 1;

/*Consulta 7: Obtener para cada medicamento (código y nombre) el número 
total de veces que ha sido prescrito, el nombre del doctor que más lo ha recetado (si existen 
empates mostrar todos los doctores empatados), y la dosis promedio recetada. Ordenar los 
resultados de mayor a menor según el número total de prescripciones.
*/
SELECT 
	m.code, 
	m.name,
    (SELECT COUNT(*) FROM prescribes WHERE medicationid = m.code) AS total_times_prescribed,
    (SELECT AVG(dose) FROM prescribes WHERE medicationid = m.code) AS avg_dose,
    p.name AS doctor_name
FROM medication m
	INNER JOIN prescribes pr ON m.code = pr.medicationid
	INNER JOIN physician p ON pr.physicianid = p.employeeid
GROUP BY m.code, m.name, p.employeeid, p.name
HAVING (m.code, COUNT(*)) IN (
        SELECT medicationid, MAX(conteos_por_doc)
        FROM (
            SELECT medicationid, physicianid, COUNT(*) as conteos_por_doc
            FROM prescribes
            GROUP BY medicationid, physicianid
        ) R
        GROUP BY medicationid
    )
ORDER BY total_times_prescribed DESC;

/*Consulta 8: Obtener el nombre de los medicamentos que han sido prescritos 
por todos los doctores pertenecientes a más de un departamento diferente.
*/
SELECT m.name AS 'Nombre Medicamento'
FROM medication m
JOIN prescribes pr ON m.code = pr.medicationid
WHERE pr.physicianid IN (
    SELECT physicianid
    FROM affiliated_with
    GROUP BY physicianid
    HAVING COUNT(departmentid) > 1
)
GROUP BY m.code, m.name
HAVING COUNT(DISTINCT pr.physicianid) = (
    SELECT COUNT(*) FROM (
        SELECT physicianid
        FROM affiliated_with
        GROUP BY physicianid
        HAVING COUNT(departmentid) > 1
    ) AS total_target_docs
);