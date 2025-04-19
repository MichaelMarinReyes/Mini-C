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
      return registro.value
  }
  
  function salidaTexto(linea) {
      if (salida !== "") {
          salida += "\n";
      }
      salida += linea;
  }
  
    function addError(errorMessage, location) {
        if (errorSalida !== "") {
            errorSalida += "\n";
        }
        let startCol = location.start.column
        let endCol = location.end.column
        let line = location.start.line
        errorSalida += "Error en linea " + line + ":" + startCol + "-" + endCol + ". " +errorMessage;
    }
}}

{
  memoria.clear();
  salida = "";
  errorSalida = "";
}

inicio "inicio"
  = _ lenguajes _ { return {salida: salida, errores: errorSalida, tablaSimbolos: memoria}; }

lenguajes "lenguajes"
  = yaml:estructuraYAML { return yaml; }
  / miniC:miniC          { return miniC; }

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
  { return [archivo + ".cmm"]; }

comentario "comentario"
  = _ "#" [^\n]* ("\n" / !.) { return null; }

//Parser para Mini C
miniC "Bloque Mini C"
  = metodoMain _ cuerpoMiniC*

metodoMain "main"
  = "void" _ "main" _ "(" _ ")" _ "{" _ cuerpo:sentencia* _ "}" _

sentencia
  = sentencia:declaracionVariables _  { return sentencia; }
  / sentencia:asignacionVariable _    { return sentencia; }
  / sentencia:condicional _           { return sentencia; }
  / sentencia:impresionConsola _      { return sentencia; }
  / sentencia:funciones _             { return sentencia; }
  / sentencia:structs _               { return sentencia; }

declaracionVariables "declaración de variables"
  = tipo:tipoVariable _ variable:variable _ "=" _ valor:expresion _ ";" 
  {
    setVariable(variable, valor, tipo.tipo, location().start.line, location().start.column);
    return { tipo: "declaracion", tipoVar: tipo.tipo, nombre: variable, valor, ubicacion: location() };
  }

asignacionVariable "asignación"
  = variable:variable _ "=" _ valor:expresion _ ";"
    {
      let tipo = getVariable(variable)?.type;
      if (tipo === null) {
        añadirError("Variable " + variable + " no está definida", location());
      }
      setVariable(variable, valor, tipo, location().start.line, location().start.column);
      return { tipo: "asignación", nombre: variable, valor, ubicacion: location() };
    }
  / nombre:variable _ "=" _ valor:funcion
    {
      let tipo = getVariable(nombre)?.type;
      if (tipo === null) {
        añadirError("Variable " + nombre + " no está definida", location());
      }
      setVariable(nombre, valor, tipo, location().start.line, location().start.column);
      return { tipo: "asignacion", nombre, valor, ubicacion: location() };
    }

funcion "función"
  = tipoVariable _ variable _ "(" _ parametros:parametros* _ ")" _ "{" _ contenidoFuncion* _ "return" _ variable _ ";" _ "}"
  / "void" _ variable _ "(" _ parametros:parametros* _ ")" _ "{" _ contenidoFuncion* _ "}"
  {
    return {
      tipo: "funcion",
      nombre: variable,
      parametros,
      contenidoFuncion,
      retorno: variable,
      ubicacion: location()
    };
  }

tipoVariable "tipo"
  = "int"         { return { tipo: "int", ubicacion: location() }; }
  / "float"       { return { tipo: "float", ubicacion: location() }; }
  / "string"      { return { tipo: "string", ubicacion: location() }; }
  / "char"        { return { tipo: "char", ubicacion: location() }; }
  / "bool"        { return { tipo: "bool", ubicacion: location() }; }

expresion "expresión"
  = exp:sumaResta { return exp; }

sumaResta
  = izq:multiplicacionDivision _ op:("+" / "-") _ der:sumaResta 
  {
    return (op == "+" ? izq + der : izq - der);
  }
  / mul:multiplicacionDivision { return mul; }

multiplicacionDivision
  = izq:potencia _ op:("*" / "/") _ der:multiplicacionDivision {
    return (op == "*" ? izq * der : izq / der);
  }
  / potencia multiplicacionImplicita*

multiplicacionImplicita
  = _ der:potencia { return der; }

potencia
  = izq:unario _ "^" _ der:potencia 
  {
    return Math.pow(izq, der);
  }
  / unario:unario { return unario; }

unario
  = "-" _ valor:unario 
  {
    return { tipo: "unario", op: "-", valor };
  }
  / primario

primario
  = "(" _ expr:sumaResta _ ")"  { return expr; }
  / expr:numero                 { return expr; }
  / expr:variable               { return expr; }
  / expr:cadena                 { return expr; }
  / expr:caracter               { return expr; }
  / expr:boolean                { return expr; }

// -> Contenido después del método main
cuerpoMiniC "contenido del mini C"
  = cuerpo:structs _            { return cuerpo; }
  / cuerpo:impresionConsola _   { return cuerpo; }
  / cuerpo:funciones _          { return cuerpo; }

//-> Struct
structs "structs"
  = "struct" _ variable:variable _ "{" campos:( _ tipoVariable _ variable _ ";" _ )* "}" _ { return {tipo: "struct", variable, campos, ubicacion: location()}; }

//-> Print
impresionConsola "print"
  = "print" _ "(" _ texto:interpolacion _ ")" _ ";" 
    {
      salidaTexto(texto);
      return { tipo: "impresion", valor: texto, ubicacion: location() };
    }

interpolacion
  = "\"" contenido:contenidoInterpolado "\"" {
      return contenido;
    }

contenidoInterpolado
  = partes:(textoLiteral / textoInterpolado)* {
      let resultado = "";
      partes.forEach(p => {
        if (typeof p === "string") {
          resultado += p;
        } else if (typeof p === "object" && p.tipo === "variable") {
          let val = getVariable(p.nombre);
          if (val !== null) {
            resultado += val;
          } else {
            addError("Variable " + p.nombre + " no definida en interpolación", location());
            resultado += "${" + p.nombre + "}";
          }
        }
      });
      return resultado;
    }

textoLiteral
  = t:[^"$"]+ { return t.join(""); }

textoInterpolado
  = "$" "{" nombre:variable "}" {
      return { tipo: "variable", nombre };
    }

//-> Funciones
funciones "función"
  = tipoVariable _ variable _ "(" _ (parametros)* _ ")" _ "{" _ contenidoFuncion* _ "return" _ variable _ ";" _ "}"
  / "void" _ variable _ "(" _ (parametros)* _ ")" _ "{" _ contenidoFuncion* _"}"

contenidoFuncion "cuerpo de una función"
	= contenido:declaracionStruct _       { return contenido; }
  / contenido:impresionConsola _        { return contenido; }
  / contenido:asignacionVariable _      { return contenido; }
  / contenido:declaracionVariables _    { return contenido; }
  / contenido:cicloFor _                { return contenido; }

declaracionStruct "variables de struct"
  = tipoVariable _ variable _ ";"

parametros "parametros"
  = tipo1:tipoVariable _ var1:variable _ puntero1:"*"? resto:(_ "," _ tipo2:tipoVariable _ var2:variable _ puntero2:"*"?)* {
    const parametros = [{ tipo: tipo1.tipo, nombre: var1, puntero: !!puntero1 }];
    resto.forEach(([, , t, v, p]) => {
      parametros.push({ tipo: t.tipo, nombre: v, puntero: !!p });
    });
    return parametros;
  }

// Condicional if-else-if
condicional "condicional if"
  = "if" _ "(" _ cond:condicion _ ")" _ "{" _ bloque:bloqueCondicional* _ "}" _ elsePart:elseParte?
  {
    let resultadoCond = cond;

    if (typeof resultadoCond !== "boolean") {
      addError("La condición del if no es booleana", location());
    } else if (resultadoCond === true) {
      bloque.forEach(instr => {
        // podrías ejecutar la instrucción aquí si tienes un motor
        // o solo guardar lo ejecutado
      });
    } else if (elsePart && elsePart.ejecutar === true) {
      // Ejecutar el bloque del else si lo hay
      elsePart.bloque.forEach(instr => {
        // Ejecutar instrucciones del else
      });
    }

    return {
      tipo: "condicional",
      condicion: cond,
      bloqueIf: bloque,
      bloqueElse: elsePart?.bloque ?? [],
      ubicacion: location()
    };
  }

elseParte
  = _ "else" _ cond:condicional
    {
      return {
        ejecutar: true,
        bloque: cond.bloqueIf,
      };
    }
  / _ "else" _ "{" _ bloque:bloqueCondicional* _ "}"
    {
      return {
        ejecutar: true,
        bloque,
      };
    }

condicion "condicion"
  = izq:expresion _ op:(">" / "<" / ">=" / "<=" / "==" / "!=") _ der:expresion
    {
      switch(op) {
        case ">": return izq > der;
        case "<": return izq < der;
        case ">=": return izq >= der;
        case "<=": return izq <= der;
        case "==": return izq === der;
        case "!=": return izq !== der;
      }
    }
  / izq:expresion _ op:("||" / "&&") _ der:expresion
    {
      switch(op) {
        case "||": return izq || der;
        case "&&": return izq && der;
      }
    }
  / "!" _ val:expresion
    {
      return !val;
    }

bloqueCondicional
  = condicional:declaracionVariables _  { return condicional; }
  / condicional:asignacionVariable _    { return condicional; }
  / condicional:condicional _           { return condicional; }
  / condicional:impresionConsola _      { return condicional; }

// Ciclo FOR
cicloFor "Ciclo For"
  = "for" _ "(" _ "int" _ variable:"i" _ "=" _ inicio:numero _ ";" _ condicion:condicion _ ";" _ cambio:("i++" / "i--") _ ")" _ "{" _ cuerpo:bloqueCondicional* _ "}" 
  {
    return {
      tipo: "cicloFor",
      variable,
      inicio,
      condicion,
      cambio,
      cuerpo,
      ubicacion: location()
    };
  }

numero "número"
  = n:([0-9]+ ("." [0-9]+)?) 
  {
    return parseFloat(n.join(""));
  }

cadena "string"
  = '"' txt:[^"\n\r"]* '"' 
  {
    return txt.join("");
  }

caracter "char"
  = "'" c:[a-zA-Z0-9] "'" 
  {
    return c;
  }

boolean "booleano"
  = "true" { return true; }
  / "false" { return false; }

variable "variable"
  = v:[a-zA-Z_][a-zA-Z0-9_]* { return v; }

_ "whitespace"
  = [ \t\n\r]*