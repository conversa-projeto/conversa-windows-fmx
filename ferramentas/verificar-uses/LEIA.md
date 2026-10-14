# Verificador estático das units (sem compilar)

Esta máquina não compila Delphi por linha de comando (edição Community; o `DelphiLSP` fora do IDE também exige licença — ADR 0001). O verificador é a rede de segurança entre escrever o código e o "build geral" do responsável no IDE. **Não substitui o compilador.**

## Como rodar

```bash
node ferramentas/verificar-uses/verificar.mjs                 # app, core, ui, midia, testes (as que existirem)
node ferramentas/verificar-uses/verificar.mjs core/eventos    # só uma pasta ou arquivo
node ferramentas/verificar-uses/verificar.mjs --reindexar     # refaz o índice da RTL (depois de atualizar o Delphi)
```

Precisa do Node 18+ e do Delphi 12 instalado em `C:\Program Files (x86)\Embarcadero\Studio\23.0`; para outro caminho, use `--bds <pasta>`. O índice da RTL leva ~3 s e fica em cache no `%TEMP%`. Sai com código 1 se houver erro.

## O que confere

1. **`uses`:**
   - unit que não existe (nem no projeto nem na RTL/FMX/FireDAC/DUnitX/Skia instalada);
   - unit repetida;
   - unit que usa a si mesma;
   - ciclo entre seções `interface` de units do projeto;
   - nome curto que depende do *namespace* do `.dproj` (aviso: use `System.SysUtils`, não `SysUtils`).
2. **Identificador sem a unit no `uses`:** todo identificador de nível de unit declarado na seção `interface` da RTL/FMX/FireDAC/DUnitX/Skia (tipos, rotinas, constantes, variáveis, valores de enumeração sem `SCOPEDENUMS`) usado sem a unit que o declara. Na seção `interface`, só valem as units do `uses` da interface.
3. **Estrutura:** `begin`/`try`/`case`/`asm`/`record`/`class`/`interface`/`object` sem o `end` correspondente; `except`/`finally` fora de `try`; unit sem `implementation` ou sem `end.`.
4. **Métodos:**
   - método declarado na classe/record e não implementado;
   - método implementado e não declarado;
   - método implementado numa unit diferente da do tipo;
   - rotina da `interface` sem implementação.
5. **Formulários:**
   - `{$R *.fmx}` sem o `.fmx`;
   - campo publicado sem objeto no `.fmx` ou com outra classe (erro);
   - objeto do `.fmx` sem campo publicado (aviso).
6. **Codificação:** fonte com acento em UTF-8 **sem BOM** é erro. Sem BOM, o compilador lê o arquivo no code page ANSI da máquina (1252) e corrompe todo texto acentuado. Os testes não pegam isso, porque os dois lados da comparação ficam corrompidos do mesmo jeito.
7. **Comentário `{ }` com `{` dentro** é erro: em Pascal ele não aninha, e o primeiro `}` fecha o comentário. Aconteceu na nova base com `{error}` dentro do cabeçalho de uma unit, e o resto do texto virou código.
8. **Projetos (`.dpr`):**
   - o `.dproj` ao lado tem os mesmos `DCCReference` que os `uses ... in` do `.dpr`;
   - toda unit do projeto usada, direta ou indiretamente, está listada no `.dpr`. Sem caminho de busca, o compilador não acha uma unit que só outra unit usa ("File not found").

O verificador avalia `{$IFDEF}`/`{$IF}`/`{$ELSE}` como num build **Win64 Debug** (`MSWINDOWS`, `WIN64`, `CPUX64`, `DEBUG`…), e o código das outras plataformas fica de fora.

## Limites conhecidos

- **Não confere tipos:** assinaturas, número de parâmetros, compatibilidade de atribuições, sobrecargas. Isso continua dependendo de revisar contra o fonte do Delphi (`Studio\23.0\source`) e do build no IDE.
- **Membros:** dentro de corpos de método e de blocos `with`, um nome solto que existe como membro de alguma classe (da RTL ou do projeto) é aceito sem conferir a herança.
  - Na nova base, **não usar `with`**.
- **`{` dentro de comentário:** no legado aparece um caso inofensivo (cabeçalho de licença do DCPcrypt). Na nova base a regra é estrita.
- **Falsos positivos** podem ser silenciados com um comentário na própria unit:
  ```pascal
  // verificar-uses: ignorar NomeDoIdentificador
  ```

## Calibração (2026-10-09)

Rodado contra o código do app atual (153 arquivos: `src`, `lib`, `conversa-webrtc` e as units da raiz), que compila no IDE. Os 1.963 apontamentos da primeira versão caíram para 7, todos acertos reais, todos em units que **não estão no `Conversa.dproj`** (código morto, que não compilaria):
- `src/chat/Conversa.Conteudo.pas`: usa units inexistentes (`Mensagem.Visualizador`, `Mensagem.Editor`, `Mensagem.Tipos`, `Mensagem.Anexo`);
- `lib/tcp.pas`: `IPPROTO_IP`/`IP_TOS` sem `Winapi.WinSock` no `uses`;
- `src/chamada/Conversa.Audio.Windows.pas`: `ECaptureDeviceException` com o `FMX.Media` comentado no `uses`.

Ficaram também 76 avisos: nomes curtos de unit (DCPcrypt, `MMSystem`, `Skia`) e objetos do `.fmx` sem campo publicado.

Cada falso positivo encontrado na calibração virou uma regra:
- `SCOPEDENUMS`;
- tipos embutidos;
- `Self` implícito;
- `with`;
- rotinas locais aninhadas;
- `record` aninhado;
- tipo genérico com o mesmo nome de um não genérico (`TX` e `TX<T>`);
- compilação condicional;
- parâmetros `const` em cabeçalhos;
- extensão `.Pas` em maiúsculas.

A conferência inversa também passou: numa unit com erros plantados, todos foram apontados. Os erros plantados foram:
- unit repetida e inexistente;
- `TStringList`, `TStream` e `Max` sem a unit;
- método sem implementação e implementação sem declaração;
- rotina sem corpo;
- `finally` fora de `try` e `begin` sem `end`.

O método `abstract` não foi apontado, como devia.
