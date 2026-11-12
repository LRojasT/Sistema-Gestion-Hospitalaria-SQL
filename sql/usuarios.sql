/*
1. Añade un usuario a la base de datos y dale permiso de lectura sobre la vista anteriormente creada.
*/
CREATE USER IF NOT EXISTS 'gestor_informes'@'localhost' IDENTIFIED BY 'HospitalPass2025!'; 
GRANT SELECT ON hospital_management_system.PrescriptionView TO 'gestor_informes'@'localhost';