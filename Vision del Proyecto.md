# MuColaboradores - Visión y Progreso del Proyecto

*Última actualización y análisis de progreso realizados por Gemini.*

La idea central es recrear la experiencia nostálgica y adictiva del MMORPG clásico "Mu Online", adaptándola a la plataforma Roblox. No se trata de una copia exacta, sino de capturar su esencia con una arquitectura de código moderna y un enfoque en la jugabilidad.

---

## Los Tres Pilares Fundamentales

- **[COMPLETADO ✅] Combate de Acción y Responsivo ⚔️:** La base del combate está planteada, aunque requiere pulido.
- **[EN PROGRESO 🟡] Progresión de Personaje Profunda 📈:** Los sistemas de stats e inventario están completos. Faltan las habilidades.
- **[COMPLETADO ✅] Arquitectura de Código Escalable y Profesional 💻:** Hemos establecido una base modular y una comunicación centralizada robusta.

---

## Las Fases del Proyecto

### Fase 1: El Núcleo Jugable (MVP)
*El objetivo de esta fase es tener un prototipo jugable. Se centra en el bucle de juego fundamental: moverse, atacar, derrotar a un enemigo y obtener una recompensa.*

- **1.1. El Personaje y Controles Básicos**
  - `[COMPLETADO ✅]` **Movimiento:** Se utiliza el sistema estándar de Roblox.
  - `[EN PROGRESO 🟡]` **Recursos Fundamentales (HP/MP):** La lógica y los datos existen en `PlayerDataManager`. Las barras de UI están por implementarse.
  - `[PENDIENTE ❌]` **Sistema de Muerte:** La reaparición en la ciudad aún no está implementada.

- **1.2. El Mapa Inicial (Versión 1.0)**
  - `[PENDIENTE ❌]` **Diseño General:** Se necesita construir el mapa que fusione Lorencia y Noria.
  - `[PENDIENTE ❌]` **Zonas Clave:** Las zonas segura y de principiantes deben ser definidas en el mapa.

- **1.3. El Primer Enemigo: "Spider"**
  - `[PENDiente ❌]` **Modelo y IA:** Se necesita crear el modelo 3D y el script de IA para el enemigo.

- **1.4. Sistema de Combate Básico**
  - `[PENDIENTE ❌]` **Ataque del Jugador:** La lógica de ataque (cliente-servidor) y el cálculo de daño deben ser implementados.

- **1.5. Bucle de Recompensa y Guardado**
  - `[COMPLETADO ✅]` **Experiencia (XP) y Moneda (Zen):** La estructura para guardar estos datos ya existe en `PlayerDataManager`.
  - `[COMPLETADO ✅]` **Guardado de Datos:** Se utiliza `ProfileService` para guardar el progreso del jugador de forma segura.

- **1.6. Interfaz de Usuario (UI) Esencial**
  - `[EN PROGRESO 🟡]` **Elementos Fijos:** Los datos para las barras de HP/MP/XP y los textos de Nivel/Zen están disponibles. Falta conectar la UI principal (`MainHudGui`).

### Fase 2: Profundización del RPG y la Progresión
*Con el núcleo jugable funcionando, esta fase añade los sistemas que definen la identidad de un RPG de acción.*

- **2.1. Sistema de Clases**
  - `[COMPLETADO ✅]` **Elección Inicial:** El proyecto ya cuenta con un `ClassSelectionService` y la lógica para guardar la clase del jugador.

- **2.2. Sistema de Estadísticas (Stats)**
  - `[COMPLETADO ✅]` **Atributos Clásicos:** Implementados (STR, AGI, VIT, ENE).
  - `[COMPLETADO ✅]` **Asignación de Puntos:** El `StatsService` y `StatsController` gestionan la asignación de puntos al subir de nivel.
  - `[COMPLETADO ✅]` **UI de Estadísticas:** La ventana de personaje (`CharacterStatsGui`) es funcional.

- **2.3. Habilidades (Skills)**
  - `[EN PROGRESO 🟡]` **Habilidades por Clase:** Existe un `SkillConfig.lua`, pero la lógica para lanzar habilidades, su consumo de MP y cooldown está pendiente.

- **2.4. Inventario y Equipamiento**
  - `[COMPLETADO ✅]` **Inventario y Slots de Equipo:** La UI (`InventoryGui`) y toda la lógica del sistema están implementadas.
  - `[COMPLETADO ✅]` **Funcionalidad:** Los ítems equipados afectan las estadísticas del jugador y la base para mostrar los modelos 3D está lista.

- **2.5. Sistema de Ítems y "Loot"**
  - `[EN PROGRESO 🟡]` **Drops de Monstruos:** La estructura (`ItemConfig.lua`) está lista. Falta implementar la lógica de "drop" en los enemigos.
  - `[COMPLETADO ✅]` **Nivel de Ítem (+X):** El concepto ya está definido en `ItemConfig.lua` y el `InventoryManager` lo gestiona.

### Fase 3: Construcción del Mundo y la Comunidad
*El objetivo es transformar el juego de una experiencia RPG funcional a un mundo multijugador vivo y coherente.*

- `[PENDIENTE ❌]` **3.1. Expansión y Zonas del Mapa**
- `[PENDIENTE ❌]` **3.2. Sistema de "Party" (Grupo)**
- `[PENDIENTE ❌]` **3.3. NPCs y Tiendas**

### Fase 4: Sistemas Avanzados y de "Endgame"
*Se implementan las mecánicas complejas y adictivas que definen la experiencia de "grindeo" y los objetivos a largo plazo.*

- `[PENDIENTE ❌]` **4.1. El Sistema de Joyas**
- `[PENDIENTE ❌]` **4.2. Creación de Alas (Wings)**
- `[PENDIENTE ❌]` **4.3. Eventos de Mapa**

### Fase 5: Pulido, Balance y Futuro
*Esta fase final se enfoca en refinar la experiencia del jugador y asegurar la sostenibilidad del juego a largo plazo.*

- `[PENDIENTE ❌]` **5.1. Pulido Visual y Sonoro**
- `[PENDIENTE ❌]` **5.2. Balanceo Continuo**
- `[PENDIENTE ❌]` **5.3. Monetización (Opcional y Ética)**
