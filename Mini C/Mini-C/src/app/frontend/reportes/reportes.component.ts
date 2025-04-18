import { Component, OnInit } from "@angular/core";
import { CommonModule } from "@angular/common";
import { ErrorService } from "../../backend/parser.service";

@Component ({
    selector: 'app-reportes',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './reportes.component.html',
    styleUrls: ['./reportes.component.css']
})

export class ReporteComponent implements OnInit {
    errores: any[] = [];
  
    constructor(private errorService: ErrorService) {}
  
    ngOnInit(): void {
      this.errores = this.errorService.getErrores();
    }
  }