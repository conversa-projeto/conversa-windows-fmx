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

O verificador avalia `{$IFDEF}`/`{$IF}`/`{$ELSE}` como num build **Win64 Debug** (`MSWINDOWS`, `WIN64`, `CPUX64`, `DEBUG`…), e o código das outras plataformas fica de fora.

## Limites conhecidos

- **Não confere tipos:** assinaturas, número de parâmetros, compatibilidade de atribuições, sobrecargas. Isso continua dependendo de revisar contra o fonte do Delphi (`Studio\23.0\source`) e do build no IDE.
- **Membros:** dentro de corpos de método e de blocos `with`, um nome solto que existe como membro de alguma classe (da RTL ou do projeto) é aceito sem conferir a herança.
  - Na nova base, **não usar `with`**.
- **Falsos positivos** podem ser silenciados com um comentário na própria unit:
  ```pascal
  // verificar-uses: ignorar NomeDoIdentificador
  ```

## Calibração (2026-10-09)

Rodado contra o código do app atual (`src`, `lib`, `conversa-webrtc` e as units da raiz), que compila no IDE. Os 1.963 apontamentos da primeira versão caíram para os acertos reais:
- `src/chat/Conversa.Conteudo.pas` usa units inexistentes (`Mensagem.Visualizador`, `Mensagem.Editor`, `Mensagem.Tipos`, `Mensagem.Anexo`). É código morto: a unit não está no projeto.
- `Conversa.Inicializacoes.pas` e `Conversa.Memoria.pas` usam `Conversa.Log`, que não existe no repositório.
- Avisos de nome curto de unit (DCPcrypt, `MMSystem`, `Skia`) e de objetos do `.fmx` sem campo publicado.

Cada falso positivo encontrado na calibração virou uma regra: `SCOPEDENUMS`, tipos embutidos, `Self` implícito, `with`, rotinas locais aninhadas, `record` aninhado, compilação condicional e parâmetros `const` em cabeçalhos.
