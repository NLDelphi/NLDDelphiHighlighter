(* ----------------------------------------------------------------------------
unit NLDVBulletinDelphiHighlighter
Download the latest version at
http://www.nldelphi.com/Forum/forumdisplay.php?s=&forumid=72
-------------------------------------------------------------------------------
Author:  Jos Visser aka GolezTrol
Date  :  february 2004
Web   :  www.goleztrol.nl
-------------------------------------------------------------------------------
Uses NLDDelphiHighlighter to output Delphi source to vBulletin mark-up
-------------------------------------------------------------------------------
Changes:    Version and description
----------  -------------------------------------------------------------------
2004-02-10  1.0: Created
2004-03-26  1.1: Skip Color tag if color is black, reduces output size
-------------------------------------------------------------------------------
ToDo:
- Nothing at the moment
---------------------------------------------------------------------------- *)
unit NLDVBulletinDelphiHighlighter;

interface

uses
  Graphics, NLDDelphiHighlighter;

type
  TNLDvBDelphiHighlighter = class(TNLDCustomDelphiHighlighter)
  private
    FColorOpen: Boolean;
  protected
    procedure BeginDocument; override;
    procedure EndDocument; override;

    procedure BeginForegroundColor(Color: TColor); override;
    procedure EndForegroundColor(Color: TColor); override;
    procedure BeginBold; override;
    procedure EndBold; override;
    procedure BeginItalic; override;
    procedure EndItalic; override;
  public
    property TextStyles;
  end;

implementation

uses
  SysUtils;

{ TNLDvBDelphiHighlighter }

procedure TNLDvBDelphiHighlighter.BeginBold;
begin
  Write('[B]');
end;

procedure TNLDvBDelphiHighlighter.BeginDocument;
begin
  inherited;
  Write('[CODE]');
end;

procedure TNLDvBDelphiHighlighter.BeginForegroundColor(Color: TColor);
var
  Clr: Integer;
begin
  Clr := Color and $FF shl 16 + Color and $FF00 + Color and $FF0000 shr 16;
  FColorOpen := Clr <> 0;
  if FColorOpen then
    Write(Format('[COLOR=#%s]', [IntToHex(Clr, 6)] ));
end;

procedure TNLDvBDelphiHighlighter.BeginItalic;
begin
  Write('[I]');
end;

procedure TNLDvBDelphiHighlighter.EndBold;
begin
  Write('[/B]');
end;

procedure TNLDvBDelphiHighlighter.EndDocument;
begin
  Write('[/CODE]');
  inherited;
end;

procedure TNLDvBDelphiHighlighter.EndForegroundColor(Color: TColor);
begin
  if FColorOpen then
  begin
    Write('[/COLOR]');
    FColorOpen := False;
  end;
end;

procedure TNLDvBDelphiHighlighter.EndItalic;
begin
  Write('[/I]');
end;

end.
