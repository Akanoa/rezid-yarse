unit ShellFolderSearchResultsHostsHost;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, Searching, Forms, ShellFolderView;

type
  TIExtractIconImplWSearchResultsHostsHost = class(TIExtractIconImplW)
    protected
      FSearch : TSearch;
      FFolder : TSearchVFFolder;
    public
      constructor Create(pidl : PItemIDList); override;
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal;
        out phiconLarge: HICON; out phiconSmall: HICON;
        nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderSearchResultsHostsHost = class(TShellFolderD)
    private
      FPIDLList : TList;
      FSearch : TSearch;
      FHost : TSearchVFHost;
      ExtractIcon : TIExtractIconImplWSearchResultsHostsHost;
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

  TEnumIDListSearchResultsHostsHost = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplSearchResultsHostsHost = class(TIContextMenuImpl)
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolderOfflineBrowserHost, ShellFolderMainMenu, ShellIcons;

{ TShellFolderSearchResultsHostsHost }

function TShellFolderSearchResultsHostsHost.CompareIDs(pidl1,
  pidl2: PItemIDList): Integer;
var
  pidl_struct1, pidl_struct2 : TPIDLStructure;
  temp_result : Integer;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.CompareIDs');
  pidl_struct1 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl1));
  pidl_struct2 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl2));
  temp_result := pidl_struct1.ItemInfo2 - pidl_struct2.ItemInfo2;

  if temp_result = 0 then
    Result := 0
  else if temp_result < 0 then
    Result := -1
  else if temp_result > 0 then
    Result := 1;
end;

constructor TShellFolderSearchResultsHostsHost.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.Create');
  FPIDLList := TList.Create;
  FSearch := GetSearchByID(PIDL.ItemInfo1);
  if not Assigned(FSearch) then
    FSearch := TSearch.Create;
  FHost := FSearch.GetVHostByVID(PIDL.ItemInfo2);
  ExtractIcon := nil;
end;

destructor TShellFolderSearchResultsHostsHost.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.Destroy');
  FPIDLList.Free;
  inherited;
end;

function TShellFolderSearchResultsHostsHost.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.EnumObjects');
  RebuildPIDLList;
  Result := TEnumIDListSearchResultsHostsHost.Create(FPIDLList, grfFlags);
  Result.Reset;
end;

function TShellFolderSearchResultsHostsHost.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
  aFolder : TSearchVFFolder;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType <> ITEM_SEARCH_SORT_HOSTS_FOLDER then
    begin
      Exit;
    end;
  aFolder := FHost.GetSubFolder(aPIDLStructure.ItemInfo2);
  if not Assigned(aFolder) then
    begin
      Exit;
    end;
  Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE;
end;

function TShellFolderSearchResultsHostsHost.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderSearchResultsHostsHost.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderSearchResultsHostsHost.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aFolder : TSearchVFFolder;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.GetDetailsOf');
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
      if aPIDLStructure.ItemType = ITEM_SEARCH_SORT_HOSTS_FOLDER then
        begin
          aFolder := FHost.GetSubFolder(aPIDLStructure.ItemInfo2);
          if Assigned(aFolder) then
            begin
              case iColumn of
                0: sString := aFolder.Name;
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

function TShellFolderSearchResultsHostsHost.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aFolder : TSearchVFFolder;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsHost.GetDisplayNameOf');
//  OutputDebugString3('ID'+inttostr(aPIDLStructure.ItemInfo2));
  Result := 'Ordinateur Inconnu';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_SEARCH_SORT_HOSTS_FOLDER then
    begin
      Exit;
    end;

  aFolder := FHost.GetSubFolder(aPIDLStructure.ItemInfo2);
  if Assigned(aFolder) then
    Result := aFolder.Name;
end;

function TShellFolderSearchResultsHostsHost.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWSearchResultsHostsHost.Create(pidl);
  ExtractIcon := TIExtractIconImplWSearchResultsHostsHost(Result);
end;

function TShellFolderSearchResultsHostsHost.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := TIContextMenuImplSearchResultsHostsHost.Create(pidl);
end;

function TShellFolderSearchResultsHostsHost.GetViewForm: TShellViewForm;
begin
  Result := nil;
end;

function TEnumIDListSearchResultsHostsHost.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListSearchResultsHostsHost.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListSearchResultsHostsHost.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListSearchResultsHostsHost.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderSearchResultsHostsHost.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  aFolder : TSearchVFFolder;
begin
  FPIDLList.Clear;
  for aFolder in FHost.Folders do
    begin
      aPidlStructure.ItemType := ITEM_SEARCH_SORT_HOSTS_FOLDER;
      aPidlStructure.ItemInfo1 := FSearch.Search_ID;
      aPidlStructure.ItemInfo2 := aFolder.vID;
//      OutputDebugString3('Adding to host item '+inttostr(aFolder.vID));
      FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));
    end;
end;

{ TIExtractIconImplWSearchResultsHostsHost }

constructor TIExtractIconImplWSearchResultsHostsHost.Create(pidl: PItemIDList);
var
  aPIDLStructure : TPIDLStructure;
begin
  inherited;
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  FSearch := GetSearchByID(aPIDLStructure.ItemInfo1);
  if not Assigned(FSearch) then
    FSearch := TSearch.Create;
  FFolder := FSearch.FindFolderInIndex(aPIDLStructure.ItemInfo2);
end;

function TIExtractIconImplWSearchResultsHostsHost.Extract(pszFile: PWideChar;
  nIconIndex: Cardinal; out phiconLarge, phiconSmall: HICON;
  nIconSize: Cardinal): HRESULT;
var
  IconObject : TIcon;
begin
  Result := S_FALSE;
  IconObject := nil;

  if not Assigned(FFolder) then
    begin
      Exit;
    end;

  phiconLarge := GetRessourceIconHandle('OB_SHARE');
  phiconSmall := GetRessourceIconHandle('OB_SHARE');
  Result := S_OK;
end;



{ TIContextMenuImplSearchResultsHostsHost }

//procedure TIContextMenuImplSearchResultsHostsHost.Populate;
//begin
//  inherited;
//
//end;

{ TIContextMenuImplSearchResultsHostsHost }

procedure TIContextMenuImplSearchResultsHostsHost.PopulateItems;
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
