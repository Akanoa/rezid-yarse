unit ShellFolderSearchResultsHostsFolder;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, OfflineBrowsing,
     Forms, Searching, ShellFolderView;

type
  TIExtractIconImplWSearchResultsHostsFolder = class(TIExtractIconImplW)
    protected
      FSearch : TSearch;
      FFolder : TSearchVFFolder;
      function PIDLStructToSearchResult(PIDLStruct : TPIDLStructure) : TSearchResult;
    public
      constructor Create(pidl : PItemIDList; Search : TSearch; Folder : TSearchVFFolder);
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal; out phiconLarge: HICON; out phiconSmall: HICON; nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderSearchResultsHostsFolder = class(TShellFolderD)
    private
      FSearch : TSearch;
      FFolder : TSearchVFFolder;
      FPIDLListAll : TList;
      FPIDLListFolders : TList;
      ExtractIcon : TIExtractIconImplWSearchResultsHostsFolder;
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

  TEnumIDListSearchResultsHostsFolder = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplSearchResultsHostsFolder = class(TIContextMenuImpl)
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolder, ShellIcons, ShellAPI;

{ TShellFolderSearchResultsHostsFolder }

function TShellFolderSearchResultsHostsFolder.CompareIDs(pidl1,
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

constructor TShellFolderSearchResultsHostsFolder.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.Create');
  FPIDLListAll := TList.Create;
  FPIDLListFolders := TList.Create;
  FSearch := GetSearchByID(PIDL.ItemInfo1);
  if not Assigned(FSearch) then
    begin
      FSearch := TSearch.Create;
    end;
  FFolder := FSearch.FindFolderInIndex(PIDL.ItemInfo2);
  if not Assigned(FFolder) then
    FFolder := TSearchVFFolder.Create;
//  OutputDebugString3('creating folder: '+inttostr(PIDL.ItemInfo2)+' content: '+inttostr(Length(FFolder.Items))+' items '+inttostr(Length(FFolder.SubFolders))+' sf');
  ExtractIcon := nil;
end;

destructor TShellFolderSearchResultsHostsFolder.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.Destroy');
  FPIDLListFolders.Free;
  FPIDLListAll.Free;
  inherited;
end;

function TShellFolderSearchResultsHostsFolder.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.EnumObjects');
  RebuildPIDLList;
  if grfFlags and SHCONTF_NONFOLDERS = SHCONTF_NONFOLDERS then
    Result := TEnumIDListSearchResultsHostsFolder.Create(FPIDLListAll, grfFlags)
  else
    Result := TEnumIDListSearchResultsHostsFolder.Create(FPIDLListFolders, grfFlags);
  Result.Reset;
end;

function TShellFolderSearchResultsHostsFolder.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  case aPIDLStructure.ItemType of
    ITEM_SEARCH_ITEM:
      begin
        //Rien
      end;
    ITEM_SEARCH_SORT_HOSTS_FOLDER:
      begin
        Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE;
      end;
  end;
end;

function TShellFolderSearchResultsHostsFolder.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderSearchResultsHostsFolder.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderSearchResultsHostsFolder.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
  aFolder : TSearchVFFolder;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.GetDetailsOf');
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
      case aPIDLStructure.ItemType of
        ITEM_SEARCH_ITEM:
          begin
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
          end;
        ITEM_SEARCH_SORT_HOSTS_FOLDER:
          begin
            aFolder := FSearch.FindFolderInIndex(aPIDLStructure.ItemInfo2);
            if Assigned(aFolder) then
              case iColumn of
                0: sString := aFolder.Name;
                1: sString := '';
                2: sString := '';
                3: sString := '';
              end;
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

function TShellFolderSearchResultsHostsFolder.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
  aFolder : TSearchVFFolder;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.GetDisplayNameOf');
  Result := 'Fichier ou dossier inconnu';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  case aPIDLStructure.ItemType of
    ITEM_SEARCH_ITEM:
      begin
        aSearchResult := PIDLStructToSearchResult(aPIDLStructure);
        if Assigned(aSearchResult) then
          begin
            Result := aSearchResult.Name;
          end;
      end;
    ITEM_SEARCH_SORT_HOSTS_FOLDER:
      begin
        Result := 'Dossier inconnu';
        aFolder := FSearch.FindFolderInIndex(aPIDLStructure.ItemInfo2);
        if Assigned(aFolder) then
          begin
            Result := aFolder.Name;
          end;
      end;
  end;
end;

function TShellFolderSearchResultsHostsFolder.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWSearchResultsHostsFolder.Create(pidl, FSearch, FFolder);
  ExtractIcon := TIExtractIconImplWSearchResultsHostsFolder(Result);
end;

function TShellFolderSearchResultsHostsFolder.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := TIContextMenuImplSearchResultsHostsFolder.Create(pidl);
end;

function TShellFolderSearchResultsHostsFolder.GetViewForm: TShellViewForm;
begin
  Result := nil;
end;

function TShellFolderSearchResultsHostsFolder.PIDLStructToSearchResult(
  PIDLStruct: TPIDLStructure): TSearchResult;
begin
  Result := nil;
  if PIDLStruct.ItemInfo1 <> FSearch.Search_ID then
    Exit;
  if PIDLStruct.ItemInfo2 <> FFolder.vID then
    Exit;
  if PIDLStruct.ItemInfo3 >= Length(FFolder.Items) then
    Exit;
  Result := FFolder.Items[PIDLStruct.ItemInfo3];
end;

function TEnumIDListSearchResultsHostsFolder.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListSearchResultsHostsFolder.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListSearchResultsHostsFolder.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListSearchResultsHostsFolder.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderSearchResultsHostsFolder.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  i : word;
  aFolder : TSearchVFFolder;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsHostsFolder.RebuildPIDLList');
  FPIDLListAll.Clear;
  FPIDLListFolders.Clear;

  if Length(FFolder.Items) > 0 then
    begin
      for i := 0 to Length(FFolder.Items) - 1 do
        begin
          case FFolder.Items[i].ItemType of
            itFile:
              begin
//                OutputDebugString3('Inserting file '+inttostr(i));
                aPidlStructure.ItemType := ITEM_SEARCH_ITEM;
                aPidlStructure.ItemInfo1 := FSearch.Search_ID;
                aPidlStructure.ItemInfo2 := FFolder.vID;
                aPidlStructure.ItemInfo3 := i;
                FPIDLListAll.Add(TPIDLStructure_To_PIDl(aPidlStructure));
              end;
          end;
        end;
    end;
  if Length(FFolder.SubFolders) > 0 then
    begin
      for aFolder in FFolder.SubFolders do
      begin
        aPidlStructure.ItemType := ITEM_SEARCH_SORT_HOSTS_FOLDER;
        aPidlStructure.ItemInfo1 := FSearch.Search_ID;
        aPidlStructure.ItemInfo2 := aFolder.vID;
        FPIDLListAll.Add(TPIDLStructure_To_PIDl(aPidlStructure));
        FPIDLListFolders.Add(TPIDLStructure_To_PIDl(aPidlStructure));
      end;
    end;
end;

{ TIExtractIconImplWSearchResultsHostsFolder }

constructor TIExtractIconImplWSearchResultsHostsFolder.Create(pidl : PItemIDList; Search : TSearch; Folder : TSearchVFFolder);
var
  aPIDLStructure : TPIDLStructure;
begin
  inherited Create(pidl);
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  Self.FSearch := Search;
  Self.FFolder := Folder;
end;

function TIExtractIconImplWSearchResultsHostsFolder.Extract(pszFile: PWideChar;
  nIconIndex: Cardinal; out phiconLarge, phiconSmall: HICON;
  nIconSize: Cardinal): HRESULT;
var
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
  Ext : string;
begin
  Result := S_FALSE;

  aPIDLStructure := SelfPIDL;
  case aPIDLStructure.ItemType of
    ITEM_SEARCH_ITEM:
      begin
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
    ITEM_SEARCH_SORT_HOSTS_FOLDER:
      begin
        phiconLarge := GetDirectoryIconHandle(SHGFI_LARGEICON);
        phiconSmall := GetDirectoryIconHandle(SHGFI_SMALLICON);
        Result := S_OK;
      end;
  end;
end;

function TIExtractIconImplWSearchResultsHostsFolder.PIDLStructToSearchResult(
  PIDLStruct: TPIDLStructure): TSearchResult;
begin
  Result := nil;
  if PIDLStruct.ItemInfo1 <> FSearch.Search_ID then
    Exit;
  if PIDLStruct.ItemInfo2 <> FFolder.vID then
    Exit;
  if PIDLStruct.ItemInfo3 >= Length(FFolder.Items) then
    Exit;
  Result := FFolder.Items[PIDLStruct.ItemInfo3];
end;


{ TIContextMenuImplSearchResultsHostsFolder }

procedure TIContextMenuImplSearchResultsHostsFolder.PopulateItems;
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
