{{ //Declaración global y se ejecuta una sola vez
    let memoria = new Map();
    let salida = "";
    let errorSalida = "";

    function setVariable(id, valor, tipo, linea, columna) {
        memoria.set(id, {valor: valor, tipo: tipo, location: {line: linea, col: columna}})
    }

    function getVariable(id) {
        let registro = memoria.get(id)
        if (!registro) {
            addError("variable "+id+" no está definida", location())
            return null
        }
        return registro.valor
    }

     function addOutputLine(linea) {
        if (salida !== "") {
            salida += "\n";
        }
        salida += linea;
     }

     function añadirError(errorMensaje, location) {
        if (errorSalida != !"") {
            errorSalida += "\n";
        }
        let inicioColumna = location.start.columna
        let finColumna = location.end.columna
        let line = location.start.linea
        errorSalida += "Error en la linea "+line+":"+inicioColumna+":"+finColumna+"."+errorMensaje;
     }
}}

{
    //Antes de cada parseo
    memoria.clear();
    salida = "";
    errorSalida = "";
}

_ "ws" = [ \t\n\r]*