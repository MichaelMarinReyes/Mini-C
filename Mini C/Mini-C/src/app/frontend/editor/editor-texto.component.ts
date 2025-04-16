import { Component, ViewChild, ElementRef, AfterViewInit, OnInit } from "@angular/core";
import { FormsModule } from "@angular/forms";
import { CommonModule } from "@angular/common";

import * as parser from '../../../utils/parser.js';

@Component({
  selector: 'app-editor-codigo',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './editor-texto.component.html',
  styleUrls: ['./editor-codigo.component.css']
})
export class EditorTextoComponent implements AfterViewInit, OnInit {
  texto: string = '';
  lineas: number[] = [1];
  lineaCursor = 1;
  columnaCursor = 1;
  salidaConsola: string = 'Prueba de consola';
  error: string = "";
  tablaSymbolos: Map<string, { value: AnalyserNode, type: String, location: any }> = new Map();
  estructuraArchivos: ArchivoNodo[] = [];

  @ViewChild('editor') editor!: ElementRef<HTMLTextAreaElement>;

  ngOnInit(): void {
    this.actualizarLineas();
  }

  ngAfterViewInit(): void {
    this.actualizarPosicionCursor();
  }

  onInput() {
    this.actualizarLineas();
    this.actualizarPosicionCursor();
  }

  actualizarLineas() {
    const cuentaLinea = this.texto.split('\n').length;
    this.lineas = Array.from({ length: cuentaLinea }, (_, i) => i + 1);
  }

  actualizarPosicionCursor() {
    const textArea = this.editor.nativeElement;
    const posicion = textArea.selectionStart;
    const textUptoCursor = this.texto.substring(0, posicion);
    const lineas = textUptoCursor.split('\n');

    this.lineaCursor = lineas.length;
    this.columnaCursor = lineas[lineas.length - 1].length + 1;
  }

  sincronizarScroll(event: Event) {
    const target = event.target as HTMLTextAreaElement;
    const lineasDiv = document.querySelector('.numero-linea') as HTMLDivElement;
    if (lineasDiv) {
      lineasDiv.scrollTop = target.scrollTop;
    }
  }

  obtenerTexto(): any {
    this.salidaConsola = this.texto;
    try {
      const resultado = parser.parse(this.texto);
      this.salidaConsola = resultado.salida;
      this.error = resultado.error;
      this.tablaSymbolos = resultado.tablaSimbolos;
      console.log('parseado sin errores');
      this.salidaConsola = "parseo sin errores";
    } catch (error: any) {
      this.salidaConsola = 'Error: ' + error.message;
      console.log(error.message);
    }
  }

  async abrirCarpeta() {
    try {
      const dirHandle = await (window as any).showDirectoryPicker();
      this.estructuraArchivos = await this.recorrerDirectorio(dirHandle);
    } catch (error) {
      console.error('Error al abrir carpeta:', error);
    }
  }

  private async recorrerDirectorio(dirHandle: FileSystemDirectoryHandle): Promise<ArchivoNodo[]> {
    const nodos: ArchivoNodo[] = [];

    for await (const [, handle] of dirHandle.entries()) {
      if (handle.kind === 'file' && handle.name.endsWith('.cmm')) {
        nodos.push({ nombre: handle.name, archivo: handle as FileSystemFileHandle });
      } else if (handle.kind === 'directory') {
        const hijos = await this.recorrerDirectorio(handle as FileSystemDirectoryHandle);
        nodos.push({ nombre: handle.name, hijos });
      }
      
    }

    return nodos;
  }

  async abrirArchivo(archivoHandle: FileSystemFileHandle) {
    try {
      const archivo = await archivoHandle.getFile();
      const contenido = await archivo.text();
      this.texto = contenido;
      this.actualizarLineas();
    } catch (error) {
      console.error('Error al leer archivo:', error);
    }
  }
}

interface ArchivoNodo {
  nombre: string;
  archivo?: FileSystemFileHandle;
  hijos?: ArchivoNodo[];
}