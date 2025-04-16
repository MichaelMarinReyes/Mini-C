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
  { return {nombre: np, main: main, modulos: mods}; }

nombreProyecto "nombre proyecto"
  = comentario* "nombre_proyecto" _ ":" _ "\"" nombre:variable "\"" comentario*
  { return nombre; }
  
main "main"
  = comentario* "main" _ ":" _ "\"" _ archivo:variable ".cmm" _ "\"" comentario*
  { return archivo + ".cmm"; }
  
modulos "modulos"
	= comentario* "modulo" numero ":" "\n" archivos:lista* comentario* 
  { return archivos.flat(); }
    
lista "lista"
	= comentario* "archivo" numero _ ":" _ "\"" _ archivo:variable ".cmm" "\"" "\n"* comentario*
  { return [archivo - ".cmm"]; }

comentario "comentario"
  = _ "#" [^\n]* ("\n" / !.) { return null; }

//Parser para Mini C
miniC "Bloque Mini C"
  = cuerpoMiniC*

metodoMain "main"
  = "void" _ "main" _ "(" _ ")" _ "{" _ cuerpo:sentencia* _ "}" _ {
      return { tipo: "main", cuerpo };
  }

sentencia
  = declaracionVariables
  / asignacionVariable

declaracionVariables "declaración de variables"
  = tipo:tipoVariable _ nombre:variable _ "=" _ valor:expresion _ ";" {
      return { tipo: "declaracion", tipoVar: tipo, nombre, valor };
  }

asignacionVariable "asignación"
  = nombre:variable _ "=" _ valor:expresion _ ";" {
      return { tipo: "asignacion", nombre, valor };
  }

tipoVariable "tipo"
  = "int"
  / "float"
  / "string"
  / "char"
  / "bool"

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
  
cuerpoMiniC
	= structs
    / impresionConsola
    / funciones

structs "structs"
	= "struct" _ variable _ "{" ( _ tipoVariable _ variable _ ";" _ )* "}" _
    
impresionConsola "print"
	= "print" _ "(" _ "\"" _ variable* _ ("$"_ "{"_ variable _ "}" _ )* "\"" _ ")" _ ";"
    / "print" _ "(" _ variable _ ")" _ ";"
    / "print" _ "(" (_ variable* _ "{" _ variable _ "}" _)* ";"
    
funciones "función"
	= tipoVariable _ variable _ "(" _ (parametros)* _ ")" _ "{" _ declaracionStruct* _ "return" _ variable _ ";" _ "}"
    / "void" _ variable _ "(" _ (parametros)* _ ")" _ "{" _ declaracionStruct* _ "}"
    
    
declaracionStruct "variables de struct"
	= tipoVariable _ variable _ ";"

parametros "parametros"
	= tipoVariable _ variable _ ("," _ tipoVariable _ variable _ )*

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