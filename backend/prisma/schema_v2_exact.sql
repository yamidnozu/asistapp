-- ============================================
-- AsistApp V2 - PostgreSQL Schema (MVP)
-- Versión: 2.0.0
-- Fecha: 23 de Octubre 2025
-- Descripción: Esquema minimalista para MVP
-- ============================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TABLAS PRINCIPALES
-- ============================================

-- 1. INSTITUCIONES (Colegios)
CREATE TABLE instituciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(255) NOT NULL,
    codigo VARCHAR(50) UNIQUE NOT NULL, -- Código corto único (ej: "sanjose")
    direccion TEXT,
    telefono VARCHAR(20),
    email VARCHAR(255),
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. USUARIOS (Admins, Profesores, Estudiantes)
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institucion_id UUID REFERENCES instituciones(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombres VARCHAR(255) NOT NULL,
    apellidos VARCHAR(255) NOT NULL,
    rol VARCHAR(50) NOT NULL CHECK (rol IN ('super_admin', 'admin_institucion', 'profesor', 'estudiante')),
    telefono VARCHAR(20),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Un super_admin no tiene institución (es global)
    CONSTRAINT check_institucion_segun_rol CHECK (
        (rol = 'super_admin' AND institucion_id IS NULL) OR
        (rol != 'super_admin' AND institucion_id IS NOT NULL)
    )
);

-- 3. ESTUDIANTES (Info adicional de estudiantes)
CREATE TABLE estudiantes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    identificacion VARCHAR(50) UNIQUE NOT NULL, -- Documento de identidad
    codigo_qr VARCHAR(255) UNIQUE NOT NULL, -- Para escaneo
    nombre_responsable VARCHAR(255), -- Padre/Tutor
    telefono_responsable VARCHAR(20), -- WhatsApp del responsable
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. PERIODOS ACADÉMICOS (Años lectivos)
CREATE TABLE periodos_academicos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institucion_id UUID REFERENCES instituciones(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL, -- "2025", "2025-1", "2026"
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activo BOOLEAN DEFAULT true, -- Solo un periodo puede estar activo a la vez por institución
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Un solo periodo activo por institución (índice único parcial)
CREATE UNIQUE INDEX unique_periodo_activo ON periodos_academicos(institucion_id, activo) WHERE (activo = true);

-- 5. GRUPOS (Salones de clase)
CREATE TABLE grupos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institucion_id UUID REFERENCES instituciones(id) ON DELETE CASCADE,
    periodo_id UUID REFERENCES periodos_academicos(id) ON DELETE CASCADE,
    nombre VARCHAR(50) NOT NULL, -- "10-A", "11-B"
    grado VARCHAR(10) NOT NULL, -- "10", "11"
    seccion VARCHAR(10), -- "A", "B"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_grupo_por_periodo UNIQUE (institucion_id, periodo_id, nombre)
);

-- 6. MATERIAS (Asignaturas)
CREATE TABLE materias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institucion_id UUID REFERENCES instituciones(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL, -- "Matemáticas", "Español"
    codigo VARCHAR(50), -- "MAT101", "ESP201"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_materia_por_institucion UNIQUE (institucion_id, codigo)
);

-- 7. HORARIOS (Qué clase, cuándo, quién la dicta)
CREATE TABLE horarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institucion_id UUID REFERENCES instituciones(id) ON DELETE CASCADE,
    periodo_id UUID REFERENCES periodos_academicos(id) ON DELETE CASCADE,
    grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE,
    materia_id UUID REFERENCES materias(id) ON DELETE CASCADE,
    profesor_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    
    -- Días de la semana (1=Lunes, 7=Domingo)
    dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
    
    -- Hora de inicio y fin
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Evitar solapamiento: un profesor no puede dar 2 clases a la misma hora
    CONSTRAINT unique_profesor_horario UNIQUE (profesor_id, dia_semana, hora_inicio),
    
    -- Evitar solapamiento: un grupo no puede tener 2 clases a la misma hora
    CONSTRAINT unique_grupo_horario UNIQUE (grupo_id, dia_semana, hora_inicio)
);

-- 8. ESTUDIANTES_GRUPOS (Relación muchos a muchos)
CREATE TABLE estudiantes_grupos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estudiante_id UUID REFERENCES estudiantes(id) ON DELETE CASCADE,
    grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_estudiante_grupo UNIQUE (estudiante_id, grupo_id)
);

-- 9. ASISTENCIAS (Registro de asistencia por clase)
CREATE TABLE asistencias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estudiante_id UUID REFERENCES estudiantes(id) ON DELETE CASCADE,
    horario_id UUID REFERENCES horarios(id) ON DELETE CASCADE,
    profesor_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    
    -- Fecha y hora del registro
    fecha DATE NOT NULL,
    hora_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Tipo de registro
    tipo_registro VARCHAR(20) DEFAULT 'qr' CHECK (tipo_registro IN ('qr', 'manual')),
    
    -- Notas opcionales
    observaciones TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Un estudiante solo puede tener una asistencia por clase por día
    CONSTRAINT unique_asistencia_diaria UNIQUE (estudiante_id, horario_id, fecha)
);

-- 10. CONFIGURACIONES (Ajustes por institución)
CREATE TABLE configuraciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institucion_id UUID UNIQUE REFERENCES instituciones(id) ON DELETE CASCADE,
    
    -- Notificaciones WhatsApp
    notificaciones_activas BOOLEAN DEFAULT false,
    modo_notificacion VARCHAR(20) DEFAULT 'diaria' CHECK (modo_notificacion IN ('diaria', 'por_clase', 'umbral')),
    hora_notificacion TIME DEFAULT '18:00:00',
    umbral_faltas INTEGER DEFAULT 3, -- Para modo 'umbral'
    
    -- Configuración de horarios
    hora_inicio_clases TIME DEFAULT '07:00:00',
    hora_fin_clases TIME DEFAULT '15:00:00',
    
    -- Días laborales (JSON array: [1,2,3,4,5] = Lunes a Viernes)
    dias_laborales JSONB DEFAULT '[1,2,3,4,5]',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. LOGS_NOTIFICACIONES (Historial de notificaciones enviadas)
CREATE TABLE logs_notificaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estudiante_id UUID REFERENCES estudiantes(id) ON DELETE CASCADE,
    telefono_destino VARCHAR(20) NOT NULL,
    mensaje TEXT NOT NULL,
    fecha_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    exitoso BOOLEAN DEFAULT false,
    error_mensaje TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

-- Búsquedas frecuentes por institución
CREATE INDEX idx_usuarios_institucion ON usuarios(institucion_id);
CREATE INDEX idx_grupos_institucion ON grupos(institucion_id);
CREATE INDEX idx_materias_institucion ON materias(institucion_id);
CREATE INDEX idx_horarios_institucion ON horarios(institucion_id);

-- Búsquedas por periodo
CREATE INDEX idx_grupos_periodo ON grupos(periodo_id);
CREATE INDEX idx_horarios_periodo ON horarios(periodo_id);

-- Búsquedas de asistencia
CREATE INDEX idx_asistencias_fecha ON asistencias(fecha);
CREATE INDEX idx_asistencias_estudiante ON asistencias(estudiante_id);
CREATE INDEX idx_asistencias_horario ON asistencias(horario_id);
CREATE INDEX idx_asistencias_estudiante_fecha ON asistencias(estudiante_id, fecha);

-- Búsquedas de horarios por profesor
CREATE INDEX idx_horarios_profesor ON horarios(profesor_id);

-- Búsqueda de estudiante por QR
CREATE INDEX idx_estudiantes_qr ON estudiantes(codigo_qr);

-- Búsqueda de estudiante por identificación
CREATE INDEX idx_estudiantes_identificacion ON estudiantes(identificacion);

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a tablas relevantes
CREATE TRIGGER update_instituciones_updated_at BEFORE UPDATE ON instituciones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_estudiantes_updated_at BEFORE UPDATE ON estudiantes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_configuraciones_updated_at BEFORE UPDATE ON configuraciones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- DATOS DE EJEMPLO (SEED PARA DESARROLLO)
-- ============================================

-- Crear institución de prueba
INSERT INTO instituciones (nombre, codigo, direccion, email) VALUES
('Colegio San José', 'sanjose', 'Calle 123 #45-67', 'admin@sanjose.edu'),
('IE Francisco de Paula Santander', 'fps', 'Carrera 10 #20-30', 'admin@fps.edu');

-- Crear super admin
INSERT INTO usuarios (email, password_hash, nombres, apellidos, rol) VALUES
('superadmin@asistapp.com', crypt('Admin123!', gen_salt('bf')), 'Super', 'Admin', 'super_admin');

-- Crear admin de institución (usar ID real después de insertar)
-- INSERT INTO usuarios (institucion_id, email, password_hash, nombres, apellidos, rol) VALUES
-- ((SELECT id FROM instituciones WHERE codigo = 'sanjose'), 'admin@sanjose.edu', crypt('SanJose123!', gen_salt('bf')), 'María', 'González', 'admin_institucion');

-- ============================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ============================================

COMMENT ON TABLE instituciones IS 'Colegios o instituciones educativas registradas en la plataforma';
COMMENT ON TABLE usuarios IS 'Todos los usuarios del sistema (admins, profesores, estudiantes)';
COMMENT ON TABLE estudiantes IS 'Información adicional específica de estudiantes (QR, responsables)';
COMMENT ON TABLE periodos_academicos IS 'Años lectivos o periodos escolares';
COMMENT ON TABLE grupos IS 'Salones de clase (ej: 10-A, 11-B)';
COMMENT ON TABLE materias IS 'Asignaturas o materias disponibles';
COMMENT ON TABLE horarios IS 'Horarios de clase (qué materia, cuándo, quién la dicta)';
COMMENT ON TABLE estudiantes_grupos IS 'Relación de qué estudiantes pertenecen a qué grupos';
COMMENT ON TABLE asistencias IS 'Registro de asistencia por clase';
COMMENT ON TABLE configuraciones IS 'Configuraciones específicas por institución';
COMMENT ON TABLE logs_notificaciones IS 'Historial de notificaciones WhatsApp enviadas';

-- ============================================
-- CONSULTAS ÚTILES PARA DESARROLLO
-- ============================================

-- Ver todas las clases del día para un profesor
-- SELECT h.*, m.nombre as materia, g.nombre as grupo
-- FROM horarios h
-- JOIN materias m ON h.materia_id = m.id
-- JOIN grupos g ON h.grupo_id = g.id
-- WHERE h.profesor_id = 'UUID_DEL_PROFESOR'
-- AND h.dia_semana = EXTRACT(ISODOW FROM CURRENT_DATE);

-- Ver asistencia de un estudiante en una fecha
-- SELECT a.*, h.hora_inicio, m.nombre as materia
-- FROM asistencias a
-- JOIN horarios h ON a.horario_id = h.id
-- JOIN materias m ON h.materia_id = m.id
-- WHERE a.estudiante_id = 'UUID_ESTUDIANTE'
-- AND a.fecha = CURRENT_DATE;

-- Contar faltas de un estudiante en un periodo
-- SELECT COUNT(*) as faltas
-- FROM horarios h
-- LEFT JOIN asistencias a ON h.id = a.horario_id 
--     AND a.estudiante_id = 'UUID_ESTUDIANTE'
--     AND a.fecha = CURRENT_DATE
-- WHERE h.grupo_id IN (
--     SELECT grupo_id FROM estudiantes_grupos WHERE estudiante_id = 'UUID_ESTUDIANTE'
-- )
-- AND h.dia_semana = EXTRACT(ISODOW FROM CURRENT_DATE)
-- AND a.id IS NULL;

-- ============================================
-- FIN DEL SCHEMA
-- ============================================
