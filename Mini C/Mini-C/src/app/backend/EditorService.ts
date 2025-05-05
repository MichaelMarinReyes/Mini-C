import { Injectable } from '@angular/core';
import { ArchivoCMM } from './ArchivoCMM';

@Injectable({ providedIn: 'root' })
export class EditorService {
  private archivos: ArchivoCMM[] = [];

  crearArchivo(archivo: ArchivoCMM) {
    this.archivos.push(archivo);
  }

  obtenerArchivos(): ArchivoCMM[] {
    return this.archivos;
  }
}
