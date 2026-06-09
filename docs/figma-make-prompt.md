# Quadrant App

---

## App Overview

**Quadrant** es una herramienta de priorización estratégica basada en los principios de Stephen Covey (Los 7 Hábitos de las Personas Altamente Efectivas). Ayuda a personas de alto rendimiento y equipos pequeños a alinear su ejecución diaria con su misión, visión y principios, usando un motor de priorización basado en urgencia × importancia × impacto / esfuerzo.

---

## Target User

Andrés Alonso, CTO de Necta (gobierno de Mendoza). Recibe decenas de pedidos de organismos públicos. Hoy prioriza basado en conocimiento tácito. Necesita una herramienta visual, simple, que lo ayude a decidir QUÉ hacer basado en datos y alineación estratégica, no en urgencia del que grita más fuerte.

---

## Core Flow (5 pasos)

### Paso 1: Onboarding — Visión, Misión, Principios
- Pantalla de bienvenida con 3 cards grandes
- Card 1: "¿Cuál es tu visión?" — input multilínea, fondo con gradient suave
- Card 2: "¿Cuál es tu misión?" — input multilínea
- Card 3: "¿Cuáles son tus principios?" — lista de principios, cada uno con título + descripción corta, se pueden reordenar por drag
- Botón grande "Comenzar" al final

### Paso 2: Cultura — Hábitos y Valores
- Pantalla para definir hábitos
- Cada hábito: nombre, descripción, frecuencia (diario/semanal/mensual), vinculado a un rol
- Grid de cards visuales con íconos representativos

### Paso 3: Jerarquía de Objetivos
- **Ámbitos** → **Roles** → **Objetivos** → **Metas** → **Tareas**
- Cada nivel se define desde el anterior (zoom-in progresivo)
- Vista de árbol colapsable
- Los ámbitos tienen color e ícono propios
- Los roles pertenecen a un ámbito
- Los objetivos tienen: título, descripción, horizonte (3 meses, 6 meses, 1 año, 3 años), tipo, fecha inicio y fecha objetivo
- Las metas tienen: titulo, descripción, período, y los campos de priorización (abajo)
- Las tareas son checklist dentro de cada meta

### Paso 4: Priorización (el CORAZÓN de la app)
Cada meta se prioriza con 4 sliders visuales de 1-5 (escala Likert con emojis):

1. **Urgencia** ⏰ — ¿Qué tan pronto necesita atención?
   - 1 = No hay prisa / 5 = Arde
2. **Importancia** 🎯 — ¿Qué tan crítico para la misión/visión?
   - 1 = Podría esperar / 5 = Es estratégico
3. **Impacto** 🚀 — ¿Cuánto cambio genera?
   - 1 = Mejora marginal / 5 = Transformacional
4. **Esfuerzo** 💪 — ¿Cuánto trabajo requiere? (inverso)
   - 1 = Muy complejo / 5 = Muy simple

**Score automático**: `(urgencia × importancia × impacto) × (esfuerzo / 5)`

- Muestra el score en vivo mientras movés los sliders
- Ordenamiento automático de metas por score descendente
- Vista de matriz 2×2 (Urgencia × Importancia) donde las metas aparecen como burbujas de tamaño proporcional al score
- Vista de lista ordenada con score visible

### Paso 5: Plan Semanal
- Vista de semana actual (lunes a domingo)
- Arrastrar metas del backlog priorizado a la semana
- Cada meta genera items en el plan semanal
- Checkbox de completado
- Al final de la semana, revisión (que se completó, que no, por qué)

---

## Data Model (relacional, para Supabase)

### Tablas principales:

**usuarios**
- id (uuid, PK), email, nombre, foto_url, created_at, updated_at

**espacios_de_trabajo**
- id (uuid, PK), usuario_id (FK), nombre, slug, es_predeterminado

**visiones** y **misiones**
- id (uuid, PK), espacio_trabajo_id (FK), titulo, descripcion

**principios**
- id (uuid, PK), espacio_trabajo_id (FK), titulo, descripcion, posicion

**ambitos**
- id (uuid, PK), espacio_trabajo_id (FK), nombre, descripcion, color, icono, posicion, archivado

**roles**
- id (uuid, PK), espacio_trabajo_id (FK), ambito_id (FK), nombre, descripcion, posicion, archivado

**objetivos**
- id (uuid, PK), espacio_trabajo_id (FK), rol_id (FK), titulo, descripcion, tipo, horizonte, estado (activo/completado/archivado), prioridad (1-5), fecha_inicio, fecha_objetivo, archivado

**metas**
- id (uuid, PK), espacio_trabajo_id (FK), objetivo_id (FK), titulo, descripcion, estado, periodo, progreso (0-100), impacto (1-5), esfuerzo (1-5), urgencia (1-5), importancia (1-5), score (decimal calculado), tipo_prioridad (automática/manual), estado_producto (idea/validación/construcción/lanzado/escalando), fecha_inicio, fecha_objetivo, archivado

**tareas**
- id (uuid, PK), espacio_trabajo_id (FK), meta_id (FK), titulo, descripcion, estado, prioridad, fecha_vencimiento, completada, posicion, archivada

**planes_semanales**
- id (uuid, PK), espacio_trabajo_id (FK), semana_inicio (date), enfoque, notas

**items_plan_semanal**
- id (uuid, PK), plan_semanal_id (FK), rol_id (FK), objetivo_id (FK), meta_id (FK), tarea_id (FK, nullable), titulo, tipo_item (meta/tarea/nota), posicion, completado

**habitos**
- id (uuid, PK), espacio_trabajo_id (FK), rol_id (FK), nombre, descripcion, frecuencia, estado

**notas**
- id (uuid, PK), espacio_trabajo_id (FK), ambito_id (FK, nullable), rol_id (FK, nullable), titulo, contenido, tipo

---

## Screens / Pages (6 pantallas principales)

### 1. Dashboard
- Header con el nombre del espacio de trabajo
- 4 cards resumen: Objetivos activos, Metas priorizadas, Progreso semanal, Score promedio
- Matriz 2×2 (Urgencia × Importancia) con burbujas de metas
- Timeline de la semana actual

### 2. Estrategia (Visión, Misión, Principios)
- Sección expandible de Visión (texto grande, inspiracional)
- Sección de Misión
- Grid de Principios (cards con ícono + texto)
- Botón editar

### 3. Objetivos (jerarquía completa)
- Navegación tipo árbol: Ámbito → Rol → Objetivo → Meta → Tarea
- Cada nivel es una pantalla con lista y botón "+" flotante
- Formularios modales para crear/editar cada entidad
- Filtros por estado, horizonte, ámbito, rol

### 4. Priorización
- Lista de metas con sliders de urgencia, importancia, impacto, esfuerzo
- Score calculado en vivo
- Botón "Ordenar por score"
- Vista de matriz 2×2 con drag de metas entre cuadrantes
- Vista de ranking (top 10)

### 5. Plan Semanal
- Calendario de la semana (lunes a domingo)
- Backlog a la izquierda con metas priorizadas
- Drag & drop del backlog al día correspondiente
- Cada item se puede marcar como completado
- Botón "Cerrar semana" con resumen

### 6. Hábitos
- Lista de hábitos con tracking de racha
- Check diario/semanal
- Vinculado a roles específicos

---

## Visual Design Guidelines

- **Colores**: Fondo blanco/gris muy claro (#f8f9fa). Acentos en azul profundo (#1a56db) y verde menta (#059669). Tarjetas blancas con sombra suave.
- **Tipografía**: Sistema sans-serif, títulos grandes (32px+), body 16px. Maximizar legibilidad.
- **Botones**: Grandes, redondeados (border-radius: 12px), con sombra. Texto claro. Iconos acompañando.
- **Cards**: Esquinas redondeadas (16px), sombra sutil, padding generoso (24px+).
- **Espaciado**: Mucho espacio blanco. Nada apretado.
- **Sliders**: Custom, gruesos, color por nivel (rojo para urgencia alta, verde para impacto alto).
- **Matriz 2×2**: Cuadrantes con colores suaves de fondo. Burbujas con nombre de meta + score.
- **Animaciones**: Transiciones suaves entre pantallas. Score que se actualiza con animación de contador.

---

## Technical Requirements

- **Supabase backend** para persistencia (las tablas ya están diseñadas arriba)
- **Autenticación** por email/password o magic link
- **Responsive**: funciona en desktop y mobile
- **Dark mode** opcional (toggle en header)
- **Exportar** plan semanal como PDF o imagen

---

## Edge Cases & Behaviors

- Si un usuario no tiene visión/misión definidas, mostrar onboarding amigable
- Las metas archivadas no se muestran en priorización pero sí en el historial
- Los scores se recalculan automáticamente al cambiar cualquier slider
- Dos metas con el mismo score se ordenan por importancia descendente
- Al crear una meta nueva sin score, sugerir los sliders con valores default (3)
- Los planes semanales se generan automáticamente cada lunes si no existe uno
- Las tareas completadas se archivan visualmente pero no se borran
- Las notas pueden vincularse a ámbito, rol, o ser independientes
- Un principio no se puede eliminar si está referenciado en objetivos activos

---

## English Version — Figma Make Prompt

**Quadrant — Strategic Prioritization Matrix**

Personal/team prioritization app based on Stephen Covey's The 7 Habits of Highly Effective People. Target: CTOs, PMs, high-performance individuals who need to align daily execution with their vision and mission.

**Core Flow (5 steps):**
1. Onboarding: define Vision, Mission, Principles (large cards, multiline inputs)
2. Culture: define Habits linked to Roles (name, frequency, description)
3. Hierarchy: Domains → Roles → Objectives → Goals → Tasks (collapsible tree view)
4. Prioritization (CORE): each Goal has 4 sliders 1-5 (urgency, importance, impact, effort). Score = (urgency × importance × impact) × (effort / 5). 2×2 matrix view + ranked list.
5. Weekly Plan: drag & drop prioritized goals onto week days. Completion checkbox.

**6 screens:** Dashboard (summary + 2×2 matrix), Strategy (vision/mission/principles), Objectives (hierarchical tree), Prioritization (sliders + live score), Weekly Plan (calendar drag-drop), Habits (streak tracking).

**Visual:** Background #f8f9fa, deep blue #1a56db, mint green #059669. Large rounded buttons (12px). Cards with generous padding (24px+), soft shadows, 16px corners. Custom thick sliders with color-coded levels. 2×2 matrix with score-proportional bubbles. Sans-serif. Plenty of white space.

**Backend:** Supabase. Tables: users, workspaces, visions, missions, principles, domains, roles, objectives, goals, tasks, weekly_plans, weekly_plan_items, habits, notes. Email/password auth.

**Edge cases:** onboarding if no vision/mission set, archived goals hidden from prioritization, live score recalculation, ties broken by importance, default sliders at 3, weekly plan auto-generated every Monday.
