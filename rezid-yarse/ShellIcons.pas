unit ShellIcons;

interface

uses Controls, Windows, Graphics, Classes;

var
  SysIco_Big: TImageList;
  SysIco_Small: TImageList;
  ilExtraLargeIcon: TImageList;
  ilLargeIcons: TImageList;
  ilSmallIcons: TImageList;
  FIconExtIndexes : TStrings;
  FDirectoryImageIndex : integer = -1;

  IconOB_OnlineComputer : TIcon;
  IconOB_OfflineComputer : TIcon;
  IconOB_OnlineSucker : TIcon;
  IconOB_Share : TIcon;
  IconOfflineBrowser : TIcon;
  Icon_SearchFolder : TIcon;
  Icon_SearchSortTypes : TIcon;
  IconYARSE : TIcon;
  IconSEARCH : TIcon;

function GetIconIndex(Extension: String; Attribus: DWORD; var TypeFichier :string):Integer;
function GetDirectoryImageIndex():Integer;
procedure CreateImageLists;
procedure FreeImageLists;

function GetRessourceIconHandle(RessourceName : string) : HICON;
function GetExtensionIconHandle(Extension : string; OrFlags : Cardinal) : HICON;
function GetExtensionTypeName(Extension : string) : string;
function GetDirectoryIconHandle(OrFlags : Cardinal) : HICON;

implementation

uses ShellAPI, ConstsAndVars, SysUtils;

procedure CreateImageLists;
var
  SHFileInfo :TSHFileINfo;
  LibHandle: THandle;
begin
  FIconExtIndexes := TStringList.Create;

  ilSmallIcons := TImageList.Create(nil);
  ilSmallIcons.Width := 16;
  ilSmallIcons.Height := 16;
  ilSmallIcons.BkColor := clFuchsia;
  ilLargeIcons := TImageList.Create(nil);
  ilLargeIcons.Width := 32;
  ilLargeIcons.Height := 32;
  ilExtraLargeIcon := TImageList.Create(nil);
  ilExtraLargeIcon.Width := 48;
  ilExtraLargeIcon.Height := 48;

  LibHandle:=Loadlibrary(PWideChar(Sto_GetModuleName()));
  try
    if LibHandle > 0 then
    begin
      IconOB_OnlineComputer := TIcon.Create;
      IconOB_OnlineComputer.LoadFromResourceName(LibHandle, 'OB_ONLINE_COMPUTER');

      IconOB_OfflineComputer := TIcon.Create;
      IconOB_OfflineComputer.LoadFromResourceName(LibHandle, 'OB_OFFLINE_COMPUTER');

      IconOB_OnlineSucker := TIcon.Create;
      IconOB_OnlineSucker.LoadFromResourceName(LibHandle, 'OB_ONLINE_SUCKER');

      IconOB_Share := TIcon.Create;
      IconOB_Share.LoadFromResourceName(LibHandle, 'OB_SHARE');

      IconYARSE := TIcon.Create;
      IconYARSE.LoadFromResourceName(LibHandle, 'YARSE');

      IconSEARCH := TIcon.Create;
      IconSEARCH.LoadFromResourceName(LibHandle, 'SEARCH');

      IconOfflineBrowser := TIcon.Create;
      IconOfflineBrowser.LoadFromResourceName(LibHandle, 'OFFLINE_BROWSER');

      Icon_SearchFolder := TIcon.Create;
      Icon_SearchFolder.LoadFromResourceName(LibHandle, 'SEARCH_FOLDER');

      Icon_SearchSortTypes := TIcon.Create;
      Icon_SearchSortTypes.LoadFromResourceName(LibHandle, 'SEARCH_SORTTYPES');
    end;
  finally
    CloseHandle(LibHandle);
  end;

  SysIco_Big := TImageList.Create(nil);
  SysIco_Big.Width := 32;
  SysIco_Big.Height := 32;
  SysIco_Big.ShareImages := true;
  SysIco_Small := TImageList.Create(nil);
  SysIco_Small.Width := 16;
  SysIco_Small.Height := 16;
  SysIco_Small.ShareImages := true;
// On met les grandes icones du system dans notre ImageList 32x32
  SysIco_Big.Handle := SHGetFileInfo('', 0, SHFileInfo, SizeOF(SHFileInfo), SHGFI_SYSICONINDEX );
// On met les petites icones du system dans notre ImageList 16x16
  SysIco_Small.Handle := SHGetFileInfo('', 0, SHFileInfo, SizeOF(SHFileInfo), SHGFI_SYSICONINDEX or SHGFI_SMALLICON );
end;

procedure FreeImageLists;
begin
  IconOB_OnlineComputer.Free;
  IconOB_OfflineComputer.Free;
  IconOB_OnlineSucker.Free;
  IconOB_Share.Free;
  IconOfflineBrowser.Free;
  IconYARSE.Free;
  IconSEARCH.Free;
  Icon_SearchFolder.Free;
  ilSmallIcons.Free;
  ilLargeIcons.Free;
  ilExtraLargeIcon.Free;
  SysIco_Big.Free;
  SysIco_Small.Free;
end;

function GetDirectoryImageIndex():Integer;
var SHFileInfo: TSHFileInfo;
begin
{On récolte les info pour l'extension}
   if FDirectoryImageIndex = -1 then
     begin
       SHGetFileInfo('', FILE_ATTRIBUTE_DIRECTORY, SHFileInfo, SizeOf(TSHFileInfo),
                     SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);

       Result := SHFileInfo.iIcon; //index de l'icone dans l'image list du systeme
       ilSmallIcons.AddImage(SysIco_Small, result);
       ilLargeIcons.AddImage(SysIco_Big, result);
       ilExtraLargeIcon.AddImage(SysIco_Big, result);
       Result := ilSmallIcons.Count - 1;
       FDirectoryImageIndex := Result;
     end
   else
     Result := FDirectoryImageIndex;
end;

function GetRessourceIconHandle(RessourceName : string) : HICON;
begin
  Result := 0;
  if RessourceName = 'OB_ONLINE_COMPUTER' then
    Result := IconOB_OnlineComputer.Handle
  else if RessourceName = 'OB_OFFLINE_COMPUTER' then
    Result := IconOB_OfflineComputer.Handle
  else if RessourceName = 'OB_ONLINE_SUCKER' then
    Result := IconOB_OnlineSucker.Handle
  else if RessourceName = 'OB_SHARE' then
    Result := IconOB_Share.Handle
  else if RessourceName = 'OFFLINE_BROWSER' then
    Result := IconOfflineBrowser.Handle
  else if RessourceName = 'SEARCH' then
    Result := IconSEARCH.Handle
  else if RessourceName = 'SEARCH_FOLDER' then
    Result := Icon_SearchFolder.Handle
  else if RessourceName = 'YARSE' then
    Result := IconYARSE.Handle
  else if RessourceName = 'SEARCH_SORTTYPES' then
    Result := Icon_SearchSortTypes.Handle;
end;

function GetIconIndex(Extension: String; Attribus: DWORD;
  var TypeFichier: string): Integer;
var SHFileInfo: TSHFileInfo;
begin
   if length(Extension) = 0 then
     Extension := '.'
   else if Extension[1] <> '.' then Extension := '.' + Extension;   //Il faut le "." avant

   if FIconExtIndexes.IndexOf(UpperCase(Extension)) = -1 then
     begin
       SHGetFileInfo(PChar(Extension), Attribus, SHFileInfo, SizeOf(TSHFileInfo),
                     SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES or SHGFI_TYPENAME);

       TypeFichier := SHFileInfo.szTypeName; //Quel est le type de fichier
       Result := SHFileInfo.iIcon; //index de l'icone dans l'image list du systeme
       ilSmallIcons.AddImage(SysIco_Small, result);
       ilLargeIcons.AddImage(SysIco_Big, result);
       ilExtraLargeIcon.AddImage(SysIco_Big, result);
       FIconExtIndexes.AddObject(UpperCase(Extension), TObject(ilSmallIcons.Count - 1));
       Result := ilSmallIcons.Count - 1;
     end
   else
     begin
       Result := integer(FIconExtIndexes.Objects[FIconExtIndexes.IndexOf(UpperCase(Extension))]);
       SHGetFileInfo(PChar(Extension), Attribus, SHFileInfo, SizeOf(TSHFileInfo),
                     SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES or SHGFI_TYPENAME);
       TypeFichier := SHFileInfo.szTypeName; //Quel est le type de fichier
     end;
end;

function GetDirectoryIconHandle(OrFlags : Cardinal) : HICON;
var
  SHFileInfo: TSHFileInfo;
begin
  SHGetFileInfo('', FILE_ATTRIBUTE_DIRECTORY, SHFileInfo, SizeOf(TSHFileInfo), SHGFI_ICON or OrFlags);
  Result := SHFileInfo.hIcon;
end;

function GetExtensionIconHandle(Extension : string; OrFlags : Cardinal) : HICON;
var
  SHFileInfo: TSHFileInfo;
begin
   if length(Extension) = 0 then
     Extension := '.'
   else if Extension[1] <> '.' then
     Extension := '.' + Extension;   //Il faut le "." avant

   SHGetFileInfo(PWideChar(Extension), 0, SHFileInfo, SizeOf(TSHFileInfo), SHGFI_ICON or SHGFI_USEFILEATTRIBUTES or OrFlags);
   Result := SHFileInfo.hIcon;
end;

function GetExtensionTypeName(Extension : string) : string;
var
  SHFileInfo: TSHFileInfo;
begin
   if length(Extension) = 0 then
     Extension := '.'
   else if Extension[1] <> '.' then
     Extension := '.' + Extension;   //Il faut le "." avant

   SHGetFileInfo(PWideChar(Extension), 0, SHFileInfo, SizeOf(TSHFileInfo), SHGFI_TYPENAME or SHGFI_USEFILEATTRIBUTES);
   Result := SHFileInfo.szTypeName;
end;

initialization
  CreateImageLists;

finalization
  FreeImageLists;


end.
