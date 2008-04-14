unit fTest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    mSource: TMemo;
    mTarget: TMemo;
    pToolbar: TPanel;
    btnHighlight: TButton;
    ProgressBar1: TProgressBar;
    Splitter: TSplitter;
    StatusBar: TStatusBar;
    lSource: TLabel;
    lTarget: TLabel;
    cbColor: TComboBox;
    lColor: TLabel;
    procedure btnHighlightClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses NLDDelphiHighlighter, NLDVBulletinDelphiHighlighter;

{$R *.DFM}

procedure TForm1.btnHighlightClick(Sender: TObject);
begin
  with TNLDvBDelphiHighlighter.Create do
  try
    ColorScheme := TPresets(cbColor.ItemIndex);

    mTarget.Text := HighLight(mSource.Text);
    mTarget.SetFocus;
    mTarget.SelectAll;
  finally
    Free;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  cbColor.ItemIndex := Integer(pGolezTrol);
end;

end.
