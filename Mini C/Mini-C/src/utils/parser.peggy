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
  / comentario
  / declaracionVariables

//Parser para YAML
estructuraYAML "yml"
  = np:nombreProyecto _ main:main _ mods:modulos* _

nombreProyecto "nombre proyecto"
  = comentario* "nombre_proyecto" _ ":" _ "\"" nombre:variable "\"" comentario*
  
main "main"
  = comentario* "main" _ ":" _ "\"" _ variable ".cmm" _ "\"" comentario*
  
modulos "modulos"
	= comentario* "modulo" numero ":" "\n" lista* comentario*
    
lista "lista"
	= comentario* "archivo" numero _ ":" _ "\"" _ variable ".cmm" "\"" "\n"* comentario*

comentario "comentario"
  = _ "#" [^\n]* ("\n" / !.) { return null; }

//Parser para Mini C
miniC "bloque Mini C"
  = metodoMain

metodoMain "main"
  = "void" _ "main" _ "(" _ ")" _ "{" _ sentencia _ "}"

sentencia
  = declaracionVariables*
  / asignacionVariable

declaracionVariables "declaración de variables"
  = tipo:tipoVariable _ nombre:variable _ "=" _ valor:expresion _ ";" {
      return { tipo: "declaracion", tipoVar: tipo, nombre, valor };
  }

asignacionVariable "asignación"
  = nombre:variable _ "=" _ valor:expresion {
      return { tipo: "asignacion", nombre, valor };
  }

tipoVariable "tipo"
  = "int"
  / "float"
  / "string"
  / "char"
  / "bool"
  / "struct"

expresion "expresión"
  = sumaResta

sumaResta
  = izq:multiplicacionDivision _ op:("+" / "-") _ der:sumaResta {
      return { tipo: "op", op, izq, der };
  }
  / multiplicacionDivision

multiplicacionDivision
  = izq:potencia _ op:("*" / "/") _ der:multiplicacionDivision {
      return { tipo: "op", op, izq, der };
  }
  / potencia multiplicacionImplicita*

multiplicacionImplicita
  = _ der:potencia { return der; }

potencia
  = izq:unario _ "^" _ der:potencia {
      return { tipo: "op", op: "^", izq, der };
  }
  / unario

unario
  = "-" _ valor:unario {
      return { tipo: "unario", op: "-", valor };
  }
  / primario

primario
  = "(" _ expr:sumaResta _ ")"
  / numero
  / variable
  / cadena
  / caracter
  / boolean


numero "número"
  = n:([0-9]+ ("." [0-9]+)?) {
      return parseFloat(n.join(""));
  }

cadena "string"
  = '"' txt:[^"\n\r"]* '"' {
      return txt.join("");
  }

caracter "char"
  = "'" c:[a-zA-Z0-9] "'" {
      return c;
  }

boolean "booleano"
  = "true"  { return true; }
  / "false" { return false; }

variable "variable"
  = v:[a-zA-Z_][a-zA-Z0-9_]*

_ "whitespace"
  = [ \t\n\r]*