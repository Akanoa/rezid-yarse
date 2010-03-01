unit ShellFolderView;

interface

uses Windows, ShlObj, ComObj, ActiveX;

const
  SID_IShellFolderViewCB = '{2047E320-F2A9-11CE-AE65-08002B2E1262}';
  IID_IShellFolderViewCB: TGUID = SID_IShellFolderViewCB;
  SID_IPersistFolder3    = '{CEF04FDF-FE72-11D2-87A5-00C04F6837CF}';

type
  {$IFDEF COMPILER_10_UP}
    {$EXTERNALSYM IShellFolderViewCB}
  {$ENDIF}
  IShellFolderViewCB = interface(IUnknown)
  [SID_IShellFolderViewCB]
    function MessageSFVCB(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HRESULT; stdcall;
  end;

  TShellViewCreate = packed record
    dwSize: DWORD;
    pShellFolder: IShellFolder;
    psvOuter: IShellView;
    pfnCallback: IShellFolderViewCB;
  end;

  TSHCreateShellFolderView = function(var psvcbi: TShellViewCreate; out ppv): HRESULT; stdcall;
  // TSHCreateShellFolderViewEx is too buggy to bother with

  PERSIST_FOLDER_TARGET_INFO = record
    pidlTargetFolder : PItemIdList;                           // pidl for the folder we want to intiailize
    szTargetParsingName : array [0..MAX_PATH-1] of WideChar;  // optional parsing name for the target
    szNetworkProvider : array [0..MAX_PATH-1] of WideChar;    // optional network provider
    dwAttributes : DWORD;                                     // optional FILE_ATTRIBUTES_ flags (-1 if not used)
    csidl : integer;                                          // optional folder index (SHGetFolderPath()) -1 if not used
  end;
  TPersistFolderTargetInfo = PERSIST_FOLDER_TARGET_INFO;
  PPersistFolderTargetInfo = ^PERSIST_FOLDER_TARGET_INFO;

  {$EXTERNALSYM IPersistFolder3}
  {$HPPEMIT 'typedef DelphiInterface<IBindCtx> _di_IBindCtx;'}
  IPersistFolder3 = interface(IPersistFolder2)
    [SID_IPersistFolder3]
    function InitializeEx(pbc : IBindCtx; pidlRoot : PItemIdList; const ppfti : TPersistFolderTargetInfo) : HResult; stdcall;
    function GetFolderTargetInfo(var ppfti : TPersistFolderTargetInfo) : HResult; stdcall;
  end;

const
  {$EXTERNALSYM SID_IPersistIDList}
  SID_IPersistIDList = '{1079ACFC-29BD-11D3-8E0D-00C04F6837D5}';
  {$EXTERNALSYM IID_IPersistIDList}
  IID_IPersistIDList: TGUID = SID_IPersistIDList;

type
  {$IFDEF CPPB_6_UP}
    {$EXTERNALSYM IPersistIDList}
  {$ENDIF}
  IPersistIDList = interface(IPersist)
  [SID_IPersistIDList]

    // sets or gets a fully qualifed idlist for an object
    function SetIDList(pidl : PItemIdList) : HResult; stdcall;
    function GetIDList(var pidl : PItemIdList) : HResult; stdcall;
  end;

implementation

uses Dialogs, SysUtils;


end.
