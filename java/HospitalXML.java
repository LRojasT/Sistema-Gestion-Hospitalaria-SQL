import java.sql.*;
import java.io.*;

public class HospitalXML {
    private static final String URL = "jdbc:mysql://localhost:3306/hospital_management_system?serverTimezone=UTC";
    private static final String USER = "gestor_informes";
    private static final String PASS = "HospitalPass2025!";

    public static void main(String[] args) {
        int patientSSN = 100000001;
        System.out.println("--- Iniciando Exportación XML ---");
        generarXML(patientSSN);
    }

    public static void generarXML(int patientSSN) {
        String query = "SELECT Codigo_Medicamento, Nombre_Medicamento, Marca, Fecha_Prescripcion, Nombre_Doctor FROM PrescriptionView WHERE Patient_SSN = ?";
        String fileName = "paciente_" + patientSSN + ".xml";

        try (Connection conn = DriverManager.getConnection(URL, USER, PASS);
             PreparedStatement stmt = conn.prepareStatement(query)) {

            stmt.setInt(1, patientSSN);

            try (ResultSet rs = stmt.executeQuery();
                 PrintWriter pw = new PrintWriter(new FileWriter(fileName))) {

                pw.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
                pw.println("<Prescriptions patientSSN=\"" + patientSSN + "\">");
                
                int count = 0;
                while (rs.next()) {
                    pw.println("\t<Prescription>");
                    pw.println("\t\t<Code>" + rs.getInt("Codigo_Medicamento") + "</Code>");
                    pw.println("\t\t<Medicine>" + rs.getString("Nombre_Medicamento") + "</Medicine>");
                    pw.println("\t\t<Brand>" + rs.getString("Marca") + "</Brand>");
                    pw.println("\t\t<Date>" + rs.getString("Fecha_Prescripcion") + "</Date>");
                    pw.println("\t\t<Doctor>" + rs.getString("Nombre_Doctor") + "</Doctor>");
                    pw.println("\t</Prescription>");
                    count++;
                }
                pw.println("</Prescriptions>");
                System.out.println("Exito: Se han exportado " + count + " registros a '" + fileName + "'");
            }
        } catch (SQLException | IOException e) {
            e.printStackTrace();
            System.err.println("Error durante la generación del XML.");
        }
    }
}