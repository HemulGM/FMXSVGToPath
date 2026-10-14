unit SVGToPath.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.Objects, FMX.Colors, FMX.Edit, FMX.EditBox, FMX.NumberBox,
  Xml.Win.msxmldom, System.Skia, FMX.Skia, FMX.SVG, FMX.Filter.Effects;

type
  TFormMain = class(TForm)
    LabelSkia: TLabel;
    SvgImage: TSkSvg;
    SkiaCanvas: TRectangle;
    SkiaPreviewPane: TLayout;
    LabelFmx: TLabel;
    FmxPreviewHost: TLayout;
    FmxCanvas: TRectangle;
    FmxPreviewPane: TLayout;
    SourcePreview: TLayout;
    LabelSourceHint: TLabel;
    SourceFooter: TLayout;
    LabelSvgCode: TLabel;
    MemoSVG: TMemo;
    SourceCode: TLayout;
    LabelSourceTitle: TLabel;
    SourceCard: TRectangle;
    Layout1: TLayout;
    Label1: TLabel;
    ComboColorBoxFill: TComboColorBox;
    FillField: TLayout;
    Label2: TLabel;
    ComboColorBoxStroke: TComboColorBox;
    StrokeField: TLayout;
    Layout5: TLayout;
    LabelPathPreview: TLabel;
    PathImage: TPath;
    PathCanvas: TRectangle;
    Layout4: TLayout;
    PathCopy: TPath;
    ButtonCopyToDelphi: TButton;
    Label3: TLabel;
    NumberBoxSplit: TNumberBox;
    DelphiSplitField: TLayout;
    ExportFooter: TLayout;
    LabelPathCode: TLabel;
    MemoPaths: TMemo;
    ResultCode: TLayout;
    LabelResultTitle: TLabel;
    ResultCard: TRectangle;
    Layout2: TLayout;
    Splitter1: TSplitter;
    Workspace: TLayout;
    LabelTitle: TLabel;
    LabelSubtitle: TLabel;
    Header: TLayout;
    Body: TLayout;
    StatusDivider: TRectangle;
    LabelStatus: TLabel;
    StatusSurface: TRectangle;
    RootSurface: TRectangle;
    StyleBookWinUI3: TStyleBook;
    procedure MemoSVGChange(Sender: TObject);
    procedure MemoPathsChange(Sender: TObject);
    procedure ComboColorBoxStrokeChange(Sender: TObject);
    procedure ComboColorBoxFillChange(Sender: TObject);
    procedure ButtonCopyToDelphiClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SplitterMoved(Sender: TObject);
  private
    FSVG: TSVGRender;
    FReady: Boolean;
    FUpdating: Boolean;
    FResizing: Boolean;
    FSplitRatio: Single;
    procedure SetStatus(const Text: string; IsError: Boolean = False);
    procedure UpdatePreviewWidths;
  end;

var
  FormMain: TFormMain;

implementation

uses
  FMX.platform, FMX.SVG.PathConverter;

{$R *.fmx}

procedure TFormMain.SetStatus(const Text: string; IsError: Boolean);
begin
  LabelStatus.Text := Text.Replace(#13, ' ').Replace(#10, ' ');
  if IsError then
    LabelStatus.TextSettings.FontColor := $FFFFB4AB
  else
    LabelStatus.TextSettings.FontColor := $FFBFBFBF;
  LabelStatus.Hint := Text;
  LabelStatus.ShowHint := True;
end;

procedure TFormMain.UpdatePreviewWidths;
begin
  SkiaPreviewPane.Width := Max(0, (SourcePreview.Width - 8) / 2);
  FillField.Width := Max(0, (Layout5.Width - 16) / 2);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FSVG := TSVGRender.Create(Self);
  FSVG.Parent := FmxPreviewHost;
  FSVG.Align := TAlignLayout.Client;
  FSVG.HitTest := False;
  Layout1.OnResize := FormResize;
  Layout2.OnResize := FormResize;
  SourcePreview.OnResize := FormResize;
  Layout5.OnResize := FormResize;
  Splitter1.OnMoved := SplitterMoved;
  FSplitRatio := 0.5;
  FReady := True;
  FormResize(Self);
  MemoSVGChange(Self);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FReady := False;
end;

procedure TFormMain.FormResize(Sender: TObject);
var
  AvailableWidth: Single;
begin
  if not FReady or FResizing then
    Exit;
  FResizing := True;
  try
    if Sender = Self then
    begin
      AvailableWidth := Workspace.Width - Splitter1.Width;
      Layout1.Width := EnsureRange(AvailableWidth * FSplitRatio, 524, Max(524, AvailableWidth - 524));
    end;
    UpdatePreviewWidths;
  finally
    FResizing := False;
  end;
end;

procedure TFormMain.SplitterMoved(Sender: TObject);
begin
  if FResizing or (Workspace.Width <= Splitter1.Width) then
    Exit;
  FSplitRatio := Layout1.Width / (Workspace.Width - Splitter1.Width);
  FormResize(Self);
end;

procedure TFormMain.ComboColorBoxFillChange(Sender: TObject);
begin
  if FReady then
    PathImage.Fill.Color := ComboColorBoxFill.Color;
end;

procedure TFormMain.ComboColorBoxStrokeChange(Sender: TObject);
begin
  if FReady then
    PathImage.Stroke.Color := ComboColorBoxStroke.Color;
end;

procedure TFormMain.MemoPathsChange(Sender: TObject);
begin
  if not FReady or FUpdating then
    Exit;
  try
    PathImage.Data.Data := MemoPaths.Text;
    PathImage.Fill.Color := ComboColorBoxFill.Color;
    PathImage.Stroke.Color := ComboColorBoxStroke.Color;
    ButtonCopyToDelphi.Enabled := not MemoPaths.Text.Trim.IsEmpty;
    if ButtonCopyToDelphi.Enabled then
      SetStatus(Format('Готово · Path Data: %d символов', [MemoPaths.Text.Length]))
    else
      SetStatus('Вставьте SVG-код для преобразования.');
  except
    on E: Exception do
    begin
      PathImage.Data.Clear;
      ButtonCopyToDelphi.Enabled := False;
      SetStatus('Ошибка Path Data: ' + E.Message, True);
    end;
  end;
end;

procedure TFormMain.MemoSVGChange(Sender: TObject);
var
  PathData: string;
begin
  if not FReady or FUpdating then
    Exit;
  FUpdating := True;
  try
    try
      if MemoSVG.Text.Trim.IsEmpty then
        PathData := ''
      else
        PathData := ConvertSVGToPath(MemoSVG.Text);
      MemoPaths.Text := PathData;
      PathImage.Data.Data := PathData;
      PathImage.Fill.Color := ComboColorBoxFill.Color;
      PathImage.Stroke.Color := ComboColorBoxStroke.Color;
      SvgImage.Svg.Source := MemoSVG.Text;
      FSVG.SVG := MemoSVG.Text;
      ButtonCopyToDelphi.Enabled := not PathData.Trim.IsEmpty;
      if MemoSVG.Text.Trim.IsEmpty then
        SetStatus('Вставьте SVG-код для преобразования.')
      else if not ButtonCopyToDelphi.Enabled then
        SetStatus('SVG не содержит геометрии для TPath.')
      else
        SetStatus(Format('Готово · Path Data: %d символов', [PathData.Length]));
    except
      on E: Exception do
      begin
        MemoPaths.Text := '';
        PathImage.Data.Clear;
        SvgImage.Svg.Source := '';
        FSVG.SVG := '';
        ButtonCopyToDelphi.Enabled := False;
        SetStatus('Ошибка SVG: ' + E.Message, True);
      end;
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TFormMain.ButtonCopyToDelphiClick(Sender: TObject);
var
  Res, Buf: string;
  Cnt: Integer;
  Clipboard: IFMXClipboardService;
begin
  if not ButtonCopyToDelphi.Enabled then
    Exit;
  Res := '';
  Buf := '';
  Cnt := 0;
  for var Line in MemoPaths.Lines do
  begin
    for var C in Line do
    begin
      Inc(Cnt);
      Buf := Buf + C;
      if (Cnt > NumberBoxSplit.Value) and ((C = ' ') or (C = ',')) then
      begin
        if not Res.IsEmpty then
          Res := Res + ' + '#13#10;
        Res := Res + QuotedStr(Buf);
        Buf := '';
        Cnt := 0;
      end;
    end;
    if not Buf.IsEmpty then
    begin
      if not Res.IsEmpty then
        Res := Res + ' + '#13#10;
      Res := Res + QuotedStr(Buf);
      Buf := '';
      Cnt := 0;
    end;
  end;
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, Clipboard) then
  begin
    Clipboard.SetClipboard(Res);
    SetStatus('Строка Delphi скопирована в буфер обмена.');
  end
  else
    SetStatus('Буфер обмена недоступен.', True);
end;

initialization
  Xml.Win.msxmldom.MSXMLDOMDocumentFactory.AddDOMProperty('ProhibitDTD', False);

end.

