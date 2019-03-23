// Simplified DOT grammar

{
let directed: boolean;
}

start
  = graphStmt+

graphStmt
  = _* strict:(strict _)? type:graphType _* id:(id)? _* '{' _* stmts:stmtList? _* '}' _* {
      return {type: type, id: id, strict: strict !== null, stmts: stmts};
    }

stmtList
  = first:stmt _* ';'? rest:(_* inner:stmt _* ';'?)* {
      const result = [first];
      for (const r of rest) {
        result.push(r[1]);
      }
      return result;
    }

stmt
  = attrStmt
  / edgeStmt
  / subgraphStmt
  / inlineAttrStmt
  / nodeStmt

attrStmt
  = type:(graph / node /edge) _* attrs:attrList {
      return { type: "attr", attrType: type, attrs: attrs || {}};
    }

inlineAttrStmt
  = k:id _* '=' _* v:id {
      const attrs = {[k]: v};
      return { type: "inlineAttr", attrs: attrs };
    }

nodeStmt
  = id:nodeId _* attrs:attrList? { return {type: "node", id: id, attrs: attrs || {}}; }

edgeStmt
  = lhs:(nodeIdOrSubgraph) _* rhs:edgeRHS _* attrs:attrList? {
      const elems = [lhs].concat(rhs);
      return { type: "edge", elems, attrs: attrs || {} };
    }

subgraphStmt
  = id:(subgraph _* (id _*)?)? '{' _* stmts:stmtList? _* '}' {
      id = (id && id[2]) || [];
      return { type: "subgraph", id: id[0], stmts: stmts };
    }

attrList
  = first:attrListBlock rest:(_* attrListBlock)* {
      const result = first;
      for (const r of rest) {
        Object.assign(result, r[1]);
      }
      return result;
    }

attrListBlock
  = '[' _* aList:aList? _* ']' { return aList; }

aList
  = first:idDef rest:(_* ','? _* idDef)* {
      var result = first;
      for (var i = 0; i < rest.length; ++i) {
        Object.assign(result, rest[i][3]);
      }
      return result;
    }

edgeRHS
  = ("--" !{ return directed; } / "->" &{ return directed; }) _* rhs:(nodeIdOrSubgraph) _* rest:edgeRHS? {
      const result = [rhs];
      if (rest) {
        for (let r of rest) {
          result.push(r);
        }
      }
      return result;
    }

idDef
  = k:id v:(_* '=' _* id)? {
      return {[k]: v[3]};
    }

nodeIdOrSubgraph
  = subgraphStmt
  / id:nodeId { return { type: "node", id: id, attrs: {} }; }

nodeId
  = id:id _* port? { return id; }

port
  = ':' _* id _* (':' _* compassPt)?

compassPt
  = "ne" / "se" / "sw" / "nw" / "n" / "e" / "s" / "w" / "c" / "_"

id "identifier"
  = fst:[a-zA-Z\u0200-\u0377_] rest:[a-zA-Z\u0200-\u0377_0-9]* { return fst + rest.join(""); }
  / sign:'-'? dot:'.' after:[0-9]+ {
      return (sign || "") + dot + after.join("");
    }
  / sign:'-'? before:[0-9]+ after:('.' [0-9]*)? {
      return (sign || "") + before.join("") + (after ? after[0] : "") + (after ? after[1].join("") : "");
    }
  / '"' id:("\\\"" { return '"'; } / "\\" ch:[^"] { return "\\" + ch; }  / [^"])* '"' {
      return id.join("");
    }

node = k:"node"i { return k.toLowerCase(); }
edge = k:"edge"i { return k.toLowerCase(); }
graph = k:"graph"i { return k.toLowerCase(); }
digraph = k:"digraph"i { return k.toLowerCase(); }
subgraph = k:"subgraph"i { return k.toLowerCase(); }
strict = k:"strict"i { return k.toLowerCase(); }

graphType
  = graph:graph / graph:digraph {
      directed = graph === "digraph";
      return graph;
    }

whitespace "whitespace"
  = [ \t\r\n]+

comment "comment"
  = "//" ([^\n])*
  / "/*" (!"*/" .)* "*/"

_
  = whitespace
  / comment
