import java.sql.*;
import java.io.*;

public class HospitalCSV {
    private static final String URL = "jdbc:mysql://localhost:3306/hospital_management_system?serverTimezone=UTC";
    private static final String USER = "gestor_informes";
    private static final String PASS = "HospitalPass2025!";

    public static void main(String[] args) {
        int patientSSN = 100000001;
        System.out.println("--- Iniciando Exportación CSV ---");
        generarCSV(patientSSN);
    }

    public static void generarCSV(int patientSSN) {
        String query = "SELECT Codigo_Medicamento, Nombre_Medicamento, Marca, Fecha_Prescripcion, Nombre_Doctor FROM PrescriptionView WHERE Patient_SSN = ?";
        String fileName = "paciente_" + patientSSN + ".csv";

        try (Connection conn = DriverManager.getConnection(URL, USER, PASS);
             PreparedStatement stmt = conn.prepareStatement(query)) {

            stmt.setInt(1, patientSSN);

            try (ResultSet rs = stmt.executeQuery();
                 PrintWriter pw = new PrintWriter(new FileWriter(fileName))) {

                pw.println("Codigo, Medicamento, Marca, Fecha, Doctor");
                int count = 0;

                while (rs.next()) {
                    pw.println(
                        rs.getInt("Codigo_Medicamento") + "," +
                        rs.getString("Nombre_Medicamento") + "," +
                        rs.getString("Marca") + "," +
                        rs.getString("Fecha_Prescripcion") + "," +
                        rs.getString("Nombre_Doctor")
                    );
                    count++;
                }
                System.out.println("Exito: Se han exportado " + count + " registros a '" + fileName + "'");
            }
        } catch (SQLException | IOException e) {
            e.printStackTrace();
            System.err.println("Error durante la generación del CSV.");
        }
    }
}
