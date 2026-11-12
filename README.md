# 🏥 Sistema de Gestión Hospitalaria - Base de Datos Relacional

Este proyecto consiste en el diseño, modelado e implementación de una base de datos relacional robusta para soportar la operatividad y gestión de un centro hospitalario de alta complejidad.

El sistema permite gestionar desde la información del personal (médicos, enfermería, TIGAs, farmacéuticos) y pacientes, hasta la programación de consultas, prescripción de medicamentos, gestión de ingresos y procedimientos médicos, y la administración de laboratorios especializados.

## 📊 Arquitectura y Modelado de Datos
El diseño de la base de datos se ha realizado siguiendo una metodología rigurosa:

1. **Modelado Conceptual (Diagrama Entidad-Relación):** Identificación de entidades clave y sus interrelaciones.
2. **Modelo Relacional (Paso a Tablas):** Traducción del modelo E-R a un esquema relacional normalizado.
3. **Definición de Dominios y Semántica No Contemplada:** Documentación de restricciones de negocio complejas que no pueden representarse gráficamente en el modelo E-R (ej. validación temporal de certificaciones médicas, gestión de disponibilidad y aforos).

## 💻 Implementación Técnica (SQL & Java)
El repositorio incluye el código modularizado utilizado para la manipulación de la base de datos y la exportación de información:

* **Consultas SQL Complejas:** Extracción de datos cruzando múltiples tablas (JOINs), agrupaciones, subconsultas y funciones de agregación.
* **Triggers (Disparadores):** Implementación de reglas de negocio para asegurar la integridad de los datos. 
  * Validación temporal de certificaciones médicas antes de intervenciones.
  * Restricción de borrado de pacientes con citas futuras o historial médico activo en los últimos 3 años.
* **Funciones y Procedimientos Almacenados:** 
  * Funciones para el cálculo automático de costes de estancias hospitalarias y coste total de procedimientos por paciente.
  * Procedimientos para la generación de reportes médicos detallados.
* **Vistas y Control de Acceso:** Creación de vistas consolidadas para la exportación de datos y asignación de permisos a usuarios.
* **Integración con Java:** Desarrollo de módulos en Java (JDBC) para la exportación de prescripciones médicas a formatos estructurados (CSV y XML).

## 📂 Contenido del Repositorio
El código y la documentación se encuentran organizados de la siguiente manera:

* `/sql`: Scripts de la base de datos divididos por funcionalidad:
  * `consultas.sql`
  * `triggers.sql`
  * `funciones.sql`
  * `procedimientos.sql`
  * `vistas_y_usuarios.sql`
* `/java`: Código fuente de las herramientas de exportación de datos (`HospitalCSV.java` y `HospitalXML.java`).
* `/docs`: Diagrama Entidad-Relación, esquema relacional y documentación técnica de restricciones.

---
*Proyecto desarrollado en la Universidad Politécnica de Madrid (UPM).*
