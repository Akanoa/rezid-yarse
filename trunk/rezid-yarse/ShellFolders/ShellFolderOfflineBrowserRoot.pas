unit ShellFolderOfflineBrowserRoot;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, OfflineBrowsing, Forms, ShellFolderView;

type
  TIExtractIconImplWOfflineBrowserRoot = class(TIExtractIconImplW)
    protected
      CorrespondingHost : TOfflineBrowserHost;
    public
      constructor Create(pidl : PItemIDList); override;
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal;
        out phiconLarge: HICON; out phiconSmall: HICON;
        nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderOfflineBrowserRoot = class(TShellFolderD)
    private
      FPIDLList : TList;
      FPIDLListFoldersOnly : TList;
      ExtractIcon : TIExtractIconImplWOfflineBrowserRoot;
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
      function CompareIDs(pidl1: PItemIDList; pidl2: PItemIDList): Integer; override;
      function GetViewForm : TShellViewForm; override;
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
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolderOfflineBrowserHost, ShellFolderMainMenu, ShellIcons;

{ TShellFolderOfflineBrowserRoot }

function TShellFolderOfflineBrowserRoot.CompareIDs(pidl1,
  pidl2: PItemIDList): Integer;
var
  pidl_struct1, pidl_struct2 : TPIDLStructure;
  temp_result : Integer;
begin
  Result := ComparePIDLs(pidl1, pidl2);
  Exit;
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.CompareIDs');
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

constructor TShellFolderOfflineBrowserRoot.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.Create');
  FPIDLList := TList.Create;
  FPIDLListFoldersOnly := TList.Create;
  ExtractIcon := nil;
end;

destructor TShellFolderOfflineBrowserRoot.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.Destroy');
  FPIDLListFoldersOnly.Free;
  FPIDLList.Free;
  inherited;
end;

function TShellFolderOfflineBrowserRoot.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.EnumObjects');
  RebuildPIDLList;
  if grfFlags and SHCONTF_NONFOLDERS = SHCONTF_NONFOLDERS then
    begin
      Result := TEnumIDListOfflineBrowserRoot.Create(FPIDLList, grfFlags);
    end
  else
      Result := TEnumIDListOfflineBrowserRoot.Create(FPIDLListFoldersOnly, grfFlags);
  Result.Reset;
end;

function TShellFolderOfflineBrowserRoot.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
  aHost : TOfflineBrowserHost;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserRoot.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType <> ITEM_OFFLINE_BROWSER_HOST then
    begin
      Exit;
    end;

  aHost := GetHostByID(OfflineBrowserHostList, aPIDLStructure.ItemInfo1);
  if not Assigned(aHost) then
    begin
      Exit;
    end;

  if aHost.ShareCount > 0 then
    begin
      Result := Result or SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE;
    end
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
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := TIContextMenuImplOfflineBrowserRoot.Create(pidl);
end;

function TShellFolderOfflineBrowserRoot.GetViewForm: TShellViewForm;
begin
  Result := nil;
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
  FPIDLListFoldersOnly.Clear;
  UpdateOfflineBrowsingHostList;
  for aHost in OfflineBrowserHostList do
    begin
      aPidlStructure.ItemType := ITEM_OFFLINE_BROWSER_HOST;
      aPidlStructure.ItemInfo1 := aHost.ID;
      aPidlStructure.ItemInfo2 := 12; //Cette valeur ne sert à rien
      FPIDLList.Add(TPIDLStructure_To_PIDl(aPidlStructure));
      if aHost.ShareCount > 0 then
        FPIDLListFoldersOnly.Add(TPIDLStructure_To_PIDl(aPidlStructure));
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
          phiconLarge := GetRessourceIconHandle('OB_ONLINE_COMPUTER');
          phiconSmall := GetRessourceIconHandle('OB_ONLINE_COMPUTER');
          Result := S_OK;
        end
      else
        begin
          phiconLarge := GetRessourceIconHandle('OB_ONLINE_SUCKER');
          phiconSmall := GetRessourceIconHandle('OB_ONLINE_SUCKER');
          Result := S_OK;
        end;
    end
  else
    begin
      phiconLarge := GetRessourceIconHandle('OB_OFFLINE_COMPUTER');
      phiconSmall := GetRessourceIconHandle('OB_OFFLINE_COMPUTER');
      Result := S_OK;
    end;

end;



{ TIContextMenuImplOfflineBrowserRoot }

//procedure TIContextMenuImplOfflineBrowserRoot.Populate;
//begin
//  inherited;
//
//end;

{ TIContextMenuImplOfflineBrowserRoot }

procedure TIContextMenuImplOfflineBrowserRoot.PopulateItems;
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
