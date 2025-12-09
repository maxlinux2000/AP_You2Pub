# 📚 You2Pub: Archivo de Contenido Audiovisual Offline (Soberanía Digital)

You2Pub es un conjunto de scripts y herramientas diseñado para **descargar, archivar y organizar contenido de video** (principalmente de plataformas como YouTube) de manera **totalmente offline y autosuficiente**.

Su objetivo principal es crear un **archivo local, duradero y robusto** que sea fácilmente navegable a través de una interfaz web (HTML, CSS, JS), permitiendo el consumo de la biblioteca **sin depender de una conexión a Internet**.

## 🎯 Relevancia para AP y PuebloNET

You2Pub no es solo una herramienta de descarga personal; es un pilar de la **Preservación Digital y la Soberanía Tecnológica** en entornos controlados o desconectados.

* **Archivos de Preservación (AP):** Permite la curación proactiva de contenido educativo, histórico o cultural antes de que sea eliminado por las plataformas. La estructura de archivos generada por You2Pub es ideal para la **transferencia y almacenamiento a largo plazo** en infraestructuras de archivo.
* **PuebloNET / Conectividad Limitada:** Es la solución perfecta para llevar grandes colecciones de conocimiento y entretenimiento a **zonas con conectividad limitada o nula**. El archivo local, ligero y navegable por HTML, puede ser distribuido en dispositivos locales (servidores comunitarios, Raspberry Pi, etc.) para **garantizar el acceso al conocimiento** sin depender de una infraestructura de red constante.

---

## ✨ Características y Ventajas

| Característica | Descripción | Beneficio Clave |
| :--- | :--- | :--- |
| **Soberanía Digital** | El contenido se almacena localmente, liberándote de las decisiones de eliminación o censura de las plataformas. | **Independencia** y archivo permanente. |
| **Acceso Offline** | La interfaz web generada (HTML/CSS) permite la navegación y visualización sin requerir una conexión a Internet activa. | **Acceso garantizado** en entornos sin conexión (e.g., PuebloNET, viajes). |
| **Optimización de Recursos** | La arquitectura basada en *scripts* de Bash y Deno es ligera y eficiente, minimizando la carga en el sistema operativo para la navegación. | **Económico en recursos**, ideal para hardware de baja potencia. |
| **Balanceo Inteligente** | El motor de balanceo (`generate_root.ts`) asegura que todos los canales tengan visibilidad en la portada, priorizando la actualidad sin relegar canales menos activos. | **Usabilidad** y equidad en la presentación del archivo. |

---

## 🛠️ Estructura y Funcionamiento Técnico

El proyecto opera mediante un flujo de trabajo de procesamiento por lotes (Batch Processing) orquestado por **scripts de Bash**, utilizando **Deno (TypeScript/JavaScript)** para la generación de la interfaz web dinámica y gestión de datos.

### Componentes Clave del Flujo

| Archivo / Script | Función Principal | Descripción Técnica |
| :--- | :--- | :--- |
| `1_config_manager.sh` | **Configuración** | Define rutas principales (`YOU2PUB_ROOT`) y asegura que el entorno de ejecución esté preparado. |
| `2_channel_sync.sh` | **Descarga de Canales** | Usa `yt-dlp` para descargar y sincronizar videos de la lista de canales, incluyendo metadatos y carátulas. |
| `3_channel_index.sh` | **Generación de Índice** | Procesa metadatos para crear el archivo `index.html` específico de cada canal. |
| `4_sitemap_generator.sh` | **Rastreadores Locales** | Crea archivos `sitemap.xml` para optimizar la indexación en motores de búsqueda locales o privados (como Yacy). |
| `5_menu_data.sh` | **Menú de Navegación** | Recopila la lista de canales y genera `menu_data.js` para la barra lateral de la portada. |
| `6_html_generator.sh` | **Generación de Portada** | Orquesta la creación del `index.html` principal (portada) utilizando el motor de balanceo. |
| `generate_root.ts` | **Motor de Balanceo** | Script Deno que implementa la lógica de selección de videos (ej., Límite Global, Mínimo por Canal) para la portada. |

### Lógica Clave de Balanceo (`generate_root.ts`)

La portada (`index.html`) está optimizada para la carga rápida y la visibilidad equitativa.

* **Límite Global Base:** Se muestra un máximo configurable de videos (ej., **400 videos**).
* **Límite Mínimo por Canal (VPC):** Se garantiza que cada canal aparezca con al menos **2 videos** en la portada.
* **Ajuste Dinámico:** El límite de videos por canal se ajusta automáticamente para garantizar que el mínimo de 2 VPC se cumpla, incluso si eso significa superar ligeramente el Límite Global. De esta manera, los canales menos activos no son marginados, asegurando que la portada sea un fiel reflejo de todo el archivo.

---


