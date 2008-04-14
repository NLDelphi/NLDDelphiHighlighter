(* ----------------------------------------------------------------------------
unit NLDDelphiHighlighter
Download the latest version at
http://www.nldelphi.com/Forum/forumdisplay.php?s=&forumid=72
-------------------------------------------------------------------------------
Author:  Jos Visser aka GolezTrol
Date  :  february 2004
Web   :  www.goleztrol.nl
-------------------------------------------------------------------------------
Parses Delphi source code and provides basic functionality to add mark-up to
the source. Create descendants to output to different formats.
-------------------------------------------------------------------------------
Changes:    Version and description
----------  -------------------------------------------------------------------
2004-02-09  1.0: Created
2004-03-26  1.1: Small fixes by GolezTrol
  - starting / and ( of comments are now included in markup
  - ColorScheme property to allow changing the color scheme.
  - EndDocument left one character too much in the result string

-------------------------------------------------------------------------------
ToDo:
- Try to speed up Tokenize
- Find a neat way to choose color scheme.(Maybe register TScheme class
  in same way as TGraphic descendants do)
- Optimize OutputDocument so color-tags are not closed and reopened between
  tokens if color of tokens is the same
---------------------------------------------------------------------------- *)
unit NLDDelphiHighlighter;

interface

uses
  Windows, Graphics, Classes;

const
  clDefault: TColor = -1;

type
  // Delphi color presets
  TPresets = (pDefault, pClassic, pTwilight, pOcean, pLightWeight, pGolezTrol);

  TTextAttributes = class(TPersistent)
  private
    FFontStyles: TFontStyles;
    FForeground: TColor;
    FBackground: TColor;
  public
    constructor Create;
    property FontStyles: TFontStyles read FFontStyles write FFontStyles;
    property Foreground: TColor read FForeground write FForeground;
    property Background: TColor read FBackground write FBackground;
  end;

  // Parserstates will be translated to texttypes
  TTextType = (ttIdentifier, ttKeyword, ttString, ttNumber, ttComment, ttAsm,
               ttSymbol, ttPlainText);
  TParserState = (psUnknown, psPlainText, psSymbol, psIdent, {psAsm, }
                  psString, psChar, psComment, psBlockComment1,
                  psBlockComment2, psNumber, psDecimal, psExponent, psHex,
                  psHExponent, psHexChar);

  // Breaking the code into tokens containing the text and the type.
  TToken = record
    Text: string;
    State: TParserState;
  end;

  TNLDCustomDelphiHighlighter = class(TPersistent)
  private
    FState: Integer;
    FLength: Integer;
    FPos: Integer;
    FTokens: array of TToken;
    FCurToken: Integer;
    FResWords: TStrings;
    FDocument: string;
    FDocumentPtr: Integer;
    FTextStyles: array[TTextType] of TTextAttributes;
    FScheme: TPresets;
    function GetTextStyles(TextType: TTextType): TTextAttributes;
  protected
    property Document: string read FDocument write FDocument;
    property TextStyles[TextType: TTextType]: TTextAttributes
        read GetTextStyles;
    procedure ResetColorScheme(const Scheme: TPresets); virtual;
    // Break the source into tokens with different color codes.
    procedure Tokenize(const Data: string); virtual;
    // Initialization/finalization to the generated output.
    procedure BeginDocument; virtual;
    procedure EndDocument; virtual;
    // Text mark-up of generated output
    procedure BeginForegroundColor(Color: TColor); virtual;
    procedure EndForegroundColor(Color: TColor); virtual;
    procedure BeginBackgroundColor(Color: TColor); virtual;
    procedure EndBackgroundColor(Color: TColor); virtual;
    procedure BeginBold; virtual;
    procedure EndBold; virtual;
    procedure BeginItalic; virtual;
    procedure EndItalic; virtual;
    procedure BeginUnderline; virtual;
    procedure EndUnderline; virtual;
    procedure BeginStrikeOut; virtual;
    procedure EndStrikeOut; virtual;
    // Write data to the output
    procedure Write(const Data: string); virtual;
    // Text to be output in given color state.
    procedure WriteText(const Text: string; TextType: TTextType); virtual;
    // Loops throught tokens to output them using WriteTekst.
    procedure OutputDocument; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property ColorScheme: TPresets read FScheme write ResetColorScheme;
    // Shorthand function for tokenizing and outputting a source
    function HighLight(const Source: string): string; virtual;
  end;

const
   DelphiResWords: array[0..99] of string = (
  'absolute','abstract','and','array','as','asm','assembler','automated',
  'begin','case','cdecl','class','const','constructor','default','destructor',
  'dispid','dispinterface','div','do','downto','dynamic','else','end','except',
  'export','exports','external','far','file','finalization','finally','for',
  'forward','function','goto','if','implementation','in','index','inherited',
  'initialization','inline','interface','is','label','library','message','mod',
  'near','nil','nodefault','not','object','of','or','out','overload',
  'override','packed','pascal','private','procedure','program','property',
  'protected','public','published','raise','read','readonly','record',
  'register', 'reintroduce','repeat','resident','resourcestring','safecall',
  'set','shl','shr','stdcall','stored','string','stringresource','then',
  'threadvar','to','try','type','unit','until','uses','var','virtual','while',
  'with','write','writeonly','xor');

implementation

uses
  SysUtils{, Dialogs, FTest};

function IsAlphaChar(Character: Char): Boolean;
begin
  Result := UpCase(Character) in ['A'..'Z'];
end;

function IsNumChar(Character: Char): Boolean;
begin
  Result := Character in ['0'..'9'];
end;

function IsIdentStartChar(Character: Char): Boolean;
begin
  Result := IsAlphaChar(Character) or (Character = '_');
end;

function IsIdentChar(Character: Char): Boolean;
begin
  Result := IsIdentStartChar(Character) or IsNumChar(Character);
end;

function IsHexChar(Character: Char): Boolean;
begin
  Result := IsNumChar(Character) or (UpCase(Character) in ['A'..'F']);
end;

function IsSymbol(Character: Char): Boolean;
begin
   Result := Character in [ '~', '`', '!', '@', '%', '^', '&', '*', '(', ')',
                            '-', '+', '=', '[', ']', ':', ';', '"', '<', ',',
                            '>', '.', '?', '/', '|', '\' ];
end;

{ TNLDCustomDelphiHighlighter }

procedure TNLDCustomDelphiHighlighter.BeginBackgroundColor(Color: TColor);
begin
end;

procedure TNLDCustomDelphiHighlighter.BeginBold;
begin
end;

procedure TNLDCustomDelphiHighlighter.BeginDocument;
begin
  FDocumentPtr := 1;
  FDocument := '';
end;

procedure TNLDCustomDelphiHighlighter.BeginForegroundColor(Color: TColor);
begin
end;

procedure TNLDCustomDelphiHighlighter.BeginItalic;
begin
end;

procedure TNLDCustomDelphiHighlighter.BeginStrikeOut;
begin
end;

procedure TNLDCustomDelphiHighlighter.BeginUnderline;
begin
end;

constructor TNLDCustomDelphiHighlighter.Create;
var
  i: Integer;
  j: TTextType;
begin
  FResWords := TStringList.Create;
  FResWords.Capacity := Length(DelphiResWords);
  for i := Low(DelphiResWords) to High(DelphiResWords) do
    FResWords.Add(DelphiResWords[i]);
  TStringList(FResWords).Sorted := True;
  for j := Low(TTextType) to High(TTextType) do
    FTextStyles[j] := TTextAttributes.Create;
  ResetColorScheme(pGolezTrol); // This has gotta change
end;

destructor TNLDCustomDelphiHighlighter.Destroy;
var
  j: TTextType;
begin
  FResWords.Free;
  for j := Low(TTextType) to High(TTextType) do
    FTextStyles[j].Free;
  inherited;
end;

procedure TNLDCustomDelphiHighlighter.EndBackgroundColor(Color: TColor);
begin
end;

procedure TNLDCustomDelphiHighlighter.EndBold;
begin
end;

procedure TNLDCustomDelphiHighlighter.EndDocument;
begin
  SetLength(FDocument, FDocumentPtr-1);
end;

procedure TNLDCustomDelphiHighlighter.EndForegroundColor(Color: TColor);
begin
end;

procedure TNLDCustomDelphiHighlighter.EndItalic;
begin
end;

procedure TNLDCustomDelphiHighlighter.EndStrikeOut;
begin
end;

procedure TNLDCustomDelphiHighlighter.EndUnderline;
begin
end;

function TNLDCustomDelphiHighlighter.GetTextStyles(
  TextType: TTextType): TTextAttributes;
begin
  Result := FTextStyles[TextType];
end;

function TNLDCustomDelphiHighlighter.HighLight(const Source: string): string;
//var
  //a: Cardinal;
  //s: string;
  //b: Cardinal;
begin
  //a := GetTickCount;
  //b := a;
  Tokenize(Source);
  //s := 'Tokenize: ' + IntToStr(GetTickcount-a) + #13;
  BeginDocument;
  //a := GetTickCount;
  OutputDocument;
  //s := s + 'Output: ' + IntToStr(GetTickcount-a) + #13;
  EndDocument;
  //s := s + 'Total: ' + IntToStr(GetTickcount-b) + #13;
  //s := s + 'Tokens: ' + IntToStr(Length(FTokens)) + #13;
  //ShowMessage(s);
  Result := Document;
end;

procedure TNLDCustomDelphiHighlighter.OutputDocument;
var
  i: Integer;
  Color: TTextType;
  Max: Integer;
begin
  Max := High(FTokens);
  // DEBUG: Form1.ProgressBar1.Max := Max;

  // Output each token.
  i := 0;
  while i <= Max do
  begin
      // DEBUG: Form1.ProgressBar1.Position := i;
    case FTokens[i].State of
      psPlainText:
        Color := ttPlainText;
      psIdent: begin
        Color := ttIdentifier;
        if FResWords.IndexOf(FTokens[i].Text) > 0 then
        begin
          Color := ttKeyWord;
          // Assembly code has different text styles, except for comments
          // This could be dealt with in the tokenizer, but it seems more
          // logical to do it here. The distinguishment between keywords
          // and identifiers is also made just here after all.
          // All the tokenizer should do is break the code in little pieces.
          if SameText('asm', FTokens[i].Text) then
          begin
            WriteText(FTokens[i].Text, ttKeyword);
            Inc(i);
            while (i < Max) and not SameText('end', FTokens[i].Text) do
            begin
              if FTokens[i].State in [psComment, psBlockComment1, psBlockComment2] then
                WriteText(FTokens[i].Text, ttComment)
              else
                WriteText(FTokens[i].Text, ttAsm);
              Inc(i);
            end;
          end;
        end;
      end;
      psString, psChar, psHexChar:
        Color := ttString;
      psComment, psBlockComment1, psBlockComment2:
        Color := ttComment;
      psNumber, psDecimal, psExponent, psHex, psHExponent:
        Color := ttNumber;
      psSymbol:
        Color := ttSymbol;
    else
      Assert(False, 'Output Document: Invalid parser state');
    end;
    WriteText(FTokens[i].Text, Color);
    Inc(i);
  end;
end;

procedure TNLDCustomDelphiHighlighter.ResetColorScheme(const Scheme: TPresets);
var
  i: TTextType;
begin
{  // Debug: Use TextType as color
  for i := Low(TTextType) to High(TTextType) do
    TextStyles[i].Foreground := Ord(i);
  Exit;}
  FScheme := Scheme;

  case Scheme of
    pDefault: begin
      for i := Low(TTextType) to High(TTextType) do
      begin
        TextStyles[i].FontStyles := [];
        TextStyles[i].Foreground := clBlack;
        TextStyles[i].Background := clDefault;
      end;
      TextStyles[ttKeyword].FontStyles := [fsBold];
      TextStyles[ttComment].FontStyles := [fsItalic];
      TextStyles[ttComment].Foreground := clNavy;
    end;
    pClassic: begin
      for i := Low(TTextType) to High(TTextType) do
      begin
        TextStyles[i].FontStyles := [];
        TextStyles[i].Foreground := clYellow;
        TextStyles[i].Background := clNavy
      end;
      TextStyles[ttKeyword].Foreground := clWhite;
      TextStyles[ttComment].Foreground := clSilver;
      TextStyles[ttAsm].Foreground := clLime;
    end;
    pTwilight: begin
      for i := Low(TTextType) to High(TTextType) do
      begin
        TextStyles[i].FontStyles := [];
        TextStyles[i].Foreground := clAqua;
        TextStyles[i].Background := clBlack
      end;
      TextStyles[ttKeyword].FontStyles := [fsBold];
      TextStyles[ttComment].FontStyles := [fsItalic];
      TextStyles[ttComment].Foreground := clSilver;
      TextStyles[ttIdentifier].Foreground := clWhite;
      TextStyles[ttNumber].Foreground := clFuchsia;
      TextStyles[ttString].Foreground := clYellow;
      TextStyles[ttAsm].Foreground := clLime;
    end;
    pOcean: begin
      for i := Low(TTextType) to High(TTextType) do
      begin
        TextStyles[i].FontStyles := [];
        TextStyles[i].Foreground := clBlue;
        TextStyles[i].Background := clAqua;
      end;
      TextStyles[ttKeyword].FontStyles := [fsBold];
      TextStyles[ttKeyword].Foreground := clBlack;
      TextStyles[ttComment].FontStyles := [fsItalic];
      TextStyles[ttComment].Foreground := clTeal;
      TextStyles[ttNumber].Foreground := clOlive;
      TextStyles[ttString].Foreground := clPurple;
    end;
    pLightWeight: begin
      // Lightweight style for forums. Only make keywords bold and
      // comments italic. No other mark-up.
      for i := Low(TTextType) to High(TTextType) do
      begin
        TextStyles[i].FontStyles := [];
        TextStyles[i].Foreground := clDefault;
        TextStyles[i].Background := clDefault;
      end;
      TextStyles[ttKeyword].FontStyles := [fsBold];
      TextStyles[ttComment].FontStyles := [fsItalic];
    end;
    pGolezTrol: begin
      // My favorite color scheme
      for i := Low(TTextType) to High(TTextType) do
      begin
        TextStyles[i].FontStyles := [];
        TextStyles[i].Foreground := clBlack;
        TextStyles[i].Background := clDefault;
      end;
      TextStyles[ttKeyword].FontStyles := [fsBold];
      TextStyles[ttKeyword].Foreground := clNavy;
      TextStyles[ttComment].FontStyles := [fsItalic];
      TextStyles[ttComment].Foreground := clTeal;
      TextStyles[ttString].Foreground := clMaroon;
      TextStyles[ttNumber].Foreground := clGreen;
      TextStyles[ttAsm].Foreground := clGreen;
    end;
  else
    Assert(False, 'ResetColorScheme: Unknown scheme');
  end;
end;

procedure TNLDCustomDelphiHighlighter.Tokenize(const Data: string);
var
  Size: Integer;
  Len: Integer;
  CurToken: Integer;
  Ptr: Integer;
  OldPtr: Integer;
  State: TParserState;
  OldState: TParserState;
  IsEndOfToken: Boolean;
begin
  CurToken := 0;
  Size := -1;
  State := psUnknown;
  Len := Length(Data);
  OldPtr := 1;
  Ptr := 1;
  // DEBUG: Form1.ProgressBar1.Max := Length(Data);
  while Ptr <= Len do
  begin
    // DEBUG: Form1.ProgressBar1.Position := Ptr;
    case State of
    psUnknown, psPlainText, psSymbol: begin
    // Each state checks if the current character still belongs to that state.
    // A state remains until it can't handle the current character. State is
    // set to psUnknown to indicate that the state has ended.
    // Exceptions are Unknown, PlainText and Symbol. These states can be
    // 'interrupted' by the beginning of another state:
      if IsIdentStartChar(Data[Ptr]) then
        State := psIdent
      else if IsNumChar(Data[Ptr]) then
        State := psNumber
      else if (Data[Ptr] = '/') and (Data[Ptr+1] = '/') then
      begin
        State := psComment;
        OldState := psComment; // Needed to include both // in mark-up
        Inc(Ptr);
      end
      else if Data[Ptr] = '{' then
        State := psBlockComment1
      else if (Data[Ptr] = '(') and (Data[Ptr+1] = '*') then
      begin
        State := psBlockComment2;
        OldState := psBlockComment2; // Needed to include ( in mark-up
        Inc(Ptr);
      end
      else if Data[Ptr] = '''' then
        State := psString
      else if Data[Ptr] = '#' then
        State := psChar
      else if Data[Ptr] = '$' then
        State := psHex
      else if IsSymbol(Data[Ptr]) then
        State := psSymbol
      else
        State := psPlainText;  // Unknown character
    end;
    psIdent:
    // Identifier/keyword
      if not IsIdentChar(Data[Ptr]) then
        State := psUnknown;
    psComment:
    // Simple comment (//) will end on end of line
      if Data[Ptr] = #13 then
        State := psUnknown;
    psBlockComment1:
    // BlockComment { will end on }
      if Data[Ptr] = '}' then
      begin
        State := psUnknown;
        Inc(Ptr); // Include this character in color
      end;
    psBlockComment2:
    // BlockComment (* will end on *)
      if (Data[Ptr] = '*') and (Data[Ptr+1] = ')') then
      begin
        State := psUnknown;
        Inc(Ptr, 2); // Include these characters in color
      end;
    psNumber:
    // Number can contain a number or 'e' or '.'
      if UpCase(Data[Ptr]) = 'E' then
        State := psExponent
      else if Data[Ptr] = '.' then
        State := psDecimal
      else if not IsNumChar(Data[Ptr]) then
        State := psUnknown;
    psDecimal:
    // Numbers with decimals can only be followed by yet more digits or 'e'
      if UpCase(Data[Ptr]) = 'E' then
        State := psExponent
      else if not IsNumChar(Data[Ptr]) then
        State := psUnknown;
    psHex:
    // Hex numbers can be followed by 'e' or a digit
      if not IsHexChar(Data[Ptr]) then
        if UpCase(Data[Ptr]) = 'E' then
          State := psHExponent
        else
          State := psUnknown;
    psExponent:
    // Number with exponent may only be followed by a number or a sign
      if not IsNumChar(Data[Ptr]) then
        if not ((UpCase(Data[Ptr-1]) = 'E') and (Data[Ptr] in ['+', '-'])) then
          State := psUnknown;
    psHExponent, psHexChar:
    // Hex character or Exponent of Hex number
      if not IsHexChar(Data[Ptr]) then
        State := psUnknown;
    psChar:
    // Character
      if Data[Ptr] = '$' then
      begin
        // Hexadecimal character
        if Data[Ptr-1] = '#' then
          State := psHexChar
        else
          State := psUnknown; // Could change to Hex immediately?
      end
      else if not IsNumChar(Data[Ptr]) then
        State := psUnknown;
    psString:
    // String ends on '
      if Data[Ptr] = '''' then
      begin
        State := psUnknown;
        Inc(Ptr);
      end;
    else
      Assert(False, 'Tokenizer: Invalid Parser State');
    end;
    // Increase buffer if necessary
    if CurToken > Size then
    begin
      // Use large block for performance.
      SetLength(FTokens, Size + 256);
      Size := High(FTokens);
    end;

    // End of token if set to Unknown state, or changes form WhiteSpace to something else.
    IsEndOfToken := (OldState in [psPlainText, psSymbol]) and (State <> OldState);
    IsEndOfToken := IsEndOfToken or (State = psUnknown);
    if IsEndOfToken then
    begin
      FTokens[CurToken].Text := Copy(Data, OldPtr, Ptr - OldPtr);
      if Length(FTokens[CurToken].Text) > 0 then
      begin
        FTokens[CurToken].State := OldState;
        Inc(CurToken);
      end;
      OldPtr := Ptr;
    end;
    // If Unknown, first determine new state on current character
    if State <> psUnknown then
      Inc(Ptr);
    // Save state for next loop.
    OldState := State;
  end;
  // Might be a part left.
  if (State <> psUnknown) then
  begin
    FTokens[CurToken].Text := Copy(Data, OldPtr, Ptr - OldPtr);
    FTokens[CurToken].State := OldState;
    Inc(CurToken);
  end;

  SetLength(FTokens, CurToken);
end;

procedure TNLDCustomDelphiHighlighter.Write(const Data: string);
var
  DatLen, DocLen: Integer;
begin
  // Add 'Data' to the Document 'Stream'
  DatLen := Length(Data);
  DocLen := Length(FDocument);

  // Allocate output stream in large blocks to increase performance
  if FDocumentPtr + DatLen >= DocLen then
    SetLength(FDocument, DocLen + 4096); // Randomly chosen...
  CopyMemory(@FDocument[FDocumentPtr], @Data[1], DatLen);
  Inc(FDocumentPtr, DatLen);
  // The old way was way to slow due to reallocating over and over again:
  // Document := Document + Data;
end;

procedure TNLDCustomDelphiHighlighter.WriteText(const Text: string;
  TextType: TTextType);
begin
  with FTextStyles[TextType] do
  begin
    // Open styles and close them in reverse order
    if Background <> clDefault then BeginBackgroundColor(Background);
    // If text only consists of white space, don't bother character mark-up.
    if Trim(Text) <> '' then
    begin
      if fsBold in FontStyles then BeginBold;
      if fsItalic in FontStyles then  BeginItalic;
      if fsUnderline in FontStyles then BeginUnderline;
      if fsStrikeOut in FontStyles then BeginStrikeOut;

      if (ForeGround <> clDefault) and (Length(Trim(Text)) > 0) then
        BeginForegroundColor(Foreground);

      Write(Text);

      if (ForeGround <> clDefault) and (Length(Trim(Text)) > 0) then
        EndForegroundColor(Foreground);

      if fsStrikeOut in FontStyles then EndStrikeOut;
      if fsUnderline in FontStyles then EndUnderline;
      if fsItalic in FontStyles then EndItalic;
      if fsBold in FontStyles then EndBold;
    end else
    begin
      Write(Text);
    end;

    if Background <> clDefault then EndBackgroundColor(Background);
  end;
end;

{ TTextAttributes }

constructor TTextAttributes.Create;
begin
  inherited Create;
  FFontStyles := [];
  FForeground := clDefault;
  FBackground := clDefault;
end;

end.
