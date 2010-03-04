unit ConstsAndVars;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses Windows, Classes, Graphics, Controls;

const
  ITEM_SEARCH_FOLDER = 1;
  ITEM_MAIN_MENU = 2;
  ITEM_SEARCH_OBJECT = 3;
  ITEM_NAVIGATE_OBJET = 4;

  ITEM_MAIN_MENU_OFFLINE_BROWSER = 20;
  ITEM_MAIN_MENU_NEW_SEARCH = 21;

  ITEM_OFFLINE_BROWSER_HOST = 101;
  ITEM_OFFLINE_BROWSER_SHARE = 102;
  ITEM_OFFLINE_BROWSER_FOLDER = 103;

  ITEMS_PER_PAGE = 40;


var
  SysIco_Big: TImageList;
  SysIco_Small: TImageList;
  ilExtraLargeIcon: TImageList;
  ilLargeIcons: TImageList;
  ilSmallIcons: TImageList;
  FDirectoryImageIndex : integer = -1;
  FIconExtIndexes : TStrings;

function Sto_GetModuleName: String;

function GetIconIndex(Extension: String; Attribus: DWORD; var TypeFichier :string):Integer;
function GetDirectoryImageIndex():Integer;
procedure CreateImageLists;
procedure FreeImageLists;
procedure OutputDebugString2(m : string);
procedure OutputDebugString3(m : string);
procedure OutputDebugStringFoldersD(m : string);
procedure OutputDebugStringFacade(m : string);

implementation

uses ShellAPI, SysUtils, Dialogs;

procedure OutputDebugString2(m : string);
begin
//  OutputDebugString(PWideChar(m));
end;

procedure OutputDebugString3(m : string);
begin
//  OutputDebugString(PWideChar(m));
end;

procedure OutputDebugStringFoldersD(m : string);
begin
  OutputDebugString(PWideChar(m));
end;

procedure OutputDebugStringFacade(m : string);
begin
  OutputDebugString(PWideChar(m));
end;

function Sto_GetModuleName: String;
var
  szFileName: array[0..MAX_PATH] of Char;
begin
  GetModuleFileName(hInstance, szFileName, MAX_PATH);
  Result := szFileName;
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

procedure CreateImageLists;
var
  SHFileInfo :TSHFileINfo;
  bBitmap : TBitmap;
  LibHandle: THandle;
begin
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

  bBitmap := TBitmap.Create;
  bBitmap.Width := 16;
  bBitmap.Height := 16;
  bBitmap.TransparentColor := clFuchsia;
  LibHandle:=Loadlibrary(PWideChar(Sto_GetModuleName()));
  try
    if LibHandle > 0 then
    begin
      bBitmap.LoadFromResourceName(LibHandle,'ONLINE_COMPUTER');
    end;
    ilSmallIcons.Add(bBitmap, bBitmap);

    if LibHandle > 0 then
    begin
      bBitmap.LoadFromResourceName(LibHandle,'OFFLINE_COMPUTER');
    end;
    ilSmallIcons.Add(bBitmap, bBitmap);
  finally
    bBitmap.Free;
    CloseHandle(LibHandle);
  end;

//  bBitmap := TBitmap.Create;
//  try
//    bBitmap.Handle := LoadBitmap(hInstance, '102');
//    ilSmallIcons.Add(bBitmap, bBitmap);
//    ilLargeIcons.Add(bBitmap, bBitmap);
//    ilExtraLargeIcon.Add(bBitmap, bBitmap);
//  finally
//    bBitmap.Free;
//  end;

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
  ilSmallIcons.Free;
  ilLargeIcons.Free;
  ilExtraLargeIcon.Free;
  SysIco_Big.Free;
  SysIco_Small.Free;
end;

initialization
  CreateImageLists;

finalization
  FreeImageLists;


end.
