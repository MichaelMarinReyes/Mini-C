import { Component, ElementRef, ViewChild, HostListener } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import * as parser from '../utils/parser';
import { procesarYML } from '../app/backend/LecturaArchivo';
import { Router } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterModule, CommonModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})

export class AppComponent {
  constructor(private router: Router) { }

  title = 'Mini-C';
  menuArchivoVisible: boolean = false;

  @ViewChild('menuArchivo', {static: false}) menuArchivo!: ElementRef;
  @ViewChild('fileInput', {static: false}) fileInput!: ElementRef<HTMLInputElement>;

  toggleMenuArchivo() {
    this.menuArchivoVisible = !this.menuArchivoVisible;
  }

  @HostListener('document:click', ['$event'])
  clickFuera(event: MouseEvent) {
    const clickFuera = this.menuArchivo?.nativeElement.contains(event.target);
    if (!clickFuera) {
      this.menuArchivoVisible = false;
    }
  }

  nuevoArchivo() {
    alert("Nuevo proyecto");

  }

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
