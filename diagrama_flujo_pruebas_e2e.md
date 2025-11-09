```mermaid
flowchart TD
    A[🚀 Inicio de Tests E2E] --> B[Configurar IntegrationTestWidgetsFlutterBinding]
    B --> C[Limpiar Estado de Autenticación]

    C --> D[🔐 AUTENTICACIÓN - Flujos Completos]
    D --> D1[Login Super Admin]
    D --> D2[Login Admin Institución]
    D --> D3[Login Admin Multi-institución]
    D --> D4[Login con credenciales inválidas]
    D --> D5[Login con campos vacíos]

    D1 --> E[🏛️ SUPER ADMIN - Flujos Completos]
    E --> E1[CRUD Instituciones]
    E --> E2[Navegación Completa]

    D2 --> F[👨‍💼 ADMIN INSTITUCIÓN - Flujos Completos]
    F --> F1[CRUD Usuarios]
    F --> F2[Gestión Académica]

    D --> G[🧭 NAVEGACIÓN - Flujos Completos]
    G --> G1[Estados de Carga y Transiciones]
    G --> G2[Manejo de Errores de Ruta]
    G --> G3[Navegación Entre Módulos]

    G --> H[✅ VALIDACIÓN - Flujos Completos]
    H --> H1[Campos Vacíos]
    H --> H2[Formatos de Email]

    H --> I[🚨 ERROR HANDLING - Flujos Completos]
    I --> I1[Pérdida de Conexión]
    I --> I2[Operaciones sin Permisos]

    I --> J[⚡ PERFORMANCE - Flujos Completos]
    J --> J1[Tiempos de Respuesta]

    J --> K[📚 ACADÉMICOS - Flujos End-to-End]
    K --> K1[Gestión de Materias]
    K --> K2[Gestión de Grupos]
    K --> K3[Gestión de Horarios]
    K --> K4[Navegación Entre Módulos Académicos]

    K --> L[📱 ASISTENCIA - Flujos End-to-End]
    L --> L1[Sistema QR]
    L --> L2[Registro de Asistencia]

    L --> M[👤 DASHBOARDS POR ROL - Flujos End-to-End]
    M --> M1[Dashboard Super Admin]
    M --> M2[Dashboard Admin Institución]
    M --> M3[Dashboard Profesor]
    M --> M4[Dashboard Estudiante]

    M --> N[🎯 FUNCIONALIDADES ESPECÍFICAS - Flujos End-to-End]
    N --> N1[Funcionalidades Estudiantes]
    N --> N2[Funcionalidades Profesores]
    N --> N3[Integración Académica Completa]

    N --> O[🔄 INTEGRACIÓN COMPLETA - Flujos End-to-End]
    O --> O1[Flujo Nuevo Usuario]
    O --> O2[Recuperación de Errores]

    O1 --> P[Logout]
    O2 --> P
    N3 --> P
    N2 --> P
    N1 --> P
    M4 --> P
    M3 --> P
    M2 --> P
    M1 --> P
    L2 --> P
    L1 --> P
    K4 --> P
    K3 --> P
    K2 --> P
    K1 --> P
    J1 --> P
    I2 --> P
    I1 --> P
    H2 --> P
    H1 --> P
    G3 --> P
    G2 --> P
    G1 --> P
    F2 --> P
    F1 --> P
    E2 --> P
    E1 --> P
    D5 --> P
    D4 --> P
    D3 --> P

    P --> Q[✅ Verificación de Resultados]
    Q --> R[Finalización de Tests]

    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style D fill:#e8f5e8
    style E fill:#fce4ec
    style F fill:#f1f8e9
    style G fill:#e0f2f1
    style H fill:#fff8e1
    style I fill:#ffebee
    style J fill:#f3e5f5
    style K fill:#e8eaf6
    style L fill:#f3e5f5
    style M fill:#e0f7fa
    style N fill:#f9fbe7
    style O fill:#fce4ec
    style P fill:#e8f5e8
    style Q fill:#c8e6c9
    style R fill:#4caf50,color:#fff
```</content>
<parameter name="filePath">c:\Proyectos\DemoLife\diagrama_flujo_pruebas_e2e.md