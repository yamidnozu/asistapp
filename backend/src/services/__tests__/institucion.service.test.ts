import { prisma } from '../../../src/config/database';
import InstitucionService from '../institucion.service';

describe('InstitucionService fallback behavior', () => {
  it('getInstitutionById should use admin user contact as fallback', async () => {
    // Mock data: institute missing email/telefono
    const mockInstitution: any = {
      id: 'inst-1',
      nombre: 'Institucion Test',
      direccion: null,
      telefono: null,
      email: null,
      activa: true,
      createdAt: new Date(),
      updatedAt: new Date(),
      usuarioInstituciones: [
        { usuario: { id: 'admin-1', email: 'fallback@admin.com', telefono: '+123456789' } },
      ],
    };

    jest.spyOn(prisma.institucion, 'findUnique' as any).mockResolvedValue(mockInstitution);

    const result = await InstitucionService.getInstitutionById('inst-1');
    expect(result).not.toBeNull();
    expect(result?.email).toBe('fallback@admin.com');
    expect(result?.telefono).toBe('+123456789');
  });

  it('getAllInstitutions should use admin contact as fallback in list', async () => {
    const mockResult = {
      count: 1,
      institutions: [
        {
          id: 'inst-2',
          nombre: 'Lista Institucion',
          direccion: null,
          telefono: null,
          email: null,
          activa: true,
          createdAt: new Date(),
          updatedAt: new Date(),
          usuarioInstituciones: [
            { usuario: { id: 'admin-2', email: 'admin-list@fallback.com', telefono: '+987654321' } },
          ],
        },
      ],
      pagination: { page: 1, limit: 10, total: 1, totalPages: 1, hasNext: false, hasPrev: false },
    } as any;

    // Mock prisma.institucion.findMany and count
    jest.spyOn(prisma.institucion, 'findMany' as any).mockResolvedValue([mockResult.institutions[0]]);
    jest.spyOn(prisma.institucion, 'count' as any).mockResolvedValue(1 as any);

    const result = await InstitucionService.getAllInstitutions({ page: 1, limit: 10 }, {});
    expect(result.data[0].email).toBe('admin-list@fallback.com');
    expect(result.data[0].telefono).toBe('+987654321');
  });
});
