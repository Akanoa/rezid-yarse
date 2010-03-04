unit ShellFolderMainMenu;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus;

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
      function GetFromRessource(RessourceName : string) : TIcon;
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
      function GetIContextMenuImpl(pidl: PItemIDList): IContextMenu; override;
      function GetAttributesOf(apidl:PItemIDList) : UINT; override;
      function GetDefaultColumn(var pSort: Cardinal; var pDisplay: Cardinal): HRESULT; override;
      function GetDefaultColumnState(iColumn: Cardinal; var pcsFlags: Cardinal): HRESULT; override;
      function GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal; var psd: _SHELLDETAILS): HRESULT; override;
      function CompareIDs(pidl1, pidl2:PItemIDList) : integer; override;
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
  private
    FPopupMenu : TPopupMenuIdentified;
  public
    {Bonus}
    constructor Create(pidl : PItemIDList); virtual;
    destructor Destroy; override;
    {IContextMenu}
    function GetCommandString(idCmd: Cardinal; uType: Cardinal; pwReserved: PUINT; pszName: PAnsiChar; cchMax: Cardinal): HRESULT; override; stdcall;
    function InvokeCommand(var lpici: _CMINVOKECOMMANDINFO): HRESULT; override; stdcall;
    function QueryContextMenu(Menu: HMENU; indexMenu: Cardinal; idCmdFirst: Cardinal; idCmdLast: Cardinal; uFlags: Cardinal): HRESULT; override; stdcall;
    {Actions}
    procedure Action_NewSearch(Sender: TObject);
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, NewSearch,
     ShellFolderOfflineBrowserRoot;

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
        Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER;
      end;
    ITEM_MAIN_MENU_NEW_SEARCH:
      begin
        //Rien
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
  pidl: PItemIDList): IContextMenu;
var
  aPIDLStructure : TPIDLStructure;
begin
  Result := nil;
  Exit;
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_MAIN_MENU then
    begin
      Exit;
    end;

  case aPIDLStructure.ItemInfo1 of
    ITEM_MAIN_MENU_OFFLINE_BROWSER:
      begin

      end;
    ITEM_MAIN_MENU_NEW_SEARCH:
      begin
        Result := TIContextMenuImplMainMenu.Create(pidl);
      end;
  end;
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
        if False and Assigned(IconOfflineBrowser) then
          IconObject := IconOfflineBrowser
        else
          begin
            IconObject := Self.GetFromRessource('OFFLINE_BROWSER');
            IconOfflineBrowser := IconObject;
          end;
      end;
    ITEM_MAIN_MENU_NEW_SEARCH:
      begin
        if False and Assigned(IconNewSearch) then
          IconObject := IconNewSearch
        else
          begin
            IconObject := Self.GetFromRessource('SEARCH');
            IconNewSearch := IconObject;
          end;
      end;
  end;

  if Assigned(IconObject) then
    begin
      phiconLarge := IconObject.Handle;
      phiconSmall := IconObject.Handle;
      Result := S_OK;
    end;
end;

function TIExtractIconImplWMainMenu.GetFromRessource(
  RessourceName: string): TIcon;
var
  LibHandle : THandle;
begin
  Result := TIcon.Create;
  LibHandle:=Loadlibrary(PWideChar(Sto_GetModuleName()));
  try
    if LibHandle > 0 then
    begin
      Result.LoadFromResourceName(LibHandle, RessourceName);
    end;
  finally
    FreeLibrary(LibHandle);
  end;
end;

{ TIContextMenuImplMainMenu }

constructor TIContextMenuImplMainMenu.Create(pidl : PItemIDList);
var
  pmi : TMenuItemIdentified;
begin
  inherited;
  FPopupMenu := TPopupMenuIdentified.Create(nil);

  pmi := TMenuItemIdentified.Create(FPopupMenu);
  pmi.Default := true;
  pmi.Caption := 'Open';
  pmi.Tag := 1;
  pmi.OnClick := Self.Action_NewSearch;
  FPopupMenu.Items.Add(pmi);

  pmi := TMenuItemIdentified.Create(FPopupMenu);
  pmi.Caption := 'Fuck';
  pmi.Tag := 2;
  FPopupMenu.Items.Add(pmi);
end;

destructor TIContextMenuImplMainMenu.Destroy;
begin
  FPopupMenu.Free;
  inherited;
end;

function TIContextMenuImplMainMenu.GetCommandString(idCmd, uType: Cardinal;
  pwReserved: PUINT; pszName: PAnsiChar; cchMax: Cardinal): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TIContextMenuImplMainMenu.InvokeCommand(
  var lpici: _CMINVOKECOMMANDINFO): HRESULT;
var
  amii : TMenuItemIdentified;
begin
  if HiWord(Integer(lpici.lpVerb)) <> 0 then
  begin
    Result := E_FAIL;
    Exit;
  end;
  OutputDebugString3('Quering number '+inttostr(LoWord(lpici.lpVerb)));
  amii := FPopupMenu.FindItemByIDInMenu(LoWord(lpici.lpVerb));
  if Assigned(amii) then
    begin
      amii.OnClick(amii);
//      ShowMessage(amii.Caption);
    end;
  Result := S_OK;
end;

function TIContextMenuImplMainMenu.QueryContextMenu(Menu: HMENU; indexMenu,
  idCmdFirst, idCmdLast, uFlags: Cardinal): HRESULT;
var
  aMenuItem : TMenuItem;
  count : word;
  flags : Cardinal;
  MenuItemInfo : tagMENUITEMINFO;
begin
  count := 0;
  for aMenuItem in FPopupMenu.Items do
  begin
    flags := MF_STRING;
    if aMenuItem.Default then
      flags := flags or MF_DEFAULT;
    MenuItemInfo.cbSize := SizeOf(tagMENUITEMINFO);
    MenuItemInfo.fMask := MIIM_ID or MIIM_STRING or MIIM_STATE;
    MenuItemInfo.fType := MFT_STRING;
    if aMenuItem.Default then
      MenuItemInfo.fState := MFS_DEFAULT
    else
      MenuItemInfo.fState := MFS_ENABLED;
    MenuItemInfo.wID := idCmdFirst + count;
    MenuItemInfo.dwTypeData := PWideChar(aMenuItem.Caption);
    MenuItemInfo.cch := Length(aMenuItem.Caption);
    InsertMenuItem(Menu, indexMenu+count, True, MenuItemInfo);
//    InsertMenu(Menu, indexMenu, flags, idCmdFirst+count);
    TMenuItemIdentified(aMenuItem).IDInMenu := count;
    Inc(count);
  end;
  Result := count;
end;

procedure TIContextMenuImplMainMenu.Action_NewSearch(Sender : TObject);
begin
  if Assigned(FNewSearch) then
    begin
      FNewSearch.Show;
    end
  else
    begin
      FNewSearch := TFNewSearch.Create(nil);
      FNewSearch.Show;
    end;
end;

end.
