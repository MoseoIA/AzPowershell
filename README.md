# AzPowershell
PowerShell Code for Azure



Guía Exhaustiva para la Actualización de Contraseñas de Cuentas de Servicio en SharePoint Server 2013 On-Premise sobre Windows Server 2012 R21. Resumen EjecutivoPropósito: El presente informe tiene como objetivo proporcionar una guía detallada y experta para el proceso de actualización de contraseñas de las cuentas de servicio en un entorno de SharePoint Server 2013 on-premise que opera sobre Windows Server 2012 R2.Desafíos Clave: La actualización de contraseñas de cuentas de servicio en SharePoint es una tarea crítica que presenta desafíos significativos. Entre ellos destacan la necesidad imperativa de sincronización de contraseñas entre Active Directory (AD) y SharePoint, la distinción fundamental entre cuentas administradas y no administradas por SharePoint, y el riesgo inherente de interrupción del servicio si el proceso no se ejecuta con precisión.1Recomendaciones Centrales: Se subraya la importancia de una planificación meticulosa, una ejecución por fases (priorizando la actualización en Active Directory y posteriormente en SharePoint), pruebas exhaustivas en entornos de preproducción si es posible, y el aprovechamiento de las características de cuentas administradas de SharePoint para simplificar y asegurar el proceso.Resultado Esperado: Siguiendo las directrices de este informe, se espera que la actualización de contraseñas se complete con éxito, minimizando los riesgos de interrupción del servicio y el impacto operativo en la granja de SharePoint.Es fundamental comprender que las cuentas de servicio de SharePoint no son meras cuentas de AD; son identidades profundamente integradas dentro de la granja de SharePoint. Un cambio de contraseña no es simplemente una operación de AD, sino un procedimiento que afecta la operatividad de múltiples componentes de SharePoint. La sincronización entre AD y SharePoint es la piedra angular de este proceso; una discrepancia puede llevar a la detención de servicios críticos.1 Esta interdependencia eleva la complejidad de la tarea más allá de un simple restablecimiento de contraseña en AD, justificando la necesidad de una ejecución cuidadosa y bien informada.2. Comprensión de las Cuentas de Servicio de SharePoint 2013 y la Gestión de Contraseñas2.1. Visión General de las Cuentas de Servicio en SharePoint 2013Las cuentas de servicio son un componente esencial en la arquitectura de SharePoint Server 2013, proporcionando el contexto de seguridad necesario para una amplia gama de operaciones de la granja, la ejecución de grupos de aplicaciones en Internet Information Services (IIS) y el funcionamiento de las aplicaciones de servicio. Estas cuentas requieren permisos específicos tanto en Active Directory como en SQL Server, y en ocasiones, permisos locales en los propios servidores de SharePoint.3Una granja de SharePoint 2013 típica utiliza diversas cuentas de servicio, cada una con un propósito definido. La siguiente tabla resume algunas de las cuentas más comunes y sus roles principales:Tabla 1: Cuentas de Servicio Comunes de SharePoint 2013 y Sus Roles Principales
Tipo de CuentaNombre Típico (Ejemplo)Función PrincipalAdministración Típica en SharePointCuenta de la Granja (Farm Account)dominio\sp_farmIdentidad para el servicio de temporizador de SharePoint, el sitio web de Administración Central y acceso a la base de datos de configuración. 3AdministradaGrupo de Aplicaciones Webdominio\sp_webappIdentidad para los grupos de aplicaciones de IIS que hospedan aplicaciones web. 3AdministradaServicio de Búsqueda (Servicio y Acceso)dominio\sp_searchsaEjecuta el servicio de búsqueda de SharePoint.AdministradaAcceso a Contenido de Búsquedadominio\sp_crawlCuenta utilizada para rastrear contenido. 4Administrada/No AdministradaServicio de Perfiles de Usuario (Servicio)dominio\sp_upsEjecuta el Servicio de Perfiles de Usuario.AdministradaSincronización de Perfiles de Usuario (Conexión)dominio\sp_up syncUtilizada para conectarse a Active Directory para la sincronización de perfiles. 4No AdministradaServicio de Conectividad de Datos Empresariales (BCS)dominio\sp_bcsIdentidad para el servicio BCS y acceso a orígenes de datos externos.AdministradaServicios de Exceldominio\sp_excelIdentidad para la aplicación de servicio de Servicios de Excel. 3AdministradaServicios de Visio Graphicsdominio\sp_visioIdentidad para la aplicación de servicio de Servicios de Visio Graphics. 3AdministradaAlmacén Seguro (Secure Store)dominio\sp_securestoreIdentidad para la aplicación de servicio de Almacén Seguro.AdministradaSuperusuario de Caché de Objetosdominio\sp_cacheuserCuenta con permisos de lectura completa en aplicaciones web para la caché de objetos.Configurada en Directiva Web AppLector de Caché de Objetosdominio\sp_cachereaderCuenta con permisos de lectura en aplicaciones web para la caché de objetos.Configurada en Directiva Web App
La correcta identificación de todas estas cuentas es el primer paso crucial antes de cualquier actualización de contraseñas.2.2. Cuentas Administradas vs. No AdministradasSharePoint Server 2013 ofrece un mecanismo para simplificar la gestión de contraseñas de las cuentas de servicio a través del concepto de "cuentas administradas".

Cuentas Administradas:Son cuentas de dominio que se registran en la Administración Central de SharePoint. Este registro permite que SharePoint tome el control de la gestión de sus contraseñas.1 Los beneficios son significativos: SharePoint puede cambiar automáticamente las contraseñas en Active Directory y luego propagar estos cambios a todos los servicios y servidores de la granja que utilizan dicha cuenta. Esto no solo simplifica la administración, sino que también es fundamental para mantener la sincronización y reducir el riesgo de errores manuales.1 La característica de cambio automático de contraseña se basa en estas cuentas administradas.1


Cuentas No Administradas:Son cuentas de dominio estándar cuyas contraseñas no son controladas directamente por la característica de cambio automático de contraseñas de SharePoint. Cuando la contraseña de una cuenta no administrada se cambia en Active Directory, se requiere una intervención manual para actualizar esta nueva contraseña en todas las configuraciones de SharePoint donde se utilice.6 Esto puede incluir la identidad de grupos de aplicaciones en IIS (si no se utiliza una cuenta administrada para ellos), configuraciones específicas de aplicaciones de servicio, y otras áreas. Un ejemplo notable que a menudo se cita como no administrada o que requiere un manejo especial es la cuenta del Servicio de Sincronización de Perfiles de Usuario (UPSS) y, particularmente, la cuenta de conexión de sincronización de perfiles de usuario.6

La elección entre utilizar cuentas administradas o no administradas no es meramente una cuestión de conveniencia administrativa; es una decisión estratégica que impacta la postura de seguridad y la resiliencia operacional. Las cuentas no administradas introducen más puntos de contacto manuales durante el ciclo de vida de la contraseña, lo que incrementa la probabilidad de error humano. Cada paso manual en el proceso de actualización de una cuenta no administrada es un punto potencial de fallo o descuido.1 Por el contrario, las cuentas administradas centralizan y automatizan gran parte de este proceso, reduciendo la carga administrativa y el riesgo.5Una falta de documentación centralizada o de comprensión clara sobre qué cuentas son administradas y cuáles no, puede conducir a un proceso de actualización de contraseñas caótico y arriesgado, especialmente en granjas de SharePoint maduras o heredadas. Si un administrador asume erróneamente que una cuenta es administrada (y que su contraseña se actualizará automáticamente a través de SharePoint) cuando en realidad es no administrada, los servicios críticos podrían interrumpirse después del cambio de contraseña en AD. Esto llevaría a una solución de problemas prolongada y a un tiempo de inactividad innecesario, subrayando la importancia de la fase de identificación de todas las cuentas de servicio.72.3. Importancia de la Sincronización de Contraseñas con Active DirectoryLa dependencia de SharePoint en Active Directory para la autenticación de sus cuentas de servicio es absoluta. Los servicios de SharePoint utilizan estas cuentas para autenticarse con AD y para acceder a recursos vitales, como las bases de datos de SQL Server. Si la contraseña de una cuenta de servicio almacenada en la configuración de SharePoint no coincide con la contraseña actual de esa cuenta en Active Directory, los servicios que dependen de ella no podrán iniciarse o fallarán durante su operación.1 Esta es una de las causas más comunes de interrupciones del servicio relacionadas con la gestión de contraseñas.1Incluso cuando se utilizan cuentas administradas, si un administrador de Active Directory cambia la contraseña de una cuenta de servicio directamente en AD sin la intervención de SharePoint, se producirá una desincronización. En tal escenario, es necesario que el administrador de SharePoint intervenga manualmente para resincronizar la contraseña. Esto se hace a través de la Administración Central, utilizando la opción "Usar contraseña existente" para la cuenta administrada afectada, lo que actualiza SharePoint con la contraseña que ya ha sido cambiada en AD.13. Impactos de la Actualización de Contraseñas de Cuentas de ServicioLa actualización de las contraseñas de las cuentas de servicio, aunque necesaria para la seguridad, puede tener impactos significativos en la operatividad de la granja de SharePoint si no se gestiona correctamente.3.1. Posibles Interrupciones del Servicio
Indisponibilidad General del Servicio: Cualquier servicio, aplicación web o trabajo de temporizador que dependa de una cuenta de servicio cuya contraseña no esté sincronizada entre AD y SharePoint fallará. Esto puede afectar incluso a la propia Administración Central si su grupo de aplicaciones se ejecuta bajo una cuenta afectada.1
Servicio de Búsqueda: Las funciones de consulta y rastreo del servicio de búsqueda se verán directamente afectadas. Específicamente, se estima un tiempo de inactividad de las consultas de entre 3 y 5 minutos cuando los servicios de búsqueda se reinician después de un cambio de contraseña.1 Si la cuenta de acceso a contenido tiene una contraseña incorrecta, el rastreo fallará, resultando en un índice de búsqueda desactualizado.
Servicio de Perfiles de Usuario (UPS): La sincronización de perfiles fallará si la contraseña de la cuenta del servicio UPSS o de la cuenta de conexión de sincronización no se actualiza correctamente.6 Esto tiene un impacto directo en todas las características que dependen de información de perfil actualizada, como la personalización, las audiencias y las características sociales.
Grupos de Aplicaciones (Application Pools): Los grupos de aplicaciones de IIS que se ejecutan bajo identidades de cuentas de servicio específicas no podrán iniciarse si sus contraseñas no se actualizan en la configuración de IIS. Esto resultará en la inaccesibilidad de las aplicaciones web asociadas.2
Trabajos del Temporizador (Timer Jobs): Muchas tareas de mantenimiento y operaciones en segundo plano de SharePoint se ejecutan como trabajos del temporizador bajo el contexto de seguridad de una cuenta de servicio (a menudo la cuenta de la granja). Si la contraseña de esta cuenta es incorrecta, estos trabajos fallarán, lo que puede llevar a problemas de rendimiento, datos desactualizados o fallos en tareas programadas.
Servicio de Almacén Seguro (Secure Store Service): Las aplicaciones que dependen de credenciales almacenadas en el Servicio de Almacén Seguro fallarán si esas credenciales (que podrían ser cuentas de servicio) no se actualizan después de un cambio de contraseña en AD.6
Otras Aplicaciones de Servicio: Servicios como PerformancePoint Services, Excel Services, Visio Graphics Service, y otros, se verán afectados si las contraseñas de sus respectivas cuentas de servicio no se actualizan correctamente en sus configuraciones.3
El impacto no se limita a que los servicios simplemente "se detengan". También existe el riesgo de problemas de integridad de datos si los servicios fallan a mitad de una operación o si los procesos de sincronización, como el de UPS, se interrumpen durante períodos prolongados. Por ejemplo, una falla extendida en la sincronización de perfiles de usuario significa que la información del perfil en SharePoint se volverá cada vez más divergente con respecto a Active Directory, afectando la precisión de los datos utilizados para la personalización, la selección de audiencias y las funcionalidades sociales.6 Esto va más allá de la simple indisponibilidad del servicio y puede tener consecuencias en la calidad de la información manejada por la plataforma.El "efecto dominó" mencionado en la literatura 2 puede ser fácilmente subestimado. Un fallo en un servicio fundamental, como un grupo de aplicaciones principal o la propia cuenta de la granja, puede desencadenar una cascada de fallos en otros servicios dependientes. Esto puede dificultar el diagnóstico de la causa raíz si múltiples servicios comienzan a fallar simultánea o secuencialmente. Por ejemplo, si la actualización de la contraseña de la cuenta de la granja falla y no se rectifica de inmediato, numerosos trabajos del temporizador y la propia Administración Central podrían fallar.3 Esto podría enmascarar o agravar problemas con otras cuentas de servicio actualizadas posteriormente, ya que la interfaz administrativa principal estaría comprometida. Este escenario subraya la necesidad de un proceso de actualización y verificación metódico y secuencial.3.2. Estimaciones de Tiempo de Inactividad y MitigaciónEs importante reconocer que cierto tiempo de inactividad es a menudo inevitable durante el proceso de cambio de contraseñas, especialmente si los servicios necesitan ser reiniciados para aplicar los nuevos credenciales.1El tiempo de inactividad de 3-5 minutos para las consultas de búsqueda es una cifra específica proporcionada.1 Otros servicios pueden tener tiempos de reinicio breves similares, pero las fallas acumulativas o en cascada podrían extender significativamente este período.Para mitigar el tiempo de inactividad:
Realizar los cambios durante ventanas de mantenimiento planificadas y con baja actividad de usuarios.2
Notificar a los usuarios y partes interesadas sobre las interrupciones de servicio planificadas y su duración estimada.1
Disponer de un procedimiento claro, probado y detallado para minimizar la duración de la ventana de cambio.
Actualizar las contraseñas en un orden específico (primero en AD, luego en SharePoint) para reducir la ventana de desincronización.
3.3. Implicaciones para la Experiencia del UsuarioLas interrupciones del servicio o el mal funcionamiento debido a problemas de contraseñas tienen un impacto directo en la experiencia del usuario:
Los usuarios pueden no poder acceder a los sitios de SharePoint o a funcionalidades específicas.
Los resultados de búsqueda pueden no estar disponibles o estar desactualizados.
Las características que dependen de perfiles (como "Mis Sitios" o contenido dirigido) pueden no funcionar correctamente.
Una gestión deficiente de estos cambios puede generar una percepción de inestabilidad del sistema entre los usuarios.
4. Riesgos Asociados con las Actualizaciones de ContraseñasAdemás de las interrupciones del servicio, existen otros riesgos que deben considerarse durante el proceso de actualización de contraseñas.4.1. Fallos del Servicio debido a Desajuste de ContraseñasEste es el riesgo más directo y común: los servicios de SharePoint intentan utilizar contraseñas antiguas después de que estas hayan sido cambiadas en Active Directory.1 Los síntomas incluyen servicios que no se inician, errores en los registros de eventos del sistema (por ejemplo, el Event ID 4625 que indica intentos de inicio de sesión fallidos 2), y en algunos casos, el bloqueo de aplicaciones.4.2. Bloqueos de Cuentas y Problemas de Acceso DenegadoLas cuentas de servicio podrían bloquearse en Active Directory si los componentes de SharePoint intentan autenticarse repetidamente con una contraseña incorrecta, especialmente si existen políticas de bloqueo de cuentas estrictas en el dominio. Un número elevado de intentos fallidos desde múltiples servidores puede acelerar este bloqueo.Los administradores también podrían enfrentarse a errores de "Acceso Denegado" al intentar administrar servicios o configuraciones si la cuenta de la granja u otras cuentas de servicio administrativas tienen contraseñas incorrectas.10El riesgo de bloqueo de cuenta no es solo una inconveniencia; puede desencadenar alertas de seguridad e investigaciones, consumiendo recursos adicionales de TI. Además, significa que el servicio afectado permanecerá inactivo hasta que la cuenta sea desbloqueada y la contraseña corregida, prolongando la interrupción. Esta situación se agrava si las políticas de AD requieren intervención manual para desbloquear cuentas, o si los umbrales de bloqueo son bajos y los reintentos de SharePoint son frecuentes.4.3. Propagación Incompleta de los Cambios de Contraseña
Para cuentas administradas: Si el proceso de cambio de contraseña iniciado por SharePoint falla al actualizar la contraseña en AD o al propagarla a todos los servidores de la granja, pueden surgir inconsistencias.1 Esto puede ocurrir si hay problemas de comunicación con los controladores de dominio o con otros servidores de la granja durante el proceso.
Para la cuenta de la granja: No ejecutar el comando stsadm -o updatefarmcredentials en todos los servidores de SharePoint de la granja después de cambiar la contraseña de la cuenta de la granja en AD conducirá a estados inconsistentes. Los servidores donde no se ejecute el comando seguirán intentando usar la contraseña antigua, lo que provocará fallos en esos servidores específicos.6
4.4. Errores de Sincronización de Datos
Sincronización de Perfiles de Usuario: Específicamente, si la contraseña de la cuenta de conexión de sincronización de perfiles de usuario es incorrecta, SharePoint no podrá leer los objetos de AD y los perfiles no se actualizarán.6 Esto resulta en datos de perfil obsoletos en SharePoint.
Rastreo de Búsqueda: Los rastreos de búsqueda fallarán si las contraseñas de las cuentas de acceso a contenido son incorrectas, lo que lleva a un índice de búsqueda desactualizado y resultados de búsqueda irrelevantes o incompletos.6
4.5. Problemas con Soluciones Personalizadas o Credenciales Codificadas (Hardcoded)Aunque no se detalla explícitamente para las cuentas de servicio de SharePoint 2013 en la información de referencia, se menciona el almacenamiento en caché de credenciales y las credenciales codificadas en configuraciones como un riesgo general.2 Es crucial considerar que soluciones personalizadas, scripts de PowerShell, aplicaciones de terceros integradas con SharePoint, o incluso tareas programadas del sistema operativo, podrían tener credenciales de cuentas de servicio almacenadas directamente en archivos de configuración, código fuente o dentro de la configuración de la tarea. Estos elementos no se actualizarán automáticamente y requerirán una identificación y actualización manual, lo que representa un riesgo significativo de pasar por alto alguna dependencia.Una ejecución deficiente de la actualización de contraseñas puede erosionar la confianza en la plataforma SharePoint entre los usuarios y las partes interesadas. Si el proceso conduce a interrupciones prolongadas o repetidas, puede crear una percepción de inestabilidad, dificultando la obtención de apoyo para futuras tareas de mantenimiento o actualizaciones. Este impacto en la confianza puede tener ramificaciones organizacionales más amplias, afectando la adopción de la plataforma y la moral del equipo de TI.5. Planificación y Preparación Previas al CambioUna planificación exhaustiva es fundamental para minimizar los riesgos y el impacto de la actualización de contraseñas.5.1. Identificación de Todas las Cuentas de Servicio de SharePoint y sus DependenciasAntes de realizar cualquier cambio, es imperativo crear un inventario completo de todas las cuentas de servicio utilizadas por la granja de SharePoint.

Métodos para la Identificación:

Administración Central: Navegar a Seguridad > Configurar cuentas administradas. Este es el lugar principal para identificar las cuentas que SharePoint gestiona directamente.7
Administrador de IIS (inetmgr): Revisar los Grupos de Aplicaciones y examinar la columna "Identidad" para cada uno.7
Consola de Servicios (services.msc): En cada servidor de SharePoint, revisar la columna "Iniciar sesión como" para identificar las cuentas bajo las cuales se ejecutan los servicios relacionados con SharePoint.7
Scripts de PowerShell: Utilizar cmdlets como Get-SPManagedAccount para listar las cuentas administradas. Se pueden desarrollar scripts adicionales para consultar los grupos de aplicaciones de IIS y los servicios de Windows en todos los servidores de la granja.7



Documentación de Dependencias: Para cada cuenta identificada, es crucial documentar qué servicios específicos de SharePoint (Servicio de Búsqueda, UPS, etc.), grupos de aplicaciones de IIS, trabajos del temporizador y, potencialmente, sistemas externos dependen de ella. Este mapeo ayuda a comprender el "radio de impacto" de un cambio de contraseña para cada cuenta.El paso de "Identificación de Cuentas de Servicio" no se trata solo de listar nombres de cuentas. Implica mapear todo el gráfico de dependencias. Una cuenta puede ser utilizada por un servicio aparentemente menor, que a su vez es consumido por una aplicación empresarial crítica. Sin esta comprensión profunda, el verdadero impacto de un cambio de contraseña puede pasarse por alto. Por ejemplo, una cuenta para "Servicios de Excel" 3 podría parecer aislada, pero si informes financieros críticos dependen de ella, su fallo es significativo. Por lo tanto, el proceso de identificación debe involucrar no solo qué es la cuenta, sino quién o qué consume los servicios que ejecuta.


Cuentas de Servicio Dedicadas: Seguir la práctica recomendada de utilizar cuentas de servicio dedicadas para diferentes roles en lugar de sobrecargar una sola cuenta (como la cuenta de administrador de la granja) para múltiples funciones.2 Esto limita el impacto de un solo cambio de contraseña y adhiere al principio de menor privilegio.

La siguiente tabla puede servir como plantilla para el inventario y mapeo de dependencias:Tabla 2: Inventario de Cuentas de Servicio y Mapa de DependenciasNombre de Cuenta de Servicio (SAMAccountName)Nombre para Mostrar¿Administrada en SharePoint? (Sí/No)Propósito/RolServicios que Usan Esta Cuenta (Servicios Windows, Servicios SharePoint)Grupos de Aplicaciones que Usan Esta CuentaDependencias Clave (Bases de Datos Específicas, Sistemas Externos)Última Fecha de Cambio de Contraseña (si se conoce)Nueva Contraseña (a registrar durante el proceso)dominio\sp_farmCuenta Granja SPSíOperaciones centrales de la granja, servicio de temporizadorServicio de Temporizador de SharePoint FoundationAppPool Administración CentralBase de datos de configuración, bases de datos de contenidodominio\sp_webappCuenta AppPool WebSíIdentidad para aplicaciones web de contenidoN/AAppPools de Aplicaciones WebBases de datos de contenido asociadas... (continuar para todas las cuentas)5.2. Plan de Comunicación (Notificación a las Partes Interesadas)
Identificar a todas las partes interesadas: usuarios finales, propietarios de negocios, otros equipos de TI (redes, bases de datos, seguridad).
Comunicar la ventana de mantenimiento planificada, el impacto esperado (posible indisponibilidad del servicio o degradación del rendimiento) y la duración estimada.1
Proporcionar información de contacto para soporte durante y después del cambio.
5.3. Consideraciones sobre la Estrategia de Copia de Seguridad y Reversión (Rollback)
Copias de Seguridad: Aunque una "reversión" directa de un cambio de contraseña es simplemente volver a la contraseña anterior (si se conoce y la política de AD permite su reutilización), tener copias de seguridad recientes de la granja de SharePoint (configuración y contenido) es una práctica recomendada general antes de cualquier cambio significativo en el entorno.
Plan de Reversión:

La reversión principal consiste en restablecer la contraseña en Active Directory a su valor anterior y luego actualizar SharePoint para que utilice esa contraseña nuevamente. Para las cuentas administradas, esto se haría mediante la opción "Usar contraseña existente"; para las no administradas, mediante los procedimientos manuales correspondientes.
Esto requiere conocer la contraseña anterior. Es fundamental registrarla de forma segura antes del cambio.
Documentar los pasos exactos realizados durante el cambio para facilitar la reversión si fuera necesario.
Considerar las políticas de historial de contraseñas de Active Directory, que podrían impedir la reutilización inmediata de una contraseña antigua.11


La estrategia de reversión debe tener en cuenta las políticas de contraseñas de AD, como la antigüedad mínima de la contraseña y el historial de contraseñas.11 Si se cambia una contraseña y se necesita una reversión inmediata, AD podría impedir la reutilización de la contraseña antigua si la Antigüedad mínima de la contraseña es mayor que 0 días o si la contraseña antigua está en el historial reciente. Esto podría complicar y retrasar la recuperación, convirtiendo una reversión rápida en una sesión de solución de problemas más compleja y prolongada. Por ejemplo, si la antigüedad mínima es de 1 día, no se podrá cambiar la contraseña nuevamente (ni siquiera a la anterior) el mismo día. Si la contraseña antigua está en el historial, no se podrá reutilizar hasta que salga del ciclo. Esto significa que una simple reversión de "cambiarla de nuevo" podría no ser posible sin alterar temporalmente las políticas de AD o esperar, lo que extendería el tiempo de inactividad.5.4. Programación de Ventanas de Mantenimiento
Elegir horarios de baja actividad (noches, fines de semana) para minimizar el impacto en los usuarios.2
Asegurar que la ventana de mantenimiento sea lo suficientemente larga para completar todos los cambios, realizar una verificación exhaustiva y solucionar cualquier problema imprevisto.
Coordinar con otros equipos de TI si existen dependencias (por ejemplo, el equipo de SQL Server, el equipo de AD).
6. Procedimientos de Active Directory para Contraseñas de Cuentas de Servicio (Windows Server 2012 R2)La gestión de las contraseñas de las cuentas de servicio comienza en Active Directory.6.1. Restablecimiento Manual de Contraseñas en "Usuarios y equipos de Active Directory"El procedimiento estándar para cambiar manualmente la contraseña de una cuenta de servicio en AD es el siguiente:
Abrir la consola "Usuarios y equipos de Active Directory" (ADUC) en un controlador de dominio o en una estación de trabajo con las herramientas de administración remota del servidor (RSAT) instaladas.
Navegar a la Unidad Organizativa (OU) donde residen las cuentas de servicio. Es una buena práctica tener una OU dedicada para las cuentas de servicio de SharePoint.
Hacer clic con el botón derecho en la cuenta de usuario de servicio deseada y seleccionar "Restablecer contraseña".9
Ingresar y confirmar la nueva contraseña.
Crucial: Asegurarse de que la casilla "El usuario debe cambiar la contraseña en el siguiente inicio de sesión" esté desmarcada. Las cuentas de servicio nunca deben tener esta opción habilitada, ya que no pueden realizar un inicio de sesión interactivo para cambiar la contraseña.
Importante: Para las cuentas de servicio, generalmente se recomienda marcar la casilla "La contraseña nunca expira". Esto evita interrupciones inesperadas del servicio debido a la expiración de la contraseña. Sin embargo, esta configuración debe ir acompañada de una política de rotación de contraseñas regular, ya sea manual o automatizada (como la que ofrecen las cuentas administradas de SharePoint). Si no se utiliza el cambio automático de SharePoint, esta configuración previene expiraciones, pero los cambios periódicos siguen siendo una mejor práctica de seguridad.1
Hacer clic en "Aceptar".
Anotar de forma segura la nueva contraseña si no se va a ingresar inmediatamente en la configuración de SharePoint.9
6.2. Mejores Prácticas para Contraseñas de Cuentas de Servicio en AD
Complejidad: Las contraseñas deben cumplir con los requisitos de complejidad de la directiva de contraseñas del dominio (generalmente incluyen una combinación de letras mayúsculas, minúsculas, números y caracteres especiales).11
Longitud: Microsoft recomienda una longitud mínima de 12 caracteres para las contraseñas; cuanto más larga, mejor.11 Para cuentas de servicio críticas, se pueden considerar longitudes mayores.
Historial: Aplicar una política de historial de contraseñas (por ejemplo, que las últimas 24 contraseñas no puedan reutilizarse) para evitar que los usuarios (o administradores) vuelvan a utilizar contraseñas antiguas y potencialmente comprometidas.11
Antigüedad Mínima: La configuración predeterminada suele ser de 1 día. Esto evita que se cambie la contraseña varias veces seguidas rápidamente para eludir la política de historial.11
Antigüedad Máxima: Considerar una antigüedad máxima elevada si se utiliza la función de cambio automático de contraseñas de SharePoint o un proceso manual muy fiable y programado. De lo contrario, podría aplicarse una política típica (por ejemplo, 60-90 días), lo que requiere un seguimiento diligente para evitar expiraciones.1
La configuración "La contraseña nunca expira" para las cuentas de servicio es una práctica común para evitar interrupciones, pero conlleva sus propios riesgos si no se gestiona activamente. Aunque previene interrupciones por expiración, puede llevar a la complacencia, haciendo que las contraseñas permanezcan sin cambios durante demasiado tiempo. Esto incrementa el riesgo si la contraseña se ve comprometida y no se rota. La funcionalidad de cambio automático de SharePoint para cuentas administradas 1 mitiga este riesgo para dichas cuentas. Para cuentas no administradas, o si no se usa la función de SharePoint, una política de rotación manual disciplinada es esencial, o se podría considerar el uso de Directivas de Contraseña Detalladas (FGPP) para un control más granular.
Principio de Menor Privilegio: Las cuentas de servicio solo deben tener los permisos estrictamente necesarios para realizar sus funciones.2 Evitar agregar estas cuentas a grupos de alta privilegiación como "Administradores del Dominio" a menos que sea absolutamente indispensable, esté documentado y aprobado.
6.3. Configuración de Directivas de Contraseña Detalladas (FGPP) (Opcional pero Recomendado para Seguridad Mejorada)Las Directivas de Contraseña Detalladas (Fine-Grained Password Policies - FGPP) permiten aplicar diferentes políticas de contraseña y de bloqueo de cuenta a diferentes conjuntos de usuarios o grupos dentro del mismo dominio. Esta característica está disponible en Windows Server 2008 y versiones posteriores, por lo que es aplicable a Windows Server 2012 R2.11
Beneficios para Cuentas de Servicio: Con FGPP, se pueden aplicar políticas más estrictas (por ejemplo, contraseñas más largas, cambios más frecuentes si se gestionan manualmente, umbrales de bloqueo de cuenta diferentes) a las cuentas de servicio sensibles sin afectar las políticas aplicadas a las cuentas de usuario regulares.
Cómo Configurar FGPP:

Usando el Centro de Administración de Active Directory (ADAC):

Abrir ADAC.
Navegar al contenedor Sistema (System) dentro del dominio y luego al contenedor Configuración de Contraseña (Password Settings Container).
En el panel Tareas, elegir Nuevo (New) y luego Configuración de Contraseña (Password Settings).12
Completar los campos requeridos como Nombre y Precedencia. La precedencia determina qué política se aplica si un usuario es miembro de múltiples grupos con diferentes FGPP. Un valor más bajo tiene mayor precedencia.
Configurar los ajustes de la política de contraseña (longitud mínima, historial, complejidad, antigüedad mínima/máxima).
En la sección "Se aplica directamente a" (Directly Applies To), hacer clic en Agregar (Add) y seleccionar el grupo de seguridad de AD que contiene las cuentas de servicio a las que se aplicará esta política.12 Es una buena práctica crear un grupo específico para las cuentas de servicio de SharePoint que requieran esta política.
Hacer clic en Aceptar (OK).


Usando PowerShell:
Se puede utilizar el cmdlet New-ADFineGrainedPasswordPolicy para crear una FGPP y Add-ADFineGrainedPasswordPolicySubject o Set-ADFineGrainedPasswordPolicy -Identity <PolicyName> -Subject <GroupOrUser> para aplicarla a un grupo o usuario.12
Ejemplo básico:
PowerShellNew-ADFineGrainedPasswordPolicy -Name "PoliticaContraseñaServiciosSP" -Precedence 10 -MinPasswordLength 15 -PasswordHistoryCount 24 -MaxPasswordAge "90.00:00:00" -ComplexityEnabled $true
Add-ADFineGrainedPasswordPolicySubject "PoliticaContraseñaServiciosSP" -Subjects "GrupoServiciosSharePointCriticos"




La implementación de FGPP para cuentas de servicio, aunque añade una sobrecarga de configuración inicial, mejora significativamente la postura de seguridad. Permite controles personalizados y más estrictos para estas cuentas privilegiadas sin imponer esas mismas políticas (potencialmente disruptivas o menos amigables para el usuario) a la población general de usuarios. Esto demuestra un enfoque maduro para la segmentación de la seguridad y es una práctica recomendada para proteger activos críticos como las cuentas de servicio de SharePoint.7. Procedimiento Manual para Actualizar Contraseñas de Cuentas de Servicio de SharePointUna vez que la contraseña ha sido cambiada en Active Directory, el siguiente paso es actualizarla en SharePoint.Orden General: Siempre cambiar la contraseña en Active Directory primero, y luego actualizar SharePoint con esa nueva contraseña.6 Intentar que SharePoint cambie una contraseña que no coincide con la actual en AD puede llevar a errores.7.1. Actualización de Cuentas Administradas a través de la Administración CentralPara las cuentas que están registradas como "Cuentas Administradas" en SharePoint:
Navegar a la Administración Central de SharePoint.
En la sección Seguridad, hacer clic en Configurar cuentas administradas.8
Seleccionar la cuenta administrada cuya contraseña se ha cambiado en AD.
Hacer clic en el icono Editar (o en el nombre de la cuenta para acceder a sus propiedades).
Aquí se presentan dos opciones principales para la gestión de contraseñas:

Opción 1: Si SharePoint debe cambiar la contraseña en AD (y ya se conoce la contraseña actual o se quiere generar una nueva):

Marcar la casilla "Cambiar contraseña ahora".
Seleccionar la opción "Establecer la contraseña de la cuenta en un valor nuevo".
Ingresar la nueva contraseña y confirmarla.
Al hacer clic en Aceptar, SharePoint intentará cambiar la contraseña en Active Directory y luego la propagará a todos los servicios y servidores de la granja que la utilicen.1 Esta opción es útil si se quiere que SharePoint gestione todo el proceso.


Opción 2: Si la contraseña ya fue cambiada en Active Directory y solo se necesita sincronizar SharePoint (la más común para actualizaciones planificadas iniciadas en AD):

Marcar la casilla "Cambiar contraseña ahora".
Seleccionar la opción Usar contraseña existente.
Ingresar la nueva contraseña que se estableció previamente en Active Directory en el campo correspondiente.
Al hacer clic en Aceptar, SharePoint actualizará su configuración interna con esta contraseña, sincronizándose con el cambio ya realizado en AD.1




7.2. Guía Paso a Paso para Cuentas Clave No Administradas o de Manejo Especial (después del cambio de contraseña en AD)Para las cuentas que no son gestionadas por el sistema de cuentas administradas de SharePoint, o que requieren pasos adicionales, el proceso es más manual y específico para cada servicio.7.2.1. Cuenta de la Granja (Farm Account)Esta es una de las cuentas más críticas. Después de cambiar su contraseña en AD:
Iniciar sesión en cada servidor de SharePoint de la granja, comenzando por el servidor que hospeda el sitio web de Administración Central.
Abrir el Shell de administración de SharePoint 2013 como administrador. Es necesario ser administrador de la granja para ejecutar este comando.
Ejecutar el siguiente comando stsadm, reemplazando NombreDominio\NombreUsuario con el nombre de la cuenta de la granja y NuevaContraseña con la contraseña recién establecida en AD:
stsadm -o updatefarmcredentials -userlogin NombreDominio\NombreUsuario -password NuevaContraseña


.64.  Repetir los pasos 1-3 en todos los demás servidores de la granja de SharePoint.5.  Verificar que el sitio de Administración Central sea accesible y que el servicio de temporizador de SharePoint (SharePoint Timer Service) se esté ejecutando en todos los servidores.El comando stsadm -o updatefarmcredentials es una herramienta heredada, pero sigue siendo fundamental para la cuenta de la granja en SharePoint 2013. Su requisito de ejecución por servidor destaca que la base de datos de configuración de la granja no propaga automáticamente este cambio de credencial específico a todos los servidores; cada servidor necesita ser informado explícitamente. Este es un comportamiento único en comparación con muchas otras configuraciones de toda la granja y subraya la importancia de no omitir ningún servidor durante este paso.67.2.2. Cuenta del Servicio de Sincronización de Perfiles de Usuario (UPSS)Si el UPSS se ejecuta bajo la cuenta de la granja, el paso anterior podría haberla cubierto. Sin embargo, a menudo es una cuenta dedicada y se considera no administrada para fines de cambio de contraseña.
Ir a Administración Central > Configuración del Sistema > Administrar servicios en el servidor.
Seleccionar el servidor (o servidores) que ejecuta el Servicio de Sincronización de Perfiles de Usuario de la lista desplegable en la parte superior.
Es probable que el servicio "Servicio de Sincronización de Perfiles de Usuario" esté detenido si su contraseña cambió en AD y no se ha actualizado aquí.
Hacer clic en Iniciar junto al "Servicio de Sincronización de Perfiles de Usuario".
Cuando se solicite, ingresar la nueva contraseña para la cuenta de servicio del UPSS. Hacer clic en Aceptar.6
Esperar y verificar que el servicio se inicie correctamente. Esto puede tomar varios minutos.
7.2.3. Cuenta de Conexión de Sincronización de Perfiles de UsuarioEsta cuenta es utilizada por el UPSS para conectarse a Active Directory y leer la información de los perfiles.
Ir a Administración Central > Administración de Aplicaciones > Administrar aplicaciones de servicio.
Hacer clic en la Aplicación de Servicio de Perfiles de Usuario.
En la página de administración de la aplicación de servicio de perfiles, en la sección "Sincronización", hacer clic en Configurar conexiones de sincronización. (Nota: si el servicio UPSS está detenido, esta lista de conexiones puede aparecer vacía).
Hacer clic en el menú desplegable junto al nombre de la conexión de sincronización (generalmente con el bosque de AD) y seleccionar Modificar conexión.
En la sección "Configuración de la conexión", ingresar la nueva contraseña para la cuenta de conexión.
Hacer clic en el botón Rellenar contenedores. Si la nueva contraseña es correcta y la cuenta tiene los permisos necesarios (como "Replicating Directory Changes" en AD), el árbol de contenedores de AD debería cargarse.
Hacer clic en Aceptar.6
7.2.4. Cuenta(s) de Acceso a Contenido del Servicio de Búsqueda
Ir a Administración Central > Administración de Aplicaciones > Administrar aplicaciones de servicio.
Hacer clic en la Aplicación de Servicio de Búsqueda.
En la página de administración de búsqueda, en la sección "Estado del sistema", buscar el enlace de la Cuenta de acceso a contenido predeterminada y hacer clic en él.
En la ventana emergente, ingresar la nueva contraseña para la cuenta. Hacer clic en Aceptar.6
Adicionalmente, si se han definido cuentas de acceso a contenido específicas en las Reglas de rastreo, estas también deben revisarse y actualizarse si utilizan la cuenta cuya contraseña cambió.
7.2.5. Cuenta de Acceso a Contenido de Búsqueda de SharePoint Foundation (si aplica)Si se está utilizando la búsqueda de SharePoint Foundation (menos común si Enterprise Search está configurado):
Ir a Administración Central > Configuración del Sistema > Administrar servicios en el servidor.
Seleccionar el servidor (o servidores) que ejecuta el servicio "Servicio de búsqueda de SharePoint Foundation Server".
Hacer clic en el enlace del servicio.
Actualizar la contraseña en la sección "Cuenta de acceso a contenido". Hacer clic en Aceptar.6
7.2.6. Credenciales de Aplicación de Destino del Servicio de Almacén SeguroSi las cuentas de servicio se utilizan como credenciales dentro de las Aplicaciones de Destino del Servicio de Almacén Seguro (por ejemplo, para acceso desatendido para Servicios de Excel, Servicios de Visio, BCS):
Ir a Administración Central > Administración de Aplicaciones > Administrar aplicaciones de servicio.
Hacer clic en la Aplicación de Servicio de Almacén Seguro.
Para cada ID de Aplicación de Destino relevante que utilice la cuenta de servicio afectada, seleccionar la aplicación de destino y, en el menú contextual o la cinta de opciones, elegir Establecer credenciales.
Ingresar el nombre de usuario (si es necesario) y la nueva contraseña para la cuenta. Hacer clic en Aceptar.6
7.2.7. Otras Aplicaciones de Servicio (por ejemplo, PerformancePoint, Servicios de Excel, Servicios de Visio Graphics)Estas aplicaciones de servicio a menudo tienen sus propias páginas de configuración dentro de "Administrar aplicaciones de servicio" donde las credenciales de las cuentas de servicio (si no se gestionan centralmente como cuentas administradas) podrían necesitar actualización.
Ejemplo para la Cuenta de Servicio Desatendida de PerformancePoint: Ir a Administrar aplicaciones de servicio > Aplicación de Servicios de PerformancePoint > Configuración del servicio PerformancePoint. En la sección "Cuenta de servicio desatendida", ingresar la nueva contraseña.6
Cuentas de Superusuario de Caché de Objetos y Lector de Caché de Objetos: Estas cuentas generalmente se configuran a nivel de directiva de la aplicación web. Si sus contraseñas se cambian en AD, no suelen requerir una actualización directa en una página de configuración de servicio específica de SharePoint, ya que la autenticación se maneja a través de la directiva de la aplicación web. Sin embargo, es crucial asegurarse de que estas cuentas sigan teniendo los permisos correctos después del cambio de contraseña.6
La complejidad y el número de pasos manuales necesarios para las cuentas no administradas (como se detalla en 6) abogan firmemente por la conversión de tantas cuentas de servicio como sea posible a "Cuentas Administradas" dentro de SharePoint.1 Cada paso manual es un punto potencial de error, inconsistencia u omisión, lo que aumenta el riesgo y la carga administrativa. La tarea actual del usuario de actualizar manualmente todas estas cuentas resalta el problema que las cuentas administradas buscan resolver.7.3. Orden de Operaciones y DependenciasEl orden en que se actualizan las contraseñas es importante para minimizar las interrupciones.Tabla 3: Orden Recomendado para Actualizar Contraseñas de Cuentas de ServicioPaso No.Tipo/Nombre de CuentaAcción en Active DirectoryAcción en SharePoint (Admin Central, STSADM, PowerShell, Página Específica del Servicio)Servidores Clave (si aplica)Notas/Dependencias Críticas1Todas las cuentas de servicio afectadasCambiar contraseña. Desmarcar "Usuario debe cambiar contraseña...". Considerar "Contraseña nunca expira". Registrar nueva contraseña de forma segura.N/AControladores de DominioEste es siempre el primer paso para cualquier cuenta.2Cuenta de la Granja(Ya realizada en Paso 1)Ejecutar stsadm -o updatefarmcredentials -userlogin <cuenta> -password <nueva_pass>Todos los servidores de SharePoint en la granja, comenzando por el que hospeda Admin Central.Crítico para la funcionalidad de Admin Central y el servicio de temporizador.3Cuentas Administradas (excepto la de la granja si se maneja por separado)(Ya realizada en Paso 1)Admin Central > Seguridad > Configurar cuentas administradas > Editar cuenta > "Usar contraseña existente".Servidor de Admin Central (la propagación es a toda la granja).Asegurar que la cuenta esté registrada como administrada.4Cuenta del Servicio de Sincronización de Perfiles de Usuario (UPSS)(Ya realizada en Paso 1)Admin Central > Administrar servicios en el servidor > Seleccionar servidor UPSS > Iniciar servicio UPSS e ingresar nueva contraseña.Servidor(es) que ejecutan UPSS.El servicio UPSS debe estar en ejecución para modificar las conexiones de sincronización.5Cuenta de Conexión de Sincronización de Perfiles de Usuario(Ya realizada en Paso 1)Admin Central > Aplicación de Servicio de Perfiles de Usuario > Configurar conexiones de sincronización > Modificar conexión > Ingresar nueva contraseña > Rellenar contenedores.Servidor de Admin Central (configuración).Depende de que el servicio UPSS esté en ejecución.6Cuenta(s) de Acceso a Contenido de Búsqueda(Ya realizada en Paso 1)Admin Central > Aplicación de Servicio de Búsqueda > Cuenta de acceso a contenido predeterminada (y reglas de rastreo).Servidor de Admin Central (configuración).Esencial para el rastreo de contenido.7Credenciales de Aplicación de Destino del Servicio de Almacén Seguro(Ya realizada en Paso 1)Admin Central > Aplicación de Servicio de Almacén Seguro > Administrar > Establecer credenciales para IDs de destino afectadas.Servidor de Admin Central (configuración).Afecta a los servicios que dependen de estas credenciales (Excel Services Unattended, etc.).8Otras cuentas específicas de Aplicaciones de Servicio (PerformancePoint, etc.)(Ya realizada en Paso 1)Página de configuración de la aplicación de servicio correspondiente en Admin Central.Servidor de Admin Central (configuración).Consultar documentación específica del servicio si no es una cuenta administrada.9Identidades de Grupos de Aplicaciones de IIS (si no usan Cuentas Administradas)(Ya realizada en Paso 1)Administrador de IIS en cada servidor WFE/APP > Grupos de Aplicaciones > Seleccionar AppPool > Configuración Avanzada > Identidad > Establecer credenciales.Todos los servidores WFE y de Aplicaciones que hospedan los AppPools.Impacto directo en la disponibilidad de aplicaciones web.8. Automatización de Actualizaciones de Contraseñas con Scripts de PowerShellPowerShell es una herramienta poderosa para automatizar tareas administrativas en SharePoint, incluyendo la gestión de contraseñas de cuentas administradas.8.1. Uso del Cmdlet Set-SPManagedAccount (para Cuentas Administradas)Este es el cmdlet principal para gestionar mediante programación las cuentas administradas y sus contraseñas.5

Requisitos Previos:

La cuenta debe estar registrada como una cuenta administrada en SharePoint.
El usuario que ejecuta el script necesita permisos adecuados en SharePoint (por ejemplo, ser Administrador de la Granja y tener el rol SharePoint_Shell_Access en la base de datos de configuración y el rol db_owner en las bases de datos de contenido relevantes si la operación lo requiere).
El servicio de Administración de SharePoint debe estar en ejecución.



Escenario 1: Actualizar con una Nueva Contraseña (conocida por el administrador, SharePoint actualiza AD)Este escenario se utiliza cuando se desea que SharePoint establezca una nueva contraseña específica en Active Directory y luego la propague.
PowerShell# Convertir la contraseña a SecureString
$newPassword = ConvertTo-SecureString "Nuev@P@$$wOrd123!" -AsPlainText -Force

# Obtener la cuenta administrada
$managedAccount = Get-SPManagedAccount -Identity "DOMINIO\CuentaServicioAdministrada"

# Establecer la nueva contraseña
Set-SPManagedAccount -Identity $managedAccount -NewPassword $newPassword -ConfirmPassword $newPassword -SetNewPassword

Explicación:

-Identity: Especifica la cuenta administrada a modificar.
-NewPassword y -ConfirmPassword: Toman la nueva contraseña como un objeto SecureString.
-SetNewPassword: Este modificador indica a SharePoint que establezca esta nueva contraseña en AD y luego la propague a través de la granja.13



Escenario 2: Actualizar con una Contraseña Existente (ya cambiada en AD)Este es el escenario más común para actualizaciones planificadas donde el cambio de contraseña se realiza primero en AD.
PowerShell# Convertir la contraseña (que ya fue cambiada en AD) a SecureString
$existingPassword = ConvertTo-SecureString "P@$$wOrdCambi@daEnAD!" -AsPlainText -Force

# Obtener la cuenta administrada
$managedAccount = Get-SPManagedAccount -Identity "DOMINIO\CuentaServicioAdministrada"

# Sincronizar SharePoint con la contraseña existente de AD
Set-SPManagedAccount -Identity $managedAccount -ExistingPassword $existingPassword -UseExistingPassword

Explicación:

-ExistingPassword: Toma la contraseña que ya se estableció en Active Directory.
-UseExistingPassword: Este modificador indica a SharePoint que sincronice su configuración con esta contraseña existente de AD.5 Es extremadamente útil si los administradores de AD cambian las contraseñas de forma independiente.
El parámetro -UseExistingPassword de Set-SPManagedAccount es particularmente crucial para entornos donde los cambios de contraseña de AD pueden ser iniciados por un equipo de seguridad separado o un proceso automatizado de AD, fuera del control directo del administrador de SharePoint. Esto permite que SharePoint se "ponga al día" y se resincronice, evitando interrupciones prolongadas del servicio.13 Sin este parámetro, el administrador de SharePoint tendría que hacer que SharePoint cambiara la contraseña (lo que podría entrar en conflicto con el proceso del equipo de seguridad) o enfrentarse a una desincronización.



Escenario 3: Configurar la Generación Automática de ContraseñasSharePoint puede generar automáticamente contraseñas seguras y aleatorias para las cuentas administradas y cambiarlas según una programación.
PowerShell# Obtener la cuenta administrada
$managedAccount = Get-SPManagedAccount -Identity "DOMINIO\CuentaServicioAdministrada"

# Configurar el cambio automático de contraseña
Set-SPManagedAccount -Identity $managedAccount -AutoGeneratePassword $true -Schedule "weekly at Saturday 02:00" -PreExpireDays 7 -EmailNotification 5

Explicación:

-AutoGeneratePassword $true: Habilita la característica de generación automática de contraseñas.
-Schedule: Define la programación para el cambio (ej. "semanalmente el sábado a las 02:00"). Se pueden usar formatos como "daily at HH:MM", "weekly on DayOfWeek at HH:MM", "monthly on DayOfMonth at HH:MM".14
-PreExpireDays: Especifica cuántos días antes de la expiración de la contraseña en AD SharePoint debe iniciar el cambio. El valor predeterminado es 2.13
-EmailNotification: Especifica cuántos días antes del cambio se enviarán notificaciones por correo electrónico (si las notificaciones por correo electrónico están configuradas a nivel de granja). El valor predeterminado es 5.5
Para una programación más granular (por ejemplo, un día específico del mes), se puede crear un objeto SPMonthlySchedule y asignarlo a la propiedad ChangeSchedule de la cuenta administrada.14


8.2. Scripts de Muestra y ExplicacionesA continuación, se muestra un script de ejemplo que podría leer una lista de cuentas administradas desde un archivo CSV y actualizar sus contraseñas en SharePoint utilizando el método -UseExistingPassword, asumiendo que las contraseñas ya se han cambiado en AD.Archivo CSV de entrada (ej. CuentasSP.csv):Fragmento de códigoSamAccountName,NuevaPasswordAD
DOMINIO\sp_servicio1,NuevaPassServ1!
DOMINIO\sp_servicio2,OtraPassServ2*
Script de PowerShell:PowerShell# Importar cuentas y contraseñas desde CSV
$cuentasParaActualizar = Import-Csv -Path "C:\Ruta\A\CuentasSP.csv"

foreach ($cuentaInfo in $cuentasParaActualizar) {
    $samAccountName = $cuentaInfo.SamAccountName
    $nuevaPasswordAD = $cuentaInfo.NuevaPasswordAD

    Write-Host "Procesando cuenta: $samAccountName" -ForegroundColor Yellow

    # Convertir la nueva contraseña a SecureString
    $securePassword = ConvertTo-SecureString $nuevaPasswordAD -AsPlainText -Force

    # Obtener la cuenta administrada
    $managedAccount = Get-SPManagedAccount -Identity $samAccountName -ErrorAction SilentlyContinue

    if ($managedAccount) {
        try {
            Write-Host "Actualizando contraseña para $samAccountName en SharePoint..."
            Set-SPManagedAccount -Identity $managedAccount -ExistingPassword $securePassword -UseExistingPassword -ErrorAction Stop
            Write-Host "Contraseña para $samAccountName actualizada exitosamente en SharePoint." -ForegroundColor Green
        }
        catch {
            Write-Host "Error al actualizar la contraseña para $samAccountName en SharePoint: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Cuenta administrada $samAccountName no encontrada en SharePoint." -ForegroundColor Red
    }
}
Write-Host "Proceso completado."
Este script incluye manejo básico de errores y retroalimentación en la consola.Script para listar todas las cuentas administradas y su configuración de cambio automático:PowerShellGet-SPManagedAccount | Select-Object UserName, AutomaticChange, @{Name="ChangeSchedule"; Expression={$_.ChangeSchedule.ToString()}}, DaysBeforeExpiryToChange, EnableEmailBeforePasswordChange, DaysBeforeChangeToEmail | Format-Table -AutoSize
8.3. Scripting de stsadm -o updatefarmcredentials (para la Cuenta de la Granja)Aunque stsadm.exe es una herramienta de línea de comandos, su ejecución puede encapsularse en un script de PowerShell, lo cual es especialmente útil si se necesita ejecutar en múltiples servidores de forma remota utilizando Invoke-Command.PowerShell# --- Script para actualizar credenciales de la cuenta de la granja en todos los servidores ---

# Definir la cuenta de la granja y solicitar la nueva contraseña de forma segura
$farmAccountLogin = "DOMINIO\CuentaDeLaGranja" # Reemplazar con el login real
$newPasswordSecure = Read-Host "Ingrese la nueva contraseña para la cuenta de la granja ($farmAccountLogin)" -AsSecureString

# Convertir la SecureString a texto plano (necesario para stsadm.exe)
# ADVERTENCIA: Manejar con cuidado. Limitar el alcance de la variable de texto plano.
$BSTR =::SecureStringToBSTR($newPasswordSecure)
$plainPassword =::PtrToStringAuto($BSTR)
::ZeroFreeBSTR($BSTR) # Liberar memoria

# Obtener todos los servidores de la granja (excluyendo roles inválidos como SQL)
$spServers = Get-SPServer | Where-Object {$_.Role -ne "Invalid" -and $_.Role -ne "SingleServer"} # Ajustar filtro si es necesario
if ((Get-SPServer | Where-Object {$_.Role -eq "SingleServer"}).Count -eq 1 -and $spServers.Count -eq 0) {
    $spServers = Get-SPServer | Where-Object {$_.Role -eq "SingleServer"} # Caso de granja de un solo servidor
}


if ($spServers.Count -eq 0) {
    Write-Error "No se encontraron servidores de SharePoint válidos en la granja."
    exit
}

Write-Host "Se actualizarán las credenciales en los siguientes servidores:"
$spServers | ForEach-Object { Write-Host "- $($_.Address)" }

foreach ($server in $spServers) {
    $serverName = $server.Address
    Write-Host "Actualizando credenciales de la granja en el servidor: $serverName..."
    try {
        Invoke-Command -ComputerName $serverName -ScriptBlock {
            param($login, $password)
            # Ruta a stsadm.exe para SharePoint 2013 (versión 15)
            $stsadmPath = Join-Path $env:CommonProgramFiles "Microsoft Shared\Web Server Extensions\15\BIN\STSADM.EXE"
            
            if (Test-Path $stsadmPath) {
                & $stsadmPath -o updatefarmcredentials -userlogin $login -password $password
            } else {
                Write-Error "stsadm.exe no encontrado en la ruta esperada en $using:serverName."
            }
        } -ArgumentList $farmAccountLogin, $plainPassword -ErrorAction Stop
        Write-Host "Credenciales actualizadas exitosamente en $serverName." -ForegroundColor Green
    }
    catch {
        Write-Host "Error al actualizar credenciales en $serverName: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Limpiar la variable de contraseña en texto plano de la memoria lo antes posible
Clear-Variable plainPassword
Write-Host "Proceso de actualización de credenciales de la granja completado."
Precaución: El manejo de contraseñas en texto plano, incluso temporalmente como en el script anterior para stsadm.exe, requiere sumo cuidado. SecureString debe usarse tanto como sea posible. El ejemplo convierte la contraseña a texto plano porque stsadm.exe no acepta SecureString directamente. Es fundamental limitar el alcance y la vida útil de la variable de contraseña en texto plano.Aunque PowerShell ofrece una potente automatización para las cuentas administradas, la dependencia de stsadm.exe para la contraseña de la cuenta de la granja evidencia una ligera inconsistencia arquitectónica o un remanente heredado en las herramientas de administración de SharePoint 2013. Un enfoque totalmente centrado en PowerShell para todos los tipos de cuenta sería más ágil y coherente.6 La necesidad de cambiar a stsadm.exe para una cuenta crítica, especialmente una que debe ejecutarse en todos los servidores, interrumpe ligeramente el flujo de automatización de PowerShell y requiere un manejo diferente (por ejemplo, la ejecución remota de un archivo .exe en lugar de cmdlets nativos).9. Verificación Posterior al Cambio y Solución de ProblemasUna vez completada la actualización de contraseñas, es crucial verificar la funcionalidad de la granja y estar preparado para solucionar cualquier problema.9.1. Validación de la Funcionalidad del ServicioSe debe realizar una comprobación sistemática de todos los servicios y funcionalidades clave de SharePoint:
Acceso a la Administración Central: Asegurarse de que el sitio web de Administración Central sea accesible y operativo.
Acceso a Aplicaciones Web: Navegar a las principales aplicaciones web de contenido y verificar que se cargan correctamente.
Funcionalidad de Búsqueda: Realizar consultas de búsqueda y verificar que devuelven resultados. Revisar los registros de rastreo para confirmar que los nuevos rastreos (si se inician) se completan con éxito.
Sincronización de Perfiles de Usuario: Verificar que el Servicio de Sincronización de Perfiles de Usuario esté en ejecución. Comprobar si los perfiles de usuario son accesibles y si las actualizaciones de AD se reflejan (puede requerir un ciclo de sincronización).
Grupos de Aplicaciones en IIS: Abrir el Administrador de IIS en los servidores WFE y de aplicaciones y confirmar que todos los grupos de aplicaciones de SharePoint estén iniciados.
Servicios Específicos: Probar la funcionalidad de servicios como Servicios de Excel, PerformancePoint, Almacén Seguro, etc., si sus cuentas asociadas fueron modificadas.
Trabajos del Temporizador: Revisar el estado de los trabajos del temporizador importantes (Historial de trabajos del temporizador en Administración Central) o ejecutar manualmente algunos trabajos clave para probar su funcionamiento.
9.2. Comprobación de Registros de Eventos en busca de ErroresMonitorear activamente los registros de eventos de Windows (Aplicación, Sistema y Seguridad) en todos los servidores de SharePoint y en los Controladores de Dominio.Buscar específicamente:
Intentos de inicio de sesión fallidos: Event ID 4625 en los registros de Seguridad de los Controladores de Dominio y servidores de SharePoint.2 Estos eventos suelen indicar qué cuenta está fallando, desde qué servidor y a qué recurso.
Fallos de autenticación NTLM: Event ID 4776 en los Controladores de Dominio.2
Errores específicos de SharePoint: Revisar los registros ULS (Unified Logging Service) de SharePoint para obtener información detallada sobre errores internos. Aunque no se mencionan directamente en los fragmentos para este contexto, son una fuente primordial para la solución de problemas de SharePoint.
Errores del Administrador de Control de Servicios (Service Control Manager): Eventos que indican que los servicios no pudieron iniciarse (a menudo en el registro del Sistema).
Una monitorización proactiva de los registros inmediatamente después de los cambios puede acortar significativamente el tiempo de detección y resolución de problemas. Un patrón de mensajes de error específicos en los registros de eventos (por ejemplo, repetidos Event ID 4625 desde un servidor de SharePoint particular para una cuenta de servicio específica) puede señalar rápidamente dónde reside un desajuste de contraseña, incluso antes de que las pruebas funcionales revelen un problema.9.3. Problemas Comunes y Pasos para la Solución de Problemas
Desajuste de Contraseña (Password Mismatch):

Síntoma: El servicio no se inicia, errores de "acceso denegado" en los registros, funcionalidad interrumpida.
Solución:

Verificar que la contraseña en Active Directory es la correcta y que la cuenta no está bloqueada.
Volver a ingresar la contraseña en la configuración de SharePoint:

Para cuentas administradas: Usar la opción "Usar contraseña existente" en Configurar Cuentas Administradas.5
Para la cuenta de la granja: Asegurarse de que stsadm -o updatefarmcredentials se haya ejecutado en todos los servidores.
Para cuentas no administradas: Actualizar la contraseña en la página de configuración de la aplicación de servicio correspondiente o en la identidad del grupo de aplicaciones de IIS.






Acceso Denegado para la Cuenta de la Granja o Cuentas de Servicio Administrativas:

Síntoma: No se puede acceder a la Administración Central, los cmdlets de PowerShell fallan con errores de acceso.
Solución:

En Active Directory, para la cuenta afectada, asegurarse de que la opción "El usuario no puede cambiar la contraseña" NO esté marcada y que "La contraseña nunca expira" esté marcada (a menos que se gestione activamente la expiración).10
Verificar la contraseña de la cuenta de la granja con stsadm -o updatefarmcredentials en todos los servidores.
Para otras cuentas administradoras, verificar su contraseña en Configurar Cuentas Administradas.
Comprobar las directivas de seguridad locales o GPOs que puedan estar restringiendo el inicio de sesión como servicio o el acceso a la red para la cuenta.




El Servicio de Sincronización de Perfiles de Usuario (UPSS) no se Inicia:

Solución:

Verificar la contraseña de la cuenta del UPSS en "Administrar servicios en el servidor".
Asegurarse de que los servicios de Forefront Identity Manager (FIM) en el servidor UPSS (Servicio de Forefront Identity Manager y Servicio de Sincronización de Forefront Identity Manager) puedan iniciarse con las nuevas credenciales. Sus contraseñas se actualizan cuando se inicia el servicio UPSS desde SharePoint.
Verificar los permisos de la cuenta del UPSS en Active Directory (por ejemplo, permisos de "Replicating Directory Changes" en el dominio/OU que se está sincronizando).
Revisar los registros de eventos y ULS en el servidor UPSS para obtener errores específicos.




Los Rastreos de Búsqueda Fallan:

Solución:

Verificar la contraseña de la cuenta de acceso a contenido predeterminada en la configuración de la Aplicación de Servicio de Búsqueda.
Verificar las contraseñas de cualquier cuenta de acceso a contenido definida en las reglas de rastreo.
Asegurarse de que la cuenta de acceso a contenido tenga los permisos de lectura necesarios sobre las fuentes de contenido.




Error "La contraseña no cumple los requisitos de la directiva de contraseñas":

Síntoma: Ocurre cuando SharePoint intenta establecer una contraseña en AD (ya sea a través del cambio automático de cuenta administrada o manualmente con "Establecer la contraseña de la cuenta en un valor nuevo").
Solución: Asegurarse de que la contraseña que SharePoint está intentando establecer (o la que se ingresó manualmente) cumpla con los requisitos de complejidad, longitud e historial de la directiva de contraseñas de Active Directory.10


Problemas de Inicio de Sesión de SharePoint Designer (generalmente relacionados con Autenticación Moderna, menos probable para cuentas de servicio en SP2013 on-premise):
El fragmento 16 discute problemas con ADAL en SharePoint Designer 2013 y Office 2013, típicamente en escenarios de nube o autenticación moderna. Aunque menos directamente relevante para los cambios de contraseña de cuentas de servicio on-premise, destaca que las herramientas cliente también pueden tener problemas de caché de credenciales. Si se experimentan problemas con herramientas cliente después de cambios de contraseña (aunque no sea de cuentas de servicio), borrar los cachés locales de estas herramientas puede ser un paso de solución de problemas general.16
Una solución de problemas eficaz después del cambio depende en gran medida de la calidad de la documentación previa al cambio (Sección 5.1). Si no se sabe qué servicios utilizan qué cuentas, identificar la causa de un fallo se convierte en un proceso mucho más lento y de prueba y error. El "Inventario de Cuentas de Servicio y Mapa de Dependencias" es invaluable aquí. Si un servicio falla, la primera pregunta es "¿Qué cuenta utiliza este servicio?". Si el inventario es preciso, el administrador puede verificar rápidamente si la contraseña de esa cuenta específica se actualizó correctamente tanto en AD como en SharePoint.10. Recomendaciones y Mejores PrácticasPara asegurar un proceso de gestión de contraseñas de cuentas de servicio robusto y seguro a largo plazo, se recomiendan las siguientes prácticas:10.1. Implementar Cuentas Administradas de SharePoint ExtensivamenteSe recomienda encarecidamente utilizar la característica de cuentas administradas de SharePoint para tantas cuentas de servicio como sea posible. Esto permite cambios de contraseña centralizados y automáticos, reduciendo el esfuerzo manual, el riesgo de error humano y la probabilidad de desincronización.110.2. Políticas de Rotación Regular de ContraseñasEstablecer y adherirse a un programa regular para cambiar las contraseñas de las cuentas de servicio, incluso si se utiliza la opción "la contraseña nunca expira" en Active Directory. Esto se alinea con las mejores prácticas generales de seguridad para limitar la ventana de exposición en caso de que una contraseña se vea comprometida.1 La frecuencia puede depender de la política organizacional y el riesgo percibido (por ejemplo, cada 60, 90 o 180 días). La documentación sugiere que la frecuencia depende del entorno y las necesidades, siendo un cambio anual una posible base si la cuenta no se comparte extensamente.1710.3. Principio de Menor Privilegio para Cuentas de ServicioReiterar y aplicar consistentemente el principio de menor privilegio: otorgar solo los permisos mínimos necesarios a cada cuenta de servicio en Active Directory, SQL Server y SharePoint.2 Evitar el uso de cuentas altamente privilegiadas, como la cuenta de administrador de la granja, para múltiples servicios si existen alternativas con menos privilegios.10.4. Documentación y Mantenimiento de RegistrosMantener una documentación actualizada de todas las cuentas de servicio, sus propósitos, las contraseñas (almacenadas de forma segura, por ejemplo, en una bóveda de contraseñas), y las fechas del último cambio.2 Documentar el procedimiento completo de cambio de contraseña seguido en cada ocasión.10.5. Probar en un Entorno de PreproducciónSi se dispone de una granja de preproducción o pruebas representativa, probar siempre el procedimiento de actualización de contraseñas allí antes de aplicarlo a producción.2 Esto ayuda a identificar problemas imprevistos, validar scripts y familiarizar al personal con el proceso.La recomendación de "Probar en un Entorno de Preproducción" 2 es a menudo un desafío para SharePoint on-premise debido a la complejidad y el costo de mantener una granja de ensayo verdaderamente idéntica. Sin embargo, incluso una granja de pruebas parcialmente representativa (por ejemplo, con el mismo nivel de parches y las aplicaciones de servicio clave) puede descubrir fallos de procedimiento o errores de script, lo que la convierte en una actividad valiosa de reducción de riesgos. Es mejor que ninguna prueba.10.6. Usar Contraseñas Fuertes y ÚnicasAsegurar que todas las nuevas contraseñas sean criptográficamente fuertes (combinación de mayúsculas, minúsculas, números y símbolos), únicas para cada cuenta, y que cumplan o superen las políticas de longitud y complejidad del dominio.110.7. Planificar la Replicación de Active DirectoryAl cambiar contraseñas en Active Directory, tener en cuenta la latencia de replicación de AD, especialmente en entornos con múltiples sitios de AD. Asegurarse de que el cambio de contraseña se haya replicado a los Controladores de Dominio que utilizan los servidores de SharePoint para la autenticación antes de actualizar la contraseña en SharePoint (si se realiza un cambio manual en AD y luego la actualización en SharePoint). Esto puede requerir forzar la replicación o esperar un tiempo prudencial.10.8. Utilizar una Bóveda de Contraseñas (Password Vault)La adopción de una "bóveda de contraseñas" para almacenar las credenciales de las cuentas de servicio es una medida de seguridad operativa crítica. Evita que las contraseñas se escriban en texto plano en scripts o documentos inseguros y proporciona una forma auditable de gestionar el acceso a estas poderosas credenciales. Aunque la consulta inmediata del usuario es sobre el proceso de cambio de contraseñas, una recomendación holística debe incluir cómo gestionar estas contraseñas de forma segura a lo largo de su ciclo de vida. Una bóveda de contraseñas es la mejor práctica de la industria para esto.2Siguiendo estas directrices y procedimientos, la administración de las contraseñas de las cuentas de servicio de SharePoint 2013 puede llevarse a cabo de manera más segura y eficiente, minimizando el riesgo para la estabilidad y seguridad de la plataforma.