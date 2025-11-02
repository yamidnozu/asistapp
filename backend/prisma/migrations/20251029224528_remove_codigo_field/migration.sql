/*
  Warnings:

  - You are about to drop the column `codigo` on the `instituciones` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "instituciones_codigo_key";

-- AlterTable
ALTER TABLE "instituciones" DROP COLUMN "codigo";
