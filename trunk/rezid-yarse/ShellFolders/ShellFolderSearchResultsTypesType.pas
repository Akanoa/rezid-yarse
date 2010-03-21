unit ShellFolderSearchResultsTypesType;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, OfflineBrowsing,
     Forms, Searching, ShellFolderView;

type
  TIExtractIconImplWSearchResultsTypesType = class(TIExtractIconImplW)
    protected
      FSearch : TSearch;
      FType : TSearchVFFileType;
      function PIDLStructToSearchResult(PIDLStruct : TPIDLStructure) : TSearchResult;
    public
      constructor Create(pidl : PItemIDList; Search : TSearch; Folder : TSearchVFFileType);
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal; out phiconLarge: HICON; out phiconSmall: HICON; nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderSearchResultsTypesType = class(TShellFolderD)
    private
      FSearch : TSearch;
      FType : TSearchVFFileType;
      FPIDLListAll : TList;
      ExtractIcon : TIExtractIconImplWSearchResultsTypesType;
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

  TEnumIDListSearchResultsTypesType = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplSearchResultsTypesType = class(TIContextMenuImpl)
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolder, ShellIcons, ShellAPI;

{ TShellFolderSearchResultsTypesType }

function TShellFolderSearchResultsTypesType.CompareIDs(pidl1,
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

constructor TShellFolderSearchResultsTypesType.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.Create');
  FPIDLListAll := TList.Create;
  FSearch := GetSearchByID(PIDL.ItemInfo1);
  if not Assigned(FSearch) then
    begin
      FSearch := TSearch.Create;
    end;
  FType := FSearch.GetVTypeByVID(PIDL.ItemInfo2);
  if not Assigned(FType) then
    FType := TSearchVFFileType.Create;
//  OutputDebugString3('creating folder: '+inttostr(PIDL.ItemInfo2)+' content: '+inttostr(Length(FType.Items))+' items '+inttostr(Length(FType.SubFolders))+' sf');
  ExtractIcon := nil;
end;

destructor TShellFolderSearchResultsTypesType.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.Destroy');
  FPIDLListAll.Free;
  inherited;
end;

function TShellFolderSearchResultsTypesType.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.EnumObjects');
  RebuildPIDLList;
  Result := TEnumIDListSearchResultsTypesType.Create(FPIDLListAll, grfFlags);
  Result.Reset;
end;

function TShellFolderSearchResultsTypesType.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  case aPIDLStructure.ItemType of
    ITEM_SEARCH_ITEM:
      begin
        //Rien
      end;
  end;
end;

function TShellFolderSearchResultsTypesType.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderSearchResultsTypesType.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderSearchResultsTypesType.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
  aFolder : TSearchVFFileType;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.GetDetailsOf');
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

function TShellFolderSearchResultsTypesType.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aSearchResult : TSearchResult;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.GetDisplayNameOf');
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
  end;
end;

function TShellFolderSearchResultsTypesType.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWSearchResultsTypesType.Create(pidl, FSearch, FType);
  ExtractIcon := TIExtractIconImplWSearchResultsTypesType(Result);
end;

function TShellFolderSearchResultsTypesType.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := TIContextMenuImplSearchResultsTypesType.Create(pidl);
end;

function TShellFolderSearchResultsTypesType.GetViewForm: TShellViewForm;
begin
  Result := nil;
end;

function TShellFolderSearchResultsTypesType.PIDLStructToSearchResult(
  PIDLStruct: TPIDLStructure): TSearchResult;
begin
  Result := nil;
  if PIDLStruct.ItemInfo1 <> FSearch.Search_ID then
    Exit;
  if PIDLStruct.ItemInfo2 <> FType.vID then
    Exit;
  if PIDLStruct.ItemInfo3 >= Length(FType.Items) then
    Exit;
  Result := FType.Items[PIDLStruct.ItemInfo3];
end;

function TEnumIDListSearchResultsTypesType.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListSearchResultsTypesType.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListSearchResultsTypesType.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListSearchResultsTypesType.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderSearchResultsTypesType.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  i : word;
  aFolder : TSearchVFFileType;
begin
  OutputDebugStringFoldersD('TShellFolderSearchResultsTypesType.RebuildPIDLList');
  FPIDLListAll.Clear;

  if Length(FType.Items) > 0 then
    begin
      for i := 0 to Length(FType.Items) - 1 do
        begin
          case FType.Items[i].ItemType of
            itFile:
              begin
//                OutputDebugString3('Inserting file '+inttostr(i));
                aPidlStructure.ItemType := ITEM_SEARCH_ITEM;
                aPidlStructure.ItemInfo1 := FSearch.Search_ID;
                aPidlStructure.ItemInfo2 := FType.vID;
                aPidlStructure.ItemInfo3 := i;
                FPIDLListAll.Add(TPIDLStructure_To_PIDl(aPidlStructure));
              end;
          end;
        end;
    end;
end;

{ TIExtractIconImplWSearchResultsTypesType }

constructor TIExtractIconImplWSearchResultsTypesType.Create(pidl : PItemIDList; Search : TSearch; Folder : TSearchVFFileType);
var
  aPIDLStructure : TPIDLStructure;
begin
  inherited Create(pidl);
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  Self.FSearch := Search;
  Self.FType := Folder;
end;

function TIExtractIconImplWSearchResultsTypesType.Extract(pszFile: PWideChar;
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

function TIExtractIconImplWSearchResultsTypesType.PIDLStructToSearchResult(
  PIDLStruct: TPIDLStructure): TSearchResult;
begin
  Result := nil;
  if PIDLStruct.ItemInfo1 <> FSearch.Search_ID then
    Exit;
  if PIDLStruct.ItemInfo2 <> FType.vID then
    Exit;
  if PIDLStruct.ItemInfo3 >= Length(FType.Items) then
    Exit;
  Result := FType.Items[PIDLStruct.ItemInfo3];
end;


{ TIContextMenuImplSearchResultsTypesType }

procedure TIContextMenuImplSearchResultsTypesType.PopulateItems;
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
