# ChronoLife: Emergent Reality

Un simulador de vida en Flutter donde cada decisión importa y el tiempo evoluciona coherentemente.

## Características

- Simulación diaria con módulos de dinero, salud, relaciones, proyectos.
- Planificador drag-and-drop.
- Control giroscópico del tiempo.
- Eventos emergentes.
- Persistencia con Hive.
- Audio y animaciones adaptativas.

## Instalación

1. Clona el repo.
2. `flutter pub get`
3. `flutter run`

## Arquitectura

- `LifeController`: Gestiona la simulación.
- Módulos: Money, Health, etc.
- Pantallas: Dashboard, Planner, Summary.

## Checklist de Validación

Verifica que:
1. Se puede planear el día.
2. Acciones inválidas se bloquean.
3. Giroscopio controla tiempo.
4. Módulos actualizan correctamente.
5. Inversiones generan retornos.
6. Eventos afectan variables.
7. Resumen muestra cambios precisos.
8. Proyectos progresan.
9. Rewind tiene consecuencias.
10. Rendimiento >60fps.
11. Estado se guarda/carga.
12. UI es accesible.