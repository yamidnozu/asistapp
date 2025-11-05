INSERT INTO periodos_academicos (id, institucion_id, nombre, fecha_inicio, fecha_fin, activo, created_at)
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'ebccf67e-1f12-467f-9927-6fc4ec20289a', '2025', '2025-01-01', '2025-12-31', true, NOW())
ON CONFLICT DO NOTHING;