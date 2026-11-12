/*
1. Diseña una vista que permita consultar los medicamentos prescritos. La vista debe incluir el 
   código, nombre y marca del medicamento, el nombre del paciente, fecha y nombre del doctor.
*/
CREATE OR REPLACE VIEW PrescriptionView AS 
SELECT 
    m.code AS 'Codigo_Medicamento', 
    m.name AS 'Nombre_Medicamento', 
    m.brand AS 'Marca', 
    p.name AS 'Nombre_Paciente', 
    pr.date AS 'Fecha_Prescripcion', 
    phy.name AS 'Nombre_Doctor', 
    p.ssn AS 'Patient_SSN' 
FROM prescribes pr 
JOIN medication m ON pr.medicationid = m.code 
JOIN patient p ON pr.patientid = p.ssn 
JOIN physician phy ON pr.physicianid = phy.employeeid;