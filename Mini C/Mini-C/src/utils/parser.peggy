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
  = _ lenguajes _ 

lenguajes "lenguajes"
  = estructuraYAML
  / miniC

estructuraYAML "yml"
  = np:nombreProyecto _ main:main _ mods:modulos* _

nombreProyecto "nombre proyecto"
  = "nombre_proyecto" _ ":" _ "\"" nombre:variable "\"" 
  
main "main"
  = "main" _ ":" _ "\"" _ "main.cmm" _ "\""
  
modulos "modulos"
	= "modulo" numero ":" "\n" lista*
    
lista "lista"
	= "archivo" numero _ ":" _ "\"" _ variable ".cmm" "\"" "\n"*


comentario "comentario"
  = _ "#" [^\n]* ("\n" / !.) { return null; }

miniC "mini c"
  = "hola"
    
variable "variable"
  = [a-zA-Z_]* [a-zA-Z0-9]*

numero "numero"
	= [0-9]*

_ "whitespace"
  = [ \t\n\r]*