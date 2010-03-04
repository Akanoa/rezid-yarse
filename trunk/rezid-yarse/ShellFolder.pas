unit ShellFolder;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses Windows,ActiveX,CommCtrl,ShellAPI,RegStr,Messages,ComObj,
     ComServ,ShlObj,Classes, Dialogs, SysUtils,
     Graphics, ShellFolderView, ConstsAndVars, ShellFolderD, PIDLs;

const
     CLSID_CustomShellFolder:TGUID='{822B56D4-2343-4C1C-B816-09EB10E6F081}';

type
   TCustomShellFolder=class(TComObject, IShellFolder, IShellFolder2, IPersistFolder, IPersistFolder2, IPersistIDList)
   private
     FShellFolderD : TShellFolderD;
     //This folder really has some sex-aPIDL
     SeInitPIDL : PItemIDList;
   protected
      function IPersistFolder.Initialize=PersistInitialize;
      function IPersistFolder2.Initialize=PersistInitialize;
   public
      {IShellFolder}
      function ParseDisplayName(hwndOwner:HWND;pbcReserved:Pointer;
           lpszDisplayName:POLESTR; out pchEaten:ULONG; out ppidl:PItemIDList;
           var dwAttributes:ULONG):HResult;stdcall;
      function EnumObjects(hwndOwner:HWND;grfFlags:DWORD;
           out EnumIDList:IEnumIDList):HResult;stdcall;
      function BindToObject(pidl:PItemIDList;
           pbcReserved:Pointer;const riid:TIID;out ppvOut):HResult;stdcall;
      function BindToStorage(pidl:PItemIDList;pbcReserved:Pointer;
          const riid:TIID;out ppvObj):HResult;stdcall;
      function CompareIDs(lParam:LPARAM;
          pidl1,pidl2:PItemIDList):HResult;stdcall;
      function CreateViewObject(hwndOwner:HWND;
          const riid:TIID;out ppvOut):HResult;stdcall;
      function GetAttributesOf(cidl:UINT;var apidl:PItemIDList;
          var rgfInOut:UINT):HResult;stdcall;
      function GetUIObjectOf(hwndOwner:HWND;cidl:UINT;var apidl:PItemIDList;
          const riid:TIID;prgfInOut:Pointer;out ppvOut):HResult;stdcall;
      function GetDisplayNameOf(pidl:PItemIDList;uFlags:DWORD;
          var lpName:TStrRet):HResult;stdcall;
      function SetNameOf(hwndOwner:HWND;pidl:PItemIDList;lpszName:POLEStr;
          uFlags:DWORD;var ppidlOut:PItemIDList):HResult;stdcall;
      {Persist}
      function GetClassID(out classID:TCLSID):HResult;stdcall;
      function PersistInitialize(pidl:PItemIDList):HResult;
         virtual;stdcall;

      {IShellFolder2}
      function EnumSearches(out ppEnum: IEnumExtraSearch): HRESULT; stdcall;
      function GetDefaultColumn(dwRes: Cardinal; var pSort: Cardinal;
        var pDisplay: Cardinal): HRESULT; stdcall;
      function GetDefaultColumnState(iColumn: Cardinal;
        var pcsFlags: Cardinal): HRESULT; stdcall;
      function GetDefaultSearchGUID(out pguid: TGUID): HRESULT; stdcall;
      function GetDetailsEx(pidl: PItemIDList; const pscid: SHCOLUMNID;
        pv: POleVariant): HRESULT; stdcall;
      function GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
        var psd: _SHELLDETAILS): HRESULT; stdcall;
      function MapNameToSCID(pwszName: PWideChar; var pscid: SHCOLUMNID): HRESULT;
        stdcall;

      {IPersistFolder2}
      function GetCurFolder(var pidl: PItemIDList): HRESULT; stdcall;

      // IPersistFolder3
      function InitializeEx(pbc : IBindCtx; pidlRoot : PItemIdList; const ppfti : TPersistFolderTargetInfo) : HResult; stdcall;
      function GetFolderTargetInfo(var ppfti : TPersistFolderTargetInfo) : HResult; stdcall;

      {IPersistIDList}
      function GetIDList(var pidl: PItemIDList): HRESULT; stdcall;
      function SetIDList(pidl: PItemIDList): HRESULT; stdcall;

      constructor Create(dShellFolderD : TShellFolderD);
      destructor Destroy; override;
   end;

  TEasyInterfacedObject = class(TObject, IUnknown)
  private
    FReferenceCount: Boolean;
    FOuter: TEasyInterfacedObject;
  protected
    FRefCount: Integer;
  public
    constructor Create(RefCount: Boolean); overload; virtual;
    destructor Destroy; override;

    class function NewInstance: TObject; override;
    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    property Outer: TEasyInterfacedObject read FOuter write FOuter;
    property ReferenceCount: Boolean read FReferenceCount write FReferenceCount;
  end;

  TEnumEmptyIDListImpl = class(TEasyInterfacedObject, IEnumIDList)
  private
  protected
    function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; stdcall;
    function Skip(celt: ULONG): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out ppenum: IEnumIDList): HResult; stdcall;
  end;

  TCustomShellFolderIDataObject = class(TEasyInterfacedObject, IDataObject)
  public
    function DAdvise(const formatetc: tagFORMATETC; advf: Integer;
      const advSink: IAdviseSink; out dwConnection: Integer): HRESULT; stdcall;
    function GetData(const formatetcIn: tagFORMATETC;
      out medium: tagSTGMEDIUM): HRESULT; stdcall;
    function GetDataHere(const formatetc: tagFORMATETC;
      out medium: tagSTGMEDIUM): HRESULT; stdcall;
    function GetCanonicalFormatEtc(const formatetc: tagFORMATETC;
      out formatetcOut: tagFORMATETC): HRESULT; stdcall;
    function SetData(const formatetc: tagFORMATETC; var medium: tagSTGMEDIUM;
      fRelease: LongBool): HRESULT; stdcall;
    function DUnadvise(dwConnection: Integer): HRESULT; stdcall;
    function EnumDAdvise(out enumAdvise: IEnumSTATDATA): HRESULT; stdcall;
    function QueryGetData(const formatetc: tagFORMATETC): HRESULT; stdcall;
    function EnumFormatEtc(dwDirection: Integer;
      out enumFormatEtc: IEnumFORMATETC): HRESULT; stdcall;
  end;

var
  ObjectCount: Integer = 0;
  SHCreateShellFolderView: TSHCreateShellFolderView = nil;


implementation

uses Registry, ShellFolderMainMenu;

type
    TShellFolderObjectFactory=class(TComObjectFactory)
   public
      procedure UpdateRegistry(Register:Boolean);override;
   end;


function TCustomShellFolder.ParseDisplayName(hwndOwner:HWND;pbcReserved:Pointer;
   lpszDisplayName:POLESTR; out pchEaten:ULONG; out ppidl:PItemIDList;
   var dwAttributes:ULONG):HResult;
begin
  ShowMessage('TCustomShellFolder.ParseDisplayName');
     Result:=E_NOTIMPL;
end;

function TCustomShellFolder.EnumObjects(hwndOwner:HWND;grfFlags:DWORD;
      out EnumIDList:IEnumIDList):HResult;
var
  FEnumIDList : IEnumIDList;
begin
//  MessageBox(0, 'TCustomShellFolder.EnumObjects', nil, 0);
  FEnumIDList := FShellFolderD.EnumObjects(grfFlags);
  if Assigned(FEnumIDList) then
    begin
      FEnumIDList.QueryInterface(IID_IEnumIDList, EnumIDList);
      Result := S_OK;
    end
  else
    begin
      Result := E_FAIL;
    end;
end;

function TCustomShellFolder.EnumSearches(out ppEnum: IEnumExtraSearch): HRESULT;
begin
//  ShowMessage('TCustomShellFolder.EnumSearches');
  Result := E_NOTIMPL;
end;

function TCustomShellFolder.BindToObject(pidl:PItemIDList;pbcReserved:Pointer;
      const riid:TIID;out ppvOut):HResult;
var
  pShellFolder : TCustomShellFolder;
  dShellFolderD : TShellFolderD;
  APIDL : PItemIDList;
begin
  OutputDebugString2(PWideChar('TCustomShellFolder.BindToObject - '+GUIDToString(riid)));
  Pointer(ppvOut) := nil;
  Result := E_NOTIMPL;
    if IsEqualGUID(riid, IShellFolder) or IsEqualGUID(riid, IShellFolder2) then
      begin
        dShellFolderD := GetPIDLShellFolderD(GetPointerToLastID(pidl));
//        dShellFolderD := FShellFolderD.GetPIDLShellFolderD(pidl);
        if Assigned(dShellFolderD) then
          begin
            APIDL := AppendPIDL(SeInitPIDL, pidl);
            OutputDebugString2('SeINIT: '+IntToStr(PIDLSize(SeInitPIDL))+' pidl:'+IntToStr(pidlsize(pidl))+' total:'+inttostr(pidlsize(APIDL)));
            OutputDebugString3('BIND IShellFolder!');
            pShellFolder := TCustomShellFolder.Create(dShellFolderD);
            pShellFolder.PersistInitialize(APIDL);
            (pShellFolder as IShellFolder).QueryInterface(riid, ppvOut);
            FreeAndNilPIDL(APIDL);
            Result := S_OK;
          end;
      end
end;

function TCustomShellFolder.BindToStorage(pidl:PItemIDList;
      pbcReserved:Pointer;const riid:TIID;out ppvObj):HResult;
begin
//  ShowMessage('TCustomShellFolder.BindToStorage');
     Result:=E_NOTIMPL;
end;

function TCustomShellFolder.CompareIDs(lParam:LPARAM;
      pidl1,pidl2:PItemIDList):HResult;
begin
//  ShowMessage('TCustomShellFolder.CompareIDs');
  Result := FShellFolderD.CompareIDs(pidl1, pidl2);
end;

{constructor TCustomShellFolder.Create(dShellFolderD : TShellFolderD);
begin
  inherited Create;
  FShellFolderD := dShellFolderD;
end;}

constructor TCustomShellFolder.Create(dShellFolderD : TShellFolderD);
begin
  inherited Create;
  Self.FShellFolderD := dShellFolderD;
  OutputDebugString2('TCustomShellFolder.Create ShellFolderd');
end;

function TCustomShellFolder.CreateViewObject(hwndOwner:HWND;
    const riid:TIID;out ppvOut):HResult;
var
  CreateData: TShellViewCreate;
  LocalView: IShellView;
begin
  Pointer(ppvOut):=nil;
  Result:=E_NOINTERFACE;

  if IsEqualGUID(riid,IShellView) then
    begin
      OutputDebugString2(PWideChar('TCustomShellFolder.CreateViewObject - IShellView'));
      CreateData.dwSize := SizeOf(CreateData);
      CreateData.pfnCallback := nil;
      CreateData.pShellFolder := Self as IShellFolder;
      CreateData.psvOuter := nil;
      Result := SHCreateShellFolderView(CreateData, LocalView);
      IShellView(ppvOut) := LocalView;
      CreateData.pShellFolder._Release;
   end;
end;

destructor TCustomShellFolder.Destroy;
begin
  OutputDebugString2('TCustomShellFolder.Destroy');
  inherited;
end;

function TCustomShellFolder.GetAttributesOf(cidl:UINT;
   var apidl:PItemIDList;var rgfInOut:UINT):HResult;
begin
//  MessageBox( 0, 'TShellFolderImpl.GetAttributesOf', nil, 0 );
  if cidl > 1  then
    begin
      Result := E_NOTIMPL;
      Exit;
    end;

  rgfInOut := rgfInOut and FShellFolderD.GetAttributesOf(apidl);
  Result := S_OK;
end;

function TCustomShellFolder.GetUIObjectOf(hwndOwner:HWND;cidl:UINT;
   var apidl:PItemIDList;const riid:TIID;prgfInOut:Pointer;out ppvOut):HResult;
var
  ExtractIconImplW : IExtractIconW;
  ContextMenuImpl : IContextMenu;
begin
  OutputDebugString2(PWideChar('TCustomShellFolder.GetUIObjectOf - '+GUIDToString(riid)));
  Result := E_NOTIMPL;
  Pointer(ppvOut) := nil;
  if IsEqualGUID( riid, IID_IExtractIconW ) then
    begin
      ExtractIconImplW := FShellFolderD.GetExtractIconImplW(apidl);
      if Assigned(ExtractIconImplW) then
        Result := ExtractIconImplW.QueryInterface(riid, ppvOut);
    end
  else if IsEqualGUID(riid, IID_IContextMenu) then
    begin
      ContextMenuImpl := FShellFolderD.GetIContextMenuImpl(apidl);
      if Assigned(ContextMenuImpl) then
        Result := ContextMenuImpl.QueryInterface(riid, ppvOut);
    end
  else
    begin

    end;
end;

function TCustomShellFolder.InitializeEx(pbc: IBindCtx; pidlRoot: PItemIdList;
  const ppfti: TPersistFolderTargetInfo): HResult;
begin
  Result := Self.PersistInitialize(pidlRoot);
end;

function TCustomShellFolder.GetDefaultColumn(dwRes: Cardinal; var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  Result := FShellFolderD.GetDefaultColumn(pSort, pDisplay);
end;

function TCustomShellFolder.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  Result := FShellFolderD.GetDefaultColumnState(iColumn, pcsFlags);
end;

function TCustomShellFolder.GetDefaultSearchGUID(out pguid: TGUID): HRESULT;
begin
//  ShowMessage('TCustomShellFolder.GetDefaultSearchGUID');
  Result := E_NOTIMPL;
end;

function TCustomShellFolder.GetDetailsEx(pidl: PItemIDList;
  const pscid: SHCOLUMNID; pv: POleVariant): HRESULT;
begin
//  ShowMessage('TCustomShellFolder.GetDetailsEx');
  Result := E_NOTIMPL;
end;

function TCustomShellFolder.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
begin
  Result := FShellFolderD.GetDetailsOf(pidl, iColumn, psd);
end;

function TCustomShellFolder.MapNameToSCID(pwszName: PWideChar;
  var pscid: SHCOLUMNID): HRESULT;
begin
  Result := E_NOTIMPL;
//  ShowMessage('TCustomShellFolder.MapNameToSCID');
//  pscid.fmtid := StringToGUID('{B725F130-47EF-101A-A5F1-02608C9EEBAC}');
//  pscid.pid := 10;
//  Result := E_NOTIMPL;
end;

function TCustomShellFolder.GetDisplayNameOf(pidl:PItemIDList;uFlags:DWORD;
   var lpName:TStrRet):HResult;
var
  sString : string;
begin
//  ShowMessage('TCustomShellFolder.GetDisplayNameOf');
  sString := FShellFolderD.GetDisplayNameOf(pidl, uFlags);
  FillStrRet(lpName, srtOLEStr, WideString(sString), 0);
  Result := S_OK;
end;

function TCustomShellFolder.GetFolderTargetInfo(
  var ppfti: TPersistFolderTargetInfo): HResult;
begin
  Result := E_NOTIMPL
end;

function TCustomShellFolder.GetIDList(var pidl: PItemIDList): HRESULT;
begin
  OutputDebugString2('TCustomShellFolder.GetIDList');
  pidl := CopyPIDL(SeInitPIDL);
  if Assigned(pidl) then
    Result := S_OK
  else
    Result := E_FAIL
end;

function TCustomShellFolder.SetIDList(pidl: PItemIDList): HRESULT;
begin
//  ShowMessage('TCustomShellFolder.SetIDList');
  Result := E_NOTIMPL;
end;

function TCustomShellFolder.SetNameOf(hwndOwner:HWND;pidl:PItemIDList;
   lpszName:POLEStr;uFlags:DWORD;var ppidlOut:PItemIDList):HResult;
begin
     Result:=E_NOTIMPL;
end;

{IPersistFolder}

function TCustomShellFolder.GetClassID(out classID:TCLSID):HResult;
begin
//  ShowMessage('TCustomShellFolder.GetClassID');
     classID:=CLSID_CustomShellFolder;
     Result:=NOERROR;
end;

function TCustomShellFolder.GetCurFolder(var pidl: PItemIDList): HRESULT;
begin
//  ShowMessage('TCustomShellFolder.GetCurFolder');
  pidl :=  CopyPIDL(SeInitPIDL);
  if Assigned(pidl) then
    Result := S_OK
  else
    Result := E_FAIL
end;

function TCustomShellFolder.PersistInitialize(pidl:PItemIDList):HResult;
begin
//  if not Assigned(FShellFolderD) then
  OutputDebugString2('TCustomShellFolder.PersistInitialize, size: '+inttostr(pidlsize(pidl)));
  if not Assigned(FShellFolderD) then
    begin
      OutputDebugString2('    Assigning Main Menu');
      FShellFolderD := GetRootShellFolderD(pidl);
    end;
  SeInitPIDL := CopyPIDL(pidl);
  Result:=S_OK;
end;
{---------------------------------------------}
procedure TShellFolderObjectFactory.UpdateRegistry(Register:boolean);
  function GetShortPath(LongPath: ansiString): ansistring;
  var
    szShortPath,
    szLongPath: array[0..MAX_PATH] of char;
    PLen: Longint;
  begin
    Result := LongPath;                       { Default - return existing string }
    StrPCopy(szLongPath, LongPath);           { Copy Long path in to work area }
    PLen := GetShortPathName(szLongPath, szShortPath, MAX_PATH);
    if not ((PLen = 0) or (Plen > MAX_PATH)) then{ no error }
      Result := StrPas(szShortPath);          { Use shortened path }
  end;
var Reg:TRegistry;
    B:array[0..3] of byte;
    BW : cardinal;
    Temp : string;
begin
     if Register then
     begin
       inherited UpdateRegistry(Register);
       Reg:=nil;
       try
         Reg:=TRegistry.Create;
         Reg.RootKey:=HKEY_CLASSES_ROOT;

         Reg.OpenKey('CLSID\'+GUIDToString(CLSID_CustomShellFolder) ,True);
         Reg.WriteString('', Description);
         Reg.CloseKey;

         Reg.OpenKey('CLSID\'+GUIDToString(CLSID_CustomShellFolder)+
             '\InprocServer32',True);
         Reg.WriteString('ThreadingModel','Apartment');
         Reg.CloseKey;

         Reg.OpenKey('CLSID\'+GUIDToString(CLSID_CustomShellFolder)+
             '\ShellFolder',True);
         Reg.WriteString('','');
         B[0]:=$40;
         B[1]:=$01;
         B[2]:=$00;
         B[3]:=$20;
         BW := SFGAO_FOLDER or SFGAO_HASSUBFOLDER;
         Reg.WriteBinaryData('Attributes',BW,sizeof(BW));
         Reg.CloseKey;

         Reg.OpenKey('CLSID\'+GUIDToString(CLSID_CustomShellFolder)+
             '\DefaultIcon',True);
         Temp := GetShortPath(ComServer.ServerFileName);
         Reg.WriteString('', Temp + ',6');
         Reg.CloseKey;

         Reg.RootKey:=HKEY_LOCAL_MACHINE;
         Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\Namespace\'+GUIDToString(CLSID_CustomShellFolder),True);
         Reg.WriteString('','YARSE');
         Reg.CloseKey;

       finally
         Reg.Free;
       end;
    end
    else
    begin
      Reg:=nil;
      try
       Reg:=TRegistry.Create;
       Reg.Rootkey:=HKEY_LOCAL_MACHINE;
       Reg.DeleteKey('Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\Namespace\'+GUIDToString(CLSID_CustomShellFolder));
       Reg.CloseKey;
     finally
       if Assigned(Reg) then Reg.Free;
  end;
  inherited UpdateRegistry(Register);
 end;
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


{ TEnumEmptyIDListImpl }

function TEnumEmptyIDListImpl.Clone(out ppenum: IEnumIDList): HResult;
begin
//  ShowMessage('TEnumEmptyIDListImpl.Clone');
  Result := E_NOTIMPL;
end;

function TEnumEmptyIDListImpl.Next(celt: ULONG; out rgelt: PItemIDList;
  var pceltFetched: ULONG): HResult;
begin
//  ShowMessage('TEnumEmptyIDListImpl.Next');
  rgelt := nil;
  Result := S_FALSE;
  Exit;
end;

function TEnumEmptyIDListImpl.Reset: HResult;
begin
//  ShowMessage('TEnumEmptyIDListImpl.Reset');
  Result := S_FALSE;
end;

function TEnumEmptyIDListImpl.Skip(celt: ULONG): HResult;
begin
//  ShowMessage('TEnumEmptyIDListImpl.Skip');
  Result := S_FALSE;
end;


{ TIExtractIconImplW }

{ TCustomShellFolderIDataObject }

function TCustomShellFolderIDataObject.DAdvise(const formatetc: tagFORMATETC;
  advf: Integer; const advSink: IAdviseSink;
  out dwConnection: Integer): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.DUnadvise(
  dwConnection: Integer): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.EnumDAdvise(
  out enumAdvise: IEnumSTATDATA): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.EnumFormatEtc(dwDirection: Integer;
  out enumFormatEtc: IEnumFORMATETC): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.GetCanonicalFormatEtc(
  const formatetc: tagFORMATETC; out formatetcOut: tagFORMATETC): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.GetData(const formatetcIn: tagFORMATETC;
  out medium: tagSTGMEDIUM): HRESULT;
begin
  ShowMessage('TCustomShellFolderIDataObject.GetData');
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.GetDataHere(
  const formatetc: tagFORMATETC; out medium: tagSTGMEDIUM): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.QueryGetData(
  const formatetc: tagFORMATETC): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TCustomShellFolderIDataObject.SetData(const formatetc: tagFORMATETC;
  var medium: tagSTGMEDIUM; fRelease: LongBool): HRESULT;
begin
  Result := E_NOTIMPL;
end;

initialization
  TShellFolderObjectFactory.Create(ComServer,TCustomShellFolder,
    CLSID_CustomShellFolder,'','YARSE (Yet Another Rezid Search Engine)',ciSingleInstance, tmFree);

  SHCreateShellFolderView := GetProcAddress(GetModuleHandle(Shell32), PChar(256));

end.
