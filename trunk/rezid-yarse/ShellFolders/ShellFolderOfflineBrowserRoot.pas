unit ShellFolderOfflineBrowserRoot;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, OfflineBrowsing;

type
  TIExtractIconImplWOfflineBrowserRoot = class(TIExtractIconImplW)
    protected
      CorrespondingHost : TOfflineBrowserHost;
    public
      constructor Create(pidl : PItemIDList); override;
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal;
        out phiconLarge: HICON; out phiconSmall: HICON;
        nIconSize: Cardinal): HRESULT; override; stdcall;
      function GetFromRessource(RessourceName : string) : TIcon;
  end;

  TShellFolderOfflineBrowserRoot = class(TShellFolderD)
    private
      FPIDLList : TList;
      ExtractIcon : TIExtractIconImplWOfflineBrowserRoot;
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
      {Bonus}
      destructor Destroy; override;
      constructor Create(PIDL: TPIDLStructure); override;
  end;

  TEnumIDListOfflineBrowserRoot = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplOfflineBrowserRoot = class(TIContextMenuImpl)
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
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl;

{ TShellFolderOfflineBrowserRoot }

constructor TShellFolderOfflineBrowserRoot.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.Create');
  FPIDLList := TList.Create;
  ExtractIcon := nil;
end;

destructor TShellFolderOfflineBrowserRoot.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.Destroy');
  FPIDLList.Free;
  inherited;
end;

function TShellFolderOfflineBrowserRoot.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.EnumObjects');
  RebuildPIDLList;
  Result := TEnumIDListOfflineBrowserRoot.Create(FPIDLList, grfFlags);
  Result.Reset;
end;

function TShellFolderOfflineBrowserRoot.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType <> ITEM_MAIN_MENU then
    begin
      Exit;
    end;

  case aPIDLStructure.ItemInfo1 of
    ITEM_MAIN_MENU_OFFLINE_BROWSER:
      begin
//        Result := Result or SFGAO_FOLDER;
      end;
    ITEM_MAIN_MENU_NEW_SEARCH:
      begin
        //Rien
      end;
  end;
end;

function TShellFolderOfflineBrowserRoot.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderOfflineBrowserRoot.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderOfflineBrowserRoot.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aHost : TOfflineBrowserHost;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.GetDetailsOf');
  if iColumn > 4 then
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
      if aPIDLStructure.ItemType = ITEM_OFFLINE_BROWSER_HOST then
        begin
          aHost := GetHostByID(OfflineBrowserHostList, aPIDLStructure.ItemInfo1);
          if Assigned(aHost) then
            begin
              case iColumn of
                0: sString := aHost.Name;
                1: sString := aHost.Comment;
                2: sString := aHost.IP;
                3: sString := inttostr(aHost.ShareCount);
                4: sString := 'Status';
              end;
            end;
        end;
    end
  else
    begin
      case iColumn of
        0: sString := 'Nom';
        1: sString := 'Description';
        2: sString := 'IP';
        3: sString := 'Nombre de partages';
        4: sString := 'Status';
      end;
    end;

  FillStrRet(psd.str, srtOLEStr, WideString(sString), 0);
  psd.cxChar := 15;
  //  psd.str
  Result := S_OK;
end;

function TShellFolderOfflineBrowserRoot.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aHost : TOfflineBrowserHost;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.GetDisplayNameOf');
  Result := 'Ordinateur Inconnu';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_OFFLINE_BROWSER_HOST then
    begin
      Exit;
    end;

  aHost := GetHostByID(OfflineBrowserHostList, aPIDLStructure.ItemInfo1);
  if Assigned(aHost) then
    Result := aHost.Name;
end;

function TShellFolderOfflineBrowserRoot.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWOfflineBrowserRoot.Create(pidl);
  ExtractIcon := TIExtractIconImplWOfflineBrowserRoot(Result);
end;

function TShellFolderOfflineBrowserRoot.GetIContextMenuImpl(
  pidl: PItemIDList): IContextMenu;
begin
  Result := nil;
//  Result := TIContextMenuImplOfflineBrowserRoot.Create(pidl);
end;

function TEnumIDListOfflineBrowserRoot.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListOfflineBrowserRoot.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListOfflineBrowserRoot.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListOfflineBrowserRoot.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderOfflineBrowserRoot.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  aHost : TOfflineBrowserHost;
begin
  FPIDLList.Clear;
  UpdateOfflineBrowsingHostList;
  for aHost in OfflineBrowserHostList do
    begin
      aPidlStructure.ItemType := ITEM_OFFLINE_BROWSER_HOST;
      aPidlStructure.ItemInfo1 := aHost.ID;
      aPidlStructure.ItemInfo2 := 12; //Cette valeur ne sert à rien
      FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));
    end;


//
//  aPidlStructure.ItemType := ITEM_MAIN_MENU;
//  aPidlStructure.ItemInfo1 := ITEM_MAIN_MENU_OFFLINE_BROWSER;
//  aPidlStructure.ItemInfo2 := 1;
//  FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));

end;

{ TIExtractIconImplWOfflineBrowserRoot }

constructor TIExtractIconImplWOfflineBrowserRoot.Create(pidl: PItemIDList);
var
  aPIDLStructure : TPIDLStructure;
begin
  inherited;
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  CorrespondingHost := nil;
  if aPIDLStructure.ItemType = ITEM_OFFLINE_BROWSER_HOST then
    begin
      CorrespondingHost := GetHostByID(OfflineBrowserHostList, aPIDLStructure.ItemInfo1);
    end;
end;

function TIExtractIconImplWOfflineBrowserRoot.Extract(pszFile: PWideChar;
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
      if CorrespondingHost.ShareCount > 0 then
        begin
          IconObject := Self.GetFromRessource('OB_ONLINE_COMPUTER');
        end
      else
        begin
          IconObject := Self.GetFromRessource('OB_ONLINE_SUCKER');
        end;
    end
  else
    begin
      IconObject := Self.GetFromRessource('OB_OFFLINE_COMPUTER');
    end;

  if Assigned(IconObject) then
    begin
      phiconLarge := IconObject.Handle;
      phiconSmall := IconObject.Handle;
      Result := S_OK;
    end;
end;

function TIExtractIconImplWOfflineBrowserRoot.GetFromRessource(
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

{ TIContextMenuImplOfflineBrowserRoot }

constructor TIContextMenuImplOfflineBrowserRoot.Create(pidl : PItemIDList);
var
  pmi : TMenuItemIdentified;
begin
  inherited;
  FPopupMenu := TPopupMenuIdentified.Create(nil);

  pmi := TMenuItemIdentified.Create(FPopupMenu);
  pmi.Default := true;
  pmi.Caption := 'Open';
  pmi.Tag := 1;
  FPopupMenu.Items.Add(pmi);

  pmi := TMenuItemIdentified.Create(FPopupMenu);
  pmi.Caption := 'Fuck';
  pmi.Tag := 2;
  FPopupMenu.Items.Add(pmi);
end;

destructor TIContextMenuImplOfflineBrowserRoot.Destroy;
begin
  FPopupMenu.Free;
  inherited;
end;

function TIContextMenuImplOfflineBrowserRoot.GetCommandString(idCmd, uType: Cardinal;
  pwReserved: PUINT; pszName: PAnsiChar; cchMax: Cardinal): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TIContextMenuImplOfflineBrowserRoot.InvokeCommand(
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

function TIContextMenuImplOfflineBrowserRoot.QueryContextMenu(Menu: HMENU; indexMenu,
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


end.
