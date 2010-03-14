unit ShellFolderSearchResults;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, OfflineBrowsing,
     Forms, Searching, ShellFolderView;

type
  TIExtractIconImplWSearchResultsAll = class(TIExtractIconImplW)
    protected
      FSearch : TSearch;
      function PIDLStructToSearchResult(PIDLStruct : TPIDLStructure) : TSearchResult;
    public
      constructor Create(pidl : PItemIDList; Search : TSearch);
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal; out phiconLarge: HICON; out phiconSmall: HICON; nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderSearchResultsAll = class(TShellFolderD)
    private
      FSearch : TSearch;
      FPIDLListAll : TList;
      FPIDLListFolders : TList;
      ExtractIcon : TIExtractIconImplWSearchResultsAll;
      procedure RebuildPIDLList;
      function PIDLStructToSearchResult(PIDLStruct : TPIDLStructure) : TSearchResult;
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

  TEnumIDListSearchResultsAll = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplSearchResultsAll = class(TIContextMenuImpl)
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolder, ShellIcons, ShellAPI;

{ TShellFolderSearchResultsAll }

function TShellFolderSearchResultsAll.CompareIDs(pidl1,
  pidl2: PItemIDList): Integer;
var
  pidl_struct1, pidl_struct2 : TPIDLStructure;
  temp_result : Integer;
begin
  pidl_struct1 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl1));
  pidl_struct2 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl2));
  temp_result := pidl_struct1.ItemInfo1 - pidl_struct2.ItemInfo1;
  Result := 0;

  if temp_result = 0 then
    Result := 0
  else if temp_result < 0 then
    Result := -1
  else if temp_result > 0 then
    Result := 1;
end;

constructor TShellFolderSearchResultsAll.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.Create');
  FPIDLListAll := TList.Create;
  FPIDLListFolders := TList.Create;
  FSearch := GetSearchByID(PIDL.ItemInfo2);
  if not Assigned(FSearch) then
    begin
      FSearch := TSearch.Create;
    end;
  ExtractIcon := nil;
end;

destructor TShellFolderSearchResultsAll.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.Destroy');
  FPIDLListFolders.Free;
  FPIDLListAll.Free;
  inherited;
end;

function TShellFolderSearchResultsAll.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.EnumObjects');
  RebuildPIDLList;
  if grfFlags and SHCONTF_NONFOLDERS = SHCONTF_NONFOLDERS then
    Result := TEnumIDListSearchResultsAll.Create(FPIDLListAll, grfFlags)
  else
    Result := TEnumIDListSearchResultsAll.Create(FPIDLListFolders, grfFlags);
  Result.Reset;
end;

function TShellFolderSearchResultsAll.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType = ITEM_OFFLINE_BROWSER_FOLDER then
    Result := Result or (SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE);
end;

function TShellFolderSearchResultsAll.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderSearchResultsAll.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderSearchResultsAll.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.GetDetailsOf');
  if iColumn > 3 then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;
  psd.fmt := LVCFMT_LEFT;
  sString := 'Saucisse';
  if Assigned(pidl)then
    begin
      aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
      aSearchResult := PIDLStructToSearchResult(aPIDLStructure);
      if Assigned(aSearchResult) then
        begin
          case iColumn of
            0: sString := aSearchResult.Name;
            1: sString := aSearchResult.FileType;
            2: sString := FormatFileSize(aSearchResult.Size, 2);
            3: sString := aSearchResult.Path;
          end;
        end;
      end
  else
    begin
      case iColumn of
        0: sString := 'Nom';
        1: sString := 'Type';
        2: sString := 'Taille';
        3: sString := 'Chemin';
      end;
    end;

  FillStrRet(psd.str, srtOLEStr, WideString(sString), 0);
  psd.cxChar := 50;
  //  psd.str
  Result := S_OK;
end;

function TShellFolderSearchResultsAll.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.GetDisplayNameOf');
  Result := 'Fichier ou dossier inconnu';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_SEARCH_ITEM then
    Exit;
  aSearchResult := PIDLStructToSearchResult(aPIDLStructure);
  if Assigned(aSearchResult) then
    begin
      Result := aSearchResult.Name;
    end;
end;

function TShellFolderSearchResultsAll.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWSearchResultsAll.Create(pidl, FSearch);
  ExtractIcon := TIExtractIconImplWSearchResultsAll(Result);
end;

function TShellFolderSearchResultsAll.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := TIContextMenuImplSearchResultsAll.Create(pidl);
end;

function TShellFolderSearchResultsAll.GetViewForm: TShellViewForm;
begin
  Result := nil;
end;

function TShellFolderSearchResultsAll.PIDLStructToSearchResult(
  PIDLStruct: TPIDLStructure): TSearchResult;
begin
  Result := nil;
  if PIDLStruct.ItemInfo1 <> FSearch.Search_ID then
    Exit;
  if PIDLStruct.ItemInfo2 >= Length(FSearch.Search_Results) then
    Exit;
  Result := FSearch.Search_Results[PIDLStruct.ItemInfo2];
end;

function TEnumIDListSearchResultsAll.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListSearchResultsAll.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListSearchResultsAll.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListSearchResultsAll.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderSearchResultsAll.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  i : word;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsAll.RebuildPIDLList');
  FPIDLListAll.Clear;
  if Length(FSearch.Search_Results) > 0 then
    begin
      for i := 0 to Length(FSearch.Search_Results) - 1 do
        begin
          aPidlStructure.ItemType := ITEM_SEARCH_ITEM;
          aPidlStructure.ItemInfo1 := FSearch.Search_ID;
          aPidlStructure.ItemInfo2 := i;
          FPIDLListAll.Add(TPIDLStructure_To_PIDl(aPidlStructure));
        end;
    end;
end;

{ TIExtractIconImplWSearchResultsAll }

constructor TIExtractIconImplWSearchResultsAll.Create(pidl : PItemIDList; Search : TSearch);
var
  aPIDLStructure : TPIDLStructure;
begin
  inherited Create(pidl);
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  Self.FSearch := Search;
end;

function TIExtractIconImplWSearchResultsAll.Extract(pszFile: PWideChar;
  nIconIndex: Cardinal; out phiconLarge, phiconSmall: HICON;
  nIconSize: Cardinal): HRESULT;
var
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
  Ext : string;
begin
  Result := S_FALSE;

  aPIDLStructure := SelfPIDL;
  if aPIDLStructure.ItemType <> ITEM_SEARCH_ITEM then
    Exit;
  aSearchResult := PIDLStructToSearchResult(aPIDLStructure);
  if Assigned(aSearchResult) then
    begin
      Ext := ExtractFileExt(aSearchResult.Name)
    end
  else
    Ext := '.';
  phiconLarge := GetExtensionIconHandle(Ext, SHGFI_LARGEICON);
  phiconSmall := GetExtensionIconHandle(Ext, SHGFI_SMALLICON);
  Result := S_OK;
end;

function TIExtractIconImplWSearchResultsAll.PIDLStructToSearchResult(
  PIDLStruct: TPIDLStructure): TSearchResult;
begin
  Result := nil;
  if PIDLStruct.ItemInfo1 <> FSearch.Search_ID then
    Exit;
  if PIDLStruct.ItemInfo2 >= Length(FSearch.Search_Results) then
    Exit;
  Result := FSearch.Search_Results[PIDLStruct.ItemInfo2];
end;


{ TIContextMenuImplSearchResultsAll }

procedure TIContextMenuImplSearchResultsAll.PopulateItems;
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
