import { Component } from '@angular/core';
import * as parser from '../../../../utils/parser.js'
import { procesarYML } from '../../../backend/LecturaArchivo';
import { Router } from '@angular/router';

@Component({
  selector: 'app-inicio',
  standalone: true,
  templateUrl: './inicio.component.html',
  styleUrl: './inicio.component.css'
})
export class InicioComponent {
  constructor(private router: Router) { }

  abrirArchivo(): void {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.yml';

    input.onchange = (event: Event) => {
      this.leerArchivoYML(event);
    };

    input.click();
  }

  public leerArchivoYML(event: Event): void {
    const input = event.target as HTMLInputElement;
    const archivo = input.files?.[0];
    if (!archivo) return;

    const reader = new FileReader();
    reader.onload = async () => {
      try {
        const contenido = reader.result as string;
        const resultado = parser.parse(contenido);
        console.log("Archivo YAML importado correctamente:", resultado);

        console.log("Estructura del proyecto parseado:", JSON.stringify(resultado, null, 2));

        const archivosGenerados = await procesarYML(resultado);
        console.log('Archivos para crear:', archivosGenerados);

        alert("Proyecto importado correctamente");
        this.router.navigate(['/editor']);
      } catch (error) {
        console.error("Error al importar el archivo:", error);
        alert("Error al leer el archivo. Consulta los reportes para más detalles.");
      }
    };

    reader.readAsText(archivo);
  }
}