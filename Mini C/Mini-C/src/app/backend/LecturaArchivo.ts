interface ArchivoGenerado {
    nombre: string;
    contenido: string;
  }
  
  export function procesarYML(data: any): ArchivoGenerado[] {
    const archivos: ArchivoGenerado[] = [];
  
    const nombreProyecto = data.nombre;
    const mainArchivo = data.main;
  
    if (nombreProyecto && mainArchivo) {
      archivos.push({
        nombre: `${nombreProyecto}/${mainArchivo}`,
        contenido: "// Archivo principal generado automáticamente"
      });
    }
  
    if (Array.isArray(data.modulos)) {
      data.modulos.forEach((modulo: any[], index: number) => {
        modulo.forEach((archivo: string) => {
          archivos.push({
            nombre: `${nombreProyecto}/modulo${index + 1}/${archivo}`,
            contenido: `// Archivo ${archivo} generado automáticamente\n`
          });
        });
      });
    }
  
    return archivos;
  }
