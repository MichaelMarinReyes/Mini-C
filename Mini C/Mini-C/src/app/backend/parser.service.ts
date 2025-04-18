import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class ErrorService {
  private errores: any[] = [];

  setErrores(errores: any[]): void {
    this.errores = errores;
  }

  getErrores(): any[] {
    return this.errores;
  }

  limpiar(): void {
    this.errores = [];
  }
}
