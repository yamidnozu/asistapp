-- CreateTable
CREATE TABLE "instituciones" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "nombre" TEXT NOT NULL,
    "codigo" TEXT NOT NULL,
    "direccion" TEXT,
    "telefono" TEXT,
    "email" TEXT,
    "activa" BOOLEAN NOT NULL DEFAULT true,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "usuario_instituciones" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "usuario_id" TEXT NOT NULL,
    "institucion_id" TEXT NOT NULL,
    "rol_en_institucion" TEXT,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "usuario_instituciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "usuario_instituciones_institucion_id_fkey" FOREIGN KEY ("institucion_id") REFERENCES "instituciones" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "nombres" TEXT NOT NULL,
    "apellidos" TEXT NOT NULL,
    "rol" TEXT NOT NULL,
    "telefono" TEXT,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "token_version" INTEGER NOT NULL DEFAULT 1,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "estudiantes" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "usuario_id" TEXT NOT NULL,
    "identificacion" TEXT NOT NULL,
    "codigo_qr" TEXT NOT NULL,
    "nombre_responsable" TEXT,
    "telefono_responsable" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "estudiantes_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "periodos_academicos" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "institucion_id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "fecha_inicio" DATETIME NOT NULL,
    "fecha_fin" DATETIME NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "periodos_academicos_institucion_id_fkey" FOREIGN KEY ("institucion_id") REFERENCES "instituciones" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "grupos" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "institucion_id" TEXT NOT NULL,
    "periodo_id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "grado" TEXT NOT NULL,
    "seccion" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "grupos_institucion_id_fkey" FOREIGN KEY ("institucion_id") REFERENCES "instituciones" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "grupos_periodo_id_fkey" FOREIGN KEY ("periodo_id") REFERENCES "periodos_academicos" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "materias" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "institucion_id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "codigo" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "materias_institucion_id_fkey" FOREIGN KEY ("institucion_id") REFERENCES "instituciones" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "horarios" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "institucion_id" TEXT NOT NULL,
    "periodo_id" TEXT NOT NULL,
    "grupo_id" TEXT NOT NULL,
    "materia_id" TEXT NOT NULL,
    "profesor_id" TEXT,
    "diaSemana" INTEGER NOT NULL,
    "hora_inicio" TEXT NOT NULL,
    "hora_fin" TEXT NOT NULL,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "horarios_institucion_id_fkey" FOREIGN KEY ("institucion_id") REFERENCES "instituciones" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "horarios_periodo_id_fkey" FOREIGN KEY ("periodo_id") REFERENCES "periodos_academicos" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "horarios_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "horarios_materia_id_fkey" FOREIGN KEY ("materia_id") REFERENCES "materias" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "horarios_profesor_id_fkey" FOREIGN KEY ("profesor_id") REFERENCES "usuarios" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "estudiantes_grupos" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estudiante_id" TEXT NOT NULL,
    "grupo_id" TEXT NOT NULL,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "estudiantes_grupos_estudiante_id_fkey" FOREIGN KEY ("estudiante_id") REFERENCES "estudiantes" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "estudiantes_grupos_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "asistencias" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estudiante_id" TEXT NOT NULL,
    "horario_id" TEXT NOT NULL,
    "grupo_id" TEXT NOT NULL,
    "profesor_id" TEXT,
    "fecha" DATETIME NOT NULL,
    "hora_registro" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tipo_registro" TEXT NOT NULL DEFAULT 'qr',
    "observaciones" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "asistencias_estudiante_id_fkey" FOREIGN KEY ("estudiante_id") REFERENCES "estudiantes" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "asistencias_horario_id_fkey" FOREIGN KEY ("horario_id") REFERENCES "horarios" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "asistencias_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "asistencias_profesor_id_fkey" FOREIGN KEY ("profesor_id") REFERENCES "usuarios" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "configuraciones" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "institucion_id" TEXT NOT NULL,
    "notificaciones_activas" BOOLEAN NOT NULL DEFAULT false,
    "modo_notificacion" TEXT NOT NULL DEFAULT 'diaria',
    "hora_notificacion" TEXT NOT NULL DEFAULT '18:00:00',
    "umbral_faltas" INTEGER NOT NULL DEFAULT 3,
    "hora_inicio_clases" TEXT NOT NULL DEFAULT '07:00:00',
    "hora_fin_clases" TEXT NOT NULL DEFAULT '15:00:00',
    "dias_laborales" TEXT NOT NULL DEFAULT '[1,2,3,4,5]',
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "configuraciones_institucion_id_fkey" FOREIGN KEY ("institucion_id") REFERENCES "instituciones" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "logs_notificaciones" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estudiante_id" TEXT NOT NULL,
    "telefono_destino" TEXT NOT NULL,
    "mensaje" TEXT NOT NULL,
    "fecha_envio" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "exitoso" BOOLEAN NOT NULL DEFAULT false,
    "error_mensaje" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "logs_notificaciones_estudiante_id_fkey" FOREIGN KEY ("estudiante_id") REFERENCES "estudiantes" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "usuario_id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires_at" DATETIME NOT NULL,
    "revoked" BOOLEAN NOT NULL DEFAULT false,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "refresh_tokens_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "instituciones_codigo_key" ON "instituciones"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "usuario_instituciones_usuario_id_institucion_id_key" ON "usuario_instituciones"("usuario_id", "institucion_id");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE UNIQUE INDEX "estudiantes_usuario_id_key" ON "estudiantes"("usuario_id");

-- CreateIndex
CREATE UNIQUE INDEX "estudiantes_identificacion_key" ON "estudiantes"("identificacion");

-- CreateIndex
CREATE UNIQUE INDEX "estudiantes_codigo_qr_key" ON "estudiantes"("codigo_qr");

-- CreateIndex
CREATE UNIQUE INDEX "configuraciones_institucion_id_key" ON "configuraciones"("institucion_id");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");
