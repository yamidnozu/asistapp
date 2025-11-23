/**
 * Constantes para roles de usuario en AsistApp
 * Centraliza todos los roles del sistema para evitar strings mágicos
 */

export enum UserRole {
    SUPER_ADMIN = 'super_admin',
    ADMIN_INSTITUCION = 'admin_institucion',
    PROFESOR = 'profesor',
    ESTUDIANTE = 'estudiante',
}

/**
 * Verifica si un string es un rol válido
 */
export function isValidRole(role: string): role is UserRole {
    return Object.values(UserRole).includes(role as UserRole);
}

/**
 * Verifica si un rol tiene permisos de administración
 */
export function isAdminRole(role: UserRole): boolean {
    return role === UserRole.SUPER_ADMIN || role === UserRole.ADMIN_INSTITUCION;
}

/**
 * Verifica si un rol puede gestionar clases
 */
export function canManageClasses(role: UserRole): boolean {
    return isAdminRole(role) || role === UserRole.PROFESOR;
}

/**
 * Obtiene el nombre legible de un rol
 */
export function getRoleName(role: UserRole): string {
    const roleNames: Record<UserRole, string> = {
        [UserRole.SUPER_ADMIN]: 'Super Administrador',
        [UserRole.ADMIN_INSTITUCION]: 'Administrador de Institución',
        [UserRole.PROFESOR]: 'Profesor',
        [UserRole.ESTUDIANTE]: 'Estudiante',
    };
    return roleNames[role];
}
