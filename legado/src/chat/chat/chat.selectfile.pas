unit chat.selectfile;

interface

uses
  System.SysUtils,
  System.Classes,
  chat.tipos;

procedure SelectFile(OnSelect: TProc<TFileSelected>);

implementation

uses
  System.IOUtils,
  System.Messaging,
  System.UITypes,
  {$IFDEF Android}
  FMX.Helpers.Android,
  FMX.Platform.Android,
  Androidapi.Helpers,
  Androidapi.JNI.App,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Net,
  Androidapi.JNI,
  Androidapi.JNI.Os,
  Androidapi.JNI.Provider,
  Androidapi.JNIBridge,
  {$ENDIF}
  FMX.Dialogs,
  FMX.Types;

const
  REQUEST_CODE_OPEN_FILE = 1; // Código para identificar a ação de abrir o arquivo

{$IFDEF MSWINDOWS}
procedure SelectFile(OnSelect: TProc<TFileSelected>);
var
  I: Integer;
begin
  if not Assigned(OnSelect) then
    Exit;
  with TOpenDialog.Create(nil) do
  try
    Options := [TOpenOption.ofAllowMultiSelect];
    if not Execute then
      Exit;

    for I := 0 to Pred(Files.Count) do
      OnSelect(TFileSelected.Create(Files[I]));
  finally
    Free;
  end;
end;
{$ENDIF}

{$IFDEF Android}
var
  OnSelectFile: TProc<TFileSelected>;

function GetFileNameFromURI(const AUri: Jnet_Uri): string;
var
  Cursor: JCursor;
  NameIndex: Integer;
  Projection: TJavaObjectArray<JString>;
  ContentResolver: JContentResolver;
begin
  Result := '';

  ContentResolver := TAndroidHelper.Context.getContentResolver;

  // Defina a projeção para buscar o nome do arquivo
  Projection := TJavaObjectArray<JString>.Create(1);
  Projection.Items[0] := TJOpenableColumns.JavaClass.DISPLAY_NAME;

  // Consulta o ContentResolver para obter o nome do arquivo
  Cursor := ContentResolver.query(AUri, Projection, nil, nil, nil);

  if Cursor <> nil then
  try
    if Cursor.moveToFirst then
    begin
      NameIndex := Cursor.getColumnIndex(TJOpenableColumns.JavaClass.DISPLAY_NAME);
      Result := JStringToString(Cursor.getString(NameIndex));
    end;
  finally
    Cursor.close;
  end;
end;

procedure SelectFile(OnSelect: TProc<TFileSelected>);
var
  Intent: JIntent;
begin
  OnSelectFile := OnSelect;
  Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
  Intent.setType(StringToJString('*/*')); // Definindo o tipo de arquivo
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);

  // Permite a seleção de múltiplos arquivos
  Intent.putExtra(TJIntent.JavaClass.EXTRA_ALLOW_MULTIPLE, True);


  TAndroidHelper.Activity.startActivityForResult(Intent, REQUEST_CODE_OPEN_FILE);
end;

function InputStreamToStringStream(AInputStream: JInputStream): TMemoryStream;
var
  Buffer: TJavaArray<Byte>;
begin
  Result := TMemoryStream.Create;
  try
    Buffer := TJavaArray<Byte>.Create(AInputStream.available);
    AInputStream.read(Buffer);
    Result.Write(Buffer.Data^, Buffer.Length);
    Result.Position := 0;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function GetUri(uri: Jnet_Uri; context: JContext): Jnet_Uri;
var
  resultURI: Jnet_Uri;
  cr: JContentResolver;
  mimeType: JString;
  extensionFile: string;
  tempFile: JFile;
  input: JInputStream;
  output: JFileOutputStream;
  buffer: TJavaArray<Byte>;
  bytesRead: Integer;
begin
  resultURI := uri;

  cr := context.getContentResolver;

  // Obtém o tipo MIME do arquivo
  mimeType := cr.getType(uri);
  extensionFile := '';

  ShowMessage(JStringToString(mimeType));

  // Define extensões padrão para alguns tipos MIME conhecidos
  if JStringToString(mimeType) = 'image/jpeg' then
    extensionFile := '.jpg'
  else if JStringToString(mimeType) = 'image/png' then
    extensionFile := '.png'
  else if JStringToString(mimeType) = 'application/pdf' then
    extensionFile := '.pdf'
  else
    extensionFile := '.tmp'; // Usar extensão genérica para outros tipos

  // Cria um arquivo temporário no diretório de cache
  tempFile := TJFile.JavaClass.createTempFile(
    StringToJString('myTempFile'),
    StringToJString(extensionFile),
    TAndroidHelper.Activity.getCacheDir
  );

  // Abre o InputStream do ContentResolver
  input := cr.openInputStream(uri);
  output := TJFileOutputStream.JavaClass.init(tempFile);

  try
    buffer := TJavaArray<Byte>.Create(1024);

    // Copia os dados do InputStream para o arquivo temporário
    repeat
      bytesRead := input.read(buffer);
      if bytesRead > 0 then
        output.write(buffer, 0, bytesRead);
    until bytesRead = -1;

    // Define o resultURI como o URI do arquivo temporário
    resultURI := TJnet_Uri.JavaClass.fromFile(tempFile);
  finally
    input.close;
    output.close;
  end;

  Result := resultURI;
end;

procedure DoSelectFile(Uri: Jnet_Uri);
var
  Resolver: JContentResolver;
  InputStream: JInputStream;
  SelectedFile: TFileSelected;
  tempFile: JFile;
  output: JFileOutputStream;
  buffer: TJavaArray<Byte>;
begin
  if not Assigned(Uri) then
    Exit;

  Resolver := TAndroidHelper.Context.getContentResolver;
  InputStream := Resolver.openInputStream(Uri);
  if not Assigned(InputStream) then
    Exit;

  try
    SelectedFile.Name := GetFileNameFromURI(Uri);
    SelectedFile.Extension := TPath.GetExtension(SelectedFile.Name).TrimLeft(['.']);
    SelectedFile.MimeType := JStringToString(Resolver.getType(Uri));

    // Cria um arquivo temporário no diretório de cache
    tempFile := TJFile.JavaClass.createTempFile(
      StringToJString(SelectedFile.Name.Replace('.'+ SelectedFile.Extension, '')),
      StringToJString('.'+ SelectedFile.Extension),
      TAndroidHelper.Activity.getCacheDir
    );

    buffer := InputStream.readAllBytes;
    output := TJFileOutputStream.JavaClass.init(tempFile);
    output.write(buffer);
    Uri := TJnet_Uri.JavaClass.fromFile(tempFile);

    SelectedFile.Path := JStringToString(tempFile.getPath);// GetFileNameFromURI(Uri);
    if not tempFile.exists then
      raise Exception.Create('Arquivo temporário inexistente!');
    SelectedFile.Extension := TPath.GetExtension(SelectedFile.Path).TrimLeft(['.']);

    SelectedFile.Data := TMemoryStream.Create;
    SelectedFile.Data.Write(buffer.Data^, buffer.Length);
    OnSelectFile(SelectedFile);
  finally
    InputStream.close;
  end;
end;

procedure HandleActivityResult(RequestCode, ResultCode: Integer; Data: JIntent);
var
  ClipData: JClipData;
  i: Integer;
begin
  if (RequestCode = REQUEST_CODE_OPEN_FILE) and (ResultCode = TJActivity.JavaClass.RESULT_OK) then
  begin
    if Assigned(Data) then
    begin
      // Verifica se múltiplos arquivos foram selecionados usando ClipData
      ClipData := Data.getClipData;
      if Assigned(ClipData) then
      begin
        // Loop através dos itens no ClipData
        for i := 0 to ClipData.getItemCount - 1 do
          DoSelectFile(ClipData.getItemAt(i).getUri);
      end
      else
        DoSelectFile(Data.getData);
    end;
  end;
end;

procedure RegisterActivityResultCallback;
begin
  TMessageManager.DefaultManager.SubscribeToMessage(
    TMessageResultNotification,
    procedure(const Sender: TObject; const M: TMessage)
    begin
      if M is TMessageResultNotification then
        HandleActivityResult(TMessageResultNotification(M).RequestCode, TMessageResultNotification(M).ResultCode, TMessageResultNotification(M).Value);
    end
  );
end;

initialization
  RegisterActivityResultCallback;
{$ENDIF}

end.
