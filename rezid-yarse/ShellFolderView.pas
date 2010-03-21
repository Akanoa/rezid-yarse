unit ShellFolderView;

interface

uses Windows, ShlObj, ComObj, ActiveX, CommCtrl, Forms, Classes;

//
// STANDARD SHELL VIEW
//
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
const
  {$EXTERNALSYM SFVM_DEFVIEWMODE}
  SFVM_DEFVIEWMODE =  27;    // <not used> : FOLDERVIEWMODE*

type
  TShellViewCreate = record
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

//
// CUSTOM SHELL VIEW
//

type
  TShellViewForm = class(TForm)
    protected
      FShellView : IShellView;
      FShellFolder : IShellFolder;
      FShellBrowser: IShellBrowser;
    public
      constructor Create(AOwner: TComponent); override;
      property ShellView : IShellView read FShellView write FShellView;
      property ShellFolder : IShellFolder read FShellFolder write FShellFolder;
      property ShellBrowser : IShellBrowser read FShellBrowser write FShellBrowser;
  end;

  TShellViewImpl = class( TInterfacedObject, IShellView )
  private
    FFolderSettings: TFolderSettings;
    FHWndParent: HWND;
//    FForm: TMainView;

  public
//    qqfdlp : TQuoiQuonFoutDansLesPIDL;
    fForm : TShellViewForm;
    fFolder : IShellFolder;
    FShellBrowser: IShellBrowser;
    constructor Create(ViewForm : TShellViewForm; Folder : IShellFolder);
    destructor Destroy;

    // IOleWindow Methods
    function GetWindow(out wnd: HWnd): HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;

    // IShellView Methods
    function TranslateAccelerator(var Msg: TMsg): HResult; stdcall;
    function EnableModeless(Enable: Boolean): HResult; stdcall;
    function UIActivate(State: UINT): HResult; stdcall;
    function Refresh: HResult; stdcall;
    function CreateViewWindow(PrevView: IShellView;
      var FolderSettings: TFolderSettings; ShellBrowser: IShellBrowser;
      var Rect: TRect; out Wnd: HWND): HResult; stdcall;
    function DestroyViewWindow: HResult; stdcall;
    function GetCurrentInfo(out FolderSettings: TFolderSettings): HResult; stdcall;
    function AddPropertySheetPages(Reseved: DWORD;
      lpfnAddPage: TFNAddPropSheetPage; lParam: LPARAM): HResult; stdcall;
    function SaveViewState: HResult; stdcall;
    function SelectItem(pidl: PItemIDList; flags: UINT): HResult; stdcall;
    function GetItemObject(Item: UINT; const iid: TIID; var IPtr: Pointer): HResult; stdcall;
    property ShellBrowser: IShellBrowser read FShellBrowser;
//    property ViewForm : TMainView read FForm write FForm;
  end;

implementation

uses Dialogs, SysUtils;


(*
**  We can create any objects we need here.
**  Initialise pointers to nil.
*)
constructor TShellViewImpl.Create(ViewForm : TShellViewForm; Folder : IShellFolder);
begin
  inherited Create;
  fForm := ViewForm;
  FShellBrowser := nil;
  fFolder := Folder;
end;

////////////////////////////////////////////////////////////////////////////////
// IOleWindow Implementation

function TShellViewImpl.GetWindow(out wnd: HWnd): HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IOleWindow.GetWindow' ) );
  Wnd := 0;
  Result := NOERROR;
end;

function TShellViewImpl.ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IOleWindow.ContextSensitiveHelp' ) );
  Result := E_NOTIMPL;
end;

////////////////////////////////////////////////////////////////////////////////
// IShellView Implementation

// This function is called by the Shell to give us first crack at translating
// an accelerator key. We don't currently support accelerators, so we just
// return NOERROR. The documentation regarding this is INCORRECT! We must
// return E_NOTIMPL and NOT NOERROR ... otherwise Explorer will hang.

function TShellViewImpl.TranslateAccelerator(var Msg: TMsg): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TShellViewImpl.EnableModeless(Enable: Boolean): HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.EnableModeless' ) );
  Result := E_NOTIMPL;
end;

function TShellViewImpl.UIActivate(State: UINT): HResult; stdcall;
var
  S: String;
begin
  case TSVUIAEnums(State) of
  SVUIA_DEACTIVATE:
    S := 'Deactivate view';
  SVUIA_ACTIVATE_NOFOCUS:
    S := 'Activate view without focus';
  SVUIA_ACTIVATE_FOCUS:
      S := 'Activate view with focus';
  SVUIA_INPLACEACTIVATE:
    S := 'Activate view for inplace-activation within ActiveX control';
  end;
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.UIActivate: ' + S ) );
  Result := NOERROR;
end;

(*
**  This is called whenever Explorer needs to update the right-hand pane (when
**  the user presses F5 for example)
*)
function TShellViewImpl.Refresh: HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.Refresh' ) );
  Result := E_NOTIMPL;
end;

// This function is the third function in the sequence called by Explorer.
// Once our TShellViewImpl object has been created, this function is called
// to create the actual window that contains our view.
//
// Two possible modes of action are possible:
//
// (1) Create a new view window that contains our view when outside of
//     Explorer (just like a folder window being opened via the desktop).
//
// (2) Create a new right hand pane window in Explorer

function TShellViewImpl.CreateViewWindow(PrevView: IShellView;
  var FolderSettings: TFolderSettings; ShellBrowser: IShellBrowser;
  var Rect: TRect; out Wnd: HWND): HResult; stdcall;
begin
  Wnd := 0;
  // Save the folder settings passed
  FFolderSettings := FolderSettings;
  FShellBrowser := ShellBrowser;

  // Get the window handle of Explorer's Parent Window
  FShellBrowser.GetWindow( FHWndParent );

  // Create our Form -  we need to pass these references for the form to use
  //  to notify the shell when our form gets focus - ajs 11Jan99
  try
    if Assigned(fForm) then
      begin
        fForm.ShellBrowser := ShellBrowser;
        Wnd := fForm.Handle;
        SetParent( Wnd, FHWndParent );

        with fForm do
        begin
          SetWindowPos( Handle, HWND_TOP, Rect.Left, Rect.Top,
            Rect.Right - Rect.Left, Rect.Bottom - Rect.Top, SWP_SHOWWINDOW );
          SetWindowLong(Handle, GWL_STYLE, WS_CHILD);//  MUST HAVE CHILD STYLE ONLY.
          Show;
        end;
      end;

    if Wnd <> 0 then
      Result := NOERROR
    else
      Result := E_UNEXPECTED;
  except
    Result := E_UNEXPECTED;
  end;
end;

destructor TShellViewImpl.Destroy;
begin
  if Assigned(fForm) then
    fForm.Free;
end;

function TShellViewImpl.DestroyViewWindow: HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.DestroyViewWindow' ) );
  Result := NOERROR;
end;

function TShellViewImpl.GetCurrentInfo(out FolderSettings: TFolderSettings): HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.GetCurrentInfo' ) );
  Result := E_NOTIMPL;
end;

function TShellViewImpl.AddPropertySheetPages(Reseved: DWORD;
  lpfnAddPage: TFNAddPropSheetPage; lParam: LPARAM): HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.AddPropertySheetPages' ) );
  Result := E_NOTIMPL;
end;

function TShellViewImpl.SaveViewState: HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.SaveViewState' ) );
  Result := E_NOTIMPL;
end;

function TShellViewImpl.SelectItem(pidl: PItemIDList; flags: UINT): HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.SelectItem' ) );
  Result := E_NOTIMPL;
end;

function TShellViewImpl.GetItemObject(Item: UINT; const iid: TIID; var IPtr: Pointer): HResult; stdcall;
begin
//  FShellBrowser.SetStatusTextSB( StringToOleStr( 'IShellView.GetItemObject' ) );
  Result := E_NOTIMPL;
end;


{ TShellViewForm }

constructor TShellViewForm.Create(AOwner: TComponent);
begin
  inherited;
  FShellView := nil;
  FShellFolder := nil;
  FShellBrowser := nil;
end;

end.
