#!/usr/bin/env node
// Verificador estático das units da nova base (Delphi), para quem não pode compilar.
//
// Confere, sem compilar:
//   1. `uses`: unit inexistente, unit repetida, ciclo entre seções `interface` de units do projeto;
//   2. identificador declarado na RTL/FMX/FireDAC/DUnitX/Skia usado sem a unit que o declara no `uses`
//      (na seção interface, só valem as units do uses da interface);
//   3. estrutura: begin/try/case/asm/record/class/interface/object sem o `end` correspondente,
//      except/finally fora de try;
//   4. métodos: declarado na classe/record e não implementado; implementado e não declarado;
//      rotina da interface da unit sem implementação.
//   5. formulários: `{$R *.fmx}` sem o .fmx ao lado; campo publicado sem objeto no .fmx e vice-versa.
//
// Não substitui o compilador: é uma rede de segurança. Falsos positivos podem ser silenciados com um
// comentário `// verificar-uses: ignorar <Identificador>` na própria unit.
//
// Uso:  node ferramentas/verificar-uses/verificar.mjs [pastas ou arquivos...]
//       (padrão: app core ui midia testes, as que existirem)
//       --reindexar  refaz o índice da RTL
//       --projeto a,b   pastas cujas units resolvem os uses (padrão: app,core,ui,midia,testes)
//       --bds <pasta> pasta do Delphi (padrão: C:\Program Files (x86)\Embarcadero\Studio\23.0)

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const args = process.argv.slice(2);
const opc = { reindexar: false, bds: 'C:\\Program Files (x86)\\Embarcadero\\Studio\\23.0', alvos: [], projeto: ['app', 'core', 'ui', 'midia', 'testes'] };
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--reindexar') opc.reindexar = true;
  else if (args[i] === '--bds') opc.bds = args[++i];
  else if (args[i] === '--projeto') opc.projeto = args[++i].split(/[;,]/);
  else opc.alvos.push(args[i]);
}
const raiz = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, '$1')), '..', '..');

// ---------------------------------------------------------------------------------------------
// Léxico
// ---------------------------------------------------------------------------------------------
const PALAVRAS = new Set(`and array as asm begin case class const constructor destructor dispinterface div do downto
else end except exports file finalization finally for function goto if implementation in inherited initialization
inline interface is label library mod nil not object of or out packed procedure program property raise record repeat
resourcestring set shl shr string then threadvar to try type unit until uses var while with xor operator`.split(/\s+/));
const DIRETIVAS = new Set(`abstract assembler cdecl deprecated dispid dynamic experimental export external far final
forward inline library local message near overload override pascal platform register reintroduce safecall static
stdcall unsafe varargs virtual winapi delayed`.split(/\s+/));
const VISIBILIDADE = new Set(['private', 'protected', 'public', 'published', 'strict', 'automated']);
// Palavras que só são diretivas em certos lugares (propriedades, exports, etc.): nunca checar como identificador.
const PALAVRAS_DE_CONTEXTO = new Set(`read write stored default nodefault implements index readonly writeonly name contains
requires package absolute on at reference helper sealed final out platform deprecated experimental`.split(/\s+/));
// Tipos e rotinas embutidos do compilador (não aparecem declarados no System.pas)
const EMBUTIDOS = new Set(`boolean bytebool wordbool longbool byte shortint smallint word integer cardinal longint longword
int8 int16 int32 int64 uint8 uint16 uint32 uint64 nativeint nativeuint single double extended real real48 currency comp
char ansichar widechar ucs2char ucs4char string ansistring widestring unicodestring shortstring rawbytestring utf8string
pointer pchar pansichar pwidechar variant olevariant true false nil copy length setlength high low inc dec ord chr succ
pred sizeof typeinfo typeof assigned exit break continue halt new dispose getmem freemem reallocmem include exclude
insert delete concat trunc round abs sqr odd hi lo swap ptr addr initialize finalize default ismanagedtype hasweakref
gettypekind slice returnaddress write writeln read readln result self str val fillchar move pos upcase random randomize
frac int sqrt sin cos arctan ln exp pi assert`.split(/\s+/));
// Prefixos de unit (namespaces) aceitos para nomes curtos no uses, como no -NS do .dproj
const PREFIXOS_NS = ['System', 'System.Win', 'Winapi', 'FMX', 'Data', 'Xml', 'Soap', 'Web', 'Datasnap', 'FireDAC', 'REST', 'Vcl'];

// Símbolos definidos num build Win64 Debug do Delphi 12 (para avaliar {$IFDEF}/{$IF})
const DEFINIDOS = new Set(['mswindows', 'win64', 'cpux64', 'cpu64bits', 'cpux86_64', 'debug', 'unicode', 'conditionalexpressions',
  'ver360', 'native_code', 'assembler', 'pic', 'align_stack', 'framework_fmx', 'weakref', 'weakintfref', 'weakinstref', 'undefined_os_unix']);

// Avalia uma expressão de {$IF ...} de forma tolerante: o que não souber avaliar conta como verdadeiro.
function avaliarIf(expr, defs) {
  let e = expr.replace(/\bDEFINED\s*\(\s*(\w+)\s*\)/gi, (_, s) => (defs.has(s.toLowerCase()) ? ' 1 ' : ' 0 '));
  e = e.replace(/\bDECLARED\s*\(\s*[\w.]+\s*\)/gi, ' 1 ');
  e = e.replace(/\b(CompilerVersion|RTLVersion\w*|FireMonkeyVersion)\s*(>=|>|<=|<|=|<>)\s*([\d.]+)/gi, (_, _v, op, n) => {
    const v = 36; const x = parseFloat(n);
    const r = { '>=': v >= x, '>': v > x, '<=': v <= x, '<': v < x, '=': v === x, '<>': v !== x }[op];
    return r ? ' 1 ' : ' 0 ';
  });
  e = e.replace(/\bAND\b/gi, '&&').replace(/\bOR\b/gi, '||').replace(/\bNOT\b/gi, '!');
  if (!/^[\s01()&|!]*$/.test(e)) return true;
  try { return !!Function(`return (${e});`)(); } catch { return true; }
}

function tokenizar(texto) {
  if (texto.charCodeAt(0) === 0xfeff) texto = texto.slice(1);
  else if (texto.startsWith('ï»¿')) texto = texto.slice(3);
  const t = [];
  const n = texto.length;
  let i = 0;
  let linha = 1;
  let enumsComEscopo = false;
  const dirs = []; // diretivas {$...}
  // compilação condicional: pilha de { ativo, jaFoi }; {$DEFINE} vale só para este arquivo
  const defs = new Set(DEFINIDOS);
  const cond = [];
  const ativo = () => cond.every((c) => c.ativo);
  const emitir = t.push.bind(t);
  t.push = (x) => (ativo() ? emitir(x) : 0);
  while (i < n) {
    const c = texto[i];
    if (c === '\n') { linha++; i++; continue; }
    if (c === ' ' || c === '\t' || c === '\r' || c === '\f') { i++; continue; }
    if (c === '{') {
      const fim = texto.indexOf('}', i + 1);
      const corpo = texto.slice(i, fim < 0 ? n : fim + 1);
      // Comentário { } não aninha: o primeiro } fecha. Um { dentro dele quase sempre é texto que virou código.
      if (!corpo.startsWith('{$') && corpo.slice(1).includes('{')) dirs.push({ comentarioAninhado: true, linha });
      if (corpo.startsWith('{$')) {
        const d = /^\{\$(\w+)\s*(.*?)\}?$/s.exec(corpo);
        const nome = d ? d[1].toUpperCase() : '';
        const resto = d ? d[2].replace(/\}$/, '').trim() : '';
        const paiAtivo = ativo();
        if (nome === 'IFDEF' || nome === 'IFNDEF') {
          const def = defs.has(resto.split(/\s/)[0].toLowerCase());
          const v = nome === 'IFDEF' ? def : !def;
          cond.push({ ativo: v, jaFoi: v });
        } else if (nome === 'IF') {
          const v = avaliarIf(resto, defs);
          cond.push({ ativo: v, jaFoi: v });
        } else if (nome === 'IFOPT') {
          cond.push({ ativo: true, jaFoi: true });
        } else if (nome === 'ELSEIF' && cond.length) {
          const topo = cond[cond.length - 1];
          const v = !topo.jaFoi && avaliarIf(resto, defs);
          topo.ativo = v; topo.jaFoi = topo.jaFoi || v;
        } else if (nome === 'ELSE' && cond.length) {
          const topo = cond[cond.length - 1];
          topo.ativo = !topo.jaFoi; topo.jaFoi = true;
        } else if ((nome === 'ENDIF' || nome === 'IFEND') && cond.length) {
          cond.pop();
        } else if (paiAtivo) {
          dirs.push({ texto: corpo, linha });
          const se = /^\{\$SCOPEDENUMS\s+(ON|OFF)/i.exec(corpo);
          if (se) enumsComEscopo = se[1].toUpperCase() === 'ON';
          const df = /^\{\$DEFINE\s+(\w+)/i.exec(corpo);
          if (df) defs.add(df[1].toLowerCase());
          const ud = /^\{\$UNDEF\s+(\w+)/i.exec(corpo);
          if (ud) defs.delete(ud[1].toLowerCase());
        }
      }
      linha += (corpo.match(/\n/g) || []).length;
      i = fim < 0 ? n : fim + 1;
      continue;
    }
    if (c === '(' && texto[i + 1] === '*') {
      const fim = texto.indexOf('*)', i + 2);
      const corpo = texto.slice(i, fim < 0 ? n : fim + 2);
      linha += (corpo.match(/\n/g) || []).length;
      i = fim < 0 ? n : fim + 2;
      continue;
    }
    if (c === '/' && texto[i + 1] === '/') {
      const fim = texto.indexOf('\n', i);
      const corpo = texto.slice(i, fim < 0 ? n : fim);
      const m = /verificar-uses:\s*ignorar\s+([\w, ]+)/i.exec(corpo);
      if (m) dirs.push({ ignorar: m[1].split(/[\s,]+/).filter(Boolean), linha });
      i = fim < 0 ? n : fim;
      continue;
    }
    if (c === "'") {
      // cadeia multilinha do Delphi 12 ('''...''')
      if (texto.startsWith("'''", i) && /^'''[ \t]*\r?\n/.test(texto.slice(i, i + 6))) {
        const fim = texto.indexOf("'''", i + 3);
        const corpo = texto.slice(i, fim < 0 ? n : fim + 3);
        t.push({ k: 's', v: corpo, l: linha });
        linha += (corpo.match(/\n/g) || []).length;
        i = fim < 0 ? n : fim + 3;
        continue;
      }
      let j = i + 1;
      while (j < n) {
        if (texto[j] === "'") { if (texto[j + 1] === "'") { j += 2; continue; } break; }
        if (texto[j] === '\n') break;
        j++;
      }
      t.push({ k: 's', v: texto.slice(i, j + 1), l: linha });
      i = j + 1;
      continue;
    }
    if (c === '#') {
      let j = i + 1;
      if (texto[j] === '$') { j++; while (j < n && /[0-9a-fA-F]/.test(texto[j])) j++; }
      else while (j < n && /[0-9]/.test(texto[j])) j++;
      t.push({ k: 's', v: texto.slice(i, j), l: linha });
      i = j;
      continue;
    }
    if (/[A-Za-z_&]/.test(c)) {
      let j = i + 1;
      while (j < n && /[A-Za-z0-9_]/.test(texto[j])) j++;
      let v = texto.slice(i, j);
      const escapado = v.startsWith('&');
      if (escapado) v = v.slice(1);
      t.push({ k: 'i', v, lv: v.toLowerCase(), l: linha, esc: escapado, se: enumsComEscopo });
      i = j;
      continue;
    }
    if (/[0-9]/.test(c) || (c === '$' && /[0-9a-fA-F]/.test(texto[i + 1] || ''))) {
      let j = i + 1;
      if (c === '$') while (j < n && /[0-9a-fA-F]/.test(texto[j])) j++;
      else {
        while (j < n && /[0-9]/.test(texto[j])) j++;
        if (texto[j] === '.' && /[0-9]/.test(texto[j + 1] || '')) { j++; while (j < n && /[0-9]/.test(texto[j])) j++; }
        if (/[eE]/.test(texto[j] || '') && /[-+0-9]/.test(texto[j + 1] || '')) { j += 2; while (j < n && /[0-9]/.test(texto[j])) j++; }
      }
      t.push({ k: 'n', v: texto.slice(i, j), l: linha });
      i = j;
      continue;
    }
    const dois = texto.slice(i, i + 2);
    if ([':=', '..', '<=', '>=', '<>', '(.', '.)'].includes(dois)) { t.push({ k: 'p', v: dois, l: linha }); i += 2; continue; }
    t.push({ k: 'p', v: c, l: linha });
    i++;
  }
  return { tokens: t, dirs };
}

const eh = (tk, v) => tk && tk.k === 'i' && !tk.esc && tk.lv === v;
const ehP = (tk, v) => tk && tk.k === 'p' && tk.v === v;
const ehPalavra = (tk) => tk && tk.k === 'i' && !tk.esc && PALAVRAS.has(tk.lv);

// pula de `(` até o `)` correspondente; devolve o índice depois do `)`
function pularParenteses(tk, i, abre = '(', fecha = ')') {
  let d = 0;
  for (; i < tk.length; i++) {
    if (ehP(tk[i], abre)) d++;
    else if (ehP(tk[i], fecha)) { d--; if (d === 0) return i + 1; }
  }
  return i;
}

// Em `Nome<...>`, j aponta para `<`: devolve o índice depois do `>` e o número de parâmetros genéricos
// (restrições como `<T: class, constructor>` não contam como parâmetros).
function generico(tk, j) {
  if (!ehP(tk[j], '<')) return { fim: j, sufixo: '' };
  let n = 0;
  let emRestricao = false;
  let k = j + 1;
  for (; k < tk.length && !ehP(tk[k], '>'); k++) {
    const t = tk[k];
    if (ehP(t, ':')) emRestricao = true;
    else if (ehP(t, ';')) emRestricao = false;
    else if (t.k === 'i' && !ehPalavra(t) && (ehP(tk[k - 1], '<') || ehP(tk[k - 1], ';') || (ehP(tk[k - 1], ',') && !emRestricao))) n++;
  }
  return { fim: k + 1, sufixo: `<${n}>` };
}

// pula até o `;` no mesmo nível de parênteses/colchetes; devolve o índice do `;`
function ateFimDeclaracao(tk, i) {
  let d = 0;
  for (; i < tk.length; i++) {
    if (ehP(tk[i], '(') || ehP(tk[i], '[')) d++;
    else if (ehP(tk[i], ')') || ehP(tk[i], ']')) d--;
    else if (d === 0 && ehP(tk[i], ';')) return i;
    else if (d === 0 && (eh(tk[i], 'end') || eh(tk[i], 'implementation'))) return i - 1;
  }
  return i;
}

// Depois de `= class` (i aponta para `class`): o tipo tem corpo?
function classeTemCorpo(tk, i) {
  let j = i + 1;
  while (eh(tk[j], 'abstract') || eh(tk[j], 'sealed')) j++;
  if (eh(tk[j], 'of')) return false;
  if (eh(tk[j], 'helper')) { j += 3; }
  if (ehP(tk[j], '(')) {
    j = pularParenteses(tk, j);
    if (ehP(tk[j], ';')) return false; // TX = class(TBase);
  }
  if (ehP(tk[j], ';')) return false; // declaração adiantada
  return true;
}

function interfaceTemCorpo(tk, i) {
  let j = i + 1;
  if (ehP(tk[j], '(')) j = pularParenteses(tk, j);
  if (ehP(tk[j], ';')) return false;
  return true;
}

// ---------------------------------------------------------------------------------------------
// Declarações de uma seção (interface ou implementation): tipos, métodos, rotinas, constantes...
// ---------------------------------------------------------------------------------------------
// Devolve { nomes:Set (lower) de identificadores de nível de unit, tipos: Map nomeTipoLower -> {nome, tipo, metodos:Map, linha} , rotinas: Map }
function declaracoes(tk, ini, fim, { coletarMetodos = false, membros = null } = {}) {
  const nomes = new Map(); // lower -> nome original
  const tipos = new Map();
  const rotinas = new Map(); // lower -> {nome, linha, semCorpo}
  let secao = '';
  let i = ini;
  const add = (tok) => { if (tok && tok.k === 'i') nomes.set(tok.lv, tok.v); };

  // Lê o corpo de um tipo estruturado a partir de i (primeiro token do corpo), até o `end` correspondente.
  // Devolve o índice depois do `end`.
  function lerCorpo(i, info, prefixo) {
    let profundidade = 1;
    let classeDeclarada = false;
    while (i < fim && i < tk.length) {
      const a = tk[i];
      if (eh(a, 'end')) { profundidade--; if (profundidade === 0) return i + 1; i++; continue; }
      if (eh(a, 'record') && (ehP(tk[i - 1], '=') || (eh(tk[i - 1], 'packed') && ehP(tk[i - 2], '=')))) {
        // record aninhado com nome (pode ter métodos)
        const nomeTk = ehP(tk[i - 1], '=') ? tk[i - 2] : tk[i - 3];
        const sub = { nome: (prefixo ? prefixo + '.' : '') + nomeTk.v, tipo: 'record', metodos: new Map(), linha: nomeTk.l };
        if (coletarMetodos) tipos.set(sub.nome.toLowerCase(), sub);
        let j = i + 1;
        if (eh(tk[j], 'helper')) j += 3;
        i = lerCorpo(j, sub, sub.nome);
        continue;
      }
      if (eh(a, 'record') && !(ehP(tk[i + 1], '>') || ehP(tk[i + 1], ','))) { profundidade++; i++; continue; }
      if ((eh(a, 'class') || eh(a, 'object')) && ehP(tk[i - 1], '=')) {
        // tipo aninhado
        const nomeTk = tk[i - 2];
        if (eh(a, 'object') || classeTemCorpo(tk, i)) {
          const sub = { nome: (prefixo ? prefixo + '.' : '') + nomeTk.v, tipo: a.lv, metodos: new Map(), linha: nomeTk.l };
          if (coletarMetodos) tipos.set(sub.nome.toLowerCase(), sub);
          let j = i + 1;
          while (eh(tk[j], 'abstract') || eh(tk[j], 'sealed')) j++;
          if (eh(tk[j], 'helper')) j += 3;
          if (ehP(tk[j], '(')) j = pularParenteses(tk, j);
          i = lerCorpo(j, sub, sub.nome);
          continue;
        }
        i++;
        continue;
      }
      if ((eh(a, 'interface') || eh(a, 'dispinterface')) && ehP(tk[i - 1], '=')) {
        if (interfaceTemCorpo(tk, i)) { profundidade++; }
        i++;
        continue;
      }
      if (info && (eh(a, 'procedure') || eh(a, 'function') || eh(a, 'constructor') || eh(a, 'destructor') || (eh(a, 'operator') && eh(tk[i - 1], 'class')))) {
        const nomeTk = tk[i + 1];
        if (nomeTk && nomeTk.k === 'i' && !ehP(tk[i - 1], ':') && !ehP(tk[i - 1], '=') && !eh(tk[i - 1], 'to') && !eh(tk[i - 1], 'of')) {
          let j = i + 2;
          if (ehP(tk[j], '<')) { while (j < tk.length && !ehP(tk[j], '>')) j++; j++; }
          if (ehP(tk[j], '(')) j = pularParenteses(tk, j);
          j = ateFimDeclaracao(tk, j);
          // diretivas depois do `;`
          let semCorpo = info.tipo === 'interface' || info.tipo === 'dispinterface';
          let k = j + 1;
          while (tk[k] && tk[k].k === 'i' && (DIRETIVAS.has(tk[k].lv) || tk[k].lv === 'dispid' || tk[k].lv === 'message')) {
            if (tk[k].lv === 'abstract' || tk[k].lv === 'external' || tk[k].lv === 'dispid') semCorpo = true;
            k = ateFimDeclaracao(tk, k + 1) + 1;
          }
          const lv = nomeTk.lv;
          if (membros) membros.add(lv);
          if (!info.metodos.has(lv)) info.metodos.set(lv, { nome: nomeTk.v, linha: nomeTk.l, semCorpo });
          else if (!semCorpo) info.metodos.get(lv).semCorpo = false;
          i = k;
          continue;
        }
      }
      if (eh(a, 'property')) {
        if (membros && tk[i + 1] && tk[i + 1].k === 'i') membros.add(tk[i + 1].lv);
        i = ateFimDeclaracao(tk, i + 1) + 1;
        continue;
      }
      if (membros && a.k === 'i' && !ehPalavra(a) && (ehP(tk[i + 1], ':') || ehP(tk[i + 1], ','))) membros.add(a.lv);
      i++;
    }
    return i;
  }

  while (i < fim) {
    const a = tk[i];
    if (!a) break;
    if (a.k === 'i' && !a.esc) {
      if (['type', 'const', 'var', 'threadvar', 'resourcestring'].includes(a.lv)) { secao = a.lv; i++; continue; }
      if (a.lv === 'uses') { i = ateFimDeclaracao(tk, i) + 1; continue; }
      if (['procedure', 'function', 'constructor', 'destructor'].includes(a.lv) || (a.lv === 'class' && ['procedure', 'function', 'constructor', 'destructor', 'operator'].includes((tk[i + 1] || {}).lv))) {
        // rotina de nível de unit (ou implementação de método: Nome.Metodo)
        let j = a.lv === 'class' ? i + 2 : i + 1;
        const partes = [];
        while (tk[j] && tk[j].k === 'i') {
          const parte = { ...tk[j] };
          j++;
          if (ehP(tk[j], '<')) {
            const g = generico(tk, j);
            // só o tipo (antes de um `.`) leva a aridade; o método genérico não
            if (ehP(tk[g.fim], '.')) { parte.lv += g.sufixo; parte.v += g.sufixo; }
            j = g.fim;
          }
          partes.push(parte);
          if (ehP(tk[j], '.')) { j++; continue; }
          break;
        }
        // pular parâmetros, tipo de retorno e diretivas: senão um `const`/`var` de parâmetro vira seção
        let k = j;
        if (ehP(tk[k], '(')) k = pularParenteses(tk, k);
        k = ateFimDeclaracao(tk, k);
        let semCorpo = false;
        let m = k + 1;
        while (tk[m] && tk[m].k === 'i' && (DIRETIVAS.has(tk[m].lv) || tk[m].lv === 'name')) {
          if (tk[m].lv === 'external' || tk[m].lv === 'forward') semCorpo = true;
          m = ateFimDeclaracao(tk, m + 1) + 1;
        }
        if (partes.length === 1) {
          add(partes[0]);
          const lv = partes[0].lv;
          if (!rotinas.has(lv)) rotinas.set(lv, { nome: partes[0].v, linha: partes[0].l, semCorpo, qualificado: null });
          else if (!semCorpo) rotinas.get(lv).semCorpo = false;
        } else if (partes.length > 1) {
          const lv = partes.map((p) => p.lv).join('.');
          if (!rotinas.has(lv)) rotinas.set(lv, { nome: partes.map((p) => p.v).join('.'), linha: partes[0].l, semCorpo: false, qualificado: true });
        }
        secao = '';
        i = m;
        continue;
      }
      if (a.lv === 'begin' || a.lv === 'initialization' || a.lv === 'finalization') {
        // corpo de rotina: pular até o end correspondente (contando blocos)
        if (a.lv === 'begin') {
          let d = 0;
          for (; i < fim; i++) {
            const b = tk[i];
            if (eh(b, 'begin') || eh(b, 'try') || eh(b, 'asm') || (eh(b, 'case') && true)) d++;
            else if (eh(b, 'record') && !(ehP(tk[i + 1], '>') || ehP(tk[i + 1], ','))) d++;
            else if (eh(b, 'end')) { d--; if (d === 0) { i++; break; } }
          }
          secao = '';
          continue;
        }
        break;
      }
    }
    if (secao === 'type' && a.k === 'i' && !ehPalavra(a)) {
      // Nome [<T,...>] = ...   (genéricos entram no mapa com a aridade: TLista<1>)
      const g = generico(tk, i + 1);
      const j = g.fim;
      if (ehP(tk[j], '=')) {
        add(a);
        const chave = a.lv + g.sufixo;
        const nomeTipo = a.v + g.sufixo;
        let k = j + 1;
        if (eh(tk[k], 'type')) k++;
        if (eh(tk[k], 'packed')) k++;
        const b = tk[k];
        if (eh(b, 'class') && classeTemCorpo(tk, k)) {
          const info = { nome: nomeTipo, tipo: 'class', metodos: new Map(), linha: a.l };
          tipos.set(chave, info);
          let m = k + 1;
          while (eh(tk[m], 'abstract') || eh(tk[m], 'sealed')) m++;
          if (eh(tk[m], 'helper')) m += 3;
          if (ehP(tk[m], '(')) m = pularParenteses(tk, m);
          i = lerCorpo(m, info, nomeTipo);
          continue;
        }
        if (eh(b, 'record') || eh(b, 'object')) {
          const info = { nome: nomeTipo, tipo: b.lv, metodos: new Map(), linha: a.l };
          tipos.set(chave, info);
          let m = k + 1;
          if (eh(tk[m], 'helper')) m += 3;
          i = lerCorpo(m, info, nomeTipo);
          continue;
        }
        if ((eh(b, 'interface') || eh(b, 'dispinterface')) && interfaceTemCorpo(tk, k)) {
          const info = { nome: nomeTipo, tipo: 'interface', metodos: new Map(), linha: a.l };
          tipos.set(chave, info);
          let m = k + 1;
          if (ehP(tk[m], '(')) m = pularParenteses(tk, m);
          i = lerCorpo(m, info, nomeTipo);
          continue;
        }
        if (ehP(b, '(')) {
          // enumeração: os valores são identificadores de nível de unit (sem SCOPEDENUMS)
          const f = pularParenteses(tk, k);
          for (let m = k + 1; m < f - 1; m++) {
            if (tk[m].k === 'i' && !tk[m].se && (ehP(tk[m + 1], ',') || ehP(tk[m + 1], ')') || ehP(tk[m + 1], '='))) add(tk[m]);
            if (ehP(tk[m + 1], '=')) { while (m < f - 1 && !ehP(tk[m], ',')) m++; }
          }
          i = ateFimDeclaracao(tk, f) + 1;
          continue;
        }
        i = ateFimDeclaracao(tk, k) + 1;
        continue;
      }
    }
    if ((secao === 'const' || secao === 'resourcestring') && a.k === 'i' && !ehPalavra(a) && (ehP(tk[i + 1], '=') || ehP(tk[i + 1], ':'))) {
      add(a);
      i = ateFimDeclaracao(tk, i + 1) + 1;
      continue;
    }
    if ((secao === 'var' || secao === 'threadvar') && a.k === 'i' && !ehPalavra(a)) {
      let j = i;
      const lista = [];
      while (tk[j] && tk[j].k === 'i') { lista.push(tk[j]); if (ehP(tk[j + 1], ',')) j += 2; else { j++; break; } }
      if (ehP(tk[j], ':')) { lista.forEach(add); i = ateFimDeclaracao(tk, j) + 1; continue; }
    }
    i++;
  }
  return { nomes, tipos, rotinas };
}

function secoes(tk) {
  let iInt = -1;
  let iImpl = -1;
  for (let i = 0; i < tk.length; i++) {
    if (iInt < 0 && eh(tk[i], 'interface') && (ehP(tk[i - 1], ';') || i < 6)) iInt = i;
    if (eh(tk[i], 'implementation')) { iImpl = i; break; }
  }
  return { iInt, iImpl };
}

function lerUses(tk, i) {
  // i aponta para `uses`
  const lista = [];
  let j = i + 1;
  while (j < tk.length && !ehP(tk[j], ';')) {
    if (tk[j].k === 'i') {
      const partes = [tk[j]];
      let k = j + 1;
      while (ehP(tk[k], '.') && tk[k + 1] && tk[k + 1].k === 'i') { partes.push(tk[k + 1]); k += 2; }
      const nome = partes.map((p) => p.v).join('.');
      let arquivo = null;
      if (eh(tk[k], 'in') && tk[k + 1] && tk[k + 1].k === 's') { arquivo = tk[k + 1].v.slice(1, -1); k += 2; }
      lista.push({ nome, lv: nome.toLowerCase(), linha: partes[0].l, arquivo });
      j = k;
      continue;
    }
    j++;
  }
  return { lista, fim: j };
}

// ---------------------------------------------------------------------------------------------
// Índice da RTL
// ---------------------------------------------------------------------------------------------
function listarPas(dir, recursivo, saida) {
  let entradas;
  try { entradas = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entradas) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { if (recursivo) listarPas(p, true, saida); }
    else if (/\.pas$/i.test(e.name)) saida.push(p);
  }
}

function construirIndice() {
  const fonte = path.join(opc.bds, 'source');
  const arquivos = [];
  for (const [d, rec] of [['rtl/common', false], ['rtl/sys', false], ['rtl/win', false], ['rtl/net', false], ['fmx', false],
    ['data', true], ['DunitX', false], ['Skia', true], ['xml', false], ['internet', false], ['databinding', true]]) {
    listarPas(path.join(fonte, d), rec, arquivos);
  }
  const ident = new Map(); // lower -> [units]
  const membros = new Set(); // nomes de métodos, propriedades e campos de classes/records da RTL
  const unidades = new Set();
  const plataformaAlheia = /\.(Android|iOS|Mac|Linux|Posix|OSX|Macapi|Androidapi|iOSapi)\b|^(Androidapi|Macapi|iOSapi|Posix|Linuxapi)\./i;
  for (const arq of arquivos) {
    const unidade = path.basename(arq).replace(/\.pas$/i, '');
    unidades.add(unidade.toLowerCase());
    if (plataformaAlheia.test(unidade)) continue;
    let texto;
    try { texto = fs.readFileSync(arq, 'latin1'); } catch { continue; }
    const { tokens } = tokenizar(texto);
    const { iInt, iImpl } = secoes(tokens);
    if (iInt < 0) continue;
    const { nomes } = declaracoes(tokens, iInt + 1, iImpl < 0 ? tokens.length : iImpl, { membros });
    for (const lv of nomes.keys()) {
      if (!ident.has(lv)) ident.set(lv, []);
      ident.get(lv).push(unidade);
    }
  }
  // units compiladas disponíveis (inclusive as sem fonte)
  for (const d of ['lib/win64/release', 'lib/win64/debug']) {
    try {
      for (const f of fs.readdirSync(path.join(opc.bds, d))) if (/\.dcu$/i.test(f)) unidades.add(f.slice(0, -4).toLowerCase());
    } catch { /* sem a pasta */ }
  }
  return { versao: 4, ident: [...ident], membros: [...membros], unidades: [...unidades] };
}

function carregarIndice() {
  const cache = path.join(os.tmpdir(), 'conversa-verificar-uses-indice-v4.json');
  if (!opc.reindexar && fs.existsSync(cache)) {
    try {
      const j = JSON.parse(fs.readFileSync(cache, 'utf8'));
      j.ident = new Map(j.ident);
      j.membros = new Set(j.membros);
      return j;
    } catch { /* refaz */ }
  }
  const t0 = Date.now();
  const idx = construirIndice();
  fs.writeFileSync(cache, JSON.stringify(idx));
  idx.ident = new Map(idx.ident);
  idx.membros = new Set(idx.membros);
  console.error(`(índice da RTL refeito em ${((Date.now() - t0) / 1000).toFixed(1)} s: ${idx.ident.size} identificadores, ${idx.unidades.length} units)`);
  return idx;
}

// ---------------------------------------------------------------------------------------------
// Verificações por arquivo
// ---------------------------------------------------------------------------------------------
function verificarEstrutura(tk, ehPrograma, erros) {
  const pilha = [];
  let aposImplementacao = false;
  for (let i = 0; i < tk.length; i++) {
    const a = tk[i];
    if (a.k !== 'i' || a.esc) continue;
    const topo = pilha[pilha.length - 1];
    switch (a.lv) {
      case 'implementation': aposImplementacao = true; break;
      case 'begin': pilha.push({ k: 'begin', l: a.l }); break;
      case 'try': pilha.push({ k: 'try', l: a.l }); break;
      case 'asm': {
        pilha.push({ k: 'asm', l: a.l });
        while (i + 1 < tk.length && !eh(tk[i + 1], 'end')) i++;
        break;
      }
      case 'case': if (!topo || topo.k !== 'record') pilha.push({ k: 'case', l: a.l }); break;
      case 'record':
        if (!(ehP(tk[i + 1], '>') || ehP(tk[i + 1], ','))) pilha.push({ k: 'record', l: a.l });
        break;
      case 'class':
        if (ehP(tk[i - 1], '=') || (eh(tk[i - 1], 'packed') && ehP(tk[i - 2], '='))) { if (classeTemCorpo(tk, i)) pilha.push({ k: 'class', l: a.l }); }
        break;
      case 'object':
        if (ehP(tk[i - 1], '=') || eh(tk[i - 1], 'packed')) pilha.push({ k: 'object', l: a.l });
        break;
      case 'interface': case 'dispinterface':
        if (ehP(tk[i - 1], '=') && interfaceTemCorpo(tk, i)) pilha.push({ k: 'interface', l: a.l });
        break;
      case 'except': case 'finally':
        if (!topo || topo.k !== 'try') erros.push({ l: a.l, m: `'${a.v}' fora de um 'try' (o bloco aberto é ${topo ? `'${topo.k}' da linha ${topo.l}` : 'nenhum'})` });
        break;
      case 'end': {
        if (ehP(tk[i + 1], '.')) {
          // fim da unit/programa
          if (ehPrograma) {
            if (pilha.length !== 1 || pilha[0].k !== 'begin') erros.push({ l: a.l, m: `'end.' do programa com blocos abertos: ${pilha.map((p) => `${p.k}@${p.l}`).join(', ') || 'nenhum begin'}` });
          } else if (pilha.length) {
            erros.push({ l: a.l, m: `'end.' com blocos abertos: ${pilha.map((p) => `${p.k}@${p.l}`).join(', ')}` });
          }
          return;
        }
        if (!pilha.length) { erros.push({ l: a.l, m: "'end' sem bloco aberto" }); break; }
        pilha.pop();
        break;
      }
      default: break;
    }
  }
  if (!aposImplementacao && !ehPrograma) erros.push({ l: 1, m: "unit sem 'implementation'" });
  erros.push({ l: tk.length ? tk[tk.length - 1].l : 1, m: "arquivo termina sem 'end.'" });
}

// identificadores declarados neste arquivo (parâmetros, variáveis, campos, tipos, rotinas...)
function declaradosNoArquivo(tk) {
  const s = new Set();
  for (let i = 0; i < tk.length; i++) {
    const a = tk[i];
    if (a.k !== 'i') continue;
    const prox = tk[i + 1];
    const ant = tk[i - 1];
    // Nome: Tipo  (não :=)
    if (ehP(prox, ':')) { s.add(a.lv); continue; }
    // lista A, B: Tipo
    if (ehP(prox, ',')) {
      let j = i;
      while (tk[j] && tk[j].k === 'i' && ehP(tk[j + 1], ',')) j += 2;
      if (tk[j] && tk[j].k === 'i' && ehP(tk[j + 1], ':')) { for (let m = i; m <= j; m += 2) s.add(tk[m].lv); }
    }
    // Nome = ... em seção type/const (antes: ; type const resourcestring ou visibilidade)
    if (ehP(prox, '=') && (ehP(ant, ';') || ehP(ant, ']') || eh(ant, 'type') || eh(ant, 'const') || eh(ant, 'resourcestring') || (ant && ant.k === 'i' && VISIBILIDADE.has(ant.lv)))) s.add(a.lv);
    // Nome<T...> =  (tipo genérico: o nome e os parâmetros)
    if (ehP(prox, '<')) {
      let j = i + 2;
      const params = [];
      while (j < tk.length && !ehP(tk[j], '>') && j < i + 40) { if (tk[j].k === 'i' && (ehP(tk[j + 1], ',') || ehP(tk[j + 1], '>') || ehP(tk[j + 1], ':') || ehP(tk[j + 1], ';'))) params.push(tk[j].lv); j++; }
      if (ehP(tk[j], '>') && (ehP(tk[j + 1], '=') || ehP(tk[j + 1], '(') || ehP(tk[j + 1], ':') || ehP(tk[j + 1], ';') || ehP(tk[j + 1], '.'))) {
        if (ehP(tk[j + 1], '=')) s.add(a.lv);
        params.forEach((p) => s.add(p));
      }
    }
    // procedure/function/property/constructor Nome
    if (ant && ant.k === 'i' && ['procedure', 'function', 'property', 'constructor', 'destructor', 'operator'].includes(ant.lv)) s.add(a.lv);
    // var X := ...  (variável inline)
    if (eh(ant, 'var') && (ehP(prox, ':=') || ehP(prox, ':'))) s.add(a.lv);
    // for var I :=
    if (eh(ant, 'var') && eh(tk[i - 2], 'for')) s.add(a.lv);
    // valores de enumeração declarados: = (a, b, c)
    if (ehP(ant, '(') && ehP(tk[i - 2], '=')) {
      let j = i;
      while (tk[j] && tk[j].k === 'i' && (ehP(tk[j + 1], ',') || ehP(tk[j + 1], ')'))) { s.add(tk[j].lv); if (ehP(tk[j + 1], ')')) break; j += 2; }
    }
  }
  return s;
}

// Marca os tokens dentro de `with X do <comando>`: lá um nome solto pode ser membro de X.
function marcarWith(tk) {
  const marca = new Uint8Array(tk.length);
  for (let i = 0; i < tk.length; i++) {
    if (!eh(tk[i], 'with')) continue;
    let j = i + 1;
    while (j < tk.length && !eh(tk[j], 'do')) j++;
    j++;
    let fim;
    if (eh(tk[j], 'begin') || eh(tk[j], 'try')) {
      let d = 0;
      for (fim = j; fim < tk.length; fim++) {
        if (eh(tk[fim], 'begin') || eh(tk[fim], 'try') || eh(tk[fim], 'case') || eh(tk[fim], 'asm')) d++;
        else if (eh(tk[fim], 'end')) { d--; if (d === 0) break; }
      }
    } else {
      let d = 0;
      for (fim = j; fim < tk.length; fim++) {
        if (eh(tk[fim], 'begin') || eh(tk[fim], 'try') || eh(tk[fim], 'case')) d++;
        else if (eh(tk[fim], 'end')) { if (d === 0) break; d--; }
        else if (d === 0 && (ehP(tk[fim], ';') || eh(tk[fim], 'else'))) break;
      }
    }
    for (let k = i; k <= fim && k < tk.length; k++) marca[k] = 1;
  }
  return marca;
}

// Marca os tokens que estão dentro de implementações de método (TTipo.Metodo), onde um identificador
// solto pode ser membro herdado (Self implícito).
function marcarCorposDeMetodo(tk, ini) {
  const marca = new Uint8Array(tk.length);
  if (ini < 0) return marca;
  let profundidade = 0;
  let atual = false;
  let corposPendentes = 0; // rotina atual + rotinas locais aninhadas ainda sem o corpo fechado
  let primeiroBloco = '';
  for (let i = ini; i < tk.length; i++) {
    const a = tk[i];
    if (a.k === 'i' && !a.esc) {
      const ehCabecalho = (['procedure', 'function', 'constructor', 'destructor'].includes(a.lv) && !eh(tk[i - 1], 'class'))
        || (a.lv === 'class' && ['procedure', 'function', 'constructor', 'destructor', 'operator'].includes((tk[i + 1] || {}).lv));
      // `procedure` depois de `:`/`=`/`of`/`to` é tipo (procedural, reference to), não cabeçalho
      const ehTipo = ehP(tk[i - 1], ':') || ehP(tk[i - 1], '=') || eh(tk[i - 1], 'to') || eh(tk[i - 1], 'of');
      if (profundidade === 0 && ehCabecalho && !ehTipo) {
        let j = a.lv === 'class' ? i + 2 : i + 1;
        let partes = 0;
        while (tk[j] && tk[j].k === 'i') {
          partes++;
          j++;
          if (ehP(tk[j], '<')) { while (j < tk.length && !ehP(tk[j], '>')) j++; j++; }
          if (ehP(tk[j], '.')) { j++; continue; }
          break;
        }
        if (corposPendentes > 0 && partes === 1) corposPendentes++; // rotina local aninhada: herda a marcação
        else { atual = partes > 1; corposPendentes = 1; }
      } else if (profundidade === 0 && (a.lv === 'initialization' || a.lv === 'finalization')) {
        atual = false;
        corposPendentes = 0;
      } else if (a.lv === 'begin' || a.lv === 'try' || a.lv === 'asm' || a.lv === 'case') {
        if (profundidade === 0) primeiroBloco = a.lv;
        profundidade++;
      } else if (a.lv === 'record' && !(ehP(tk[i + 1], '>') || ehP(tk[i + 1], ','))) {
        if (profundidade === 0) primeiroBloco = 'record';
        profundidade++;
      } else if (a.lv === 'end') {
        profundidade = Math.max(0, profundidade - 1);
        // só o fim de um corpo (begin/asm de nível 0) fecha uma rotina; o de um record local não
        if (profundidade === 0 && corposPendentes > 0 && (primeiroBloco === 'begin' || primeiroBloco === 'asm')) corposPendentes--;
      }
    }
    if (atual) marca[i] = 1;
  }
  return marca;
}

function main() {
  const idx = carregarIndice();
  const unidadesRtl = new Set(idx.unidades);
  const SEMPRE = new Set(['system', 'sysinit']);

  // arquivos a verificar
  let alvos = opc.alvos.length ? opc.alvos : ['app', 'core', 'ui', 'midia', 'testes'].filter((d) => fs.existsSync(path.join(raiz, d)));
  const arquivos = [];
  for (const a of alvos) {
    const p = path.resolve(raiz, a);
    if (!fs.existsSync(p)) { console.error(`não existe: ${a}`); process.exitCode = 2; continue; }
    if (fs.statSync(p).isDirectory()) {
      const pas = [];
      (function andar(d) {
        for (const e of fs.readdirSync(d, { withFileTypes: true })) {
          const q = path.join(d, e.name);
          if (e.isDirectory()) { if (!/^(__history|__recovery|__astcache|Win32|Win64|Android64|bin|dcu|.git|node_modules|docs|Serializer)$/i.test(e.name)) andar(q); }
          else if (/\.(pas|dpr)$/i.test(e.name)) pas.push(q);
        }
      })(p);
      arquivos.push(...pas);
    } else arquivos.push(p);
  }
  if (!arquivos.length) { console.log('nenhum arquivo .pas/.dpr para verificar'); return; }

  // units do projeto: todas as .pas da nova base (para resolver uses), mesmo fora dos alvos
  const projeto = new Map(); // lower -> caminho
  for (const d of opc.projeto) {
    const p = path.join(raiz, d);
    if (!fs.existsSync(p)) continue;
    (function andar(dd) {
      for (const e of fs.readdirSync(dd, { withFileTypes: true })) {
        const q = path.join(dd, e.name);
        if (e.isDirectory()) { if (!/^(__history|__recovery|__astcache|Win32|Win64|Android64|bin|dcu|.git|node_modules|docs|Serializer)$/i.test(e.name)) andar(q); }
        else if (/\.pas$/i.test(e.name)) projeto.set(e.name.replace(/\.pas$/i, '').toLowerCase(), q);
      }
    })(p);
  }
  for (const a of arquivos) if (/\.pas$/i.test(a)) projeto.set(path.basename(a).replace(/\.pas$/i, '').toLowerCase(), a);

  // declarações de nível de unit de cada unit do projeto (para o mesmo teste de uses)
  const analises = new Map();
  function analisar(caminho) {
    if (analises.has(caminho)) return analises.get(caminho);
    const texto = fs.readFileSync(caminho, 'utf8');
    const { tokens, dirs } = tokenizar(texto);
    const ehPrograma = /\.dpr$/i.test(caminho) || eh(tokens[0], 'program') || eh(tokens[0], 'library');
    const { iInt, iImpl } = ehPrograma ? { iInt: -1, iImpl: -1 } : secoes(tokens);
    let usesInt = [];
    let usesImpl = [];
    let fimUsesInt = iInt + 1;
    let fimUsesImpl = iImpl + 1;
    if (ehPrograma) {
      const iu = tokens.findIndex((t) => eh(t, 'uses'));
      if (iu >= 0) { const r = lerUses(tokens, iu); usesImpl = r.lista; fimUsesImpl = r.fim + 1; }
    } else {
      if (iInt >= 0 && eh(tokens[iInt + 1], 'uses')) { const r = lerUses(tokens, iInt + 1); usesInt = r.lista; fimUsesInt = r.fim + 1; }
      if (iImpl >= 0 && eh(tokens[iImpl + 1], 'uses')) { const r = lerUses(tokens, iImpl + 1); usesImpl = r.lista; fimUsesImpl = r.fim + 1; }
    }
    const membrosDaUnit = new Set();
    const decInt = (!ehPrograma && iInt >= 0) ? declaracoes(tokens, fimUsesInt, iImpl < 0 ? tokens.length : iImpl, { coletarMetodos: true, membros: membrosDaUnit }) : { nomes: new Map(), tipos: new Map(), rotinas: new Map() };
    const decImpl = (!ehPrograma && iImpl >= 0) ? declaracoes(tokens, fimUsesImpl, tokens.length, { coletarMetodos: true, membros: membrosDaUnit }) : { nomes: new Map(), tipos: new Map(), rotinas: new Map() };
    const r = { caminho, texto, tokens, dirs, ehPrograma, iInt, iImpl, usesInt, usesImpl, fimUsesInt, fimUsesImpl, decInt, decImpl, membrosDaUnit, unidade: path.basename(caminho).replace(/\.(pas|dpr)$/i, '') };
    analises.set(caminho, r);
    return r;
  }

  let totalErros = 0;
  let totalAvisos = 0;
  const grafo = new Map(); // unit do projeto -> units do projeto no uses da interface

  for (const arq of arquivos.sort()) {
    const A = analisar(arq);
    const rel = path.relative(raiz, arq).replace(/\\/g, '/');
    const erros = [];
    const avisos = [];
    const ignorar = new Set(A.dirs.filter((d) => d.ignorar).flatMap((d) => d.ignorar.map((x) => x.toLowerCase())));
    for (const d of A.dirs.filter((x) => x.comentarioAninhado))
      erros.push({ l: d.linha, m: "'{' dentro de um comentário { }: o comentário termina no primeiro '}' e o resto vira código" });
    // Codificação: sem BOM, o dcc lê o fonte no code page ANSI da máquina (1252) e corrompe os acentos.
    {
      const bruto = fs.readFileSync(arq);
      const temBom = bruto[0] === 0xef && bruto[1] === 0xbb && bruto[2] === 0xbf;
      const naoAscii = bruto.some((b) => b >= 0x80);
      if (naoAscii && !temBom) {
        let utf8 = true;
        try { new TextDecoder('utf-8', { fatal: true }).decode(bruto); } catch { utf8 = false; }
        if (utf8) erros.push({ l: 1, m: 'arquivo em UTF-8 sem BOM: o compilador o lê como ANSI (1252) e corrompe os acentos (salve com BOM)' });
      }
    }

    // nome da unit = nome do arquivo
    const cab = A.tokens[0];
    if (cab && (eh(cab, 'unit') || eh(cab, 'program') || eh(cab, 'library'))) {
      const partes = [];
      let j = 1;
      while (A.tokens[j] && A.tokens[j].k === 'i') { partes.push(A.tokens[j].v); if (ehP(A.tokens[j + 1], '.')) j += 2; else break; }
      if (partes.join('.').toLowerCase() !== A.unidade.toLowerCase()) erros.push({ l: cab.l, m: `nome '${partes.join('.')}' diferente do arquivo '${A.unidade}'` });
    } else erros.push({ l: 1, m: "o arquivo não começa com 'unit'/'program'" });

    // 1. uses (nomes curtos são resolvidos pelos prefixos de namespace, com aviso)
    for (const u of [...A.usesInt, ...A.usesImpl]) {
      if (projeto.has(u.lv) || unidadesRtl.has(u.lv)) continue;
      const pre = PREFIXOS_NS.find((p) => unidadesRtl.has(`${p.toLowerCase()}.${u.lv}`));
      if (pre) {
        avisos.push({ l: u.linha, m: `use o nome completo '${pre}.${u.nome}' (o curto depende do namespace do .dproj)` });
        u.lv = `${pre.toLowerCase()}.${u.lv}`;
      }
    }
    const todosUses = [...A.usesInt.map((u) => ({ ...u, sec: 'interface' })), ...A.usesImpl.map((u) => ({ ...u, sec: 'implementation' }))];
    const vistos = new Map();
    for (const u of todosUses) {
      if (vistos.has(u.lv)) erros.push({ l: u.linha, m: `unit '${u.nome}' repetida no uses (já na linha ${vistos.get(u.lv)})` });
      vistos.set(u.lv, u.linha);
      if (u.lv === A.unidade.toLowerCase()) erros.push({ l: u.linha, m: `a unit usa a si mesma` });
      if (!projeto.has(u.lv) && !unidadesRtl.has(u.lv) && !u.arquivo) erros.push({ l: u.linha, m: `unit '${u.nome}' não existe (nem no projeto nem na RTL/FMX instalada)` });
      if (u.arquivo) {
        const alvo = path.resolve(path.dirname(arq), u.arquivo);
        if (!fs.existsSync(alvo)) erros.push({ l: u.linha, m: `uses '${u.nome}' in '${u.arquivo}': arquivo não existe` });
      }
    }
    if (!A.ehPrograma) grafo.set(A.unidade.toLowerCase(), A.usesInt.filter((u) => projeto.has(u.lv)).map((u) => u.lv));

    // 2. identificadores sem a unit no uses
    const declLocal = declaradosNoArquivo(A.tokens);
    const declProjeto = new Map(); // lower -> units do projeto que declaram (interface)
    const membrosVisiveis = new Set(A.membrosDaUnit); // membros de classes desta unit e das units do projeto no uses
    for (const u of [...A.usesInt, ...A.usesImpl]) {
      const cam = projeto.get(u.lv);
      if (!cam) continue;
      const B = analisar(cam);
      for (const lv of B.decInt.nomes.keys()) (declProjeto.get(lv) || declProjeto.set(lv, []).get(lv)).push(u.lv);
      for (const lv of B.decInt.tipos.keys()) if (!lv.includes('.')) (declProjeto.get(lv) || declProjeto.set(lv, []).get(lv)).push(u.lv);
      for (const lv of B.membrosDaUnit) membrosVisiveis.add(lv);
    }
    const emMetodo = A.ehPrograma ? new Uint8Array(A.tokens.length) : marcarCorposDeMetodo(A.tokens, A.iImpl);
    const emWith = marcarWith(A.tokens);
    for (const lv of [...A.decInt.nomes.keys(), ...A.decImpl.nomes.keys(), ...A.decInt.tipos.keys(), ...A.decImpl.tipos.keys()]) declLocal.add(lv);
    const usesIntSet = new Set(A.usesInt.map((u) => u.lv));
    const usesTodosSet = new Set([...A.usesInt, ...A.usesImpl].map((u) => u.lv));
    const jaReportado = new Set();
    const iniCodigo = A.ehPrograma ? A.fimUsesImpl : A.fimUsesInt;
    for (let i = iniCodigo; i < A.tokens.length; i++) {
      const a = A.tokens[i];
      if (a.k !== 'i' || a.esc) continue;
      if (!A.ehPrograma && A.iImpl >= 0 && i > A.iImpl && i < A.fimUsesImpl) continue; // dentro do uses da implementation
      if (PALAVRAS.has(a.lv) || DIRETIVAS.has(a.lv) || VISIBILIDADE.has(a.lv) || PALAVRAS_DE_CONTEXTO.has(a.lv) || EMBUTIDOS.has(a.lv)) continue;
      const ant = A.tokens[i - 1];
      if (ehP(ant, '.') ) continue; // membro: X.Nome
      if (declLocal.has(a.lv) || ignorar.has(a.lv)) continue;
      // dentro de um método, um nome solto pode ser membro herdado (Self implícito)
      if ((emMetodo[i] || emWith[i]) && (idx.membros.has(a.lv) || membrosVisiveis.has(a.lv))) continue;
      const naInterface = !A.ehPrograma && A.iImpl >= 0 && i < A.iImpl;
      const validos = naInterface ? usesIntSet : usesTodosSet;
      // declarado numa unit do projeto que está no uses?
      const doProjeto = declProjeto.get(a.lv);
      if (doProjeto && doProjeto.some((u) => validos.has(u))) continue;
      if (doProjeto && !naInterface) continue;
      let candidatas = idx.ident.get(a.lv);
      if (!candidatas && ehP(ant, '[')) candidatas = idx.ident.get(a.lv + "attribute");
      if (!candidatas) continue;
      if (candidatas.some((u) => SEMPRE.has(u.toLowerCase()))) continue;
      if (candidatas.some((u) => validos.has(u.toLowerCase()))) continue;
      const chave = a.lv + (naInterface ? '@i' : '@m');
      if (jaReportado.has(chave)) continue;
      jaReportado.add(chave);
      const sugestao = [...new Set(candidatas)].slice(0, 4).join(' ou ');
      if (naInterface && candidatas.some((u) => usesTodosSet.has(u.toLowerCase()))) erros.push({ l: a.l, m: `'${a.v}' usado na interface, mas '${sugestao}' só está no uses da implementation` });
      else erros.push({ l: a.l, m: `'${a.v}' sem a unit no uses (declarado em ${sugestao})` });
    }

    // 3. estrutura
    verificarEstrutura(A.tokens, A.ehPrograma, erros);
    // (verificarEstrutura sempre acrescenta "termina sem end." se não encontrar; remover quando achou)
    const idxFim = erros.findIndex((e) => e.m === "arquivo termina sem 'end.'");
    if (idxFim >= 0 && A.tokens.some((t, k) => eh(t, 'end') && ehP(A.tokens[k + 1], '.'))) erros.splice(idxFim, 1);

    // 4. métodos e rotinas
    if (!A.ehPrograma) {
      const tiposDaUnit = new Map([...A.decInt.tipos, ...A.decImpl.tipos]);
      const impl = A.decImpl.rotinas;
      for (const [lvTipo, info] of tiposDaUnit) {
        if (info.tipo === 'interface' || info.tipo === 'dispinterface') continue;
        for (const [lvMet, met] of info.metodos) {
          if (met.semCorpo) continue;
          if (!impl.has(`${lvTipo}.${lvMet}`)) erros.push({ l: met.linha, m: `método '${info.nome}.${met.nome}' declarado e não implementado` });
        }
      }
      for (const [lv, r] of impl) {
        if (!r.qualificado) continue;
        const pos = lv.lastIndexOf('.');
        const lvTipo = lv.slice(0, pos);
        const lvMet = lv.slice(pos + 1);
        const info = tiposDaUnit.get(lvTipo);
        if (!info) erros.push({ l: r.linha, m: `'${r.nome}' implementado, mas o tipo não está declarado nesta unit` });
        else if (!info.metodos.has(lvMet)) erros.push({ l: r.linha, m: `'${r.nome}' implementado, mas não declarado em '${info.nome}'` });
      }
      for (const [lv, r] of A.decInt.rotinas) {
        if (r.qualificado || r.semCorpo) continue;
        if (!impl.has(lv)) erros.push({ l: r.linha, m: `rotina '${r.nome}' declarada na interface e não implementada` });
      }
    }

    // 5. formulários
    const temFmx = A.dirs.some((d) => d.texto && /\{\$R\s+\*\.fmx\}/i.test(d.texto));
    if (temFmx) {
      const fmx = arq.replace(/\.pas$/i, '.fmx');
      if (!fs.existsSync(fmx)) erros.push({ l: 1, m: `{$R *.fmx} sem o arquivo ${path.basename(fmx)}` });
      else {
        const tf = fs.readFileSync(fmx, 'utf8');
        const objetos = new Map();
        const re = /^\s*(?:object|inherited|inline)\s+(\w+)\s*:\s*(\w+)/gim;
        let m;
        let primeiro = null;
        while ((m = re.exec(tf))) { if (!primeiro) primeiro = m; else objetos.set(m[1].toLowerCase(), m[2]); }
        // campos publicados: do início da classe do formulário até a primeira visibilidade
        const tipoForm = primeiro ? primeiro[2].toLowerCase() : null;
        const info = tipoForm ? A.decInt.tipos.get(tipoForm) || A.decImpl.tipos.get(tipoForm) : null;
        if (!info) erros.push({ l: 1, m: `classe '${primeiro ? primeiro[2] : '?'}' do .fmx não declarada na unit` });
        else {
          const campos = new Map();
          const ini = A.tokens.findIndex((t, k) => t.k === 'i' && t.lv === tipoForm && ehP(A.tokens[k + 1], '='));
          for (let k = ini + 2; k < A.tokens.length; k++) {
            const t = A.tokens[k];
            if (eh(t, 'end') || (t.k === 'i' && VISIBILIDADE.has(t.lv)) || eh(t, 'procedure') || eh(t, 'function') || eh(t, 'property')) break;
            if (t.k === 'i' && ehP(A.tokens[k + 1], ':')) campos.set(t.lv, { nome: t.v, tipo: A.tokens[k + 2] ? A.tokens[k + 2].v : '?', l: t.l });
          }
          for (const [lv, c] of campos) {
            if (!objetos.has(lv)) erros.push({ l: c.l, m: `campo '${c.nome}' do formulário sem objeto no .fmx` });
            else if (objetos.get(lv).toLowerCase() !== c.tipo.toLowerCase()) erros.push({ l: c.l, m: `campo '${c.nome}': ${c.tipo} na unit, ${objetos.get(lv)} no .fmx` });
          }
          for (const [lv, tipo] of objetos) if (!campos.has(lv)) avisos.push({ l: 1, m: `objeto '${lv}: ${tipo}' do .fmx sem campo publicado na unit` });
        }
      }
    }

    erros.sort((x, y) => x.l - y.l);
    if (erros.length || avisos.length) {
      console.log(`\n${rel}`);
      for (const e of erros) console.log(`  ✖ ${e.l}: ${e.m}`);
      for (const e of avisos) console.log(`  ⚠ ${e.l}: ${e.m}`);
    }
    totalErros += erros.length;
    totalAvisos += avisos.length;
  }

  // projetos (.dpr): .dproj em sincronia e toda unit do projeto alcançável listada no .dpr
  for (const arq of arquivos.filter((a) => /\.dpr$/i.test(a))) {
    const rel = path.relative(raiz, arq).replace(/\\/g, '/');
    const A = analisar(arq);
    const listadas = new Map(); // unit lower -> caminho relativo ao dpr
    for (const u of A.usesImpl) if (u.arquivo) listadas.set(u.lv, u.arquivo.replace(/\//g, '\\').toLowerCase());
    const problemas = [];
    const dproj = arq.replace(/\.dpr$/i, '.dproj');
    if (fs.existsSync(dproj)) {
      const x = fs.readFileSync(dproj, 'utf8');
      const refs = new Set([...x.matchAll(/<DCCReference\s+Include="([^"]+)"/g)].map((m) => m[1].replace(/\//g, '\\').toLowerCase()));
      for (const [u, cam] of listadas) if (!refs.has(cam)) problemas.push(`'${u}' está no .dpr mas não no .dproj (${cam})`);
      for (const cam of refs) if (![...listadas.values()].includes(cam)) problemas.push(`'${cam}' está no .dproj mas não no .dpr`);
    } else problemas.push(`sem o .dproj ao lado (${path.basename(dproj)})`);
    // fecho: units do projeto usadas (direta ou indiretamente) pelas listadas
    const fila = [...listadas.keys()];
    const vistas = new Set(fila);
    while (fila.length) {
      const u = fila.shift();
      const cam = projeto.get(u);
      if (!cam) continue;
      const B = analisar(cam);
      for (const v of [...B.usesInt, ...B.usesImpl]) {
        if (!projeto.has(v.lv) || vistas.has(v.lv)) continue;
        vistas.add(v.lv);
        fila.push(v.lv);
        if (!listadas.has(v.lv)) problemas.push(`'${v.nome}' é usada por ${B.unidade} mas não está no .dpr (o compilador não a acha sem caminho de busca)`);
      }
    }
    if (problemas.length) {
      console.log(`\n${rel} (projeto)`);
      for (const p of problemas) console.log(`  ✖ ${p}`);
      totalErros += problemas.length;
    }
  }

  // ciclos entre seções interface
  const visit = new Map();
  const ciclos = [];
  function dfs(u, caminho) {
    visit.set(u, 1);
    for (const v of grafo.get(u) || []) {
      if (visit.get(v) === 1) ciclos.push([...caminho, u, v].slice([...caminho, u].indexOf(v)));
      else if (!visit.get(v)) dfs(v, [...caminho, u]);
    }
    visit.set(u, 2);
  }
  for (const u of grafo.keys()) if (!visit.get(u)) dfs(u, []);
  for (const c of ciclos) { console.log(`\n✖ referência circular entre seções interface: ${c.join(' → ')}`); totalErros++; }

  console.log(`\n${arquivos.length} arquivo(s) verificado(s): ${totalErros} erro(s), ${totalAvisos} aviso(s).`);
  if (totalErros) process.exitCode = 1;
}

main();
