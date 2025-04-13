import { Component, ViewChild, ElementRef, AfterViewInit } from "@angular/core";
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
  
export class EditorTextoComponent implements AfterViewInit {
    texto: string = '';
    lineas: number[] = [1];
    lineaCursor = 1;
    columnaCursor = 1;
    salidaConsola: string = 'Prueba de consola';

    @ViewChild('editor') editor!: ElementRef<HTMLTextAreaElement>;

    ngAfterViewInit(): void {
        this.actualizarPosicionCursor();
    }

    onInput() {
        const cuentaLinea = this.texto.split('\n').length;
        this.lineas = Array.from({ length: cuentaLinea });
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
        lineasDiv.scrollTop = target.scrollTop;
    }

    obtenerTexto() {
        this.salidaConsola = this.texto;
    }
}