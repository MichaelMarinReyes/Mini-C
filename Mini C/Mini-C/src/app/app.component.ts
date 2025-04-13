import { Component, ElementRef, ViewChild, HostListener } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterModule, CommonModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})

export class AppComponent {
  title = 'Mini-C';
  menuArchivoVisible: boolean = false;

  @ViewChild('menuArchivo', {static: false}) menuArchivo!: ElementRef;

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
}
