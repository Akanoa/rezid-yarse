unit SearchEngineFacade;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses Classes, OfflineBrowsing, Searching;

type

  IAbstractSearchEngineFacade = interface
    function GetCallbackTextInformation : TSearchEngineCallbackTextInformation;
    procedure SetCallbackTextInformation(new_value : TSearchEngineCallbackTextInformation);
    property CallbackTextInformation : TSearchEngineCallbackTextInformation read GetCallbackTextInformation write SetCallbackTextInformation;
    function GetCurrentComputerList() : TOnlineHostList;
    function MakeSearch(search_string : string; search_in : TSearchInEnum) : TSearch;
    function GetOfflineBrowserComputerList : TOfflineBrowserHostArray;
    function GetOfflineBrowserShareList(HostId : Integer) : TOfflineBrowserShareList;
    procedure FetchOfflineBrowserFolderContent(var Folder : TOfflineBrowserFolder);
  end;

function GetConcreteSearchEngineFacade : IAbstractSearchEngineFacade;

implementation

uses IndexeurBleuSearchEngine;

function GetConcreteSearchEngineFacade : IAbstractSearchEngineFacade;
begin
  Result := TIndexeurBleuSearchEngineFacade.Create;
end;



end.
