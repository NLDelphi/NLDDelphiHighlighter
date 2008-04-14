program Test;

uses
  Forms,
  fTest in 'fTest.pas' {Form1},
  NLDDelphiHighlighter in 'NLDDelphiHighlighter.pas',
  NLDVBulletinDelphiHighlighter in 'NLDVBulletinDelphiHighlighter.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
