program IPT_LAB;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Laboratorio};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TLaboratorio, Laboratorio);
  Application.Run;
end.
