unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.WinXCalendars, Vcl.ExtCtrls,
  Vcl.WinXPickers, VclTee.TeeGDIPlus, Vcl.StdCtrls, VCLTee.TeEngine,
  VCLTee.TeeProcs, VCLTee.Chart, frxClass, VCLTee.Series, PythonEngine,
  Vcl.PythonGUIInputOutput, SynEditPythonBehaviour, SynEditHighlighter,
  SynEditCodeFolding, SynHighlighterPython, SynEdit, DateUtils, Vcl.ComCtrls,
  JSon;

type
  TLaboratorio = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Laboratorio: TComboBox;
    Pesquisar: TButton;
    Panel3: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    TempUmi: TChart;
    UMedia: TEdit;
    TMedia: TEdit;
    Exportar: TButton;
    Imprimir: TButton;
    Label4: TLabel;
    Label7: TLabel;
    frxReport1: TfrxReport;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Label8: TLabel;
    SynEdit1: TSynEdit;
    Memo1: TMemo;
    PythonEngine1: TPythonEngine;
    SynPythonSyn1: TSynPythonSyn;
    SynEditPythonBehaviour1: TSynEditPythonBehaviour;
    PythonGUIInputOutput1: TPythonGUIInputOutput;
    DataInicio: TDateTimePicker;
    DataFinal: TDateTimePicker;
    HoraInicio: TDateTimePicker;
    HoraFinal: TDateTimePicker;
    Sair: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ImprimirClick(Sender: TObject);
    procedure PesquisarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SairClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Laboratorio: TLaboratorio;


implementation

{$R *.dfm}

procedure TLaboratorio.Button1Click(Sender: TObject);
var
  jsonObj, jSubObj: TJSONObject;
  ja: TJSONArray;
  jv: TJSONValue;
    datahora: array of TDatetime;
  temp: array of double;
  I: Integer;
  texto: String;
begin
  texto := '{"T": [{"ts": 1656012688505, "value": "28.0"}, {"ts": 1656012628158, "value": "28.0"}, {"ts": 1656012567730, "value": "28.0"}]}';
  jsonObj := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(Memo1.Text), 45, false) as TJSONObject;

  jv := jsonObj.Get('T').JsonValue;
  ja := jv as TJSONArray;

  setlength(datahora, ja.Count);
  setlength(temp, ja.Count);
//  setlength(umi, ja.Count);

  for I := 0 to ja.Count - 1 do
  begin
    jSubObj := ja.Items[I] as TJSONObject;
    datahora[I] := UnixToDateTime(Round(StrToINT64(jSubObj.GetValue('ts').Value)/1000), false);
    temp[I] := StrToFloat(StringReplace(jSubObj.GetValue('value').Value, '.', ',', [rfReplaceAll]));
//    umi[I] := StrToINT(jSubObj.GetValue('UM').Value);
  end;
end;

procedure TLaboratorio.FormCreate(Sender: TObject);
begin
  DataFinal.Date := Now;
  HoraFinal.Time := Now;
  DataInicio.Date := Now;
  HoraInicio.Time := Now;
  TMedia.Text := '';
  UMedia.Text := '';
  SynEdit1.lines.Clear;
  Memo1.Lines.Clear;
end;

procedure TLaboratorio.ImprimirClick(Sender: TObject);
begin
  TempUmi.SaveToBitmapFile('TempUmi.bmp');
  frxReport1.Variables.Variables['Laboratorio'] := Quotedstr(UPPERCASE(Laboratorio.Text));
  frxReport1.Variables.Variables['Temperatura'] := Quotedstr(TMedia.Text+' C');
  frxReport1.Variables.Variables['Umidade'] := Quotedstr(UMedia.Text+' %');
  frxReport1.Variables.Variables['OBS'] := Quotedstr('Ensaio com início em '+ DateToStr(DataInicio.Date)+' '+TimeToStr(HoraInicio.Time)+' e término em '+ DateToStr(DataFinal.Date)+' '+TimeToStr(HoraFinal.Time)+'.');
  frxReport1.ShowReport();
end;

procedure TLaboratorio.PesquisarClick(Sender: TObject);
var
  datahora: array of TDatetime;
  temp: array of double;
  tempmin, tempmax, tempmedia: double;
  umi: array of double;
  umimin, umimax, umimedia: double;
  I: Integer;
  comando, key, linha, retira, resultado: String;
  inicio, final: Int64;
  jsonObj, jSubObj: TJSONObject;
  jaT, jaU: TJSONArray;
  jvT, jvU: TJSONValue;
begin
  inicio := DateUtils.DateTimeToUnix(DataInicio.Date + HoraInicio.Time, false);
  final := DateTimeToUnix(DataFinal.Date + HoraFinal.Time, false);

  key:= 'T';

  Memo1.Clear;
  SynEdit1.lines.Clear;
  SynEdit1.lines.Add('import logging');
  SynEdit1.lines.Add('from tb_rest_client.rest_client_ce import *');
  SynEdit1.lines.Add('from tb_rest_client.rest import ApiException');
  SynEdit1.lines.Add('logging.basicConfig(level=logging.DEBUG,');
  SynEdit1.lines.Add('                   format='+chr(39)+'%(asctime)s - %(levelname)s - %(module)s - %(lineno)d - %(message)s'+chr(39)+',');
  SynEdit1.lines.Add('                   datefmt='+chr(39)+'%Y-%m-%d %H:%M:%S'+chr(39)+')');
  SynEdit1.lines.Add('url = '+'"http://'+'192.168.0.149'+':8080"');
  SynEdit1.lines.Add('username = '+'"tenant@thingsboard.org"');
  SynEdit1.lines.Add('password = '+'"tenant"');
  SynEdit1.lines.Add('with RestClientCE(base_url=url) as rest_client:');
  SynEdit1.lines.Add('    try:');
  SynEdit1.lines.Add('         rest_client.login(username=username, password=password)');
  SynEdit1.lines.Add('         device = rest_client.get_tenant_device('+'"DHT22"'+')');
  SynEdit1.lines.Add('         ts_start = '+IntToStr(inicio * 1000));
  SynEdit1.lines.Add('         ts_stop = '+IntToStr(final * 1000));
  SynEdit1.lines.Add('         key = '+chr(39)+ key +chr(39)+'');
  SynEdit1.lines.Add('         x = rest_client.get_timeseries('+'"DEVICE"'+',device.id.id, key, start_ts=ts_start, end_ts=ts_stop)');
  SynEdit1.lines.Add('         logging.info(x)');
  SynEdit1.lines.Add('    except ApiException as e:');
  SynEdit1.lines.Add('        logging.exception(e)');

  comando := UTF8Encode(SynEdit1.Text);
  GetPythonEngine.ExecString(comando);
//  retira := copy(Memo1.Lines[0], 0, 46);
//  Memo1.Lines[0] := StringReplace(Memo1.Lines[0], retira, '{',[rfIgnoreCase]);
//  Memo1.Text := StringReplace(Memo1.Text, chr(39)+'ts'+chr(39)+': ', chr(39)+'ts'+chr(39)+': '+chr(39), [rfReplaceAll]);
//  Memo1.Text := StringReplace(Memo1.Text, ', '+chr(39)+'value'+chr(39)+': ', chr(39)+', '+chr(39)+'value'+chr(39)+': ', [rfReplaceAll]);
  Memo1.Text := StringReplace(Memo1.Text, chr(39), chr(34), [rfReplaceAll]);
  Memo1.Text := StringReplace(Memo1.Text, #13#10, '', [rfReplaceAll]);

  jsonObj := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(Memo1.Text), 45) as TJSONObject;

  jvT := jsonObj.Get('T').JsonValue;
  jaT := jvT as TJSONArray;

  setlength(datahora, jaT.Count);
  setlength(temp, jaT.Count);

  tempmedia := 0;
  for I := jaT.Count-1 downto 0 do
  begin
    jSubObj := jaT.Items[I] as TJSONObject;
    datahora[jaT.Count -1 - I] := UnixToDateTime(Round(StrToINT64(jSubObj.GetValue('ts').Value)/1000), false);
    temp[jaT.Count -1 - I] := StrToFloat(StringReplace(jSubObj.GetValue('value').Value, '.', ',', [rfReplaceAll]));
    tempmedia := tempmedia + temp[jaT.Count -1 - I];
  end;

  tempmedia := tempmedia / jaT.Count;

  key := 'Um';
  Memo1.Clear;
  SynEdit1.lines.Clear;
  SynEdit1.lines.Add('import logging');
  SynEdit1.lines.Add('from tb_rest_client.rest_client_ce import *');
  SynEdit1.lines.Add('from tb_rest_client.rest import ApiException');
  SynEdit1.lines.Add('logging.basicConfig(level=logging.DEBUG,');
  SynEdit1.lines.Add('                   format='+chr(39)+'%(asctime)s - %(levelname)s - %(module)s - %(lineno)d - %(message)s'+chr(39)+',');
  SynEdit1.lines.Add('                   datefmt='+chr(39)+'%Y-%m-%d %H:%M:%S'+chr(39)+')');
  SynEdit1.lines.Add('url = '+'"http://'+'192.168.0.149'+':8080"');
  SynEdit1.lines.Add('username = '+'"tenant@thingsboard.org"');
  SynEdit1.lines.Add('password = '+'"tenant"');
  SynEdit1.lines.Add('with RestClientCE(base_url=url) as rest_client:');
  SynEdit1.lines.Add('    try:');
  SynEdit1.lines.Add('         rest_client.login(username=username, password=password)');
  SynEdit1.lines.Add('         device = rest_client.get_tenant_device('+'"DHT22"'+')');
  SynEdit1.lines.Add('         ts_start = '+IntToStr(inicio * 1000));
  SynEdit1.lines.Add('         ts_stop = '+IntToStr(final * 1000));
  SynEdit1.lines.Add('         key = '+chr(39)+ key +chr(39)+'');
  SynEdit1.lines.Add('         x = rest_client.get_timeseries('+'"DEVICE"'+',device.id.id, key, start_ts=ts_start, end_ts=ts_stop)');
  SynEdit1.lines.Add('         logging.info(x)');
  SynEdit1.lines.Add('    except ApiException as e:');
  SynEdit1.lines.Add('        logging.exception(e)');

  comando := UTF8Encode(SynEdit1.Text);
  GetPythonEngine.ExecString(comando);

  Memo1.Text := StringReplace(Memo1.Text, chr(39), chr(34), [rfReplaceAll]);
  Memo1.Text := StringReplace(Memo1.Text, #13#10, '', [rfReplaceAll]);
  jsonObj := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(Memo1.Text), 45) as TJSONObject;

  jvU := jsonObj.Get('Um').JsonValue;
  jaU := jvU as TJSONArray;

  setlength(umi, jaU.Count);
  umimedia := 0;

  for I := jaU.Count - 1 downto 0 do
  begin
    jSubObj := jaU.Items[I] as TJSONObject;
    umi[jaU.Count - 1 - I] := StrToFloat(StringReplace(jSubObj.GetValue('value').Value, '.', ',', [rfReplaceAll]));
    umimedia := umimedia + umi[jaU.Count - 1 - I];
  end;
  umimedia := Round(umimedia / jaU.Count);

//  FreeAndNil(jsonObj);

  {  setlength(datahora, 5);
  setlength(temp, 5);
  setlength(umi, 5);
  for I := 0 to 9 do
  begin
    datahora[I] := StrToDateTime('20-06-202//2 08:00:00');
    temp[I] := 25.5;
    umi[I] := 40;
  end;
    datahora[0] := StrToDateTime('20/06/2022 08:00:00');
    temp[0] := 25.5;
    umi[0] := 40;
    datahora[1] := StrToDateTime('20/06/2022 08:01:00');
    temp[1] := 26.5;
    umi[1] := 43;
    datahora[2] := StrToDateTime('20/06/2022 08:02:00');
    temp[2] := 24.5;
    umi[2] := 45;
    datahora[3] := StrToDateTime('20/06/2022 08:03:00');
    temp[3] := 26.5;
    umi[3] := 39;
    datahora[4] := StrToDateTime('20/06/2022 08:04:00');
    temp[4] := 28.5;
    umi[4] := 41;
}   tempmax := Temp[0];
    tempmin := Temp[0];
    umimax := Umi[0];
    umimin := Umi[0];
    for I := 0 to Length(Temp) - 1 do
    begin
      if tempmin > Temp[I] then
        tempmin := Temp[I];
      if tempmax < Temp[I] then
        tempmax := Temp[I];
      if umimin > Umi[I] then
        umimin := Umi[I];
      if umimax < Umi[I] then
        umimax := Umi[I];
      TempUmi.Series[0].AddY(Temp[I], DateTimeToStr(datahora[I]), clteecolor);
      TempUmi.Series[1].AddY(Umi[I], DateTimeToStr(datahora[I]), clteecolor);
    end;

   TempUmi.LeftAxis.Maximum := Tempmax + 5;
   TempUmi.LeftAxis.Minimum := Tempmin - 5;
   TempUmi.RightAxis.Maximum := Umimax + 5;
   TempUmi.RightAxis.Minimum := Umimin - 5;
   TempUmi.Series[0].VertAxis := aLeftAxis;
   TempUmi.Series[1].VertAxis := aRightAxis;
   TempUmi.BottomAxis.Maximum := Length(Temp);

   TMedia.Text := FormatFloat('00.0', TempMedia);
   UMedia.Text := FormatFloat('00.0', UmiMedia);

end;

procedure TLaboratorio.SairClick(Sender: TObject);
begin
    Application.Terminate;
end;

end.
