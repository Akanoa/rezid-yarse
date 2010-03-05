unit ConstsAndVars;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses Windows, Classes, Controls;

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
  ITEM_OFFLINE_BROWSER_FILE = 104;

  ITEMS_PER_PAGE = 40;


function Sto_GetModuleName: String;
function FormatFileSize(FileSize : Int64 ; digits : byte): string;

procedure OutputDebugString2(m : string);
procedure OutputDebugString3(m : string);
procedure OutputDebugStringFoldersD(m : string);
procedure OutputDebugStringFacade(m : string);

implementation

uses SysUtils;

function FormatFileSize(FileSize : Int64 ; digits : byte): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
var
  BufferString : string;
begin
  BufferString := '';
  if FileSize <  KB then
    BufferString := IntToStr(FileSize)+' Bytes'
  else if FileSize < MB then
    BufferString := Format('%.'+inttostr(digits)+'f '+'KB', [FileSize / KB])
  else if FileSize < GB then
    BufferString := Format('%.'+inttostr(digits)+'f '+'MB', [FileSize / MB])
  else
    BufferString := Format('%.'+inttostr(digits)+'f '+'GB', [FileSize / GB]);
  Result := BufferString;
end;

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
//  OutputDebugString(PWideChar(m));
end;

procedure OutputDebugStringFacade(m : string);
begin
//  OutputDebugString(PWideChar(m));
end;

function Sto_GetModuleName: String;
var
  szFileName: array[0..MAX_PATH] of Char;
begin
  GetModuleFileName(hInstance, szFileName, MAX_PATH);
  Result := szFileName;
end;




end.
