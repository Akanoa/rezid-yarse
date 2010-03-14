unit ShellFolderMainMenu;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, Forms, ShellFolderView, ActiveX;

type
  TIExtractIconImplWMainMenu = class(TIExtractIconImplW)
    protected
      IconOfflineBrowser : TIcon;
      IconNewSearch : TIcon;
    public
      constructor Create(pidl : PItemIDList); override;
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal;
        out phiconLarge: HICON; out phiconSmall: HICON;
        nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderMainMenu = class(TShellFolderD)
    private
      FPIDLList : TList;
      ExtractIcon : TIExtractIconImplWMainMenu;
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
      function CompareIDs(pidl1, pidl2:PItemIDList) : integer; override;
      function GetViewForm : TShellViewForm; override;
//      procedure PopulateMenu(Menu: TIContextMenuImpl); override;
      {Bonus}
      destructor Destroy; override;
      constructor Create(PIDL: TPIDLStructure); override;
  end;

  TEnumIDListMainMenu = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplMainMenu = class(TIContextMenuImpl)
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl,
     ShellFolderOfflineBrowserRoot, ShellIcons, Searching;

{ TShellFolderMainMenu }

function TShellFolderMainMenu.CompareIDs(pidl1, pidl2: PItemIDList): integer;
var
  pidl_struct1, pidl_struct2 : TPIDLStructure;
  temp_result : Integer;
begin
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

constructor TShellFolderMainMenu.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderMainMenu.Create');
  FPIDLList := TList.Create;
  ExtractIcon := nil;
end;

destructor TShellFolderMainMenu.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderMainMenu.Destroy');
  FPIDLList.Free;
  inherited;
end;

function TShellFolderMainMenu.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderMainMenu.EnumObjects');
  RebuildPIDLList;
  Result := TEnumIDListMainMenu.Create(FPIDLList, grfFlags);
  Result.Reset;
end;

function TShellFolderMainMenu.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderMainMenu.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType <> ITEM_MAIN_MENU then
    begin
      Exit;
    end;

  case aPIDLStructure.ItemInfo1 of
    ITEM_MAIN_MENU_OFFLINE_BROWSER:
      begin
        Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE;
      end;
    ITEM_MAIN_MENU_NEW_SEARCH:
      begin
        Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE;
      end;
    ITEM_MAIN_MENU_SEARCH:
      begin
        Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE;
      end;
  end;
end;

function TShellFolderMainMenu.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderMainMenu.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderMainMenu.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderMainMenu.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderMainMenu.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderMainMenu.GetDetailsOf');
  if iColumn > 1 then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;
  psd.fmt := LVCFMT_LEFT;
  sString := 'Saucisse';
  if Assigned(pidl)then
    begin
      aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
      case aPIDLStructure.ItemInfo1 of
        ITEM_MAIN_MENU_OFFLINE_BROWSER:
          begin
            case iColumn of
              0: sString := 'Navigateur hors ligne';
              1: sString := 'Navigateur hors ligne (détails)';
            end;
          end;
        ITEM_MAIN_MENU_NEW_SEARCH:
          begin
            case iColumn of
              0: sString := 'Nouvelle recherche';
              1: sString := 'Nouvelle recherche (détails)';
            end;
          end;
        ITEM_MAIN_MENU_SEARCH:
          begin
            case iColumn of
              0: sString := 'Recherche';
              1: sString := 'Recherche (détails)';
            end;
          end;
      end;
    end
  else
    begin
      case iColumn of
        0: sString := 'Nom';
        1: sString := 'Description';
      end;
    end;

  FillStrRet(psd.str, srtOLEStr, WideString(sString), 0);
  psd.cxChar := 50;
  //  psd.str
  Result := S_OK;
end;

function TShellFolderMainMenu.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aSearch : TSearch;
begin
  OutputDebugStringFoldersD('TShellFolderMainMenu.GetDisplayNameOf');
  Result := 'ERROR';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_MAIN_MENU then
    begin
      Exit;
    end;

  case aPIDLStructure.ItemInfo1 of
    ITEM_MAIN_MENU_OFFLINE_BROWSER:
      begin
        Result := 'Navigateur Hors Ligne';
      end;
    ITEM_MAIN_MENU_NEW_SEARCH:
      begin
        Result := 'Nouvelle recherche';
      end;
    ITEM_MAIN_MENU_SEARCH:
      begin
        Result := 'Recherche inconnue';
        aSearch := GetSearchByID(aPIDLStructure.ItemInfo2);
        if Assigned(aSearch) then
          Result := 'Recherche: '+aSearch.Searched_string;
      end;
  end;
end;

function TShellFolderMainMenu.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  if False and Assigned(ExtractIcon) then
    begin
      Result := ExtractIcon;
      TIExtractIconImplW(Result).SetPidl(pidl);
    end
  else
    begin
      Result := TIExtractIconImplWMainMenu.Create(pidl);
      ExtractIcon := TIExtractIconImplWMainMenu(Result);
    end;
end;

function TShellFolderMainMenu.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
var
  aPIDLStructure : TPIDLStructure;
begin
  Result := nil;
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_MAIN_MENU then
    begin
      Exit;
    end;
  Result := TIContextMenuImplMainMenu.Create(pidl);
end;


function TShellFolderMainMenu.GetViewForm: TShellViewForm;
begin
  Result := nil;
end;

function TEnumIDListMainMenu.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListMainMenu.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListMainMenu.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK
end;

function TEnumIDListMainMenu.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderMainMenu.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  i : word;
begin
  FPIDLList.Clear;

  aPidlStructure.ItemType := ITEM_MAIN_MENU;
  aPidlStructure.ItemInfo1 := ITEM_MAIN_MENU_NEW_SEARCH;
  aPidlStructure.ItemInfo2 := 1;
  FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));

  aPidlStructure.ItemType := ITEM_MAIN_MENU;
  aPidlStructure.ItemInfo1 := ITEM_MAIN_MENU_OFFLINE_BROWSER;
  aPidlStructure.ItemInfo2 := 1;
  FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));

  if AllSearches.Count > 0 then
    for i := 0 to AllSearches.Count - 1 do
      begin
        aPidlStructure.ItemType := ITEM_MAIN_MENU;
        aPidlStructure.ItemInfo1 := ITEM_MAIN_MENU_SEARCH;
        aPidlStructure.ItemInfo2 := TSearch(AllSearches[i]).Search_ID;
        FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));
      end;
end;

{ TIExtractIconImplWMainMenu }

constructor TIExtractIconImplWMainMenu.Create(pidl: PItemIDList);
begin
  inherited;
  IconOfflineBrowser := nil;
  IconNewSearch := nil;
end;

function TIExtractIconImplWMainMenu.Extract(pszFile: PWideChar;
  nIconIndex: Cardinal; out phiconLarge, phiconSmall: HICON;
  nIconSize: Cardinal): HRESULT;
var
  IconObject : TIcon;
begin
  Result := S_FALSE;
  IconObject := nil;

  if Self.SelfPIDL.ItemType <> ITEM_MAIN_MENU then
    begin
      Exit;
    end;

  case Self.SelfPIDL.ItemInfo1 of
    ITEM_MAIN_MENU_OFFLINE_BROWSER:
      begin
        phiconLarge := GetRessourceIconHandle('OFFLINE_BROWSER');
        phiconSmall := GetRessourceIconHandle('OFFLINE_BROWSER');
        Result := S_OK;
      end;
    ITEM_MAIN_MENU_NEW_SEARCH:
      begin
        phiconLarge := GetRessourceIconHandle('SEARCH');
        phiconSmall := GetRessourceIconHandle('SEARCH');
        Result := S_OK;
      end;
    ITEM_MAIN_MENU_SEARCH:
      begin
        phiconLarge := GetRessourceIconHandle('SEARCH_FOLDER');
        phiconSmall := GetRessourceIconHandle('SEARCH_FOLDER');
        Result := S_OK;
      end;
  end;

end;

//procedure TIContextMenuImplMainMenu.Populate;
//begin
//
//end;


{ TIContextMenuImplMainMenu }

procedure TIContextMenuImplMainMenu.PopulateItems;
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
