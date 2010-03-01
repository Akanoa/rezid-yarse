unit ShellFolderD;

interface

uses Classes, Windows, PIDLs, ShlObj, Menus;

type
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
    private
      SelfPIDL : TPIDLStructure;
    public
      constructor Create(PIDL : TPIDLStructure); virtual;
      function EnumObjects(grfFlags:DWORD) : IEnumIDList; virtual; stdcall; abstract;
      function GetDisplayNameOf(pidl:PItemIDList;uFlags:DWORD) : string; virtual; abstract;
      function GetExtractIconImplW(pidl:PItemIDList) : IExtractIconW; virtual; abstract;
      function GetIContextMenuImpl(pidl:PItemIDList) : IContextMenu; virtual; abstract;
      function GetAttributesOf(apidl:PItemIDList) : UINT; virtual; abstract;
      function GetDefaultColumn(var pSort: Cardinal; var pDisplay: Cardinal): HRESULT; virtual; stdcall; abstract;
      function GetDefaultColumnState(iColumn: Cardinal; var pcsFlags: Cardinal): HRESULT; virtual; stdcall; abstract;
      function GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal; var psd: _SHELLDETAILS): HRESULT; virtual; stdcall; abstract;
      function GetPIDLShellFolderD(pidl:PItemIDList):TShellFolderD; virtual; abstract;
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

  TMenuItemIdentified = class(TMenuItem)
    protected
      FIDInMenu : integer;
    public
      property IDInMenu : Integer read FIDInMenu write FIDInMenu;
  end;

  TPopupMenuIdentified = class(TPopupMenu)
    public
      function FindItemByIDInMenu(IDInMenu : Integer) : TMenuItemIdentified;
  end;

  TIContextMenuImpl = class(TInterfacedObject, IContextMenu)
   protected
    SelfPIDL : TPIDLStructure;
  public
    constructor Create(pidl : PItemIDList); virtual;
    function GetCommandString(idCmd: Cardinal; uType: Cardinal;
      pwReserved: PUINT; pszName: PAnsiChar; cchMax: Cardinal): HRESULT;
      virtual; stdcall; abstract;
    function InvokeCommand(var lpici: _CMINVOKECOMMANDINFO): HRESULT; virtual; stdcall; abstract;
    function QueryContextMenu(Menu: HMENU; indexMenu: Cardinal;
      idCmdFirst: Cardinal; idCmdLast: Cardinal; uFlags: Cardinal): HRESULT;
      virtual; stdcall; abstract;
  end;

implementation

uses ConstsAndVars, SysUtils;

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

end.
