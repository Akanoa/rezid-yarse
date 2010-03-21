unit ShellFolderD;

interface

uses Classes, Windows, PIDLs, ShlObj, Menus, Forms, ShellFolderView, ActiveX;

const
  {$EXTERNALSYM SID_SShellBrowser}
  SID_SShellBrowser = '{000214E2-0000-0000-C000-000000000046}';
  {$EXTERNALSYM IID_SShellBrowser}
  IID_SShellBrowser: TGUID = SID_SShellBrowser;

  MENUITEM_SPECIAL_COMMAND_NONE = 0;
  MENUITEM_SPECIAL_COMMAND_OPEN = 1;
  MENUITEM_SPECIAL_COMMAND_EXPLORE = 2;

type
  TMenuItemIdentified = class(TMenuItem)
    protected
      FIDInMenu : integer;
      FSpecialCommand : Byte;
    public
      constructor Create(AOwner: TComponent); override;
      property IDInMenu : Integer read FIDInMenu write FIDInMenu;
      property SpecialCommand : Byte read FSpecialCommand write FSpecialCommand;
  end;

  TPopupMenuIdentified = class(TPopupMenu)
    public
      function FindItemByIDInMenu(IDInMenu : Integer) : TMenuItemIdentified;
  end;

  TIContextMenuImpl = class(TInterfacedObject, IContextMenu, IObjectWithSite)
   protected
    SelfPIDL : TPIDLStructure;
    Site : IUnknown;
    FPopupMenu : TPopupMenuIdentified;
  public
    constructor Create(pidl : PItemIDList); virtual;
    destructor Destroy; override;
    procedure PopulateItems; virtual; abstract;
    {IContextMenu}
    function GetCommandString(idCmd: Cardinal; uType: Cardinal;
      pwReserved: PUINT; pszName: PAnsiChar; cchMax: Cardinal): HRESULT; stdcall;
    function InvokeCommand(var lpici: _CMINVOKECOMMANDINFO): HRESULT; stdcall;
    function QueryContextMenu(Menu: HMENU; indexMenu: Cardinal;
      idCmdFirst: Cardinal; idCmdLast: Cardinal; uFlags: Cardinal): HRESULT; stdcall;
    {IObjectWithSite}
    function GetSite(const riid: TGUID; out site: IInterface): HRESULT; stdcall;
    function SetSite(const pUnkSite: IInterface): HRESULT; stdcall;
  end;

  TEasyInterfacedObject = class(TObject, IUnknown)
  private
    FReferenceCount: Boolean;
    FOuter: TEasyInterfacedObject;
  protected
    FRefCount: Integer;
    class var ObjectCount: Integer;
  public
    constructor Create(RefCount: Boolean); virtual;
    destructor Destroy; override;

    class function NewInstance: TObject; override;
    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    property Outer: TEasyInterfacedObject read FOuter write FOuter;
    property ReferenceCount: Boolean read FReferenceCount write FReferenceCount;
  end;

  TShellFolderD = class
    protected
      SelfPIDL : TPIDLStructure;
    public
      constructor Create(PIDL : TPIDLStructure); virtual;
      function EnumObjects(grfFlags:DWORD) : IEnumIDList; virtual; stdcall; abstract;
      function GetDisplayNameOf(pidl:PItemIDList;uFlags:DWORD) : string; virtual; abstract;
      function GetExtractIconImplW(pidl:PItemIDList) : IExtractIconW; virtual; abstract;
      function GetIContextMenuImpl(pidl:PItemIDList) : TIContextMenuImpl; virtual; abstract;
      function GetAttributesOf(apidl:PItemIDList) : UINT; virtual; abstract;
      function GetDefaultColumn(var pSort: Cardinal; var pDisplay: Cardinal): HRESULT; virtual; stdcall; abstract;
      function GetDefaultColumnState(iColumn: Cardinal; var pcsFlags: Cardinal): HRESULT; virtual; stdcall; abstract;
      function GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal; var psd: _SHELLDETAILS): HRESULT; virtual; stdcall; abstract;
      function CompareIDs(pidl1, pidl2:PItemIDList) : integer; virtual; abstract;
      function GetViewForm : TShellViewForm; virtual; abstract;
//      procedure PopulateMenu(Menu : TIContextMenuImpl); virtual; abstract;
    protected
  end;

  TEnumIDListD = class(TEasyInterfacedObject, IEnumIDList)
    protected
      grfFlags: DWORD;
      FPIDLList : TList;
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; virtual; stdcall; abstract;
      function Skip(celt: ULONG): HResult; virtual; stdcall; abstract;
      function Reset: HResult; virtual; stdcall; abstract;
      function Clone(out ppenum: IEnumIDList): HResult; virtual; stdcall; abstract;
    public
      property PIDLList : TList read FPIDLList write FPIDLList;
      constructor Create(kPIDLList : TList; grfFlags: DWORD); overload; virtual;
  end;

  TIExtractIconImplW = class (TObject, IExtractIconW)
   protected
    SelfPIDL : TPIDLStructure;
   public
    constructor Create(pidl : PItemIDList); virtual;
    procedure SetPidl(pidl : PItemIDList);
    function GetIconLocation(uFlags: UINT; szIconFile: PWideChar; cchMax: UINT;
      out piIndex: Integer; out pwFlags: UINT): HResult; stdcall;
    function Extract(pszFile: PWideChar; nIconIndex: UINT;
      out phiconLarge, phiconSmall: HICON; nIconSize: UINT): HResult; virtual; stdcall; abstract;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

function GetPIDLShellFolderD(pidl : PITEMIDLIST) : TShellFolderD;
function GetRootShellFolderD(pidl : PITEMIDLIST) : TShellFolderD;

implementation

uses ConstsAndVars, SysUtils,
     ShellFolderMainMenu, ShellFolderOfflineBrowserRoot,
     ShellFolderOfflineBrowserHost, ShellFolderOfflineBrowserFolder,
     ShellFolderNewSearch, ShellFolderSearchResults,
     ShellFolderSearchResultsHostsRoot, ShellFolderSearchResultsHostsHost,
     ShellFolderSearchResultsHostsFolder, ShellFolderSearchResultsTypesRoot,
     ShellFolderSearchResultsTypesType;

function GetPIDLShellFolderD(pidl : PITEMIDLIST) : TShellFolderD;
var
  pidl_structure : TPIDLStructure;
begin
  Result := nil;
  pidl_structure := PIDL_To_TPIDLStructure(pidl);
  case pidl_structure.ItemType of
    ITEM_MAIN_MENU :
      begin
        case pidl_structure.ItemInfo1 of
          ITEM_MAIN_MENU_OFFLINE_BROWSER :
            Result := TShellFolderOfflineBrowserRoot.Create(pidl_structure);
          ITEM_MAIN_MENU_NEW_SEARCH:
            Result := TShellFolderNewSearch.Create(pidl_structure);
          ITEM_MAIN_MENU_SEARCH:
            Result := TShellFolderSearchResultsAll.Create(pidl_structure);
        end;
      end;
    ITEM_OFFLINE_BROWSER_HOST :
      Result := TShellFolderOfflineBrowserHost.Create(pidl_structure);
    ITEM_OFFLINE_BROWSER_SHARE,
    ITEM_OFFLINE_BROWSER_FOLDER :
      Result := TShellFolderOfflineBrowserFolder.Create(pidl_structure);
    ITEM_SEARCH_SORT_HOSTS:
      Result := TShellFolderSearchResultsHostsRoot.Create(pidl_structure);
    ITEM_SEARCH_SORT_HOSTS_HOST:
      Result := TShellFolderSearchResultsHostsHost.Create(pidl_structure);
    ITEM_SEARCH_SORT_HOSTS_FOLDER:
      Result := TShellFolderSearchResultsHostsFolder.Create(pidl_structure);
    ITEM_SEARCH_SORT_TYPES:
      Result := TShellFolderSearchTypesRoot.Create(pidl_structure);
    ITEM_SEARCH_SORT_TYPES_TYPE:
      Result := TShellFolderSearchResultsTypesType.Create(pidl_structure);
  end;
end;

function GetRootShellFolderD(pidl : PITEMIDLIST) : TShellFolderD;
var
  pidl_structure : TPIDLStructure;
begin
  pidl_structure := PIDL_To_TPIDLStructure(pidl);
  Result := TShellFolderMainMenu.Create(pidl_structure);
end;

function TEasyInterfacedObject._AddRef: Integer;
begin
  if ReferenceCount then
  begin
    if Assigned(Outer) then
      Result := Outer._AddRef
    else
      Result := InterlockedIncrement(FRefCount)
  end else
    Result := -1;
end;

function TEasyInterfacedObject._Release: Integer;
begin
  if ReferenceCount then
  begin
    if Assigned(Outer) then
      Result := Outer._Release
    else begin
      Result := InterlockedDecrement(FRefCount);
      if Result <= 0 then
        Destroy;
    end
  end else
    Result := -1;
end;

constructor TEasyInterfacedObject.Create(RefCount: Boolean);
begin
  inherited Create;
  FReferenceCount := RefCount;
end;

function TEasyInterfacedObject.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

class function TEasyInterfacedObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  InterlockedIncrement(ObjectCount);
end;

destructor TEasyInterfacedObject.Destroy;
begin
  InterlockedDecrement(ObjectCount);
  inherited;
end;

{ TShellFolderD }

constructor TShellFolderD.Create(PIDL: TPIDLStructure);
begin
  SelfPIDL := PIDL;
end;


{ TEnumIDListD }

constructor TEnumIDListD.Create(kPIDLList : TList; grfFlags: DWORD);
begin
  inherited Create(grfFlags <> 0);
  Self.PIDLList := kPIDLList;
  Self.grfFlags := grfFlags;
end;

constructor TIExtractIconImplW.Create(pidl : PItemIDList);
begin
  inherited Create;
  SelfPIDL := PIDL_To_TPIDLStructure(pidl);
end;

function TIExtractIconImplW.GetIconLocation(uFlags: UINT; szIconFile: PWideChar; cchMax: UINT;
  out piIndex: Integer; out pwFlags: UINT): HResult; stdcall;
begin
  piIndex := 0;
  pwFlags := pwFlags or GIL_PERINSTANCE or GIL_DONTCACHE;
  Result := S_OK;
end;

function TIExtractIconImplW.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

procedure TIExtractIconImplW.SetPidl(pidl: PItemIDList);
begin
  SelfPIDL := PIDL_To_TPIDLStructure(pidl);
end;

function TIExtractIconImplW._AddRef: Integer;
begin
  Result := -1;
end;

function TIExtractIconImplW._Release: Integer;
begin
  Result := -1;
end;

{ TIContextMenuImpl }

constructor TIContextMenuImpl.Create(pidl: PItemIDList);
begin
  SelfPIDL := PIDL_To_TPIDLStructure(pidl);
  FPopupMenu := TPopupMenuIdentified.Create(nil);
  Site := nil;
end;

destructor TIContextMenuImpl.Destroy;
begin
  FPopupMenu.Free;
  inherited;
end;

function TIContextMenuImpl.GetCommandString(idCmd, uType: Cardinal;
  pwReserved: PUINT; pszName: PAnsiChar; cchMax: Cardinal): HRESULT;
begin
//  OutputDebugString3('TIContextMenuImpl.GetCommandString');
  Result := E_NOTIMPL;
end;

function TIContextMenuImpl.GetSite(const riid: TGUID;
  out site: IInterface): HRESULT;
begin
  Site := nil;
  Result := E_NOTIMPL;
  if Assigned(site) then
    Result := site.QueryInterface(riid, site);
end;

function TIContextMenuImpl.InvokeCommand(
  var lpici: _CMINVOKECOMMANDINFO): HRESULT;
var
  amii : TMenuItemIdentified;
  ShellBrowser : IShellBrowser;
  ServiceProvider : IServiceProvider;
begin
//  OutputDebugString3('TIContextMenuImpl.InvokeCommand');
  if HiWord(Integer(lpici.lpVerb)) <> 0 then
  begin
    Result := E_FAIL;
    Exit;
  end;
//  OutputDebugString3('Quering number '+inttostr(LoWord(lpici.lpVerb)));
  amii := FPopupMenu.FindItemByIDInMenu(LoWord(lpici.lpVerb));
  if Assigned(amii) then
    begin
      case amii.FSpecialCommand of
        MENUITEM_SPECIAL_COMMAND_NONE:
          begin
            if Assigned(amii.OnClick) then
              amii.OnClick(amii);
          end;
        MENUITEM_SPECIAL_COMMAND_OPEN:
          begin
            ServiceProvider := nil;
            Site.QueryInterface(IServiceProvider, ServiceProvider);
            if Assigned(ServiceProvider) then
              begin
                ShellBrowser := nil;
                ServiceProvider.QueryService(IID_SShellBrowser, IShellBrowser, ShellBrowser);
                if Assigned(ShellBrowser) then
                  begin
                    ShellBrowser.BrowseObject(TPIDLStructure_To_PIDl(Self.SelfPIDL), SBSP_RELATIVE);
                  end;
              end;
          end;
        MENUITEM_SPECIAL_COMMAND_EXPLORE:
          begin

          end;
      end;
    end;
  Result := S_OK;
end;

function TIContextMenuImpl.QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst,
  idCmdLast, uFlags: Cardinal): HRESULT;
var
  aMenuItem : TMenuItem;
  count : word;
  MenuItemInfo : tagMENUITEMINFO;
begin
  //OutputDebugString3('TIContextMenuImpl.QueryContextMenu');
  count := 0;
  for aMenuItem in FPopupMenu.Items do
  begin
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
    TMenuItemIdentified(aMenuItem).IDInMenu := count;
    Inc(count);
  end;
  Result := count;
end;

function TIContextMenuImpl.SetSite(const pUnkSite: IInterface): HRESULT;
begin
  //OutputDebugString3('TIContextMenuImpl.SetSite');
  Site := pUnkSite;
  Result := S_OK;
end;

{ TPopupMenuIdentified }

function TPopupMenuIdentified.FindItemByIDInMenu(
  IDInMenu: Integer): TMenuItemIdentified;
var
  amii : TMenuItem;
begin
  Result := nil;
  for amii in Items do
    begin
      if not (amii is TMenuItemIdentified) then
        Continue;
      if TMenuItemIdentified(amii).IDInMenu = IDInMenu then
        begin
          Result := TMenuItemIdentified(amii);
          Exit;
        end;
    end;
end;

{ TMenuItemIdentified }

constructor TMenuItemIdentified.Create(AOwner: TComponent);
begin
  inherited;
  SpecialCommand := MENUITEM_SPECIAL_COMMAND_NONE;
end;

end.
