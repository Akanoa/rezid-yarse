unit ShellFolderOfflineBrowserHost;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, OfflineBrowsing;

type
  TIExtractIconImplWOfflineBrowserHost = class(TIExtractIconImplW)
    protected
    public
      constructor Create(pidl : PItemIDList); override;
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal;
        out phiconLarge: HICON; out phiconSmall: HICON;
        nIconSize: Cardinal): HRESULT; override; stdcall;
      function GetFromRessource(RessourceName : string) : TIcon;
  end;

  TShellFolderOfflineBrowserHost = class(TShellFolderD)
    private
      FHost : TOfflineBrowserHost;
      FPIDLList : TList;
      ExtractIcon : TIExtractIconImplWOfflineBrowserHost;
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
      function CompareIDs(pidl1: PItemIDList; pidl2: PItemIDList): Integer; override;
      {Bonus}
      destructor Destroy; override;
      constructor Create(PIDL: TPIDLStructure); override;
  end;

  TEnumIDListOfflineBrowserHost = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplOfflineBrowserHost = class(TIContextMenuImpl)
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

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolder;

{ TShellFolderOfflineBrowserHost }

function TShellFolderOfflineBrowserHost.CompareIDs(pidl1,
  pidl2: PItemIDList): Integer;
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

constructor TShellFolderOfflineBrowserHost.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.Create');
  FPIDLList := TList.Create;
  FHost := GetHostByID(OfflineBrowserHostList, PIDL.ItemInfo1);
  if not Assigned(FHost) then
    begin
      FHost := TOfflineBrowserHost.CreateEmpty;
    end;
  ExtractIcon := nil;
end;

destructor TShellFolderOfflineBrowserHost.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.Destroy');
  FPIDLList.Free;
  inherited;
end;

function TShellFolderOfflineBrowserHost.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.EnumObjects');
  RebuildPIDLList;
  Result := TEnumIDListOfflineBrowserHost.Create(FPIDLList, grfFlags);
  Result.Reset;
end;

function TShellFolderOfflineBrowserHost.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType <> ITEM_OFFLINE_BROWSER_SHARE then
    begin
      Exit;
    end;
end;

function TShellFolderOfflineBrowserHost.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderOfflineBrowserHost.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderOfflineBrowserHost.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aShare : TOfflineBrowserShare;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.GetDetailsOf');
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
      if aPIDLStructure.ItemType = ITEM_OFFLINE_BROWSER_SHARE then
        begin
          aShare := Self.FHost.Shares.GetByID(aPIDLStructure.ItemInfo1);
          if Assigned(aShare) then
            begin
              case iColumn of
                0: sString := aShare.Name;
                1: sString := aShare.Comment;
              end;
            end;
        end;
    end
  else
    begin
      case iColumn of
        0: sString := 'Nom';
        1: sString := 'Commentaire';
      end;
    end;

  FillStrRet(psd.str, srtOLEStr, WideString(sString), 0);
  psd.cxChar := 15;
  //  psd.str
  Result := S_OK;
end;

function TShellFolderOfflineBrowserHost.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aShare : TOfflineBrowserShare;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.GetDisplayNameOf');
  Result := 'Partage inconnu';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType <> ITEM_OFFLINE_BROWSER_SHARE then
    begin
      Exit;
    end;

  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.GetDisplayNameOf Share: '+inttostr(aPIDLStructure.ItemInfo1));
  aShare := Self.FHost.Shares.GetByID(aPIDLStructure.ItemInfo1);
  if Assigned(aShare) then
    Result := aShare.Name;
end;

function TShellFolderOfflineBrowserHost.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWOfflineBrowserHost.Create(pidl);
  ExtractIcon := TIExtractIconImplWOfflineBrowserHost(Result);
end;

function TShellFolderOfflineBrowserHost.GetIContextMenuImpl(
  pidl: PItemIDList): IContextMenu;
begin
  Result := nil;
//  Result := TIContextMenuImplOfflineBrowserHost.Create(pidl);
end;

function TEnumIDListOfflineBrowserHost.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListOfflineBrowserHost.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListOfflineBrowserHost.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListOfflineBrowserHost.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderOfflineBrowserHost.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  aShare : TOfflineBrowserShare;
  i : word;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserHost.RebuildPIDLList');
  FPIDLList.Clear;
  GetHostShares(FHost);
  OutputDebugStringFoldersD('   Got '+inttostr(Self.FHost.Shares.Count)+' shares');
  if Self.FHost.Shares.Count > 0 then
    begin
      for i := 0 to Self.FHost.Shares.Count - 1 do
        begin
          aShare := Self.FHost.Shares.Item(i);
          OutputDebugStringFoldersD('   Share '+inttostr(aShare.ID)+': '+aShare.Name);
          aPidlStructure.ItemType := ITEM_OFFLINE_BROWSER_SHARE;
          aPidlStructure.ItemInfo1 := aShare.ID;
          aPidlStructure.ItemInfo2 := 12; //Cette valeur ne sert à rien

          FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));
        end;
    end;

end;

{ TIExtractIconImplWOfflineBrowserHost }

constructor TIExtractIconImplWOfflineBrowserHost.Create(pidl: PItemIDList);
var
  aPIDLStructure : TPIDLStructure;
begin
  inherited;
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  if aPIDLStructure.ItemType = ITEM_OFFLINE_BROWSER_SHARE then
    begin

    end;
end;

function TIExtractIconImplWOfflineBrowserHost.Extract(pszFile: PWideChar;
  nIconIndex: Cardinal; out phiconLarge, phiconSmall: HICON;
  nIconSize: Cardinal): HRESULT;
var
  IconObject : TIcon;
begin
  Result := S_FALSE;
  IconObject := nil;

  IconObject := Self.GetFromRessource('OB_SHARE');

  if Assigned(IconObject) then
    begin
      phiconLarge := IconObject.Handle;
      phiconSmall := IconObject.Handle;
      Result := S_OK;
    end;
end;

function TIExtractIconImplWOfflineBrowserHost.GetFromRessource(
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

{ TIContextMenuImplOfflineBrowserHost }

constructor TIContextMenuImplOfflineBrowserHost.Create(pidl : PItemIDList);
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

destructor TIContextMenuImplOfflineBrowserHost.Destroy;
begin
  FPopupMenu.Free;
  inherited;
end;

function TIContextMenuImplOfflineBrowserHost.GetCommandString(idCmd, uType: Cardinal;
  pwReserved: PUINT; pszName: PAnsiChar; cchMax: Cardinal): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TIContextMenuImplOfflineBrowserHost.InvokeCommand(
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

function TIContextMenuImplOfflineBrowserHost.QueryContextMenu(Menu: HMENU; indexMenu,
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
