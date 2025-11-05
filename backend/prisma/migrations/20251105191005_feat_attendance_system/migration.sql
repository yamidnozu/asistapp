/*
  Warnings:

  - You are about to drop the column `created_at` on the `asistencias` table. All the data in the column will be lost.
  - You are about to drop the column `grupo_id` on the `asistencias` table. All the data in the column will be lost.
  - You are about to drop the column `hora_registro` on the `asistencias` table. All the data in the column will be lost.
  - You are about to drop the column `observaciones` on the `asistencias` table. All the data in the column will be lost.
  - You are about to drop the column `tipo_registro` on the `asistencias` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[horario_id,estudiante_id,fecha]` on the table `asistencias` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `institucion_id` to the `asistencias` table without a default value. This is not possible if the table is not empty.
  - Made the column `profesor_id` on table `asistencias` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "public"."asistencias" DROP CONSTRAINT "asistencias_estudiante_id_fkey";

-- DropForeignKey
ALTER TABLE "public"."asistencias" DROP CONSTRAINT "asistencias_grupo_id_fkey";

-- DropForeignKey
ALTER TABLE "public"."asistencias" DROP CONSTRAINT "asistencias_horario_id_fkey";

-- DropForeignKey
ALTER TABLE "public"."asistencias" DROP CONSTRAINT "asistencias_profesor_id_fkey";

-- AlterTable
ALTER TABLE "asistencias" DROP COLUMN "created_at",
DROP COLUMN "grupo_id",
DROP COLUMN "hora_registro",
DROP COLUMN "observaciones",
DROP COLUMN "tipo_registro",
ADD COLUMN     "estado" TEXT NOT NULL DEFAULT 'PRESENTE',
ADD COLUMN     "institucion_id" UUID NOT NULL,
ALTER COLUMN "profesor_id" SET NOT NULL,
ALTER COLUMN "fecha" SET DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "fecha" SET DATA TYPE TIMESTAMP(3);

-- CreateIndex
CREATE UNIQUE INDEX "asistencias_horario_id_estudiante_id_fecha_key" ON "asistencias"("horario_id", "estudiante_id", "fecha");

-- AddForeignKey
ALTER TABLE "asistencias" ADD CONSTRAINT "asistencias_horario_id_fkey" FOREIGN KEY ("horario_id") REFERENCES "horarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asistencias" ADD CONSTRAINT "asistencias_estudiante_id_fkey" FOREIGN KEY ("estudiante_id") REFERENCES "estudiantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asistencias" ADD CONSTRAINT "asistencias_profesor_id_fkey" FOREIGN KEY ("profesor_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asistencias" ADD CONSTRAINT "asistencias_institucion_id_fkey" FOREIGN KEY ("institucion_id") REFERENCES "instituciones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
