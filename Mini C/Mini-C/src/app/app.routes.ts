import { Routes } from '@angular/router';
import { InicioComponent } from './frontend/paginaPrincipal/inicio/inicio.component';
import { EditorTextoComponent } from './frontend/editor/editor-texto.component';
import { ReporteComponent } from './frontend/reportes/reportes.component';

export const routes: Routes = [
    {path: '', redirectTo: 'inicio', pathMatch: 'full'},
    {path: 'inicio', title: 'Mini-C', component: InicioComponent},
    {path: 'editor', title: 'Editor', component: EditorTextoComponent },
    {path: 'reportes', title: 'Reportes', component: ReporteComponent}
];
