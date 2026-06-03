# Anexos del TFG — TourClick

Índice general de los documentos básicos (anexos) del proyecto. Cada anexo comienza con su
propio índice interno de capítulos y apartados.

| Anexo | Documento | Contenido |
|---|---|---|
| **A1** | [Especificaciones del sistema](./A1_especificaciones.md) | Requisitos: historias de usuario + RF/RNF (IEEE-830), reglas de negocio, casos de uso generales y trazabilidad. |
| **A2** | [Análisis y diseño del sistema](./A2_analisis_diseno.md) | Modelo de análisis (dominio, casos de uso, secuencias) y diseño (arquitectura, funcionalidad, interfaces, datos). |
| — | [Modelo de dominio](./modelo_dominio.md) | Documento compartido: glosario, entidades y relaciones. Base de A2 y reutilizable por los demás anexos. |

## Notas de uso

- **Diagramas en PlantUML.** Los bloques ` ```plantuml ` se renderizan en VS Code
  (extensión *PlantUML*), IntelliJ o el servidor público de PlantUML. Para exportarlos a
  imagen (PNG/SVG) e incrustarlos en la memoria, copia el bloque en
  [planttext.com](https://www.planttext.com) o usa la CLI `plantuml`.
- **Trazabilidad.** Épica → Historia de usuario (HU) → Requisito funcional (RF) → Caso de
  uso (CU). La matriz se encuentra al final del Anexo A1 y se reutiliza en A2.
- **Pendiente para los 3 anexos restantes.** Esta base cubre A1 y A2. Posibles anexos
  adicionales reutilizando este material: manual de usuario, manual técnico/despliegue,
  documentación del modelo de IA (entrenamiento del clasificador y construcción del RAG) y
  plan de pruebas.
