unit ShellFolderNewSearch;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, Forms, ShellFolderView;

type
  TShellFolderNewSearch = class(TShellFolderD)
    private
    public
      {TShellFolderD}
      function EnumObjects(grfFlags:DWORD) : IEnumIDList; override; stdcall;
      function GetDisplayNameOf(pidl:PItemIDList;uFlags:DWORD) : string; override;
      function GetExtractIconImplW(pidl:PItemIDList) : IExtractIconW; override;
      function GetIContextMenuImpl(pidl: PItemIDList): TIContextMenuImpl; override;
      function GetAttributesOf(apidl:PItemIDList) : UINT; override;
      function GetDefaultColumn(var pSort: Cardinal; var pDisplay: Cardinal): HRESULT; override;
      function GetDefaultColumnState(iColumn: Cardinal; var pcsFlags: Cardinal): HRESULT; override;
      function GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal; var psd: _SHELLDETAILS): HRESULT; override;
      function CompareIDs(pidl1, pidl2:PItemIDList) : integer; override;
      function GetViewForm : TShellViewForm; override;
      {Bonus}
      destructor Destroy; override;
      constructor Create(PIDL: TPIDLStructure); override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolder, NewSearch;

{ TShellFolderNewSearch }

function TShellFolderNewSearch.CompareIDs(pidl1, pidl2: PItemIDList): integer;
begin
  Result := 1;
end;

constructor TShellFolderNewSearch.Create(PIDL: TPIDLStructure);
begin
  inherited;
end;

destructor TShellFolderNewSearch.Destroy;
begin
  inherited;
end;

function TShellFolderNewSearch.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  Result := TEnumEmptyIDListImpl.Create;
end;

function TShellFolderNewSearch.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  Result := SFGAO_READONLY;
end;

function TShellFolderNewSearch.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TShellFolderNewSearch.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TShellFolderNewSearch.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TShellFolderNewSearch.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
begin
  Result := '';
end;

function TShellFolderNewSearch.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := nil;
end;

function TShellFolderNewSearch.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := nil;
end;


function TShellFolderNewSearch.GetViewForm: TShellViewForm;
begin
  FNewSearch := TFNewSearch.Create(nil);
  Result := FNewSearch;
end;



end.
