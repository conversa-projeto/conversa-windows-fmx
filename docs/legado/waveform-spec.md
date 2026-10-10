# Especificação Técnica: Waveform de Áudio

## Objetivo
Visualização em tempo real das ondas de áudio durante chamadas de voz.

## Componentes

### TWaveformData
Classe responsável pelo armazenamento e processamento dos dados de amplitude.

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| FAmplitudes | array[0..299] of Single | Buffer circular com 300 pontos (10s @ 30fps) |
| FWritePos | Integer | Posição atual de escrita no buffer |

| Método | Descrição |
|--------|-----------|
| AddSamples(Data: TBytes) | Processa chunk PCM 16-bit e extrai pico de amplitude |
| GetAmplitudes | Retorna array ordenado do mais antigo ao mais recente |
| Clear | Limpa o buffer |

### TWaveformView
Componente visual FMX que renderiza o waveform.

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| FPath | TPath | Componente FMX para desenho da curva |
| FTimer | TTimer | Timer de atualização (33ms / 30fps) |
| FData | TWaveformData | Referência aos dados de amplitude |
| Color | TAlphaColor | Cor da linha do waveform |

| Método | Descrição |
|--------|-----------|
| Atualizar | Reconstrói PathData baseado nas amplitudes |
| Vincular(Data: TWaveformData) | Associa fonte de dados |
| Iniciar / Parar | Controle do timer |

## Parâmetros de Áudio

| Parâmetro | Valor |
|-----------|-------|
| Sample Rate | 44100 Hz |
| Bits per Sample | 16 |
| Channels | 1 (mono) |
| Samples por frame | ~1470 (44100 / 30) |

## Integração

### Waveform Geral
- **Local:** TConversaChamadaView
- **Fonte:** FPlayerAudioBuffer (saída do mixer)
- **Posição:** Acima da barra de botões

### Waveform por Usuário
- **Local:** TConversaChamadaUsuariosListItem
- **Fonte:** ClientStream[N].Buffer
- **Posição:** Abaixo do nome do usuário

## Fluxo de Dados

```
[Captura Local] → FCaptureAudioBuffer → TCP Server
                                            ↓
[TCP Receive] → ClientStream[N].Buffer → TWaveformData[N] → TWaveformView[N]
                        ↓
                   AudioMixer
                        ↓
                FPlayerAudioBuffer → TWaveformData(Geral) → TWaveformView(Geral)
```

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| Conversa.Chamada.Waveform.pas | Unit com TWaveformData e TWaveformView |
| Conversa.Chamada.view.pas | Integração do waveform geral |
| Conversa.Chamada.Usuarios.Listagem.Item.pas | Integração do waveform por usuário |
