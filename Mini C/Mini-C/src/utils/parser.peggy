{{ 
    let memoria = new Map();
    let salida = "";
    let errorSalida = "";
    let errores = [];

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

    function añadirError(mensaje, location, tipo = "sintáctico") {
      errores.push({
          tipo,
          linea: location.start.line,
          columna: location.start.column,
          descripcion: mensaje
    });

    module.exports = {parse, getErrores(): () => errores};
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
  = metodoMain _ cuerpoMiniC*

metodoMain "main"
  = "void" _ "main" _ "(" _ ")" _ "{" _ cuerpo:sentencia* _ "}" _

sentencia
  = declaracionVariables _
  / asignacionVariable _
  / condicional _
  / impresionConsola _
  / funciones _
  / structs _

declaracionVariables "declaración de variables"
  = tipo:tipoVariable _ nombre:variable _ "=" _ valor:expresion _ ";" {
      return { tipo: "declaracion", tipoVar: tipo, nombre, valor };
  }

asignacionVariable "asignación"
  = nombre:variable _ "=" _ valor:expresion _ ";"
  / nombre:variable _ "=" _ valor:funcion

funcion
  = variable _ "(" _ ((variable / numero) _ ("," _ (variable / numero))*)? _ ")" _ ";"

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

// -> Contenido después del método main
cuerpoMiniC
  = structs _
  / impresionConsola _
  / funciones _

//-> Struct
structs "structs"
  = "struct" _ variable _ "{" ( _ tipoVariable _ variable _ ";" _ )* "}" _

impresionConsola "print"
  = "print" _ "(" _ "\"" _ variable* _ ("$" _ "{" _ variable _ "}" _ (variable _)*)* "\"" _ ")" _ ";" 
  / "print" _ "(" _ (variable _)* _ ")" _ ";"

//-> Funciones
funciones "función"
  = tipoVariable _ variable _ "(" _ (parametros)* _ ")" _ "{" _ contenidoFuncion* _ "return" _ variable _ ";" _ "}"
  / "void" _ variable _ "(" _ (parametros)* _ ")" _ "{" _ contenidoFuncion* _"}"

contenidoFuncion
	= declaracionStruct _
    / impresionConsola _
    / asignacionVariable _
    / declaracionVariables _
    / cicloFor _

declaracionStruct "variables de struct"
  = tipoVariable _ variable _ ";"

parametros "parametros"
  = tipoVariable _ variable _ "*"?
  (_ "," _ tipoVariable _ variable _ "*"?)?

// Condicional if-else-if
condicional "condicional if"
  = "if" _ "(" _ condicion _ ")" _ "{" _ bloqueCondicional* _ "}" _ elseParte?

elseParte
  = _ "else" _ ( condicional / "{" _ bloqueCondicional* _ "}" )

condicion "condicion"
  = expresion _ (">" / "<" / ">=" / "<=") _ expresion
  / expresion _ ("||" / "&&") _ expresion
  / "!" _ expresion

bloqueCondicional
  = declaracionVariables _
  / asignacionVariable _
  / condicional _
  / impresionConsola _


// Ciclo FOR
cicloFor "Ciclo For"
  = "for" _ "(" _ "int" _ variable:"i" _ "=" _ inicio:numero _ ";" _ condicion:condicion _ ";" _ cambio:("i++" / "i--") _ ")" _ "{" _ cuerpo:bloqueCondicional* _ "}" {
      return {
        tipo: "cicloFor",
        variable,
        inicio,
        condicion,
        cambio,
        cuerpo
      };
}

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
  = "true" { return true; }
  / "false" { return false; }

variable "variable"
  = v:[a-zA-Z_][a-zA-Z0-9_]*

_ "whitespace"
  = [ \t\n\r]*