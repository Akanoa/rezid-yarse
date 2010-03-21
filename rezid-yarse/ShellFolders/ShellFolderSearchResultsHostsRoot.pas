unit ShellFolderSearchResultsHostsRoot;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, Searching, Forms, ShellFolderView;

type
  TIExtractIconImplWHostsRoot = class(TIExtractIconImplW)
    protected
      CorrespondingHost : TSearchVFHost;
    public
      constructor Create(pidl : PItemIDList); override;
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal;
        out phiconLarge: HICON; out phiconSmall: HICON;
        nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderSearchResultsHostsRoot = class(TShellFolderD)
    private
      FPIDLList : TList;
      ExtractIcon : TIExtractIconImplWHostsRoot;
      FSearch : TSearch;
      procedure RebuildPIDLList;
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
      function CompareIDs(pidl1: PItemIDList; pidl2: PItemIDList): Integer; override;
      function GetViewForm : TShellViewForm; override;
      {Bonus}
      destructor Destroy; override;
      constructor Create(PIDL: TPIDLStructure); override;
  end;

  TEnumIDListHostsRoot = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplHostsRoot = class(TIContextMenuImpl)
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolderOfflineBrowserHost, ShellFolderMainMenu, ShellIcons;

{ TShellFolderHostsRoot }

function TShellFolderSearchResultsHostsRoot.CompareIDs(pidl1,
  pidl2: PItemIDList): Integer;
var
  pidl_struct1, pidl_struct2 : TPIDLStructure;
  temp_result : Integer;
begin
  Result := ComparePIDLs(pidl1, pidl2);
  Exit;
  OutputDebugStringFoldersD('TShellFolderHostsRoot.CompareIDs');
  pidl_struct1 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl1));
  pidl_struct2 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl2));
  temp_result := pidl_struct1.ItemInfo1 - pidl_struct2.ItemInfo1;

  if temp_result = 0 then
    Result := 0
  else if temp_result < 0 then
    Result := -1
  else if temp_result > 0 then
    Result := 1;
end;

constructor TShellFolderSearchResultsHostsRoot.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderHostsRoot.Create');
  FPIDLList := TList.Create;
  FSearch := GetSearchByID(PIDL.ItemInfo1);
  ExtractIcon := nil;
end;

destructor TShellFolderSearchResultsHostsRoot.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderHostsRoot.Destroy');
  FPIDLList.Free;
  inherited;
end;

function TShellFolderSearchResultsHostsRoot.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderHostsRoot.EnumObjects');
  RebuildPIDLList;
  Result := TEnumIDListHostsRoot.Create(FPIDLList, grfFlags);
  Result.Reset;
end;

function TShellFolderSearchResultsHostsRoot.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
  aHost : TSearchVFHost;
begin
  OutputDebugStringFoldersD('TShellFolderHostsRoot.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType <> ITEM_SEARCH_SORT_HOSTS_HOST then
    begin
      Exit;
    end;

  aHost := FSearch.GetVHostByVID(aPIDLStructure.ItemInfo2);
  if not Assigned(aHost) then
    begin
      Exit;
    end;

  Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE;
end;

function TShellFolderSearchResultsHostsRoot.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderHostsRoot.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderSearchResultsHostsRoot.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderHostsRoot.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderSearchResultsHostsRoot.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aHost : TSearchVFHost;
begin
  OutputDebugStringFoldersD('TShellFolderHostsRoot.GetDetailsOf');
  if iColumn > 1 then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;
  psd.fmt := LVCFMT_LEFT;
  sString := 'Saucisse';
  if Assigned(pidl)then
    begin
      sString := 'SaucisseP';
      aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
      if aPIDLStructure.ItemType = ITEM_SEARCH_SORT_HOSTS then
        begin
          aHost := FSearch.GetVHostByVID(aPIDLStructure.ItemInfo2);
          if Assigned(aHost) then
            begin
              case iColumn of
                0: sString := aHost.Name;
              end;
            end;
        end;
    end
  else
    begin
      case iColumn of
        0: sString := 'Nom';
      end;
    end;

  FillStrRet(psd.str, srtOLEStr, WideString(sString), 0);
  psd.cxChar := 15;
  //  psd.str
  Result := S_OK;
end;

function TShellFolderSearchResultsHostsRoot.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aHost : TSearchVFHost;
begin
  OutputDebugStringFoldersD('TShellFolderHostsRoot.GetDisplayNameOf');
  Result := 'Ordinateur Inconnu';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_SEARCH_SORT_HOSTS_HOST then
    begin
      Exit;
    end;

  aHost := FSearch.GetVHostByVID(aPIDLStructure.ItemInfo2);
  if Assigned(aHost) then
    Result := aHost.Name;
end;

function TShellFolderSearchResultsHostsRoot.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWHostsRoot.Create(pidl);
  ExtractIcon := TIExtractIconImplWHostsRoot(Result);
end;

function TShellFolderSearchResultsHostsRoot.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := TIContextMenuImplHostsRoot.Create(pidl);
end;

function TShellFolderSearchResultsHostsRoot.GetViewForm: TShellViewForm;
begin
  Result := nil;
end;

function TEnumIDListHostsRoot.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListHostsRoot.Next(celt: ULONG; out rgelt: PItemIDList;
  var pceltFetched: ULONG): HResult;
begin
  rgelt := nil;
  if celt > 1 then
    Result := S_FALSE
  else
    begin
      if FIndex < PIDLList.Count then
          begin
            rgelt := PIDLList[Findex];
            inc(FIndex);
          end;
      if Assigned(rgelt) then
        begin
          pceltFetched := 1;
          Result := S_OK;
        end
      else
        begin
          FIndex := 0;
          Result := S_FALSE;
        end
    end;
end;

function TEnumIDListHostsRoot.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListHostsRoot.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderSearchResultsHostsRoot.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  aHost : TSearchVFHost;
begin
  FPIDLList.Clear;
  for aHost in FSearch.VFPhysicalTree do
    begin
      aPidlStructure.ItemType := ITEM_SEARCH_SORT_HOSTS_HOST;
      aPidlStructure.ItemInfo1 := FSearch.Search_ID;
      aPidlStructure.ItemInfo2 := aHost.vID;
      FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));
    end;
end;

{ TIExtractIconImplWHostsRoot }

constructor TIExtractIconImplWHostsRoot.Create(pidl: PItemIDList);
var
  aPIDLStructure : TPIDLStructure;
  FSearch : TSearch;
begin
  inherited;
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  CorrespondingHost := nil;
  if aPIDLStructure.ItemType = ITEM_SEARCH_SORT_HOSTS_HOST then
    begin
      FSearch := GetSearchByID(aPIDLStructure.ItemInfo1);
      CorrespondingHost := FSearch.GetVHostByVID(aPIDLStructure.ItemInfo2);
    end;
end;

function TIExtractIconImplWHostsRoot.Extract(pszFile: PWideChar;
  nIconIndex: Cardinal; out phiconLarge, phiconSmall: HICON;
  nIconSize: Cardinal): HRESULT;
var
  IconObject : TIcon;
begin
  Result := S_FALSE;
  IconObject := nil;

  if not Assigned(CorrespondingHost) then
    begin
      Exit;
    end;

  if CorrespondingHost.Online then
    begin
      phiconLarge := GetRessourceIconHandle('OB_ONLINE_COMPUTER');
      phiconSmall := GetRessourceIconHandle('OB_ONLINE_COMPUTER');
      Result := S_OK;
    end
  else
    begin
      phiconLarge := GetRessourceIconHandle('OB_OFFLINE_COMPUTER');
      phiconSmall := GetRessourceIconHandle('OB_OFFLINE_COMPUTER');
      Result := S_OK;
    end;

end;



{ TIContextMenuImplHostsRoot }

//procedure TIContextMenuImplHostsRoot.Populate;
//begin
//  inherited;
//
//end;

{ TIContextMenuImplHostsRoot }

procedure TIContextMenuImplHostsRoot.PopulateItems;
var
  pmi : TMenuItemIdentified;
begin
  inherited;
  pmi := TMenuItemIdentified.Create(FPopupMenu);
  pmi.Default := True;
  pmi.Caption := 'Open';
  pmi.Tag := 1;
  pmi.SpecialCommand := MENUITEM_SPECIAL_COMMAND_OPEN;
  FPopupMenu.Items.Add(pmi);
end;

end.
