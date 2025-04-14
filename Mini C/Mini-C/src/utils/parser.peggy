{{ 
    let memoria = new Map();
    let salida = "";
    let errorSalida = "";

    function setVariable(id, valor, tipo, linea, columna) {
        memoria.set(id, {value: valor, type: tipo, location: {line: linea, col: columna}})
    }

    function getVariable(id) {
        let registro = memoria.get(id)
        if (!registro) {
            añadirError("Variable " + id + " no está definida", location())
            return null
        }
        return registro.valor
    }

    function salidaTexto(linea) {
        if (salida !== "") {
            salida += "\n";
        }
        salida += linea;
    }

    function añadirError(errorMensaje, location) {
        if (errorSalida !== "") {
            errorSalida += "\n";
        }
        let inicioColumna = location.start.column;
        let finColumna = location.end.column;
        let line = location.start.line;
        errorSalida += `Error en la linea ${line}:${inicioColumna}:${finColumna}. ${errorMensaje}`;
    }
}}

{
    memoria.clear();
    salida = "";
    errorSalida = "";
}

inicio "inicio"
    = (lenguajes _?) {
        return { salida: salida, error: errorSalida, symTable: memoria };
    }

lenguajes 
    = estructuraYAML
    / miniC

estructuraYAML
    = comentario* np:nombreProyecto comentario* _ main:main comentario* _ mods:moduloBloque* comentario* {
        return {
            nombre_proyecto: np,
            main: main,
            modulos: mods
        };
    }

nombreProyecto
    = "nombre_proyecto" _ ":" _ "\"" nombre:variable "\"" _ {
        memoria.set("nombre_proyecto", nombre);
        return nombre;
    }

main
    = "main" _ ":" _ "\"" archivo:variable ".cmm" "\"" {
        const ruta = archivo + ".cmm";
        memoria.set("main", ruta);
        return ruta;
    }

moduloBloque
    = nombre:variable _ ":" _ archivos:archivoModulo+ {
        let mod = {};
        archivos.forEach(a => mod[a.nombre] = a.archivo);
        memoria.set(nombre, mod);
        return { nombre, archivos: mod };
    }


archivoModulo
    = _ "-" nombre:variable _ ":" _ "\"" archivo:variable ".cmm" "\"" _ {
        return { nombre, archivo: archivo + ".cmm" };
    }


comentario
    = _ "#" [^\n]* ("\n" / !.) { return null; }

variable
    = l:[a-zA-Z_] r:[a-zA-Z0-9_]* { return l + r.join(""); }

miniC = "mini"

_ "WS"
    = [ \t\r\n]*

EOF = !.