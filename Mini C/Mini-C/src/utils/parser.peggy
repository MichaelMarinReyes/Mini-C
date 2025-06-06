{{ 
  let memoria = new Map();
  let salida = "";
  let errorSalida = "";
  let errores = [];
 
  function setVariable(id, valor, tipo, linea, columna) {
    const tipoValor = tipoDeValor(valor);

    if (tipo === "string" && tipoValor === "string") {
      memoria.set(id, {value: valor, type: tipo, location: {line: linea, col: columna}});
    } else if (tipo === "int" && tipoValor === "int") {
      memoria.set(id, {value: valor, type: tipo, location: {line: linea, col: columna}});
    } else if (tipo === "float" && tipoValor === "float") {
      memoria.set(id, {value: valor, type: tipo, location: {line: linea, col: columna}});
    } else if (tipo === "char" && tipoValor === "char") {
      memoria.set(id, {value: valor, type: tipo, location: {line: linea, col: columna}});
    } else if (tipo === "bool" && tipoValor === "bool") {
      memoria.set(id, {value: valor, type: tipo, location: {line: linea, col: columna}});
    } else {
      let mensaje = "No se puede asignar el valor \"" + valor + "\" (tipo " + tipoValor + ") a una variable de tipo " + tipo;
      añadirError(mensaje, columna);
    }
  }

  
  function getVariable(id) {
      let registro = memoria.get(id)
      if (!registro) {
          añadirError("Variable " + id + " no está definida", location())
          return null
      }
      return registro.value;
  }
  
  function salidaTexto(linea) {
      if (salida !== "") {
          salida += "\n";
      }
      salida += String(linea);
  }
  
  function añadirError(errorMessage, location) {
      if (errorSalida !== "") {
          errorSalida += "\n";
      }
      let startCol = location.start.column
      let endCol = location.end.column
      let line = location.start.line
      errorSalida += "Error en linea " + line + ":" + startCol + "-" + endCol + ". " +errorMessage;
      console.log("ERROR-> " + errorSalida)
  }

  function convertirBoleano(valor) {
    if (valor === "true") return true;
    if (valor === "false") return false;
    return valor;
  }

  function tipoDeValor(valor) {
    valor = convertirBoleano(valor);

    if (typeof valor === "number" && Number.isInteger(valor)) return "int";
    if (typeof valor === "number") return "float";
    if (typeof valor === "boolean") return "bool";
    if (typeof valor === "string") {
      if (/^'.{1}'$/.test(valor)) return "char";    
      if (/^".*"$/.test(valor)) return "string";
    }

    return "desconocido";
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
  {
    const resultado = {
      nombre_proyecto: np,
      main: main
    };

    mods.forEach((modulo, index) => {
      const nombreModulo = `modulo${index + 1}`;
      const archivos = {};
      modulo.forEach((archivo, i) => {
        const nombre = archivo.replace('.cmm', '');
        archivos[`archivo${i + 1}`] = archivo;
      });
      resultado[nombreModulo] = archivos;
    });

    return resultado;
  }


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

//Declaración de variables
declaracionVariables "declaración de variables"
  = tipo:tipoVariable _ variable:variable _ "=" _ valor:expresion _ ";" 
  {
  const tipoValor = tipoDeValor(valor);
  if (tipo.tipo !== tipoValor) {
    añadirError("Tipo de valor incorrecto para la variable '" + variable + "'. Se esperaba '" + tipo.tipo + "' y se recibió '" + tipoValor + "'", location());
  }

  setVariable(variable, valor, tipo.tipo, location().start.line, location().start.column);
  return { tipo: "declaracion", tipoVar: tipo.tipo, nombre: variable, valor, ubicacion: location() };
}

//Modificación de valor a las variables
asignacionVariable "asignación"
  = variable:variable _ "=" _ valor:expresion _ ";"
    {
      const registro = memoria.get(variable);
      if (!registro) {
        añadirError("Variable '" + variable + "' no está definida", location());
      } else {
        const tipoValor = tipoDeValor(valor);
        if (registro.type !== tipoValor) {
          añadirError("Tipo de valor incorrecto al asignar a la variable '" + variable + "'. Se esperaba '" + registro.type + "' y se recibió '" + tipoValor + "'", location());
        }
        setVariable(variable, valor, registro.type, location().start.line, location().start.column);
      }

      return { tipo: "asignación", nombre: variable, valor, ubicacion: location() };
    }

  / nombre:variable _ "=" _ valor:funcion
    {
      const registro = memoria.get(nombre);
      if (!registro) {
        añadirError("Variable '" + nombre + "' no está definida", location());
      } else {
        const tipoValor = tipoDeValor(valor);
        if (registro.type !== tipoValor) {
          añadirError("Tipo de valor incorrecto al asignar a la variable '" + nombre + "'. Se esperaba '" + registro.type + "' y se recibió '" + tipoValor + "'", location());
        }
        setVariable(nombre, valor, registro.type, location().start.line, location().start.column);
      }

      return { tipo: "asignación", nombre, valor, ubicacion: location() };
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
  = izq:potencia _ op:("*" / "/") _ der:multiplicacionDivision 
    {
      return (op == "*" ? izq * der : izq / der);
    }
  / base:potencia lista:multiplicacionImplicita* {
      let resultado = base;
      for (let i = 0; i < lista.length; i++) {
        resultado *= lista[i];
      }
      return resultado;
    }


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
  / pri:primario { return pri; }

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
  / "print" _ "(" _ variable:variable _ ")" _ ";"
    {
      const variableExiste = getVariable(variable);
      if (variableExiste !== null) {
        salidaTexto(variableExiste);
      } else {
        añadirError("La variable " + variable + "no esta declarada", location())
      }
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
            añadirError("Variable " + p.nombre + " no definida en interpolación", location());
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
      añadirError("La condición del if no es booleana", location());
    } else if (resultadoCond === true) {
      //condicion del bloque if
    } else if (elsePart && elsePart.ejecutar === true) {
      // Ejecutar el bloque del else-if
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
  = entero:[0-9]+ decimal:("." [0-9]+)? {
      const numeroComoTexto = entero.join("") + (decimal ? decimal[0] + decimal[1].join("") : "");
      return parseFloat(numeroComoTexto);
  }

cadena "string"
  = '"' [^"\n\r"]* '"' { return text(); }

caracter "char"
  = "'" [a-zA-Z0-9] "'" { return text(); }

boolean "booleano"
  = ("true" / "false") { return text(); }

variable "variable"
  = [a-zA-Z_][a-zA-Z0-9_]* { return text(); }

_ "whitespace"
  = [ \t\n\r]*