unit Searching;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses Classes, ConstsAndVars;

var
  AllSearches : TList;

implementation


initialization
  AllSearches := TList.Create;

finalization
  AllSearches.Free;

end.
