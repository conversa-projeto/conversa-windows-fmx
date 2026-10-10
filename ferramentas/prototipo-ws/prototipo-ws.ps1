<#
  Protótipo do tempo real da nova base (TODO 0.7, doc 07 §10, D9).

  Usa as MESMAS funções do WinHTTP que o Delphi vai usar (WinHttpWebSocketCompleteUpgrade,
  WinHttpWebSocketSend/Receive/Close) para provar, nesta máquina e contra o servidor de
  desenvolvimento, que:
    - o handshake em wss://<host>/ws/ funciona com o certificado do mkcert (repositório do usuário);
    - o login {"tipo":1,"token":...} (tipo como NÚMERO JSON) é aceito;
    - os eventos chegam (WS 2 quando outro usuário manda mensagem);
    - a conexão sobrevive a minutos ociosa (keepalive do WinHTTP);
    - a queda da API (docker restart api) é percebida e o cliente reconecta com backoff.

  Nunca registra o token, a senha nem o conteúdo das mensagens: só o tipo e o tamanho de cada evento.

  Uso (PowerShell do Windows 5.1 ou 7):
    $env:CONVERSA_LOGIN = 'teste.android.a'
    $env:CONVERSA_SENHA = '<senha da conta de teste>'
    .\prototipo-ws.ps1 -Servidor https://localhost -Minutos 8
#>
param(
  [string]$Servidor = 'https://localhost',
  [int]$Minutos = 8,
  [int]$KeepaliveMs = 30000
)

$ErrorActionPreference = 'Stop'

if (-not $env:CONVERSA_LOGIN -or -not $env:CONVERSA_SENHA) {
  throw 'Defina CONVERSA_LOGIN e CONVERSA_SENHA (conta de teste do servidor de desenvolvimento).'
}

$codigo = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class WinHttpWs
{
    // Valores do winhttp.h (Windows SDK). Os que a RTL do Delphi não declara estão marcados com *.
    public const uint WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY = 4;          // * (Windows 8.1+)
    public const uint WINHTTP_FLAG_SECURE = 0x00800000;
    public const uint WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET = 114;       // *
    public const uint WINHTTP_OPTION_WEB_SOCKET_CLOSE_TIMEOUT = 115;    // *
    public const uint WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL = 116; // *
    public const uint WINHTTP_QUERY_STATUS_CODE = 19;
    public const uint WINHTTP_QUERY_FLAG_NUMBER = 0x20000000;
    public const int BUFFER_BINARY_MESSAGE = 0;   // *
    public const int BUFFER_BINARY_FRAGMENT = 1;  // *
    public const int BUFFER_UTF8_MESSAGE = 2;     // *
    public const int BUFFER_UTF8_FRAGMENT = 3;    // *
    public const int BUFFER_CLOSE = 4;            // *
    public const ushort CLOSE_SUCCESS = 1000;     // *

    [DllImport("winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr WinHttpOpen(string agent, uint accessType, string proxy, string bypass, uint flags);
    [DllImport("winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr WinHttpConnect(IntPtr session, string server, ushort port, uint reserved);
    [DllImport("winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr WinHttpOpenRequest(IntPtr connect, string verb, string objectName, string version,
        string referrer, IntPtr acceptTypes, uint flags);
    [DllImport("winhttp.dll", SetLastError = true)]
    public static extern bool WinHttpSetOption(IntPtr handle, uint option, IntPtr buffer, uint length);
    [DllImport("winhttp.dll", SetLastError = true)]
    public static extern bool WinHttpSetOption(IntPtr handle, uint option, ref uint buffer, uint length);
    [DllImport("winhttp.dll", SetLastError = true)]
    public static extern bool WinHttpSetTimeouts(IntPtr handle, int resolve, int connect, int send, int receive);
    [DllImport("winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool WinHttpSendRequest(IntPtr request, string headers, uint headersLength, IntPtr optional,
        uint optionalLength, uint totalLength, IntPtr context);
    [DllImport("winhttp.dll", SetLastError = true)]
    public static extern bool WinHttpReceiveResponse(IntPtr request, IntPtr reserved);
    [DllImport("winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool WinHttpQueryHeaders(IntPtr request, uint infoLevel, string name, ref uint buffer,
        ref uint bufferLength, IntPtr index);
    [DllImport("winhttp.dll", SetLastError = true)]
    public static extern IntPtr WinHttpWebSocketCompleteUpgrade(IntPtr request, IntPtr context);
    [DllImport("winhttp.dll")]
    public static extern uint WinHttpWebSocketSend(IntPtr webSocket, int bufferType, byte[] buffer, uint length);
    [DllImport("winhttp.dll")]
    public static extern uint WinHttpWebSocketReceive(IntPtr webSocket, byte[] buffer, uint length, out uint read,
        out int bufferType);
    [DllImport("winhttp.dll")]
    public static extern uint WinHttpWebSocketClose(IntPtr webSocket, ushort status, IntPtr reason, uint length);
    [DllImport("winhttp.dll")]
    public static extern uint WinHttpWebSocketQueryCloseStatus(IntPtr webSocket, out ushort status, byte[] reason,
        uint length, out uint consumed);
    [DllImport("winhttp.dll", SetLastError = true)]
    public static extern bool WinHttpCloseHandle(IntPtr handle);

    public static IntPtr Sessao;
    public static IntPtr Conexao;
    public static IntPtr Socket;
    public static string Ultimo = "";

    static void Falha(string onde)
    {
        throw new Exception(onde + " falhou: erro " + Marshal.GetLastWin32Error());
    }

    // Abre o socket e devolve o status HTTP do handshake (101 = sucesso).
    public static uint Conectar(string host, ushort porta, string caminho, uint keepaliveMs)
    {
        Ultimo = "keepalive no websocket: não configurado (sem upgrade)";
        Sessao = WinHttpOpen("Conversa-prototipo-ws/1.0", WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY, null, null, 0);
        if (Sessao == IntPtr.Zero) Falha("WinHttpOpen");
        // Resolver, conectar, enviar, receber (ms). O receber só vale até o upgrade.
        WinHttpSetTimeouts(Sessao, 10000, 10000, 10000, 15000);
        Conexao = WinHttpConnect(Sessao, host, porta, 0);
        if (Conexao == IntPtr.Zero) Falha("WinHttpConnect");
        IntPtr req = WinHttpOpenRequest(Conexao, "GET", caminho, null, null, IntPtr.Zero, WINHTTP_FLAG_SECURE);
        if (req == IntPtr.Zero) Falha("WinHttpOpenRequest");
        try
        {
            if (!WinHttpSetOption(req, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, IntPtr.Zero, 0)) Falha("UPGRADE_TO_WEB_SOCKET");
            if (!WinHttpSendRequest(req, null, 0, IntPtr.Zero, 0, 0, IntPtr.Zero)) Falha("WinHttpSendRequest");
            if (!WinHttpReceiveResponse(req, IntPtr.Zero)) Falha("WinHttpReceiveResponse");
            uint status = 0, tam = 4;
            if (!WinHttpQueryHeaders(req, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, null, ref status, ref tam, IntPtr.Zero))
                Falha("WinHttpQueryHeaders");
            if (status != 101) return status;
            Socket = WinHttpWebSocketCompleteUpgrade(req, IntPtr.Zero);
            if (Socket == IntPtr.Zero) Falha("WinHttpWebSocketCompleteUpgrade");
            // O intervalo de keepalive só é aceito no handle do WebSocket, depois do upgrade: na sessão e no
            // pedido o WinHTTP responde 12018 (ERROR_WINHTTP_INCORRECT_HANDLE_TYPE). Mínimo 15000 ms; padrão 30000.
            Ultimo = "keepalive no websocket: " + (WinHttpSetOption(Socket, WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL, ref keepaliveMs, 4)
                ? keepaliveMs + " ms" : "erro " + Marshal.GetLastWin32Error());
            return status;
        }
        finally
        {
            WinHttpCloseHandle(req); // depois do upgrade, o pedido HTTP pode (e deve) ser fechado
        }
    }

    public static uint EnviarTexto(string texto)
    {
        byte[] dados = Encoding.UTF8.GetBytes(texto);
        return WinHttpWebSocketSend(Socket, BUFFER_UTF8_MESSAGE, dados, (uint)dados.Length);
    }

    // Recebe uma mensagem inteira (junta fragmentos). Devolve o código de erro do WinHTTP (0 = ok).
    public static uint Receber(out string texto, out int tipoBuffer)
    {
        texto = null;
        tipoBuffer = -1;
        byte[] buffer = new byte[16384];
        System.IO.MemoryStream acumulado = new System.IO.MemoryStream();
        while (true)
        {
            uint lidos;
            int tipo;
            uint erro = WinHttpWebSocketReceive(Socket, buffer, (uint)buffer.Length, out lidos, out tipo);
            if (erro != 0) return erro;
            tipoBuffer = tipo;
            acumulado.Write(buffer, 0, (int)lidos);
            if (tipo == BUFFER_UTF8_FRAGMENT || tipo == BUFFER_BINARY_FRAGMENT) continue;
            texto = Encoding.UTF8.GetString(acumulado.ToArray());
            return 0;
        }
    }

    public static string StatusFechamento()
    {
        ushort status;
        uint consumido;
        byte[] motivo = new byte[123];
        uint erro = WinHttpWebSocketQueryCloseStatus(Socket, out status, motivo, (uint)motivo.Length, out consumido);
        if (erro != 0) return "sem status de fechamento (erro " + erro + ")";
        return status + " " + Encoding.UTF8.GetString(motivo, 0, (int)consumido);
    }

    public static void Fechar()
    {
        if (Socket != IntPtr.Zero)
        {
            WinHttpWebSocketClose(Socket, CLOSE_SUCCESS, IntPtr.Zero, 0);
            WinHttpCloseHandle(Socket);
            Socket = IntPtr.Zero;
        }
        if (Conexao != IntPtr.Zero) { WinHttpCloseHandle(Conexao); Conexao = IntPtr.Zero; }
        if (Sessao != IntPtr.Zero) { WinHttpCloseHandle(Sessao); Sessao = IntPtr.Zero; }
    }
}
'@

Add-Type -TypeDefinition $codigo -Language CSharp

function Registrar([string]$texto) {
  Write-Host ('{0:HH:mm:ss.fff}  {1}' -f (Get-Date), $texto)
}

function Entrar() {
  $corpo = @{ login = $env:CONVERSA_LOGIN.Trim(); senha = $env:CONVERSA_SENHA } | ConvertTo-Json -Compress
  $r = Invoke-RestMethod -Method Post -Uri ($Servidor.TrimEnd('/') + '/api/login') -Body ([Text.Encoding]::UTF8.GetBytes($corpo)) -ContentType 'application/json; charset=utf-8'
  if (-not $r.token) { throw 'Resposta de login inválida: token ausente.' }
  Registrar ('login HTTP ok: usuário {0}, token com {1} caracteres' -f $r.id, $r.token.Length)
  return $r.token
}

$uri = [Uri]$Servidor
$porta = if ($uri.IsDefaultPort) { 443 } else { $uri.Port }
$token = Entrar
$fim = (Get-Date).AddMinutes($Minutos)
$tentativa = 0
$contagem = @{}
$rnd = New-Object Random

while ((Get-Date) -lt $fim) {
  try {
    $t0 = Get-Date
    $status = [WinHttpWs]::Conectar($uri.Host, [uint16]$porta, '/ws/', [uint32]$KeepaliveMs)
    Registrar ([WinHttpWs]::Ultimo)
    if ($status -ne 101) { throw "handshake recusado: HTTP $status" }
    Registrar ('conectado em {0:N0} ms (HTTP 101)' -f ((Get-Date) - $t0).TotalMilliseconds)
    $tentativa = 0

    # tipo como NÚMERO JSON (o servidor compara com ===; "1" em texto é ignorado em silêncio)
    $erro = [WinHttpWs]::EnviarTexto('{"tipo":1,"token":"' + $token + '"}')
    if ($erro -ne 0) { throw "envio do login falhou: erro $erro" }
    Registrar 'login do socket enviado (sem resposta de sucesso, por contrato)'

    $ultimoEvento = Get-Date
    while ((Get-Date) -lt $fim) {
      $texto = $null; $tipoBuf = 0
      $erro = [WinHttpWs]::Receber([ref]$texto, [ref]$tipoBuf)
      if ($erro -ne 0) { Registrar "recepção terminou com erro do WinHTTP $erro"; break }
      if ($tipoBuf -eq [WinHttpWs]::BUFFER_CLOSE) { Registrar ('servidor fechou: ' + [WinHttpWs]::StatusFechamento()); break }
      $tipoEvento = '?'
      try { $tipoEvento = ($texto | ConvertFrom-Json).tipo } catch { $tipoEvento = 'JSON inválido' }
      $contagem[[string]$tipoEvento] = 1 + [int]$contagem[[string]$tipoEvento]
      $ocioso = ((Get-Date) - $ultimoEvento).TotalSeconds
      Registrar ('evento tipo {0} ({1} bytes) depois de {2:N0} s sem eventos' -f $tipoEvento, [Text.Encoding]::UTF8.GetByteCount($texto), $ocioso)
      if ($tipoEvento -eq 0) { Registrar 'tipo 0: sessão recusada pelo servidor -> relogar'; $token = Entrar; break }
      $ultimoEvento = Get-Date
    }
  } catch {
    Registrar ('falha: ' + $_.Exception.Message)
  } finally {
    [WinHttpWs]::Fechar()
  }
  if ((Get-Date) -ge $fim) { break }
  # backoff min(30 s, 1 s × 2^n) com jitter de até 20%
  $espera = [Math]::Min(30, [Math]::Pow(2, $tentativa))
  $espera = $espera * (0.8 + 0.4 * $rnd.NextDouble())
  $tentativa++
  Registrar ('reconectando em {0:N1} s (tentativa {1})' -f $espera, $tentativa)
  Start-Sleep -Milliseconds ([int]($espera * 1000))
}

Registrar ('fim. eventos por tipo: ' + (($contagem.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ', '))
