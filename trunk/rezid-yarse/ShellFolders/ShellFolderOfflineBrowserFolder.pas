unit ShellFolderOfflineBrowserFolder;

interface

uses Classes, ShellFolderD, PIDLs, ShlObj, Windows, Graphics, Menus, OfflineBrowsing, Forms, ShellFolderView;

type
  TIExtractIconImplWOfflineBrowserFolder = class(TIExtractIconImplW)
    protected
      FFolder : TOfflineBrowserFolder;
    public
      constructor Create(pidl : PItemIDList; Folder : TOfflineBrowserFolder);
      function Extract(pszFile: PWideChar; nIconIndex: Cardinal; out phiconLarge: HICON; out phiconSmall: HICON; nIconSize: Cardinal): HRESULT; override; stdcall;
  end;

  TShellFolderOfflineBrowserFolder = class(TShellFolderD)
    private
      FFolder : TOfflineBrowserFolder;
      FPIDLListAll : TList;
      FPIDLListFolders : TList;
      ExtractIcon : TIExtractIconImplWOfflineBrowserFolder;
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

  TEnumIDListOfflineBrowserFolder = class(TEnumIDListD)
    private
      FIndex: integer;
    protected
      function Next(celt: ULONG; out rgelt: PItemIDList; var pceltFetched: ULONG): HResult; override; stdcall;
      function Skip(celt: ULONG): HResult; override; stdcall;
      function Reset: HResult; override; stdcall;
      function Clone(out ppenum: IEnumIDList): HResult; override; stdcall;
  end;

  TIContextMenuImplOfflineBrowserFolder = class(TIContextMenuImpl)
  public
    procedure PopulateItems; override;
  end;

implementation

uses ConstsAndVars, Dialogs, Sysutils, CommCtrl, ShellFolder, ShellIcons, ShellAPI;

{ TShellFolderOfflineBrowserFolder }

function TShellFolderOfflineBrowserFolder.CompareIDs(pidl1,
  pidl2: PItemIDList): Integer;
var
  pidl_struct1, pidl_struct2 : TPIDLStructure;
  temp_result : Integer;
begin
  pidl_struct1 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl1));
  pidl_struct2 := PIDL_To_TPIDLStructure(GetPointerToLastID(pidl2));
  temp_result := pidl_struct1.ItemInfo1 - pidl_struct2.ItemInfo1;
  Result := 0;

  if temp_result = 0 then
    Result := 0
  else if temp_result < 0 then
    Result := -1
  else if temp_result > 0 then
    Result := 1;
end;

constructor TShellFolderOfflineBrowserFolder.Create(PIDL: TPIDLStructure);
begin
  inherited;
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.Create');
  FPIDLListAll := TList.Create;
  FPIDLListFolders := TList.Create;
  FFolder := FindFolderInIndex(PIDL.ItemInfo1);
  if not Assigned(FFolder) then
    begin
      FFolder := TOfflineBrowserFolder.Create;
    end;
  ExtractIcon := nil;
end;

destructor TShellFolderOfflineBrowserFolder.Destroy;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.Destroy');
  FPIDLListFolders.Free;
  FPIDLListAll.Free;
  inherited;
end;

function TShellFolderOfflineBrowserFolder.EnumObjects(grfFlags: DWORD): IEnumIDList;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.EnumObjects');
  RebuildPIDLList;
  if grfFlags and SHCONTF_NONFOLDERS = SHCONTF_NONFOLDERS then
    Result := TEnumIDListOfflineBrowserFolder.Create(FPIDLListAll, grfFlags)
  else
    Result := TEnumIDListOfflineBrowserFolder.Create(FPIDLListFolders, grfFlags);
  Result.Reset;
end;

function TShellFolderOfflineBrowserFolder.GetAttributesOf(apidl: PItemIDList): UINT;
var
  aPIDLStructure : TPIDLStructure;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.GetAttributesOf');
  Result := SFGAO_READONLY;
  aPIDLStructure := PIDL_To_TPIDLStructure(apidl);
  if aPIDLStructure.ItemType = ITEM_OFFLINE_BROWSER_FOLDER then
    Result := Result or (SFGAO_FOLDER or SFGAO_HASSUBFOLDER or SFGAO_BROWSABLE);
end;

function TShellFolderOfflineBrowserFolder.GetDefaultColumn(var pSort,
  pDisplay: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.GetDefaultColumn');
  pSort := 0;
  pDisplay := 0;
  Result := S_OK;
end;

function TShellFolderOfflineBrowserFolder.GetDefaultColumnState(iColumn: Cardinal;
  var pcsFlags: Cardinal): HRESULT;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.GetDefaultColumnState');
  pcsFlags := SHCOLSTATE_TYPE_STR or SHCOLSTATE_ONBYDEFAULT;
  Result := S_OK;
end;

function TShellFolderOfflineBrowserFolder.GetDetailsOf(pidl: PItemIDList; iColumn: Cardinal;
  var psd: _SHELLDETAILS): HRESULT;
var
  sString : string;
  aPIDLStructure : TPIDLStructure;
  aFolder : TOfflineBrowserFolder;
  aFile : TOfflineBrowserFile;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.GetDetailsOf');
  if iColumn > 3 then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;
  psd.fmt := LVCFMT_LEFT;
  sString := 'Saucisse';
  if Assigned(pidl)then
    begin
      aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
      case aPIDLStructure.ItemType of
        ITEM_OFFLINE_BROWSER_FOLDER:
          begin
            aFolder := Self.FFolder.FindSubFolderById(aPIDLStructure.ItemInfo1);
            if Assigned(aFolder) then
              begin
                case iColumn of
                  0: sString := aFolder.Name;
                  1: sString := 'Dossier';
                  2: sString := FormatFileSize(aFolder.Size, 2);
                  3: sString := aFolder.Path;
                end;
              end;
          end;
        ITEM_OFFLINE_BROWSER_FILE:
          begin
            aFile := Self.FFolder.FindFileById(aPIDLStructure.ItemInfo1);
            if Assigned(aFile) then
              begin
                case iColumn of
                  0: sString := aFile.Name;
                  1: sString := GetExtensionTypeName(ExtractFileExt(aFile.Name));
                  2: sString := FormatFileSize(aFile.Size, 2);
                  3: sString := aFile.Path;
                end;
              end;
          end;
      end;

    end
  else
    begin
      case iColumn of
        0: sString := 'Nom';
        1: sString := 'Type';
        2: sString := 'Taille';
        3: sString := 'Chemin';
      end;
    end;

  FillStrRet(psd.str, srtOLEStr, WideString(sString), 0);
  psd.cxChar := 50;
  //  psd.str
  Result := S_OK;
end;

function TShellFolderOfflineBrowserFolder.GetDisplayNameOf(pidl: PItemIDList;
  uFlags: DWORD): string;
var
  aPIDLStructure : TPIDLStructure;
  aFolder : TOfflineBrowserFolder;
  aFile : TOfflineBrowserFile;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.GetDisplayNameOf');
  Result := 'Fichier ou dossier inconnu';
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);

  case aPIDLStructure.ItemType of
    ITEM_OFFLINE_BROWSER_FOLDER:
      begin
        aFolder := Self.FFolder.FindSubFolderById(aPIDLStructure.ItemInfo1);
        if Assigned(aFolder) then
          begin
            Result := aFolder.Name;
          end;
      end;
    ITEM_OFFLINE_BROWSER_FILE:
      begin
        aFile := Self.FFolder.FindFileById(aPIDLStructure.ItemInfo1);
        if Assigned(aFile) then
          begin
            Result := aFile.Name;
          end;
      end;
  end;
end;

function TShellFolderOfflineBrowserFolder.GetExtractIconImplW(pidl:PItemIDList): IExtractIconW;
begin
  Result := TIExtractIconImplWOfflineBrowserFolder.Create(pidl, FFolder);
  ExtractIcon := TIExtractIconImplWOfflineBrowserFolder(Result);
end;

function TShellFolderOfflineBrowserFolder.GetIContextMenuImpl(
  pidl: PItemIDList): TIContextMenuImpl;
begin
  Result := TIContextMenuImplOfflineBrowserFolder.Create(pidl);
end;

function TShellFolderOfflineBrowserFolder.GetViewForm: TShellViewForm;
begin
  Result := nil;
end;

function TEnumIDListOfflineBrowserFolder.Clone(out ppenum: IEnumIDList): HResult;
begin
  Result := E_NOTIMPL;
end;

function TEnumIDListOfflineBrowserFolder.Next(celt: ULONG; out rgelt: PItemIDList;
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

function TEnumIDListOfflineBrowserFolder.Reset: HResult;
begin
  FIndex := 0;
  Result := S_OK;
end;

function TEnumIDListOfflineBrowserFolder.Skip(celt: ULONG): HResult;
begin
  Inc(FIndex, celt);
  Result := S_OK
end;

procedure TShellFolderOfflineBrowserFolder.RebuildPIDLList;
var
  aPidlStructure : TPIDLStructure;
  aFolder : TOfflineBrowserFolder;
  aFile : TOfflineBrowserFile;
  i : word;
begin
  OutputDebugStringFoldersD('TShellFolderOfflineBrowserFolder.RebuildPIDLList');
  FPIDLListAll.Clear;
  FPIDLListFolders.Clear;
  FetchOfflineBrowserFolderContent(FFolder);
  OutputDebugStringFoldersD('    Folders: '+inttostr(Length(Self.FFolder.SubFolders)));
  if Length(Self.FFolder.SubFolders) > 0 then
    begin
      for i := 0 to Length(Self.FFolder.SubFolders) - 1 do
        begin
          aFolder := Self.FFolder.SubFolders[i];
          aPidlStructure.ItemType := ITEM_OFFLINE_BROWSER_FOLDER;
          aPidlStructure.ItemInfo1 := aFolder.ID;

          FPIDLListAll.Add(TPIDLStructure_To_PIDl(aPidlStructure));
          FPIDLListFolders.Add(TPIDLStructure_To_PIDl(aPidlStructure));
        end;
    end;
  OutputDebugStringFoldersD('    Files: '+inttostr(Length(Self.FFolder.Files)));
  if Length(Self.FFolder.Files) > 0 then
    begin
      for i := 0 to Length(Self.FFolder.Files) - 1 do
        begin
          aFile := Self.FFolder.Files[i];
          aPidlStructure.ItemType := ITEM_OFFLINE_BROWSER_FILE;
          aPidlStructure.ItemInfo1 := aFile.ID;

          FPIDLListAll.Add(TPIDLStructure_To_PIDl(aPidlStructure));
        end;
    end;

end;

{ TIExtractIconImplWOfflineBrowserFolder }

constructor TIExtractIconImplWOfflineBrowserFolder.Create(pidl : PItemIDList; Folder : TOfflineBrowserFolder);
var
  aPIDLStructure : TPIDLStructure;
begin
  inherited Create(pidl);
  aPIDLStructure := PIDL_To_TPIDLStructure(pidl);
  FFolder := Folder;
end;

function TIExtractIconImplWOfflineBrowserFolder.Extract(pszFile: PWideChar;
  nIconIndex: Cardinal; out phiconLarge, phiconSmall: HICON;
  nIconSize: Cardinal): HRESULT;
var
  aPIDLStructure : TPIDLStructure;
  aFile : TOfflineBrowserFile;
  Ext : string;
begin
  aPIDLStructure := SelfPIDL;
  case aPIDLStructure.ItemType of
    ITEM_OFFLINE_BROWSER_FOLDER:
      begin
        phiconLarge := GetDirectoryIconHandle(SHGFI_LARGEICON);
        phiconSmall := GetDirectoryIconHandle(SHGFI_SMALLICON);
      end;
    ITEM_OFFLINE_BROWSER_FILE:
      begin
        aFile := Self.FFolder.FindFileById(aPIDLStructure.ItemInfo1);
        if Assigned(aFile) then
          Ext := ExtractFileExt(aFile.Name)
        else
          Ext := '.';
        OutputDebugStringFoldersD('Quering extension '+Ext);
        phiconLarge := GetExtensionIconHandle(Ext, SHGFI_LARGEICON);
        phiconSmall := GetExtensionIconHandle(Ext, SHGFI_SMALLICON);
      end;
  end;

  Result := S_OK;
end;



{ TIContextMenuImplOfflineBrowserFolder }

procedure TIContextMenuImplOfflineBrowserFolder.PopulateItems;
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
