import { Routes } from '@angular/router';
import { EditorTextoComponent } from './frontend/editor/editor-texto.component';
import { ReporteComponent } from './frontend/reportes/reportes.component';

export const routes: Routes = [
    {path: '', redirectTo: 'editor', pathMatch: 'full'},
    {path: 'editor', component: EditorTextoComponent },
    {path: 'reportes', component: ReporteComponent}
];
