# actividad_menu

Aplicación móvil desarrollada en Flutter que permite la creación y gestión de cuentas de usuarios. La aplicación incluye funciones de creación de cuentas, listados de usuarios y un sistema de autenticación mediante una pantalla de login. Está diseñada para facilitar la administración de usuarios con una interfaz simple y opciones de navegación eficientes.

Características
Pantalla de Login: Permite a los usuarios iniciar sesión ingresando su correo electrónico y contraseña.
Creación de cuentas: Los usuarios pueden registrar sus datos personales, como nombre, correo, dirección, número de celular y fecha de nacimiento.
Listado de usuarios: Muestra una lista de usuarios registrados en la base de datos local SQLite, con opciones de búsqueda y filtrado.
API externa: Opción para obtener datos aleatorios de una API para la creación de cuentas de manera más rápida.
Menú lateral de navegación: Acceso rápido a las principales secciones de la aplicación.
Almacenamiento en SQLite: Los datos de los usuarios se almacenan localmente en una base de datos SQLite.
Estructura del Proyecto
El proyecto consta de las siguientes pantallas:

Pantalla de Login (login_screen.dart):
Permite a los usuarios autenticarse verificando su correo y contraseña almacenados en la base de datos local.

Pantalla Principal (main.dart):
Barra de navegación superior con un menú lateral que da acceso a las secciones de "Inicio", "Creación de Cuenta" y "Listado de Usuarios".

Pantalla de Creación de Cuenta (creacion_cuenta_screen.dart):
Permite a los usuarios registrar una nueva cuenta ingresando sus datos.
Opción para obtener datos de un usuario aleatorio desde la API https://randomuser.me/api/.

Pantalla de Listado (listado_screen.dart):
Muestra un listado de los usuarios registrados con una opción de búsqueda.
Los usuarios se listan con sus datos personales y pueden seleccionarse para ver detalles o eliminarlos.

Pantalla de Detalles de Cuenta (detalle_cuenta_screen.dart):
Muestra los detalles completos de un usuario y permite eliminar su cuenta de la base de datos.
Instalación y Configuración

Clonar el repositorio:
bash
Copiar código
git clone https://github.com/tu-usuario/actividad_menu.git
cd actividad_menu
Instalar dependencias:

bash
Copiar código
flutter pub get
Ejecutar la aplicación:

bash
Copiar código
flutter run
Dependencias
Las siguientes dependencias se utilizan en este proyecto:

sqflite: Para manejar la base de datos SQLite.
path_provider: Para obtener la ruta del directorio de documentos en dispositivos móviles.
http: Para hacer solicitudes HTTP a la API externa.
flutter_masked_text2: Para aplicar máscaras en campos de texto, como el formato de fecha.
