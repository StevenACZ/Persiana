<p align="center"><img src="Assets/AppIcon.png" width="128" height="128" alt="Icono de Persiana"></p>
<h1 align="center">Persiana</h1>
<p align="center">Oculta los iconos de la barra de menús que no necesitas. Muéstralos con un clic.</p>
<p align="center"><a href="README.md">English</a> · <strong>Español</strong></p>
<p align="center">
  <img src="https://img.shields.io/badge/macOS-27%2B-black" alt="macOS 27+">
  <img src="https://img.shields.io/badge/Apple%20Silicon-arm64-black" alt="Apple Silicon">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="Licencia MIT"></a>
</p>

Persiana es una pequeña app de barra de menús para macOS 27. Aparta los iconos que
usas poco y los devuelve cuando los necesitas.

## Qué hace

- Oculta los iconos de las apps que elijas y los vuelve a mostrar con un clic.
- Los oculta de nuevo por sí sola cuando el puntero sale de la barra de menús, tras
  el tiempo que elijas: 2,5 s, 5 s, 10 s, 30 s o nunca.
- Usa su propio icono como límite, así que decides qué se oculta con el mismo
  arrastre con ⌘ que ya usas para ordenar la barra de menús.
- Te guía por el permiso de Accesibilidad y un tutorial animado la primera vez que
  la abres. El tutorial sigue disponible desde el menú.
- Habla inglés y español.
- Se mantiene al día: una versión nueva aparece en su menú y se instala con un
  clic.

## Cómo se usa

1. Mantén ⌘ y arrastra los iconos que quieras ocultar a la izquierda del icono de
   Persiana. Los iconos a su derecha siempre quedan visibles. La primera vez,
   Persiana pone su icono junto a los iconos de macOS, así que los iconos de las
   apps empiezan del lado oculto.
2. Haz clic en Persiana para mostrar los iconos ocultos.
3. Aleja el puntero de la barra de menús. Los iconos se ocultan de nuevo tras el
   tiempo elegido, o al instante si vuelves a hacer clic en Persiana.
4. Haz clic derecho (o Control-clic) en Persiana para abrir Configuración, Cómo
   funciona, Acerca de y Salir.

## Requisitos

- macOS 27 o posterior.
- Un Mac con Apple Silicon.
- Persiana debe ejecutarse desde `/Applications`. Si se ejecuta desde otra carpeta,
  incluida `~/Applications`, macOS también oculta el icono de Persiana.

## Instalación

1. Descarga el DMG más reciente de Persiana desde
   [Releases](https://github.com/StevenACZ/Persiana/releases/latest).
2. Ábrelo, arrastra Persiana a Aplicaciones y abre Persiana desde ahí.
3. Permite Persiana en Configuración del Sistema › Privacidad y seguridad › Accesibilidad
   cuando la ventana de configuración lo pida.
4. Sigue el tutorial breve y ordena tus iconos con ⌘ y arrastrar.

## Privacidad y actualizaciones

Persiana no pide Grabación de pantalla ni lee lo que escribes. Accesibilidad se usa
solo para leer dónde está cada icono de la barra de menús. Los ajustes quedan en tu
Mac. Consulta [seguridad y privacidad](SECURITY.md).

Su único acceso a la red es buscar actualizaciones en GitHub Releases. Cuando sale
una versión nueva, el menú de Persiana la ofrece y solo se instala cuando tú lo
eliges. Puedes apagar la búsqueda automática en Configuración › Actualizaciones.
Las versiones de desarrollo no usan el canal público de actualizaciones.

## Limitaciones

- Se oculta por app. Una app con varios iconos en la barra los oculta o muestra
  todos juntos.
- Los elementos propios de macOS, como el reloj, Wi-Fi, la batería y el Centro de
  control, siempre quedan visibles. Puedes desactivar la mayoría en Configuración
  del Sistema › Barra de menús.
- Persiana necesita macOS 27. En macOS 26 y anteriores, apps como Ice o Hidden Bar
  siguen funcionando con el divisor clásico.

## Compilar desde el código fuente

Requiere Xcode con el SDK de macOS 27 y una identidad de firma Apple Development.

```bash
make check
make install-dev
```

`make check` ejecuta el lint de formato, las pruebas y una compilación Release
firmada. `make install-dev` instala la compilación en `/Applications`. Consulta las
guías de [desarrollo](docs/development.md) y [contribuciones](CONTRIBUTING.md),
disponibles en inglés.

## Cómo funciona

En macOS 27 toda la barra de menús se dibuja en una sola ventana de MenuBarAgent,
así que el truco clásico de un divisor ancho que empuja los iconos fuera de la
pantalla ya no funciona. Persiana lee dónde está cada icono con la API de
Accesibilidad, solo posiciones. Después pide a macOS, mediante la restricción de
visibilidad privada de MenuBarClientCore que usa el modo de evaluación, que muestre
solo las apps del lado visible de su icono. macOS oculta el resto y reacomoda la
barra.

Si esa API privada no existe o falla, Persiana deja todo visible.

## Créditos

[Hidden Bar](https://github.com/dwarvesf/hidden), de Dwarves Foundation (MIT), usa
la misma técnica para macOS 27. El límite en Objective-C de Persiana hacia
MenuBarClientCore sigue el enfoque de Hidden Bar. Consulta los [avisos de terceros](THIRD_PARTY_NOTICES.md).

## Licencia

[MIT](LICENSE)
