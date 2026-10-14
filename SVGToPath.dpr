program SVGToPath;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  SVGToPath.Main in 'SVGToPath.Main.pas' {FormMain},
  FMX.SVG.Cache in 'FMXSVG\FMX.SVG.Cache.pas',
  FMX.SVG.Control in 'FMXSVG\FMX.SVG.Control.pas',
  FMX.SVG.Parser in 'FMXSVG\FMX.SVG.Parser.pas',
  FMX.SVG in 'FMXSVG\FMX.SVG.pas',
  FMX.SVG.Renderer in 'FMXSVG\FMX.SVG.Renderer.pas',
  FMX.SVG.Types in 'FMXSVG\FMX.SVG.Types.pas',
  FMX.SVG.PathConverter in 'FMXSVG\FMX.SVG.PathConverter.pas';

{$R *.res}

begin
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
